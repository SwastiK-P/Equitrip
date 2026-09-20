//
//  TripReviewStage.swift
//  Equitrip
//

import SwiftUI

/// The last stop before a trip becomes the group's shared record.
///
/// Everything here is editable, including everything the model produced. That
/// matters more for the import route than the manual one: an extraction that
/// can't be corrected is worse than no extraction, because the errors become
/// someone else's money.
struct TripReviewStage: View {
    @Binding var draft: TripDraft
    var onCreate: () -> Void

    @State private var editingItem: ItineraryItem?
    @State private var isAddingItem = false
    @State private var showTravellerPicker = false
    @State private var showLocationPicker = false
    @State private var showImageSource = false
    @State private var showDates = false
    @State private var showCurrencyPicker = false
    @State private var isEditingTitle = false
    /// What the consistency check has found so far, and how far it has got.
    /// Derived from the bookings on every change and never stored — a warning
    /// that outlived the booking it was about would be the worse bug.
    @State private var issues: [ItineraryIssue] = []
    @State private var checkState: ItineraryCheckState = .checking

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                cover

                // The span and the currency, which this screen used not to
                // show at all: you could set dates on the previous step, come
                // here to "check it over", and find the one thing you'd just
                // typed nowhere on the page. Both rows edit in place, because
                // a review that can only be read is a receipt.
                essentials

                if draft.wasImported { importNote }

                // Under the note about how the bookings were read, above the
                // bookings themselves: the same reading order as the sentence
                // "here is what we found, and here is what looks wrong with
                // it". Shown on the hand-built route too — a trip typed in by
                // hand double-books an afternoon just as readily as an
                // imported one.
                if !draft.items.isEmpty {
                    ItineraryIssueCard(state: checkState, issues: issues, bookingCount: draft.items.count) { id in
                        editingItem = draft.items.first { $0.id == id }
                    }
                }

                travellers

                // Shown on both routes now. It used to be here only for
                // imported trips, on the grounds that the hand-built route had
                // already chosen a typeface on its form — which put a styling
                // decision in the middle of the questions a trip can't exist
                // without, and left the people who imported a document
                // choosing it here anyway.
                titleStyle

                bookings
                totals

                Color.clear.frame(height: 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .task(id: checkKey) { await runCheck() }
        .safeAreaInset(edge: .bottom) { createBar }
        .sheet(isPresented: $showTravellerPicker) {
            TravellerPickerSheet(travellers: $draft.travellers)
        }
        .sheet(isPresented: $showDates) {
            DateRangeSheet(start: $draft.startDate, end: $draft.endDate)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $draft.currencyCode)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(initial: draft.destination) { picked in
                draft.destination = picked
                // The old cover was fetched for the old place; drop it so the
                // new destination resolves its own rather than keeping a
                // photograph of somewhere the group is no longer going.
                draft.cover = nil
            }
        }
        .sheet(isPresented: $showImageSource) {
            ImageSourceSheet(
                suggestedQuery: draft.destination.isEmpty ? draft.title : draft.destination,
                onPickUnsplash: { photo in
                    let tripID = draft.id
                    Task {
                        let stored = await CoverStore.shared.persist(photo, for: tripID)
                        draft.cover = stored
                    }
                },
                onPickLibrary: { data in
                    let tripID = draft.id
                    Task {
                        if let stored = await CoverStore.shared.persist(imageData: data, for: tripID) {
                            draft.cover = stored
                        }
                    }
                }
            )
        }
        .sheet(item: $editingItem) { item in
            ItineraryItemEditor(
                item: item,
                travellers: draft.travellers,
                currencyCode: draft.currencyCode,
                onSave: { updated in
                    if let index = draft.items.firstIndex(where: { $0.id == updated.id }) {
                        draft.items[index] = updated
                    }
                },
                onDelete: {
                    withAnimation { draft.items.removeAll { $0.id == item.id } }
                }
            )
        }
        .sheet(isPresented: $isAddingItem) {
            ItineraryItemEditor(
                item: ItineraryItem(
                    title: "",
                    date: draft.startDate,
                    participantIDs: Set(draft.travellers.map(\.id))
                ),
                travellers: draft.travellers,
                currencyCode: draft.currencyCode,
                isNew: true,
                onSave: { new in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        // The editor saves twice: once straight away, and
                        // again a moment later with the glyph it worked out in
                        // the background. Appending both put every booking on
                        // the trip twice. `TripStore.addItem` upserts for this
                        // exact reason; so does this.
                        if let index = draft.items.firstIndex(where: { $0.id == new.id }) {
                            draft.items[index] = new
                        } else {
                            draft.items.append(new)
                            expandSpanToFit(new)
                        }
                    }
                }
            )
        }
    }

    // MARK: - Consistency check

    /// Only the fields the check actually reads.
    ///
    /// Keying the task on `draft.items` wholesale would restart the model
    /// every time a cover photo resolved or somebody was added to a split —
    /// neither of which can change whether two bookings clash.
    private var checkKey: String {
        let bookings = draft.items.map { item in
            "\(item.id)|\(item.date.timeIntervalSince1970)|\(item.time?.timeIntervalSince1970 ?? -1)"
                + "|\(item.kind.rawValue)|\(item.title)|\(item.flight?.number ?? "")"
        }
        return (bookings + [
            "\(draft.startDate.timeIntervalSince1970)",
            "\(draft.endDate.timeIntervalSince1970)"
        ]).joined(separator: ";")
    }

    /// Arithmetic first and instantly, judgement after and gradually.
    ///
    /// The rule pass is synchronous and offline, so its findings are on screen
    /// before the model has produced a token — which means the card is never
    /// an empty box with a spinner in it, and a device that can't run Apple
    /// Intelligence at all still gets the half of this that is subtraction.
    @MainActor
    private func runCheck() async {
        guard !draft.items.isEmpty else {
            issues = []
            checkState = .done(usedFallback: false)
            return
        }

        // Editing a booking changes the key on every save; a burst of edits
        // shouldn't start a burst of model passes. `task(id:)` has already
        // cancelled the previous one by the time this runs.
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }

        let span = min(draft.startDate, draft.endDate)...max(draft.startDate, draft.endDate)
        let rules = ItineraryConsistency.check(draft.items, span: span)
        issues = rules

        guard case .ready = ItineraryInspector.availability else {
            checkState = .done(usedFallback: true)
            return
        }

        checkState = .checking

        let stream = ItineraryInspector.stream(
            items: draft.items,
            destination: draft.destination,
            known: rules
        )

        for await found in stream {
            guard !Task.isCancelled else { return }
            issues = ItineraryConsistency.ordered(rules + found)
        }

        guard !Task.isCancelled else { return }
        checkState = .done(usedFallback: false)
    }

    // MARK: - Cover

    /// The same card the first step builds, so the trip you named on the way
    /// in is the thing you check on the way out — and everything on it is
    /// still editable here, which for an imported trip is the only chance
    /// anybody gets to correct what the reader made of it.
    private var cover: some View {
        TripCoverCard(
            draft: $draft,
            height: 190,
            onChangePhoto: { showImageSource = true },
            onChangeDestination: { showLocationPicker = true },
            isEditingTitle: $isEditingTitle
        )
    }

    // MARK: - Essentials

    /// When the trip runs and what it's counted in.
    ///
    /// Both are facts the rest of this screen quietly depends on — every
    /// booking's day is checked against the span, every figure below is
    /// printed in the currency — and neither was visible here before.
    private var essentials: some View {
        VStack(spacing: 0) {
            essentialRow(
                symbol: "calendar",
                label: spanLabel,
                value: draft.dayCount.pluralised("day")
            ) {
                showDates = true
            }

            Hairline(inset: 16)

            essentialRow(
                symbol: "banknote",
                label: "Settled in",
                value: "\(Money.symbol(for: draft.currencyCode))  \(draft.currencyCode)"
            ) {
                showCurrencyPicker = true
            }
        }
        .cardSurface(corner: 20)
    }

    /// "Sun 20 Sep → Wed 23 Sep", or one date when the trip is a single day.
    private var spanLabel: String {
        let format = DateFormatter.cached("EEE d MMM")
        let from = format.string(from: draft.startDate)
        guard draft.dayCount > 1 else { return from }
        return "\(from) → \(format.string(from: draft.endDate))"
    }

    private func essentialRow(
        symbol: String,
        label: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 18)

                Text(label)
                    .font(.system(size: 14.5, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(value)
                    .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .contentTransition(.numericText())

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Style

    /// The typeface the trip's name is set in, previewed on the cover above as
    /// it's picked.
    private var titleStyle: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Title style", caption: draft.titleStyle.name)
            TripTitleStylePicker(title: draft.title, selection: $draft.titleStyle)
        }
    }

    /// Says which reader produced this, so nobody assumes an accuracy the
    /// pattern-matching path doesn't have.
    private var importNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: draft.usedFallbackParser ? "exclamationmark.circle.fill" : "apple.intelligence")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(draft.usedFallbackParser ? Palette.amber : AppTheme.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(draft.usedFallbackParser ? "Read by pattern matching" : "Powered by Apple Intelligence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(
                    draft.usedFallbackParser
                        ? "Apple Intelligence wasn't available, so this is a rough pass. Check the times and amounts carefully."
                        : "Apple Intelligence pulled these out of \(draft.sourceFileName ?? "your document"). Worth a quick check before the group sees it."
                )
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .panelSurface(corner: 18)
    }

    // MARK: - Travellers

    private var travellers: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Travellers", caption: "\(draft.travellers.count)")

            TravellerSummaryRow(travellers: draft.travellers) {
                showTravellerPicker = true
            }
        }
    }

    // MARK: - Bookings

    private var bookings: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Bookings",
                caption: draft.items.isEmpty ? nil : "\(draft.items.count)",
                actionTitle: "Add"
            ) {
                isAddingItem = true
            }

            if draft.items.isEmpty {
                emptyBookings
            } else {
                VStack(spacing: 16) {
                    ForEach(groupedItems, id: \.0) { day, items in
                        daySection(day: day, items: items)
                    }
                }
            }
        }
    }

    private var groupedItems: [(Date, [ItineraryItem])] {
        Dictionary(grouping: draft.items.sorted(by: Trip.chronological)) { $0.day }
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }

    private func daySection(day: Date, items: [ItineraryItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DateFormatter.cached("EEEE d MMMM").string(from: day).uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        editingItem = item
                    } label: {
                        ReviewItemRow(item: item, trip: draft)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < items.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
        }
    }

    private var emptyBookings: some View {
        Button { isAddingItem = true } label: {
            VStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)

                Text("Add your first booking")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("Flights, stays, activities — or add them later as they're booked.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        AppTheme.cardStroke.opacity(0.16),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                    )
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Totals

    private var totals: some View {
        VStack(spacing: 0) {
            totalRow(
                label: "Booked so far",
                value: Money.format(draft.totalCost, code: draft.currencyCode),
                emphasised: true
            )

            Hairline(inset: 16)

            totalRow(
                label: "Even split, \(draft.travellers.count.pluralised("person", "people"))",
                value: Money.format(
                    Money.wholeShare(of: draft.totalCost, heads: draft.travellers.count),
                    code: draft.currencyCode
                ),
                emphasised: false
            )
        }
        .cardSurface(corner: 20)
    }

    private func totalRow(label: String, value: String, emphasised: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: emphasised ? 14.5 : 13.5, weight: emphasised ? .semibold : .regular))
                .foregroundStyle(emphasised ? AppTheme.ink : AppTheme.inkSecondary)

            Spacer(minLength: 8)

            Text(value)
                .font(.system(size: emphasised ? 17 : 14.5, weight: emphasised ? .bold : .semibold, design: .rounded))
                .foregroundStyle(emphasised ? AppTheme.ink : AppTheme.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Create

    private var createBar: some View {
        Button(action: onCreate) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("Create trip")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(!draft.isValid)
        .opacity(draft.isValid ? 1 : 0.5)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    /// A booking outside the current dates widens the trip rather than being
    /// silently dropped off the end of the timeline.
    private func expandSpanToFit(_ item: ItineraryItem) {
        if item.day < draft.startDate { draft.startDate = item.day }
        if item.day > draft.endDate { draft.endDate = item.day }
    }
}

// MARK: - Row

private struct ReviewItemRow: View {
    let item: ItineraryItem
    let trip: TripDraft

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                if item.cost > 0 {
                    Text(Money.format(item.cost, code: trip.currencyCode))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private var subtitle: String {
        var parts: [String] = []
        if let clock = item.clock { parts.append("\(clock.value) \(clock.meridiem)") }
        if !item.vendor.isEmpty { parts.append(item.vendor) }
        parts.append(item.split.label)
        return parts.joined(separator: " · ")
    }
}
