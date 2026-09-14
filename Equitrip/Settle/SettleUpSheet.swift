//
//  SettleUpSheet.swift
//  Equitrip
//

import Photos
import PhotosUI
import SwiftUI

/// The payer's side of settling up: "I paid this, here's how, here's proof."
///
/// Deliberately doesn't touch anyone's balance. Submitting this writes a
/// `.pending` settlement and nothing else — the figure only moves once the
/// person on the other end agrees, which is the whole reason this app can say
/// "settled" and mean it.
struct SettleUpSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    let trip: Trip
    let toID: UUID
    let suggestedAmount: Double

    @State private var amountText: String
    @State private var method: PaymentMethod
    @State private var note = ""
    @State private var proofURL: URL?

    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var isSaving = false
    @FocusState private var amountFocused: Bool

    @State private var copiedVPA = false
    @State private var copyResetToken = UUID()
    @State private var qrSaved = false
    @State private var qrSaveFailed = false
    @State private var qrSaveResetToken = UUID()
    @State private var qrEnlarged = false
    @State private var leftColumnHeight: CGFloat = 104
    @Namespace private var qrNamespace

    init(trip: Trip, toID: UUID, suggestedAmount: Double) {
        self.trip = trip
        self.toID = toID
        self.suggestedAmount = suggestedAmount
        _amountText = State(initialValue: Self.formatted(suggestedAmount))
        _method = State(initialValue: AppSettings.defaultPaymentMethod)
    }

    private var recipient: Traveller? { trip.traveller(toID) }
    private var amount: Double { Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private var isValid: Bool { amount > 0 && amount <= suggestedAmount + 0.01 }

    /// Their VPA, as they set it in their own Settings — never something
    /// typed in on their behalf here, or it'd address the payment wherever
    /// whoever's settling up happens to type.
    private var recipientVPA: String? {
        recipient?.upiVPA.flatMap { UPILink.looksValid($0) ? $0 : nil }
    }

    private var upiURL: URL? {
        guard let recipientVPA else { return nil }
        return UPILink.payURL(
            vpa: recipientVPA,
            payeeName: recipient?.name ?? "Equitrip",
            amount: amount,
            note: trip.title
        )
    }

    private var qrImage: UIImage? {
        guard let upiURL else { return nil }
        return QRCode.make(from: upiURL.absoluteString)
    }

    // Content scrolls under both bars rather than stopping above them —
    // `safeAreaBar` plus `scrollEdgeEffectStyle` is the same pairing the
    // Trips tab uses for its top bar; here it runs both edges, since the
    // footer's single button wants the same soft fade the header gets
    // rather than the flat material slab it had before.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                amountField
                methodPicker
                if method == .upi { upiSection }
                if method.isOnline { proof }
                noteField
                if let uploadError {
                    Label(uploadError, systemImage: "exclamationmark.circle")
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.danger)
                }
                Color.clear.frame(height: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaBar(edge: .bottom, spacing: 0) { footer }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground { CanvasBackground() }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: method)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: recipientVPA)
        .onChange(of: pickedPhoto) { _, picked in
            guard let picked else { return }
            Task { await upload(picked) }
        }
        .overlay { enlargedQR }
    }

    /// The QR blown up full-size over a blurred backdrop. Lives as an
    /// overlay on the whole sheet rather than a `.sheet`/`.fullScreenCover`
    /// — a system presentation would animate in as its own sliding sheet,
    /// which reads as navigating somewhere rather than a tap just zooming
    /// the thing already on screen.
    @ViewBuilder
    private var enlargedQR: some View {
        if qrEnlarged, let qrImage {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { dismissEnlargedQR() }
                    .transition(.opacity)

                VStack(spacing: 18) {
                    qrTile(qrImage, size: 280, cornerRadius: 28, isSource: qrEnlarged)
                        .shadow(color: .black.opacity(0.18), radius: 24, y: 10)

                    if let recipientVPA {
                        Text(recipientVPA)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }
            }
        }
    }

    /// One QR tile — the white rounded square plus the code itself — shared
    /// by the inline and enlarged spots. `matchedGeometryEffect` only
    /// interpolates smoothly when the source and destination are built the
    /// same way; two views that happened to look alike but were assembled
    /// differently is what made the enlarge read as one QR swapping for
    /// another instead of the same one growing.
    private func qrTile(_ qrImage: UIImage, size: CGFloat, cornerRadius: CGFloat, isSource: Bool) -> some View {
        ZStack {
            // An explicit opaque fill under the image, not a `.background`
            // modifier — against a blurred backdrop a `.background` can read
            // as tinted at the rounded corners where it's compositing with
            // what's behind it. This is the container itself, solid white,
            // nothing else showing through.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white)

            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(size * 0.08)
        }
        .frame(width: size, height: size)
        .compositingGroup()
        .matchedGeometryEffect(id: "qr", in: qrNamespace, isSource: isSource)
    }

    private func dismissEnlargedQR() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            qrEnlarged = false
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settle with \(recipient?.name ?? "them")")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(trip.title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Amount

    private var amountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Amount")

            HStack(spacing: 10) {
                if let recipient {
                    TravellerAvatar(traveller: recipient, size: 44)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(Money.symbol(for: trip.currencyCode))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.inkTertiary)

                        // The digits people actually see are a `Text`, not the
                        // `TextField` itself — a raw text field just swaps its
                        // characters with no motion, which read as dead the
                        // moment a preset or a backspace changed more than one
                        // digit at once. The field is still what's underneath
                        // and focused; it's made invisible and only supplies
                        // the caret and the keyboard, while this rolls each
                        // digit the way the balance figures elsewhere do.
                        ZStack(alignment: .leading) {
                            Text(amountText.isEmpty ? "0" : amountText)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(amountText.isEmpty ? AppTheme.inkTertiary : AppTheme.ink)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: amountText)
                                .allowsHitTesting(false)

                            TextField("", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.clear)
                                .tint(AppTheme.accent)
                                .focused($amountFocused)
                        }
                    }

                    Text("You owe \(recipient?.name ?? "them") up to \(Money.format(suggestedAmount, code: trip.currencyCode))")
                        .font(.system(size: 12))
                        .foregroundStyle(amount > suggestedAmount + 0.01 ? AppTheme.danger : AppTheme.inkTertiary)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .cardSurface(corner: 20)
        }
    }

    // MARK: - Method

    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("How you paid")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(PaymentMethod.allCases) { option in
                    if (option == PaymentMethod.card || option == PaymentMethod.other) {
                        
                    } else {
                        methodTile(option)
                    }
                }
            }
        }
    }

    private func methodTile(_ option: PaymentMethod) -> some View {
        let on = method == option

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            method = option
            if !option.isOnline { proofURL = nil }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(on ? .white : AppTheme.inkSecondary)
                    .frame(height: 18)

                Text(option.label)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(on ? .white : AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(on ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07))
            }
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - UPI

    /// Their VPA, exactly as they set it in their own Settings, and the
    /// QR/link it turns into. `pa` on a UPI intent has to be the money's
    /// actual destination, so this only ever shows what they set for
    /// themselves — never an editable field that would let a payment get
    /// typed in on their behalf and land wherever the typer meant.
    private var upiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Their UPI ID")

            if let recipientVPA {
                if let qrImage {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Scan & pay")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)

                            Button {
                                copyVPA(recipientVPA)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: copiedVPA ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(copiedVPA ? "Copied" : recipientVPA)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer(minLength: 0)
                                }
                                .foregroundStyle(AppTheme.inkSecondary)
                                .padding(.horizontal, 12)
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.card, in: .rect(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(AppTheme.cardStroke.opacity(0.1))
                                }
                            }
                            .buttonStyle(PressableButtonStyle())

                            Button {
                                saveQRToPhotos()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: qrSaved ? "checkmark" : "square.and.arrow.down")
                                        .font(.system(size: 12.5, weight: .semibold))
                                    Text(qrSaved ? "Saved" : (qrSaveFailed ? "Couldn't save" : "Save QR"))
                                        .font(.system(size: 13.5, weight: .semibold))
                                }
                                .foregroundStyle(qrSaveFailed ? AppTheme.danger : AppTheme.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(AppTheme.card, in: .rect(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder((qrSaveFailed ? AppTheme.danger : AppTheme.accent).opacity(0.3))
                                }
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                        .background {
                            GeometryReader { geo in
                                Color.clear.preference(key: LeftColumnHeightKey.self, value: geo.size.height)
                            }
                        }

                        // Square, and exactly as tall as the column beside it
                        // — measured live rather than guessed, so it stays
                        // matched however that column's content changes.
                        qrTile(qrImage, size: leftColumnHeight, cornerRadius: 16, isSource: !qrEnlarged)
                            .opacity(qrEnlarged ? 0 : 1)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                                    qrEnlarged = true
                                }
                            }
                    }
                    .onPreferenceChange(LeftColumnHeightKey.self) { leftColumnHeight = $0 }
                    .padding(16)
                    .background(AppTheme.accent.opacity(0.1), in: .rect(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(AppTheme.accent.opacity(0.14))
                    }
                }
            } else {
                Label(
                    "\(recipient?.name ?? "They") haven't added a UPI ID yet.",
                    systemImage: "exclamationmark.circle"
                )
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .panelSurface(corner: 14)
            }
        }
    }

    /// Flips the pill to "Copied" and back on its own after a beat, rather
    /// than staying stuck until something else happens to change — nothing
    /// else was ever going to.
    private func copyVPA(_ vpa: String) {
        UIPasteboard.general.string = vpa
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        copiedVPA = true
        let token = UUID()
        copyResetToken = token
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if copyResetToken == token { copiedVPA = false }
        }
    }

    /// Writes the QR straight to Photos rather than routing through the
    /// share sheet — "save" shouldn't need a second screen and a "Save
    /// Image" tap of its own to mean what it says.
    private func saveQRToPhotos() {
        guard let qrImage else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                flashQRSaveResult(failed: true)
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: qrImage)
                }
                flashQRSaveResult(failed: false)
            } catch {
                flashQRSaveResult(failed: true)
            }
        }
    }

    private func flashQRSaveResult(failed: Bool) {
        qrSaved = !failed
        qrSaveFailed = failed
        let token = UUID()
        qrSaveResetToken = token
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if qrSaveResetToken == token {
                qrSaved = false
                qrSaveFailed = false
            }
        }
    }

    // MARK: - Proof

    private var proof: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Proof of payment")

            if let proofURL {
                VStack(spacing: 0) {
                    AsyncImage(url: proofURL) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFit()
                        case .failure: placeholder("Couldn't load that image")
                        default: placeholder("Loading…")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 220)

                    Hairline()

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $pickedPhoto, matching: .images) {
                            Text("Replace")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Spacer(minLength: 8)

                        Button("Remove") { self.proofURL = nil }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.danger)
                            .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .cardSurface(corner: 20)
            } else {
                PhotosPicker(selection: $pickedPhoto, matching: .images) {
                    HStack(spacing: 10) {
                        if isUploading {
                            ProgressView().controlSize(.small).frame(width: 34, height: 34)
                        } else {
                            SymbolBadge(symbol: "doc.viewfinder", tint: AppTheme.accent, size: 34)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(isUploading ? "Uploading…" : "Attach a screenshot")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                            Text("Optional, but it settles arguments fast")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }

                        Spacer(minLength: 6)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                .panelSurface(corner: 18)
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.inkTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
    }

    // MARK: - Note

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Note (optional)")

            TextField("e.g. \"Half now, rest at the airport\"", text: $note, axis: .vertical)
                .font(.system(size: 14.5))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1...3)
                .padding(13)
                .cardSurface(corner: 16, shadow: 6)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            markAsPaidButton
                .padding(.horizontal, 20)
                .padding(.top, 10)

            Text("\(recipient?.name ?? "They") will get a request to confirm it")
                .font(.system(size: 11.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.bottom, 12)
        }
        // The scroll view's own soft bottom edge effect is what fades the
        // content into this bar — a flat material behind the footer as well
        // would double up and flatten that gradient back into a hard line.
    }

    /// No icon and a shorter bar than the app's usual `PrimaryButton` — this
    /// is the one action on a screen that's otherwise all fields, not the
    /// kind of full-width commit the taller CTA is for elsewhere. Real
    /// Liquid Glass rather than a flat fill: this is the single floating
    /// button on the sheet, the case `GlassForm.swift` carves out rather
    /// than the repeated-many-times one it warns against.
    private var markAsPaidButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            submit()
        } label: {
            ZStack {
                Text("Mark as paid")
                    .font(.system(size: 15, weight: .semibold))
                    .opacity(isSaving ? 0 : 1)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .opacity(isSaving ? 1 : 0)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isSaving || !isValid)
        .opacity(isValid ? 1 : 0.5)
        .glassEffect(.regular.tint(AppTheme.accent).interactive(), in: .capsule)
        .animation(.easeOut(duration: 0.2), value: isSaving)
        .animation(.easeOut(duration: 0.2), value: isValid)
    }

    private func submit() {
        guard isValid else { return }
        isSaving = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        store.createSettlement(
            tripID: trip.id,
            toID: toID,
            amount: amount,
            method: method,
            proofURL: proofURL,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        dismiss()
    }

    @MainActor
    private func upload(_ picked: PhotosPickerItem) async {
        isUploading = true
        uploadError = nil
        defer {
            isUploading = false
            pickedPhoto = nil
        }

        guard let data = try? await picked.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = image.jpegForUpload() else {
            uploadError = "Couldn't read that image."
            return
        }

        do {
            // Keyed by a fresh id rather than the eventual settlement's — the
            // settlement doesn't exist until submit, and the upload has to
            // start the moment someone picks a photo, not after.
            proofURL = try await MediaStore.shared.uploadSettlementProof(jpeg, for: UUID())
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            uploadError = (error as? MediaStore.StoreError)?.errorDescription
                ?? AuthService.message(for: error)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9)
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.leading, 2)
    }

    private static func formatted(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.2f", value)
    }
}

/// The height of the UPI card's text/button column, so the QR beside it can
/// be sized to match rather than sitting at a fixed size that happens to be
/// taller or shorter than its neighbour.
private struct LeftColumnHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 104
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
