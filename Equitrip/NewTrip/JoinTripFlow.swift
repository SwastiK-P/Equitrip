//
//  JoinTripFlow.swift
//  Equitrip
//

import SwiftUI
import VisionKit

/// Joining someone else's trip.
///
/// Two ways in, because the two situations are different: you're sitting next
/// to the organiser and can point a camera at their screen, or someone sent
/// you a code in a message. Both land on the same preview — nobody should
/// join a trip without first seeing whose it is and what they're signing up to.
struct JoinTripFlow: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.notificationStore) private var notifications

    /// Pre-filled when the flow was opened by a scanned link from outside.
    var initialCode: String?

    @State private var code = ""
    @State private var stage: Stage = .entry
    @State private var matched: Trip?
    @State private var error: String?
    /// Both steps hit the network now, so both can be in flight.
    @State private var isWorking = false
    @State private var showTravellers = false
    @FocusState private var codeFocused: Bool

    /// The white the scanner's burst ends on, held here rather than inside the
    /// scanner because it has to outlive it: the camera screen is torn down
    /// and the preview built while this is opaque, and the preview is then
    /// revealed by fading it off. A cover owned by the view being replaced
    /// would blink out at exactly the wrong moment.
    @State private var flash = false
    /// What the lookup found, once it has. Held rather than acted on because
    /// the burst and the network call run at the same time and either can
    /// finish first — whichever is last calls `settleScan`.
    @State private var scanOutcome: ScanOutcome?
    /// Whether the screen is currently white.
    @State private var isCovered = false

    private enum Stage: Equatable {
        case entry, scanning, preview, joined
    }

    private enum ScanOutcome {
        case found(Trip)
        case failed(String)
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            Group {
                switch stage {
                case .entry:
                    entry
                        .transition(.opacity.combined(with: .move(edge: .leading)))

                case .scanning:
                    // The camera opens out of the middle of the screen rather
                    // than sliding in from the side: a full-bleed live feed
                    // travelling sideways looks like a dropped frame.
                    scanner
                        .transition(.scale(scale: 1.06).combined(with: .opacity))

                case .preview, .joined:
                    preview
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        // The scanner carries its own controls — see `QRScanScreen.topBar` —
        // and the peach header is invisible over a camera feed anyway.
        .safeAreaBar(edge: .top, spacing: 0) {
            if stage != .scanning { header }
        }
        .overlay {
            Color.white
                .opacity(flash ? 1 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .sheet(isPresented: $showTravellers) {
            if let matched {
                // Read-only: you can look at who's coming before you commit to
                // joining, but you're not on the trip yet and have no business
                // editing its roster.
                TravellerPickerSheet(
                    travellers: .constant(matched.travellers),
                    organiserIDs: .constant(matched.organiserIDs),
                    isEditable: false
                )
            }
        }
        .onAppear {
            if let initialCode {
                code = Trip.formatCode(initialCode)
                resolve()
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(spacing: 12) {
            CircleGlyphButton(
                symbol: stage == .entry ? "xmark" : "chevron.left",
                size: 40
            ) {
                if stage == .entry {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        stage = .entry
                        matched = nil
                    }
                }
            }

            Spacer(minLength: 0)

            Text("Join a trip")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 0)

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Entry

    private var entry: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    IconTile(symbol: "qrcode.viewfinder", tint: AppTheme.accent, size: 56, corner: 18)
                        .padding(.bottom, 4)

                    Text("Got an invite?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("Scan the organiser's QR, or type the code they sent you.")
                        .font(.system(size: 14.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                Button {
                    guard DataScannerViewController.isSupported,
                          DataScannerViewController.isAvailable else {
                        error = "This device can't scan codes. Type it instead."
                        return
                    }
                    error = nil
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { stage = .scanning }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Scan QR code")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)

                HStack(spacing: 10) {
                    Hairline()
                    Text("or")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Hairline()
                }
                .padding(.vertical, 2)

                codeField

                if let error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(error)
                            .font(.system(size: 12.5))
                    }
                    .foregroundStyle(AppTheme.danger)
                }

                Button { resolve() } label: {
                    Text("Find trip")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(alignment: .trailing) {
                            if isWorking { ProgressView().controlSize(.small) }
                        }
                }
                .buttonStyle(.glass)
                .disabled(codeTooShort || isWorking)
                .opacity(codeTooShort || isWorking ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var codeTooShort: Bool { Trip.normaliseCode(code).count < 4 }

    private var codeField: some View {
        HStack(spacing: 10) {
            Image(systemName: "number")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .frame(width: 18)

            TextField("AM9-PXQ", text: $code)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.ink)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($codeFocused)
                .submitLabel(.go)
                .onSubmit { resolve() }
                .onChange(of: code) { _, new in
                    // Re-group as they type so the field always matches the
                    // shape printed on the invite card.
                    let formatted = Trip.formatCode(new)
                    if formatted != new { code = formatted }
                    error = nil
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 56)
        .panelSurface(corner: 16)
    }

    // MARK: - Scanning

    private var scanner: some View {
        QRScanScreen(
            onScan: { scanned in
                guard let extracted = Self.code(from: scanned) else { return false }
                code = Trip.formatCode(extracted)
                resolve(viaScan: true)
                return true
            },
            onCancel: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                    stage = .entry
                }
            },
            onWhiteout: {
                // Instant, not animated: this is the frame the burst ended on,
                // and easing into it would show the camera again first.
                isCovered = true
                flash = true
                settleScan()
            },
            // Holds the "got it" frame while the lookup runs, instead of the
            // sweep resuming as though nothing had been found.
            isResolving: isWorking
        )
        .ignoresSafeArea()
    }

    /// Accepts either a bare code or a full `equitrip://join/CODE` link, since
    /// a scanner hands back whatever the QR contained.
    static func code(from scanned: String) -> String? {
        if let url = URL(string: scanned), url.scheme == "equitrip" {
            return url.lastPathComponent
        }
        let clean = Trip.normaliseCode(scanned)
        return clean.count >= 4 ? clean : nil
    }

    // MARK: - Preview

    @ViewBuilder
    private var preview: some View {
        if let trip = matched {
            ScrollView {
                VStack(spacing: 18) {
                    DestinationImage(
                        query: trip.destination,
                        photo: trip.cover,
                        fallbackSymbol: trip.symbol,
                        fallbackTint: trip.tint
                    )
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 100)
                    }
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(trip.title)
                                .font(.system(size: 23, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(trip.dateRange) · \(trip.destination)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.45), radius: 6, y: 1)
                        .padding(16)
                    }
                    .clipShape(.rect(cornerRadius: 24, style: .continuous))

                    summary(of: trip)
                    travellers(of: trip)

                    if stage == .joined {
                        joinedConfirmation(trip)
                    } else {
                        joinButton(trip)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Reads `bookingCount` and `projectedCost` rather than the items.
    ///
    /// It can't read the items: `itinerary_items` is scoped to trip members by
    /// row-level security and the person on this screen isn't one yet, so the
    /// list always came back empty and a fully-planned trip previewed as
    /// "0 bookings · ₹0". The server sends the two aggregates instead.
    private func summary(of trip: Trip) -> some View {
        HStack(spacing: 0) {
            previewCell(value: "\(trip.dayCount)", label: trip.dayCount == 1 ? "day" : "days")
            previewDivider
            previewCell(value: "\(trip.bookingCount)", label: trip.bookingCount == 1 ? "booking" : "bookings")
            previewDivider
            previewCell(value: trip.projectedLabel, label: "projected cost")
        }
        .padding(.vertical, 15)
        .cardSurface(corner: 20)
    }

    private var previewDivider: some View {
        Rectangle().fill(AppTheme.cardStroke.opacity(0.10)).frame(width: 1, height: 30)
    }

    private func previewCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func travellers(of trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHO'S GOING · \(trip.travellers.count)")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            TravellerSummaryRow(travellers: trip.travellers, organisers: trip.organisers) {
                showTravellers = true
            }
        }
    }

    private func joinButton(_ trip: Trip) -> some View {
        VStack(spacing: 8) {
            Button {
                join(trip)
            } label: {
                HStack(spacing: 7) {
                    if isWorking {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isWorking ? "Joining…" : "Join this trip")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .disabled(isWorking)

            Text("You'll be added as a traveller. Nothing is charged to you until you're put on a booking.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func joinedConfirmation(_ trip: Trip) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(AppTheme.positive)
                .transition(.scale.combined(with: .opacity))

            Text("You're on the trip")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text("Everyone already on \(trip.title) gets a notification, and shares recalculate to include you.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)

            Button("Done") { dismiss() }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    /// Looks the code up on the server.
    ///
    /// This used to search the local trip list, which could only ever hold
    /// trips you're already a member of — so a code for somebody else's trip,
    /// which is the entire point of the screen, always came back "no such
    /// trip".
    private func resolve(viaScan: Bool = false) {
        codeFocused = false
        guard !isWorking else { return }

        isWorking = true
        error = nil

        Task {
            let found = await store.findTrip(code: code)
            isWorking = false

            // A scan doesn't change screens here. The burst is still playing,
            // and swapping the camera out from under it would cut the
            // animation in half; the result waits for the white instead.
            guard !viaScan else {
                scanOutcome = found.map { .found($0) } ?? .failed("No trip matches that code.")
                if isCovered { settleScan() }
                return
            }

            guard let found else {
                error = "No trip matches that code."
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { stage = .entry }
                return
            }

            matched = found
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { stage = .preview }
        }
    }

    /// Swaps what's under the white, then takes the white away.
    ///
    /// Called from both sides of the race — the burst finishing and the lookup
    /// returning — and does nothing until both have happened. The screen
    /// change itself is deliberately unanimated: it happens behind an opaque
    /// cover, so the only thing anyone sees is the fade.
    private func settleScan() {
        guard isCovered, let outcome = scanOutcome else { return }
        scanOutcome = nil
        isCovered = false

        switch outcome {
        case .found(let trip):
            matched = trip
            stage = .preview

        case .failed(let message):
            error = message
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            stage = .entry
        }

        withAnimation(.easeOut(duration: 0.45)) { flash = false }
    }

    private func join(_ trip: Trip) {
        guard !isWorking else { return }

        isWorking = true
        error = nil

        Task {
            let outcome = await store.join(trip.id)
            isWorking = false

            switch outcome {
            case .alreadyMember:
                // Not a failure — they asked to be on it and they are. Land on
                // the trip rather than bouncing them back to the code field.
                matched = store.trip(trip.id) ?? trip
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { stage = .joined }

            case .failed(let message):
                error = message
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation { stage = .entry }

            case .joined:
                matched = store.trip(trip.id) ?? trip

                // On this device the joiner is always "you", and telling you
                // that you joined is noise — `announceJoin` skips it. The
                // notification is what the *other* travellers receive.
                if let updated = store.trip(trip.id) {
                    notifications.announceJoin(of: Traveller.you, to: updated)
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { stage = .joined }
            }
        }
    }
}
