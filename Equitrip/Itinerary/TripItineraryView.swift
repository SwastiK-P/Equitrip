//
//  TripItineraryView.swift
//  Equitrip
//

import SwiftUI

/// The master itinerary, as a timeline.
///
/// Two things drive the layout. First, a trip is a sequence, so it gets a rail
/// rather than a list — the gaps between things are information. Second, not
/// everyone is on everything, so the same timeline can be read as the group's
/// plan or as yours, and switching between them is one tap rather than a
/// different screen.
struct TripItineraryView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.notificationStore) private var notifications
    @Environment(\.dismiss) private var dismiss

    /// The trip this screen is for. Passed in by the list that pushed it,
    /// rather than read from a shared "selected" slot, so pushing two
    /// different trips can't end up showing the same one.
    let tripID: UUID

    @State private var section: Section = .timeline
    @State private var scope: Scope = .group
    @State private var showEditor = false
    @State private var editingItem: ItineraryItem?
    @State private var viewingItem: ItineraryItem?
    /// Seeds for the two ways in. Separate sheets rather than one with a mode,
    /// because swapping the item under a live `sheet(item:)` re-presents it
    /// mid-animation — the handover is sequenced explicitly instead.
    @State private var quickAdd: ItineraryItem?
    @State private var detailedAdd: ItineraryItem?
    @State private var showTravellers = false
    @State private var showShare = false

    /// The trip's two faces. Not two destinations — the plan and its money are
    /// the same trip asked two different questions, and making the money a tab
    /// of its own is what put a trip picker in front of a screen you could only
    /// reach by picking a trip.
    enum Section: Hashable { case timeline, ledger }

    enum Scope: Hashable { case group, mine }

    private var trip: Trip? { store.trip(tripID) }

    var body: some View {
        ZStack {
            CanvasBackground()

            if let trip {
                content(for: trip)
            } else {
                emptyState
            }
        }
        // An overlay rather than a `safeAreaInset`: the timeline scrolls
        // underneath it and the hero runs up behind it, which a top inset
        // would make impossible.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay(alignment: .top) { topBar }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showTravellers) {
            if let trip {
                TravellerPickerSheet(
                    travellers: Binding(
                        get: { trip.travellers },
                        set: { updated in
                            // Anyone newly on the list is an arrival worth
                            // announcing — their share of every equally-split
                            // booking changes what everyone else owes.
                            let existing = Set(trip.travellers.map(\.id))
                            let arrivals = updated.filter { !existing.contains($0.id) }

                            var copy = trip
                            copy.travellers = updated
                            store.update(copy)

                            for arrival in arrivals {
                                notifications.announceJoin(of: arrival, to: copy)
                            }
                        }
                    ),
                    organiserIDs: trip.youAreOrganiser
                        ? Binding(
                            get: { trip.organiserIDs },
                            set: { updated in
                                var copy = trip
                                copy.organiserIDs = updated
                                store.update(copy)
                            }
                        )
                        : nil,
                    isEditable: trip.youAreOrganiser
                )
            }
        }
        .sheet(isPresented: $showShare) {
            if let trip { TripInviteSheet(trip: trip) }
        }
        .sheet(isPresented: $showEditor) {
            if let trip {
                TripEditorSheet(
                    trip: trip,
                    onSave: { store.update($0) },
                    // Deleting the trip you're looking at has to take this
                    // screen with it, or the timeline sits there showing a
                    // trip that no longer exists.
                    onDelete: trip.youAreOrganiser
                        ? {
                            let id = trip.id
                            dismiss()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(280))
                                store.delete(id)
                            }
                        }
                        : nil
                )
            }
        }
        .sheet(item: $viewingItem) { item in
            if let trip {
                ItineraryItemDetailView(
                    item: item,
                    trip: trip,
                    onRecordPayment: { payer, method, receipt in
                        var updated = item
                        updated.paidByID = payer
                        updated.paymentMethod = method
                        updated.receiptURL = receipt
                        store.updateItem(updated, in: trip.id)
                        viewingItem = updated
                    },
                    // Editing is offered only to those who can actually do it.
                    // Presenting the editor while the detail sheet is still on
                    // screen makes SwiftUI juggle two `sheet(item:)` bindings
                    // at once, so the swap is sequenced explicitly.
                    onEdit: trip.youAreOrganiser
                        ? {
                            let target = item
                            viewingItem = nil
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(320))
                                editingItem = target
                            }
                        }
                        : nil
                )
            }
        }
        .sheet(item: $editingItem) { item in
            if let trip {
                ItineraryItemEditor(
                    item: item,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    onSave: { store.updateItem($0, in: trip.id) },
                    onDelete: { store.removeItem(item.id, in: trip.id) }
                )
            }
        }
        .sheet(item: $quickAdd) { _ in
            if let trip {
                QuickAddSheet(
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    day: addDay(for: trip),
                    onSave: { store.addItem($0, to: trip.id) },
                    onSwitchToDetailed: { partial in
                        quickAdd = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(320))
                            detailedAdd = partial
                        }
                    }
                )
            }
        }
        .sheet(item: $detailedAdd) { seed in
            if let trip {
                ItineraryItemEditor(
                    item: seed,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    isNew: true,
                    onSave: { store.addItem($0, to: trip.id) }
                )
            }
        }
    }

    // MARK: - Content

    private func content(for trip: Trip) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                banner(for: trip)

                GlassSegments(
                    options: [(Section.timeline, "Timeline"), (Section.ledger, "Ledger")],
                    selection: $section
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

                switch section {
                case .timeline:
                    timeline(for: trip)
                        .transition(.opacity)

                case .ledger:
                    TripLedger(trip: trip) { viewingItem = $0 }
                        .transition(.opacity)
                }

                Color.clear.frame(height: 28)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: scope)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: section)
    }

    // MARK: - Timeline

    @ViewBuilder
    private func timeline(for trip: Trip) -> some View {
        scopeFilter(for: trip)

        let days = visibleDays(of: trip)

        if days.isEmpty {
            noBookings(for: trip)
        } else {
            ForEach(days) { day in
                DayHeader(day: day)

                ForEach(Array(day.items.enumerated()), id: \.element.id) { index, item in
                    let row = TimelineRow(
                        item: item,
                        trip: trip,
                        isLast: index == day.items.count - 1 && day.id == days.last?.id
                    )

                    Button { viewingItem = item } label: { row }
                        .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    // MARK: - Banner

    /// The destination, as a banner rather than a poster.
    ///
    /// It used to be 340pt of photograph with a summary bar under it — better
    /// than half the screen before a single booking appeared, on a screen whose
    /// entire job is the bookings. A trip does deserve to look like somewhere
    /// rather than like a spreadsheet, so the picture stays; it just stops
    /// being the content.
    ///
    /// The two figures sit *on* it now instead of in a white strip below,
    /// which is what buys most of the height back. They're legible there
    /// because of the progressive blur rather than a black gradient — see
    /// `ProgressiveBlur`. The bottom of the photograph goes out of focus, the
    /// colour of the place survives, and small white type has nothing
    /// fine-grained left to fight.
    private func banner(for trip: Trip) -> some View {
        let height: CGFloat = 268

        return GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let stretch = max(0, minY)

            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint,
                onResolve: { store.setCover($0, for: trip.id) }
            )
            .frame(width: proxy.size.width, height: height + stretch)
            .clipped()
            .offset(y: -stretch)
        }
        .frame(height: height)
        // Overlays hang off the outer frame, not the stretching image, so the
        // title stays put while the photograph grows behind it.
        // The ramp is confined to the bottom half. Run across the whole banner
        // it turns the photograph into a grey panel, which defeats the point of
        // having one.
        .overlay { ProgressiveBlur(edge: .bottom, begins: 0.44, scrim: 0.34) }
        .overlay(alignment: .bottomLeading) { bannerContent(for: trip) }
    }

    private func bannerContent(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 10.5, weight: .bold))
                Text(trip.destination.isEmpty ? "Destination not set" : trip.destination)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.85))

            Text(trip.title)
                .font(AppTheme.display(27))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 3)

            HStack(spacing: 9) {
                Text("\(trip.dateRange) · \(trip.dayCount) days")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer(minLength: 4)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showTravellers = true
                } label: {
                    AvatarStack(travellers: trip.travellers, size: 24, max: 4)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 5)

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.top, 12)

            HStack(spacing: 0) {
                bannerFigure(
                    value: trip.projectedLabel,
                    label: "Projected cost"
                )

                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 1, height: 26)

                bannerFigure(
                    value: Money.format(trip.yourShare.rounded(), code: trip.currencyCode),
                    label: "Your share"
                )
            }
            .padding(.top, 11)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func bannerFigure(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Scope

    /// Whose plan you're reading. A filter, not a mode.
    ///
    /// This was a full-width segmented control directly under a second
    /// full-width segmented control, which made the screen look like it had two
    /// levels of navigation stacked on top of each other. It only ever hides
    /// rows, so it's sized like the thing it is: two small chips, secondary to
    /// the section switch above them.
    private func scopeFilter(for trip: Trip) -> some View {
        let mine = trip.items.filter { isYours($0, in: trip) }.count

        return HStack(spacing: 8) {
            scopeChip(.group, "Everyone", trip.items.count)
            scopeChip(.mine, "Just you", mine)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    private func scopeChip(_ value: Scope, _ title: String, _ count: Int) -> some View {
        let on = scope == value

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { scope = value }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 6.5)
            .background {
                Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty states

    private func noBookings(for trip: Trip) -> some View {
        VStack(spacing: 11) {
            Image(systemName: scope == .mine ? "person.crop.circle.badge.questionmark" : "calendar.badge.plus")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text(scope == .mine ? "You're not on anything yet" : "Nothing booked yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(
                scope == .mine
                    ? "The group has \(trip.items.count.pluralised("booking")), but none of them list you."
                    : "Add flights, stays and activities and they'll line up here."
            )
            .font(.system(size: 13.5))
            .foregroundStyle(AppTheme.inkSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 34)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            IconTile(symbol: "map.fill", tint: AppTheme.accent, size: 58, corner: 19)

            Text("No trip yet")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("Create one from Home and its itinerary lands here.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Top bar

    /// Back on the left, everything you can *do* to the trip on the right —
    /// as one pill rather than three separate discs.
    ///
    /// Three glass circles in a row read as three unrelated decisions floating
    /// over the photograph, and each one needed its own tap target carved out
    /// of a busy image. Grouped into a single capsule with hairlines between
    /// them they read as what they are: one toolbar for this trip.
    private var topBar: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 10) {
                CircleGlyphButton(symbol: "chevron.left", size: 40) { dismiss() }
                    .accessibilityLabel("Back to trips")

                Spacer(minLength: 0)

                actionCluster
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var actionCluster: some View {
        HStack(spacing: 0) {
            clusterButton(symbol: "person.badge.plus", label: "Invite people") {
                showShare = true
            }

            if let trip, trip.youAreOrganiser {
                clusterDivider

                clusterButton(symbol: "plus", label: "Add booking") {
                    beginAdding()
                }

                clusterDivider

                clusterButton(symbol: "slider.horizontal.3", label: "Edit trip") {
                    showEditor = true
                }
            }
        }
        .frame(height: 40)
        .glassEffect(.regular, in: .capsule)
        // Animated so the two organiser-only controls slide out of the pill
        // rather than the pill snapping to a new width.
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: trip?.youAreOrganiser)
    }

    private func clusterButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 44, height: 40)
                .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }

    private var clusterDivider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.12))
            .frame(width: 1, height: 18)
    }

    // MARK: - Adding

    /// Which day a new booking lands on: today while the trip is running,
    /// otherwise its first day.
    private func addDay(for trip: Trip) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return trip.phase == .live ? today : max(trip.startDate, today)
    }

    /// Quick add is only offered mid-trip.
    ///
    /// Before the first day nothing has "just happened" — everything being
    /// entered is a booking made in advance, which is the case the full editor
    /// exists for, with its dates and vendors and flight numbers. Offering a
    /// "log this now" form for a hotel you booked last month would just be a
    /// form missing half its fields.
    private func beginAdding() {
        guard let trip else { return }

        let seed = ItineraryItem(
            title: "",
            date: addDay(for: trip),
            participantIDs: Set(trip.travellers.map(\.id))
        )

        if trip.phase == .live {
            quickAdd = seed
        } else {
            detailedAdd = seed
        }
    }

    // MARK: - Scope

    private func visibleDays(of trip: Trip) -> [TripDay] {
        guard scope == .mine else { return trip.days }

        return trip.days.compactMap { day in
            let mine = day.items.filter { isYours($0, in: trip) }
            return mine.isEmpty ? nil : TripDay(index: day.index, date: day.date, items: mine)
        }
    }

    private func isYours(_ item: ItineraryItem, in trip: Trip) -> Bool {
        // An item with nobody named is a whole-group cost, so it's yours too.
        item.participantIDs.isEmpty || item.participantIDs.contains(Traveller.you.id)
    }
}

#Preview {
    RootTabView(userName: "Swastik Patil")
}
