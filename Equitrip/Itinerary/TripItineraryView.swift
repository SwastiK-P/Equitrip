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

    @State private var scope: Scope = .group
    @State private var showEditor = false
    @State private var editingItem: ItineraryItem?
    @State private var viewingItem: ItineraryItem?
    @State private var isAddingItem = false
    @State private var showTravellers = false
    @State private var showShare = false

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
                TripEditorSheet(trip: trip) { store.update($0) }
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
        .sheet(isPresented: $isAddingItem) {
            if let trip {
                ItineraryItemEditor(
                    item: ItineraryItem(
                        title: "",
                        date: max(trip.startDate, Calendar.current.startOfDay(for: Date())),
                        participantIDs: Set(trip.travellers.map(\.id))
                    ),
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
                cover(for: trip)
                summary(for: trip)
                scopePicker(for: trip)

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

                Color.clear.frame(height: 28)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: scope)
    }

    /// Full-bleed photograph of the destination.
    ///
    /// The stretch grows the image's *frame* upward rather than scaling it in
    /// place: a `scaleEffect` gets clipped back to the original bounds, which
    /// is what left a band of bare canvas above the photo on pull-down.
    private func cover(for trip: Trip) -> some View {
        let height: CGFloat = 340

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
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.25), .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 190)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11, weight: .bold))
                    Text(trip.destination.isEmpty ? "Destination not set" : trip.destination)
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(.white.opacity(0.9))

                Text(trip.title)
                    .font(AppTheme.display(30))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 9) {
                    Text("\(trip.dateRange) · \(trip.dayCount) days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showTravellers = true
                    } label: {
                        AvatarStack(travellers: trip.travellers, size: 24, max: 4)
                            .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .shadow(color: .black.opacity(0.45), radius: 8, y: 2)
            .padding(20)
        }
    }

    /// What the trip is costing, and what of it is yours.
    ///
    /// The balance cell only appears once the trip is under way. Before the
    /// first day nobody has paid anybody, so it read "Settled · all square" on
    /// every unstarted trip — a statement of fact about a reconciliation that
    /// hasn't begun, which is worse than saying nothing.
    private func summary(for trip: Trip) -> some View {
        HStack(spacing: 0) {
            summaryCell(
                value: trip.projectedLabel,
                label: "Projected cost"
            )

            divider

            summaryCell(
                value: Money.format(trip.yourShare, code: trip.currencyCode),
                label: "Your share"
            )

            if trip.showsBalance {
                divider

                summaryCell(
                    value: trip.netLabel,
                    label: trip.netCaption,
                    tone: trip.netTone
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        // Flush to the photograph above it and edge to edge, so the hero
        // reads as one block rather than a picture with a card floating under it.
        .background(AppTheme.card)
        .overlay(alignment: .bottom) { Hairline() }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.10))
            .frame(width: 1, height: 30)
    }

    private func summaryCell(value: String, label: String, tone: Color = AppTheme.ink) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16.5, weight: .bold, design: .rounded))
                .foregroundStyle(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func scopePicker(for trip: Trip) -> some View {
        let mine = trip.items.filter { isYours($0, in: trip) }.count

        return GlassSegments(
            options: [
                (Scope.group, "Everyone · \(trip.items.count)"),
                (Scope.mine, "Just you · \(mine)")
            ],
            selection: $scope
        )
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
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

    /// Back, and — for whoever holds the pen — the way into editing. Both
    /// float over the photograph rather than sitting in a bar above it.
    private var topBar: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 10) {
                CircleGlyphButton(symbol: "chevron.left", size: 40) { dismiss() }
                    .accessibilityLabel("Back to trips")

                Spacer(minLength: 0)

                CircleGlyphButton(symbol: "person.badge.plus", size: 40) {
                    showShare = true
                }
                .accessibilityLabel("Invite people")

                if let trip, trip.youAreOrganiser {
                    CircleGlyphButton(symbol: "plus", size: 40) {
                        isAddingItem = true
                    }
                    .accessibilityLabel("Add booking")

                    CircleGlyphButton(symbol: "slider.horizontal.3", size: 40) {
                        showEditor = true
                    }
                    .accessibilityLabel("Edit trip")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
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
