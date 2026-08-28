//
//  ItineraryItemEditor.swift
//  Equitrip
//

import SwiftUI
import VisionKit

/// Editing one booking — including the three things that make a group ledger
/// different from a shared spreadsheet: which people are actually on it, which
/// sharing rule applies to it, and whose money paid for it.
struct ItineraryItemEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ItineraryItem
    @State private var costText: String
    @State private var hasTime: Bool
    @State private var flightNumberText: String
    @State private var isLookingUpFlight = false
    @State private var flightLookupError: String?
    @State private var showBoardingPassScanner = false
    @State private var showCameraUnavailableAlert = false
    @State private var showParticipants = false
    @State private var showPayment = false
    @State private var showImageSource = false

    let travellers: [Traveller]
    let currencyCode: String
    var isNew: Bool = false
    var onSave: (ItineraryItem) -> Void
    var onDelete: (() -> Void)?

    init(
        item: ItineraryItem,
        travellers: [Traveller],
        currencyCode: String,
        isNew: Bool = false,
        onSave: @escaping (ItineraryItem) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        _draft = State(initialValue: item)
        _costText = State(initialValue: item.cost > 0 ? String(format: "%.0f", item.cost) : "")
        _hasTime = State(initialValue: item.time != nil)
        _flightNumberText = State(initialValue: item.flight?.number ?? "")
        self.travellers = travellers
        self.currencyCode = currencyCode
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var canSave: Bool {
        draft.title.trimmingCharacters(in: .whitespaces).count >= 2
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                kindPicker

                photo

                VStack(alignment: .leading, spacing: 14) {
                    GlassField(
                        label: "What is it",
                        placeholder: "Scuba diving",
                        text: $draft.title,
                        symbol: draft.kind.symbol
                    )

                    GlassField(
                        label: "Vendor",
                        placeholder: "Blue Reef Divers",
                        text: $draft.vendor,
                        symbol: "building.2"
                    )

                    GlassField(
                        label: "Cost (\(currencyCode))",
                        placeholder: "0",
                        text: $costText,
                        symbol: "indianrupeesign",
                        keyboard: .decimalPad,
                        autocapitalisation: .never
                    )
                }

                when

                if draft.kind == .flight {
                    flightSection
                }

                splitPicker
                participants
                payment

                if let onDelete { deleteButton(onDelete) }

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom) { saveBar }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .fullScreenCover(isPresented: $showBoardingPassScanner) {
            BoardingPassScanner(
                onScanned: { number in
                    showBoardingPassScanner = false
                    flightNumberText = number
                    Task { await lookUpFlight() }
                },
                onCancel: { showBoardingPassScanner = false },
                onFailure: { message in
                    showBoardingPassScanner = false
                    flightLookupError = message
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showParticipants) {
            ParticipantPickerSheet(
                travellers: travellers,
                shareEach: shareEach,
                currencyCode: currencyCode,
                selection: $draft.participantIDs
            )
        }
        .sheet(isPresented: $showImageSource) {
            ImageSourceSheet(
                suggestedQuery: photoQuerySeed,
                onPickUnsplash: { photo in
                    Task {
                        draft.cover = await CoverStore.shared.persist(photo, for: draft.id)
                    }
                },
                onPickLibrary: { data in
                    Task {
                        if let stored = await CoverStore.shared.persist(imageData: data, for: draft.id) {
                            draft.cover = stored
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showPayment) {
            PaymentSheet(
                travellers: travellers,
                itemID: draft.id,
                cost: Double(costText) ?? draft.cost,
                currencyCode: currencyCode,
                paidByID: $draft.paidByID,
                method: $draft.paymentMethod,
                receiptURL: $draft.receiptURL
            )
        }
        .alert("Camera not available", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Boarding pass scanning needs a real device's camera. Type the flight number instead.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(isNew ? "Add booking" : "Edit booking")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Photo

    /// A photo is optional and, unlike the trip cover, never auto-resolved —
    /// most bookings don't deserve one, so nothing is fetched until someone
    /// asks for it.
    private var photo: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Photo")

            Button {
                showImageSource = true
            } label: {
                ZStack {
                    if let cover = draft.cover {
                        AsyncImage(url: cover.url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: AppTheme.card
                            }
                        }
                    } else {
                        AppTheme.card
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(AppTheme.inkTertiary)
                            Text("Add a photo")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }
                    }
                }
                .frame(height: draft.cover == nil ? 90 : 140)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.07))
                }
                .overlay(alignment: .topTrailing) {
                    if draft.cover != nil {
                        HStack(spacing: 5) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Change")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.4), in: .capsule)
                        .padding(10)
                    }
                }
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var photoQuerySeed: String {
        draft.title.trimmingCharacters(in: .whitespaces).isEmpty ? draft.vendor : draft.title
    }

    // MARK: - Kind

    /// A segmented grid rather than a scrolling strip of pills.
    ///
    /// Seven categories fit in two rows at this width, so the whole set is
    /// visible at once — the strip hid half of them off the right edge, which
    /// meant scrolling to discover options you didn't know existed. Selection
    /// is carried by the tile's own tint, so the chosen one reads without
    /// needing a checkmark.
    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Category")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                spacing: 8
            ) {
                ForEach(ItineraryKind.allCases) { kind in
                    kindTile(kind)
                }
            }
        }
    }

    private func kindTile(_ kind: ItineraryKind) -> some View {
        let isSelected = draft.kind == kind

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                draft.kind = kind
                // The split rule follows the kind until someone overrides it,
                // which is right far more often than leaving a hotel on
                // "split equally".
                draft.split = kind.defaultSplit
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : kind.tint)
                    .frame(height: 20)

                Text(kind.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(kind.tint) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(isSelected ? 0 : 0.07))
            }
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - When

    private var when: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("When")

            VStack(spacing: 0) {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                    .padding(.horizontal, 14)
                    .frame(height: 52)

                Hairline(inset: 14)

                Toggle("Has a set time", isOn: $hasTime)
                    .padding(.horizontal, 14)
                    .frame(height: 52)

                if hasTime {
                    Hairline(inset: 14)

                    DatePicker(
                        "Starts at",
                        selection: Binding(
                            get: { draft.time ?? .at(9, 0, on: draft.date) },
                            set: { draft.time = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                }
            }
            .font(.system(size: 15))
            .tint(AppTheme.accent)
            .panelSurface(corner: 18)
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: hasTime)
            .onChange(of: hasTime) { _, on in
                draft.time = on ? .at(9, 0, on: draft.date) : nil
            }
            .onChange(of: draft.date) { _, day in
                // Keep the time on the day it belongs to when the day moves.
                if let time = draft.time {
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
                    draft.time = .at(parts.hour ?? 9, parts.minute ?? 0, on: day)
                }
            }
        }
    }

    // MARK: - Flight tracking

    /// Flight number is the only field anyone types; everything else here —
    /// route, terminal, scheduled times, live status — comes from a lookup,
    /// whether that number was typed or lifted off a scanned boarding pass.
    private var flightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Flight tracking")

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    GlassField(
                        label: "Flight number",
                        placeholder: "6E 5312",
                        text: $flightNumberText,
                        symbol: "number",
                        autocapitalisation: .characters
                    )
                    .onChange(of: flightNumberText) { _, newValue in
                        flightNumberText = newValue.uppercased()
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        presentScanner()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Scan boarding pass")
                                .font(.system(size: 13.5, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.glass)

                    Button {
                        Task { await lookUpFlight() }
                    } label: {
                        HStack(spacing: 6) {
                            if isLookingUpFlight {
                                ProgressView().controlSize(.mini)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Text("Look up")
                                .font(.system(size: 13.5, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.glass)
                    .disabled(flightNumberText.trimmingCharacters(in: .whitespaces).isEmpty || isLookingUpFlight)
                }

                if let flight = draft.flight, flight.isResolved {
                    // Editor gets the live status: you just pressed the button,
                    // so it's as current as it will ever be.
                    FlightTicketCard(flight: flight, fallbackDeparture: draft.time)
                    FlightRouteMap(flight: flight)
                } else if !FlightConfig.isConfigured {
                    Text("Live lookup needs a free AviationStack key — see FlightConfig.swift. The number is still saved either way.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                if let flightLookupError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(flightLookupError)
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(AppTheme.danger)
                }
            }
            .padding(14)
            .panelSurface(corner: 18)
        }
    }

    private func presentScanner() {
        guard VNDocumentCameraViewController.isSupported else {
            showCameraUnavailableAlert = true
            return
        }
        flightLookupError = nil
        showBoardingPassScanner = true
    }

    @MainActor
    private func lookUpFlight() async {
        let number = flightNumberText.trimmingCharacters(in: .whitespaces)
        guard !number.isEmpty else { return }

        isLookingUpFlight = true
        flightLookupError = nil
        defer { isLookingUpFlight = false }

        do {
            let details = try await FlightLookupService.shared.lookup(
                number: number,
                bookingDate: draft.date
            )
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                draft.flight = details
                flightNumberText = details.number
                // The airline's own departure time beats a hand-typed one, and
                // the service has already moved it onto this booking's date.
                if let scheduled = details.scheduledDeparture {
                    draft.time = scheduled
                    hasTime = true
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            flightLookupError = (error as? FlightLookupService.LookupError)?.errorDescription ?? "Couldn't look that up."
        }
    }

    // MARK: - Split

    /// Two rows of tiles instead of a five-item radio list.
    ///
    /// The list read as settings — five rows of near-identical text where the
    /// selected one was distinguished only by a tick. As tiles the choice is
    /// visual and the consequence is stated once, underneath, for whichever is
    /// selected, rather than repeated five times in grey.
    private var splitPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("How the cost is shared")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(SplitMode.allCases) { mode in
                    splitTile(mode)
                }
            }

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.top, 1)

                Text(draft.split.detail)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
    }

    private func splitTile(_ mode: SplitMode) -> some View {
        let isSelected = draft.split == mode

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { draft.split = mode }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : AppTheme.inkSecondary)
                    .frame(height: 18)

                Text(mode.shortLabel)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(isSelected ? .white : AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(isSelected ? 0 : 0.07))
            }
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Participants

    /// A row, not a chip wall.
    ///
    /// The wall carried selection in a tint and a desaturated memoji, which
    /// nobody reads as on or off, and eight people wrapped onto four rows that
    /// pushed the split rule and the save bar off screen. The row states who's
    /// on it and what they each owe in one line; the sheet behind it uses real
    /// checkmarks.
    private var participants: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Who's on this")

            ParticipantSummaryRow(
                travellers: chosenTravellers,
                shareEach: shareEach,
                currencyCode: currencyCode
            ) {
                showParticipants = true
            }

            if let note = shareNote {
                Text(note)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .padding(.leading, 2)
            }
        }
    }

    /// Empty means everybody, here as everywhere else in the app.
    private var chosenTravellers: [Traveller] {
        draft.participantIDs.isEmpty
            ? travellers
            : travellers.filter { draft.participantIDs.contains($0.id) }
    }

    /// Who the cost actually lands on, by the chosen rule. The same decision
    /// `Trip.bearers(of:)` makes, applied to a draft that isn't on a trip yet.
    private var bearers: [Traveller] {
        switch draft.split {
        case .equal:
            return travellers
        case .participants, .room:
            return chosenTravellers
        case .organiser, .individual:
            return chosenTravellers.isEmpty ? [] : [chosenTravellers[0]]
        }
    }

    /// What one person pays, which is the number the row and the sheet both
    /// show — and the thing the editor never used to state at all.
    private var shareEach: Double? {
        let cost = Double(costText) ?? 0
        guard cost > 0, !bearers.isEmpty else { return nil }
        return cost / Double(bearers.count)
    }

    // MARK: - Payment

    private var payment: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Who paid")

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showPayment = true
            } label: {
                HStack(spacing: 12) {
                    if let payer = paidBy {
                        MemojiAvatar(traveller: payer, size: 34)
                    } else {
                        SymbolBadge(symbol: "creditcard", tint: AppTheme.accent, size: 34)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(paidBy.map { $0.id == Traveller.you.id ? "You paid" : "\($0.name) paid" }
                            ?? "Nobody's paid yet")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.ink)

                        Text(paymentCaption)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    if draft.receiptURL != nil {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .panelSurface(corner: 18)
        }
    }

    private var paidBy: Traveller? {
        draft.paidByID.flatMap { id in travellers.first { $0.id == id } }
    }

    private var paymentCaption: String {
        guard paidBy != nil else { return "Their expenses go up by the full amount" }
        guard let method = draft.paymentMethod else { return "Method not recorded" }
        return draft.receiptURL == nil ? method.label : "\(method.label) · receipt attached"
    }

    /// Shows the arithmetic rather than making people trust it.
    private var shareNote: String? {
        let cost = Double(costText) ?? 0
        guard cost > 0 else { return nil }

        switch draft.split {
        case .organiser, .individual:
            return "\(draft.split.label) — nobody else is charged for this."
        default:
            guard let each = shareEach, !bearers.isEmpty else { return nil }
            let heads = bearers.count
            return "\(Money.format(each, code: currencyCode)) each, across \(heads) \(heads == 1 ? "person" : "people")."
        }
    }

    // MARK: - Actions

    private func deleteButton(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            Text("Remove booking")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .panelSurface(corner: 18)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var saveBar: some View {
        Button {
            draft.cost = max(0, Double(costText) ?? 0)
            draft.title = draft.title.trimmingCharacters(in: .whitespaces)

            let trimmedFlightNumber = flightNumberText.trimmingCharacters(in: .whitespaces)
            if draft.kind == .flight, !trimmedFlightNumber.isEmpty {
                // Keep whatever a lookup already resolved for this exact
                // number; a hand-edited number invalidates that lookup rather
                // than carrying stale route/time data forward under it.
                if draft.flight?.number != trimmedFlightNumber {
                    draft.flight = FlightDetails(number: trimmedFlightNumber)
                }
            } else if draft.kind != .flight {
                draft.flight = nil
            }

            // Fire-and-forget: the glyph is a nicety, so it resolves after the
            // booking is already saved rather than making the user wait on it.
            let saved = draft
            onSave(saved)
            Task {
                if let symbol = await ActivityIconSuggester.symbol(for: saved.title, kind: saved.kind),
                   symbol != saved.suggestedSymbol {
                    var updated = saved
                    updated.suggestedSymbol = symbol
                    onSave(updated)
                }
            }
            dismiss()
        } label: {
            Text(isNew ? "Add booking" : "Save changes")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.inkSecondary)
    }

}
