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
    @State private var confirmingDelete = false

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
        guard draft.title.trimmingCharacters(in: .whitespaces).count >= 2 else { return false }
        // Exact amounts that don't add up to the cost are the one kind of
        // half-finished booking worth blocking. Every other field can be wrong
        // and only misinform somebody; this one silently loses or invents
        // money in the balances, and nothing downstream can tell that it did.
        if draft.split.isCustom, targetCost > 0, abs(unassigned) >= 0.01 { return false }
        return true
    }

    private var targetCost: Double { max(0, Double(costText) ?? 0) }

    /// Sum of what's been typed against the people on the booking.
    private var assigned: Double {
        chosenTravellers.reduce(0) { $0 + (draft.customShares[$1.id] ?? 0) }
    }

    private var unassigned: Double { targetCost - assigned }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                kindPicker

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

                if draft.split.isCustom {
                    exactAmounts
                }

                participants
                payment

                if onDelete != nil { deleteButton }

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
                selection: $draft.participantIDs,
                singleSelection: draft.split.isSinglePerson
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
        .confirmationDialog(
            "Remove this booking?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Remove booking", role: .destructive) {
                onDelete?()
                GlassToastCenter.shared.show(.init(
                    symbol: "trash",
                    tint: AppTheme.danger,
                    title: "Booking removed",
                    subtitle: "\"\(draft.title)\" is gone from the itinerary and the ledger."
                ))
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This takes it out of the itinerary and the ledger for everyone on the trip. It can't be undone.")
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
    ///
    /// Rebuilt because it was a panel inside a section inside a form: a
    /// labelled text field with its own inset, two half-width buttons under it,
    /// and then a whole boarding pass and a map crammed into the same padded
    /// box. Everything was correct and nothing had any room. The number now
    /// reads the way a flight number is written — large and monospaced, next to
    /// the glyph — the two actions are one row of the same card rather than two
    /// floating buttons, and the results that arrive are full-width blocks
    /// underneath instead of being squeezed into the input's container.
    private var flightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Flight tracking")

            VStack(spacing: 0) {
                numberField
                Hairline(inset: 0)
                lookupActions
            }
            .panelSurface(corner: 20)

            if let flightLookupError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.top, 1)
                    Text(flightLookupError)
                        .font(.system(size: 12.5))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .foregroundStyle(AppTheme.danger)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.danger.opacity(0.08), in: .rect(cornerRadius: 14, style: .continuous))
            }

            if let flight = draft.flight, flight.isResolved {
                // Editor gets the live status: you just pressed the button, so
                // it's as current as it will ever be.
                FlightTicketCard(flight: flight, fallbackDeparture: draft.time)
                FlightRouteMap(flight: flight)
                lastChecked(flight)
            } else {
                Text(
                    FlightConfig.isConfigured
                        ? "Look it up to pull in the route, terminal and scheduled times. The number is saved either way."
                        : "Live lookup needs a free AviationStack key — see FlightConfig.swift. The number is still saved either way."
                )
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: draft.flight)
    }

    private var numberField: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: "airplane", tint: ItineraryKind.flight.tint, size: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("FLIGHT NUMBER")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)

                TextField("6E 5312", text: $flightNumberText)
                    .font(.system(size: 21, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.ink)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { Task { await lookUpFlight() } }
                    .onChange(of: flightNumberText) { _, newValue in
                        let upper = newValue.uppercased()
                        if upper != newValue { flightNumberText = upper }
                        flightLookupError = nil
                    }
            }

            Spacer(minLength: 6)

            if let flight = draft.flight, flight.isResolved, let status = flight.status {
                Text(status.label.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(status.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(status.tint.opacity(0.14), in: .capsule)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var lookupActions: some View {
        HStack(spacing: 0) {
            flightAction(
                symbol: "doc.viewfinder",
                title: "Scan pass",
                detail: "Read on device",
                isEnabled: true,
                isBusy: false,
                action: presentScanner
            )

            Rectangle()
                .fill(AppTheme.cardStroke.opacity(0.09))
                .frame(width: 1, height: 34)

            flightAction(
                symbol: "arrow.triangle.2.circlepath",
                title: "Look up",
                detail: draft.flight?.isResolved == true ? "Refresh details" : "Route and times",
                isEnabled: !flightNumberText.trimmingCharacters(in: .whitespaces).isEmpty && !isLookingUpFlight,
                isBusy: isLookingUpFlight,
                action: { Task { await lookUpFlight() } }
            )
        }
    }

    private func flightAction(
        symbol: String,
        title: String,
        detail: String,
        isEnabled: Bool,
        isBusy: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 9) {
                Group {
                    if isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .frame(width: 20)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    /// When the airline last answered. A boarding pass in a plan goes stale,
    /// and a gate number from three weeks ago is worse than none.
    @ViewBuilder
    private func lastChecked(_ flight: FlightDetails) -> some View {
        if let checked = flight.lastChecked {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 10.5, weight: .semibold))
                Text("Checked \(DateFormatter.cached("d MMM, h:mm a").string(from: checked))")
                    .font(.system(size: 11.5))
            }
            .foregroundStyle(AppTheme.inkTertiary)
            .padding(.horizontal, 2)
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
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { adopt(mode) }
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

    // MARK: - Exact amounts

    /// One field per person, and a running total against the cost.
    ///
    /// The other four modes are rules — say the rule, the arithmetic follows.
    /// This one is the escape hatch for when there is no rule: three people ate
    /// and one of them had the lobster. So it's the only split that needs an
    /// editor rather than a button, and the only thing it really has to do is
    /// make the discrepancy impossible to miss while you're creating it.
    private var exactAmounts: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("What each person owes")

            VStack(spacing: 0) {
                ForEach(Array(chosenTravellers.enumerated()), id: \.element.id) { index, traveller in
                    amountRow(traveller)
                    if index < chosenTravellers.count - 1 { Hairline(inset: 14) }
                }

                Hairline(inset: 0)
                tally
            }
            .panelSurface(corner: 18)

            if chosenTravellers.count > 1 {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { evenOut() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "equal.circle")
                            .font(.system(size: 12.5, weight: .semibold))
                        Text(assigned == 0 ? "Start from an even split" : "Even out the difference")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.leading, 2)
                }
                .buttonStyle(.plain)
                .disabled(targetCost <= 0)
                .opacity(targetCost > 0 ? 1 : 0.4)
            }
        }
    }

    private func amountRow(_ traveller: Traveller) -> some View {
        HStack(spacing: 12) {
            TravellerAvatar(traveller: traveller, size: 30)

            Text(traveller.id == Traveller.you.id ? "\(traveller.name) (you)" : traveller.name)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(Money.symbol(for: currencyCode))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField(
                "0",
                text: Binding(
                    get: {
                        let amount = draft.customShares[traveller.id] ?? 0
                        return amount > 0 ? String(format: amount == amount.rounded() ? "%.0f" : "%.2f", amount) : ""
                    },
                    set: { typed in
                        let value = Double(typed.filter { $0.isNumber || $0 == "." }) ?? 0
                        if value > 0 {
                            draft.customShares[traveller.id] = value
                        } else {
                            draft.customShares.removeValue(forKey: traveller.id)
                        }
                    }
                )
            )
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 92)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    /// The reconciliation line. Green when it balances, amber when it doesn't,
    /// and it names the gap rather than just refusing to save.
    private var tally: some View {
        HStack(spacing: 8) {
            Image(systemName: balances ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(balances ? AppTheme.positive : Palette.amber)
                .contentTransition(.symbolEffect(.replace))

            Text(tallyLine)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(balances ? AppTheme.inkSecondary : Palette.amber)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .animation(.easeOut(duration: 0.2), value: balances)
    }

    private var balances: Bool { targetCost <= 0 || abs(unassigned) < 0.01 }

    private var tallyLine: String {
        guard targetCost > 0 else { return "Set a cost first, then divide it up." }
        if balances {
            return "\(Money.format(assigned, code: currencyCode)) assigned — that's all of it."
        }
        if unassigned > 0 {
            return "\(Money.format(unassigned, code: currencyCode)) still to assign."
        }
        return "\(Money.format(-unassigned, code: currencyCode)) over the cost."
    }

    /// Spreads whatever is unaccounted for across everyone evenly, or lays
    /// down an even split when nothing has been typed yet. Rounding remainder
    /// lands on the first person rather than quietly disappearing.
    private func evenOut() {
        let people = chosenTravellers
        guard !people.isEmpty, targetCost > 0 else { return }

        if assigned == 0 {
            let each = (targetCost / Double(people.count) * 100).rounded() / 100
            for person in people { draft.customShares[person.id] = each }
        } else {
            let each = (unassigned / Double(people.count) * 100).rounded() / 100
            for person in people {
                draft.customShares[person.id] = max(0, (draft.customShares[person.id] ?? 0) + each)
            }
        }

        let drift = targetCost - chosenTravellers.reduce(0) { $0 + (draft.customShares[$1.id] ?? 0) }
        if abs(drift) >= 0.01, let first = people.first {
            draft.customShares[first.id] = max(0, (draft.customShares[first.id] ?? 0) + drift)
        }
    }

    /// Switching mode, and squaring the booking with what the new mode means.
    ///
    /// "One person" against a set of five is not a state the mode can
    /// represent, and leaving it that way meant `bearers` silently picked
    /// whoever happened to sort first. Narrowing on the way in — to the payer
    /// if we know one, otherwise to you — makes the choice visible and
    /// correctable rather than arbitrary.
    private func adopt(_ mode: SplitMode) {
        draft.split = mode

        switch mode {
        case .individual:
            let existing = chosenTravellers
            if existing.count != 1 {
                let chosen = draft.paidByID.flatMap { id in travellers.first { $0.id == id } }
                    ?? travellers.first { $0.id == Traveller.you.id }
                    ?? travellers.first
                draft.participantIDs = chosen.map { [$0.id] } ?? []
            }

        case .custom:
            // An empty set means "everyone" elsewhere, but there's nothing to
            // type an amount against until it's spelled out.
            if draft.participantIDs.isEmpty {
                draft.participantIDs = Set(travellers.map(\.id))
            }

        default:
            break
        }
    }

    // MARK: - Participants

    /// A row, not a chip wall.
    ///
    /// The wall carried selection in a tint and a desaturated avatar, which
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
        case .participants:
            return chosenTravellers
        case .custom:
            return chosenTravellers.filter { (draft.customShares[$0.id] ?? 0) > 0 }
        case .organiser, .individual:
            return chosenTravellers.isEmpty ? [] : [chosenTravellers[0]]
        }
    }

    /// What one person pays, which is the number the row and the sheet both
    /// show — and the thing the editor never used to state at all.
    private var shareEach: Double? {
        // Nil under exact amounts: there is no "each" — that's the point of
        // the mode — and showing the average against every name would be a
        // number nobody owes.
        guard !draft.split.isCustom else { return nil }
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
                        TravellerAvatar(traveller: payer, size: 34)
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
        case .custom:
            return nil
        case .organiser, .individual:
            return "\(draft.split.label) — nobody else is charged for this."
        default:
            guard let each = shareEach, !bearers.isEmpty else { return nil }
            let heads = bearers.count
            return "\(Money.format(each, code: currencyCode)) each, across \(heads) \(heads == 1 ? "person" : "people")."
        }
    }

    // MARK: - Actions

    private var deleteButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            confirmingDelete = true
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
            draft.vendor = draft.vendor.trimmingCharacters(in: .whitespaces)

            // Amounts typed under "exact" and then abandoned for another mode
            // would otherwise sit in the row waiting to reappear the next time
            // somebody picks it, describing a cost that has since changed.
            if !draft.split.isCustom {
                draft.customShares = [:]
            } else {
                draft.customShares = draft.customShares.filter { draft.participantIDs.contains($0.key) }
            }

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
            GlassToastCenter.shared.show(.init(
                symbol: "checkmark.circle.fill",
                tint: AppTheme.positive,
                title: isNew ? "Booking added" : "Booking updated",
                subtitle: "\"\(saved.title)\" is saved.",
                duration: .seconds(3)
            ))
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
