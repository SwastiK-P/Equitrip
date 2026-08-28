//
//  PaymentSheet.swift
//  Equitrip
//

import PhotosUI
import SwiftUI

/// Recording who actually paid for something.
///
/// The split says whose cost a booking is. This says whose money it was, and
/// until the app could record it every balance in the ledger was structurally
/// zero — the arithmetic had one of its two halves missing, so "Settled" was
/// the only answer it could ever give.
///
/// Three things, in the order they're known: the person, the method, and —
/// only when the method actually produces one — the confirmation.
struct PaymentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let travellers: [Traveller]
    let itemID: UUID
    let cost: Double
    let currencyCode: String

    @Binding var paidByID: UUID?
    @Binding var method: PaymentMethod?
    @Binding var receiptURL: URL?

    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var uploadError: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    payer
                    if paidByID != nil { methodPicker }
                    if let method, method.isOnline, paidByID != nil { receipt }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground { CanvasBackground() }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: paidByID)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: method)
        .onChange(of: pickedPhoto) { _, picked in
            guard let picked else { return }
            Task { await upload(picked) }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Who paid")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(cost > 0 ? Money.format(cost, code: currencyCode) : "No cost set yet")
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

    // MARK: - Payer

    private var payer: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Paid by")

            VStack(spacing: 0) {
                ForEach(Array(travellers.enumerated()), id: \.element.id) { index, traveller in
                    payerRow(traveller)
                    if index < travellers.count - 1 { Hairline(inset: 16) }
                }

                if paidByID != nil {
                    Hairline(inset: 16)
                    clearRow
                }
            }
            .cardSurface(corner: 20)
        }
    }

    private func payerRow(_ traveller: Traveller) -> some View {
        let on = paidByID == traveller.id

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            paidByID = traveller.id
            // Somebody paying with no method recorded leaves the ledger
            // technically right and useless to anyone reconciling it, so the
            // account's default is offered rather than nothing.
            if method == nil { method = AppSettings.defaultPaymentMethod }
        } label: {
            HStack(spacing: 12) {
                MemojiAvatar(traveller: traveller, size: 36)

                Text(traveller.id == Traveller.you.id ? "\(traveller.name) (you)" : traveller.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 6)

                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(on ? AppTheme.accent : AppTheme.inkTertiary.opacity(0.4))
                    .symbolEffect(.bounce, value: on)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// "Nobody yet" is a real answer, and one people need to be able to get
    /// back to after tapping the wrong face.
    private var clearRow: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            paidByID = nil
            method = nil
            receiptURL = nil
        } label: {
            HStack(spacing: 12) {
                SymbolBadge(symbol: "xmark", tint: AppTheme.inkTertiary, size: 36)

                Text("Nobody's paid yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)

                Spacer(minLength: 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Method

    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("How")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(PaymentMethod.allCases) { option in
                    methodTile(option)
                }
            }
        }
    }

    private func methodTile(_ option: PaymentMethod) -> some View {
        let on = method == option

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            method = option
            // A receipt attached to what turns out to have been a cash
            // payment is a contradiction; drop it rather than hiding it.
            if !option.isOnline { receiptURL = nil }
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

    // MARK: - Receipt

    private var receipt: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Receipt")

            if let receiptURL {
                VStack(spacing: 0) {
                    AsyncImage(url: receiptURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            placeholder("Couldn't load that receipt")
                        default:
                            placeholder("Loading…")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 260)

                    Hairline()

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $pickedPhoto, matching: .images) {
                            Text("Replace")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                        }

                        Spacer(minLength: 8)

                        Button("Remove") { self.receiptURL = nil }
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
                            ProgressView().controlSize(.small)
                                .frame(width: 34, height: 34)
                        } else {
                            SymbolBadge(symbol: "doc.viewfinder", tint: AppTheme.accent, size: 34)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(isUploading ? "Uploading…" : "Add a receipt")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                            Text("Everyone on this booking can see it")
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

            if let uploadError {
                Label(uploadError, systemImage: "exclamationmark.circle")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.leading, 2)
            }
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.inkTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
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
            receiptURL = try await MediaStore.shared.uploadReceipt(jpeg, for: itemID)
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
}
