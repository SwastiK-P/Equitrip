//
//  TripListView.swift
//  Equitrip
//

import SwiftUI

/// Every trip, grouped by where it is in its life.
///
/// This is the Itinerary tab's root. Home deliberately shows only what's
/// happening now; the full portfolio lives here, because "which trips do I
/// have?" and "what's happening today?" are different questions and answering
/// both on one screen made Home a list of lists.
///
/// The card is the place card: a titled panel with the photograph inset
/// inside it, rather than a photo with text burned over the top. The name of
/// the trip is set in the display serif and never fights a gradient for
/// legibility, and the panel picks up the trip's own colour so a list of
/// cards still reads as a list of different places.
struct TripListView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.pane) private var pane

    @State private var showNewTrip = false
    @State private var showMap = false
    @State private var editing: Trip?
    @State private var inviting: Trip?
    @State private var deleting: Trip?
    @State private var recapping: Trip?

    var body: some View {
        ZStack {
            CanvasBackground()

            if store.trips.isEmpty, store.state.isLoading {
                LoadingState(message: "Loading your trips…")
            } else if store.trips.isEmpty, let failure = store.state.failure {
                failedState(failure)
            } else if store.trips.allSatisfy({ $0.phase == .past }) {
                emptyState
            } else {
                list
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .tabAlignedHeader { header }
        // The stack's bar is empty — the header above is this screen's chrome
        // — but left visible it still sits over the top of the window and
        // swallows taps meant for the buttons that share its line.
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showNewTrip) {
            NewTripFlow { draft in store.add(draft.makeTrip()) }
        }
        .fullScreenCover(isPresented: $showMap) {
            TripsMapView(onOpenTrip: { store.open($0) })
                .environment(\.tripStore, store)
        }
        .sheet(item: $editing) { trip in
            TripEditorSheet(
                trip: trip,
                onSave: { store.update($0) },
                onDelete: trip.youAreOrganiser ? { store.delete(trip.id) } : nil
            )
        }
        .fullScreenCover(item: $recapping) { trip in
            TripRecapView(trip: trip)
        }
        .sheet(item: $inviting) { trip in
            TripInviteSheet(trip: trip)
        }
        // The menu's delete asks here rather than in the editor, since it
        // never opened the editor. Same words either way.
        .confirmationDialog(
            deleting.map { "Delete \($0.title)?" } ?? "Delete trip?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete trip", role: .destructive) {
                if let trip = deleting {
                    store.delete(trip.id)
                    GlassToastCenter.shared.show(.init(
                        symbol: "trash",
                        tint: AppTheme.danger,
                        title: "Trip deleted",
                        subtitle: "\"\(trip.title)\" and everything on it is gone."
                    ))
                }
                deleting = nil
            }
            Button("Keep it", role: .cancel) { deleting = nil }
        } message: {
            Text("This removes it for everyone on the trip, along with every booking on it. It can't be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            // Not on iPad: the tab bar on the same line already says
            // "Itinerary" in the middle of it, and a second name for the same
            // screen beside it reads as a stutter.
            if !pane.isRegular {
                Text("Trips")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "map", size: pane.scaled(38, regular: 42)) { showMap = true }
                .accessibilityLabel("See trips on a map")

            CircleGlyphButton(symbol: "plus", size: pane.scaled(38, regular: 42)) { showNewTrip = true }
                .accessibilityLabel("New or join a trip")
        }
        .gutter()
        .pageWidth()
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    /// Shown instead of the list only when there's nothing to fall back on.
    /// With trips already loaded, a later failure is a banner on Home rather
    /// than a wall here — see `ConnectionBanner`.
    private func failedState(_ message: String) -> some View {
        VStack(spacing: 16) {
            ConnectionBanner(message: message) {
                Task { await store.reload() }
            }
            .padding(.horizontal, 20)
            .readableWidth()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: pane.spacing(26)) {
                section("Happening now", trips: store.trips.filter { $0.phase == .live })
                section("Coming up", trips: store.trips.filter { $0.phase == .upcoming })
                wrappedUp(store.trips.filter { $0.phase == .past })
            }
            .padding(.horizontal, pane.isRegular ? pane.gutter : 16)
            .pageWidth()
            .padding(.top, 2)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    /// One life-stage of the portfolio.
    ///
    /// A column of place cards on a phone, a grid of them on iPad — two across
    /// in portrait, three on a 13" in landscape. The card was always squarish
    /// and photo-led, which is the shape that grids well; stacked one per row
    /// at 1300pt it became a series of billboards you could only see one of at
    /// a time, which is the opposite of what a portfolio view is for.
    @ViewBuilder
    private func section(_ title: String, trips: [Trip]) -> some View {
        if !trips.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, 6)

                CardGrid(items: trips, columns: pane.tripColumns, spacing: pane.spacing(14)) { trip in
                    TripPlaceCard(
                        trip: trip,
                        onOpen: { store.itineraryPath.append(.trip(trip.id)) },
                        onEdit: { editing = trip },
                        onInvite: { inviting = trip },
                        onRecap: trip.phase == .past ? { recapping = trip } : nil,
                        onDelete: { deleting = trip }
                    )
                }
            }
        }
    }

    /// Finished trips, folded into one row that opens them.
    ///
    /// Past trips used to be a third section of full place cards, which put
    /// every trip you've ever taken between you and the bottom of the list —
    /// and the list is for what's still ahead. They're a shelf now: one row,
    /// with the latest few covers on it so it still looks like somewhere.
    @ViewBuilder
    private func wrappedUp(_ trips: [Trip]) -> some View {
        if !trips.isEmpty {
            let recent = trips.sorted { $0.endDate > $1.endDate }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                store.itineraryPath.append(.pastTrips)
            } label: {
                HStack(spacing: 14) {
                    ZStack(alignment: .leading) {
                        ForEach(Array(recent.prefix(3).enumerated().reversed()), id: \.element.id) { index, trip in
                            DestinationImage(
                                query: trip.destination,
                                photo: trip.cover,
                                fallbackSymbol: trip.symbol,
                                fallbackTint: trip.tint
                            )
                            .frame(width: 44, height: 44)
                            .clipShape(.rect(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AppTheme.card, lineWidth: 2)
                            }
                            .offset(x: CGFloat(index) * 16)
                        }
                    }
                    .frame(width: 44 + CGFloat(min(recent.count, 3) - 1) * 16, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wrapped up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("\(trips.count.pluralised("trip")) · latest \(recent[0].title)")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .padding(12)
                .contentShape(.rect)
                .cardSurface(corner: 22)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Wrapped up, \(trips.count.pluralised("trip"))")
        }
    }

    /// Nothing live and nothing booked — which is a different screen from an
    /// empty account, and used to be the same one. A list whose only section
    /// is the "Wrapped up" shelf left two thirds of the page blank with
    /// nothing saying why, so the trips that are over keep their shelf at the
    /// top and `NoTripsAhead` takes the space under it.
    private var emptyState: some View {
        let past = store.trips.filter { $0.phase == .past }.sorted { $0.endDate > $1.endDate }

        return VStack(spacing: 0) {
            NoTripsAhead(hasFinishedTrips: !past.isEmpty)

            // Under the empty state rather than over it: the shelf is where
            // the finished trips live, and above the note it looked like the
            // page's subject rather than its footnote.
            if !past.isEmpty {
                wrappedUp(past)
                    .padding(.top, 34)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, pane.isRegular ? pane.gutter : 16)
        .pageWidth()
    }
}

// MARK: - Card

/// The place card: title block on a tinted panel, photograph inset below it.
///
/// The menu is an overlay rather than a child of the tap target, because a
/// button inside a button swallows one of the two gestures — the card opens
/// the trip, the ellipsis opens the menu, and neither has to guess.
struct TripPlaceCard: View {
    @Environment(\.tripStore) private var store
    @Environment(\.tripZoomNamespace) private var zoom
    @Environment(\.pane) private var pane

    let trip: Trip
    var onOpen: () -> Void
    var onEdit: () -> Void
    var onInvite: () -> Void
    var onRecap: (() -> Void)?
    var onDelete: (() -> Void)?

    /// The colour of this trip's photograph, once it has been sampled.
    /// `trip.tint` stands in until then — and permanently, for a trip whose
    /// cover never resolves.
    @State private var mount: Color?

    private let corner: CGFloat = 26
    private let inset: CGFloat = 8

    private var panelTint: Color { mount ?? trip.tint }

    /// Keyed to how many cards share the row rather than to how wide the
    /// window is — it's the card's own aspect that matters, and a card in a
    /// two-up grid on an 11" iPad is half again as wide as one in a three-up
    /// grid on a 13". Held to roughly the phone card's proportions either way,
    /// so the print never flattens into a letterbox strip.
    private var coverHeight: CGFloat {
        switch pane.tripColumns {
        case 1: 178
        case 2: 244
        default: 196
        }
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                titleBlock
                cover
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(panel)
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.05))
            }
            .clipShape(.rect(cornerRadius: corner, style: .continuous))
            .shadow(color: AppTheme.softShadow(.light), radius: 14, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        // The whole card is the source, not just the photograph inside it —
        // the panel, its title and the picture travel together, so the card
        // reads as being lifted off the list and opened rather than a page
        // sliding in over the top of it.
        .tripZoomSource(trip.id, in: zoom)
        .overlay(alignment: .topTrailing) { menu }
        .task(id: trip.cover?.url) { await sampleCover() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(trip.title), \(trip.destination), \(trip.bookingCount.pluralised("booking"))")
    }

    /// White, warmed by the photograph mounted on it — see `CoverTint`. Kept
    /// this pale on purpose: the panel should read as the picture's own
    /// colour, and the serif title still needs full-strength ink on top of it.
    private var panel: some View {
        ZStack {
            AppTheme.card
            LinearGradient(
                colors: [panelTint.opacity(0.30), panelTint.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .animation(.easeOut(duration: 0.35), value: mount)
    }

    private func sampleCover() async {
        guard let cover = trip.cover else { return }
        mount = await CoverTint.shared.tint(for: cover)
    }


    /// "Manali, Himachal Pradesh, India" is a geocoder's answer, not a
    /// caption. Anything longer than a place and a country gets its middle
    /// dropped, so the line stays the width of the one above the title in the
    /// reference instead of wrapping under the serif.
    private var region: String {
        let parts = trip.destination
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let first = parts.first else { return trip.dateRange }
        guard parts.count > 2, let last = parts.last else { return parts.joined(separator: ", ") }
        return "\(first), \(last)"
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(region)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.inkSecondary)

            Text(trip.title)
                .tripTitle(trip.titleStyle, size: 30)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 5) {
                Image(systemName: "map")
                    .font(.system(size: 11.5, weight: .semibold))

                Text("\(trip.bookingCount.pluralised("booking")) · \(trip.projectedLabel)")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(AppTheme.inkSecondary)
            .padding(.top, 1)
        }
        .lineLimit(1)
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.trailing, 44)
        .padding(.bottom, 12)
    }

    /// The photograph sits *inside* the card with its own radius, the way a
    /// print is mounted on a board — the panel edge stays visible all the way
    /// round it, which is what stops the card reading as a banner.
    private var cover: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
        .frame(height: coverHeight)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: corner - inset - 2, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner - inset - 2, style: .continuous)
                .strokeBorder(.white.opacity(0.35))
        }
        .overlay(alignment: .bottom) { footnote }
        .padding(.horizontal, inset)
        .padding(.bottom, inset)
    }

    /// The two facts that don't belong in the title block: when it runs, and
    /// who's on it. Kept on glass over the photo so the block above stays as
    /// quiet as the reference.
    private var footnote: some View {
        HStack(spacing: 8) {
            Text("\(trip.phase.label) · \(trip.dateRange)")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(.white.opacity(0.55)), in: .capsule)

            Spacer(minLength: 4)

            AvatarStack(travellers: trip.travellers, size: 24, max: 4, departedIDs: trip.departedIDs)
        }
        .padding(10)
    }

    private var menu: some View {
        Menu {
            Button("Open trip", systemImage: "arrow.forward") { onOpen() }

            if let onRecap {
                Button("Trip recap", systemImage: "sparkles") { onRecap() }
            }

            // Editing is the organiser's, here as everywhere else. This menu
            // was the one place that offered it to anyone: the trip screen's
            // toolbar has always hidden its edit control behind
            // `youAreOrganiser`, and the editor it opens saves unconditionally,
            // so a traveller could rename or re-date a trip they don't run —
            // and then be refused by row-level security with no explanation.
            //
            // `youAreOrganiser` is also false for somebody who has left, which
            // is the same rule for the same reason: a trip you've gone home
            // from isn't yours to re-plan.
            if trip.youAreOrganiser {
                Button("Edit trip", systemImage: "pencil") { onEdit() }
            }

            // Inviting stays open to any traveller — that's deliberate, and
            // matches the trip screen — but not to somebody who has left.
            if !trip.hasLeft(Traveller.you.id) {
                Button("Invite people", systemImage: "person.badge.plus") { onInvite() }
            }

            if trip.youAreOrganiser, let onDelete {
                Divider()
                Button("Delete trip", systemImage: "trash", role: .destructive) { onDelete() }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.inkSecondary)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.7), in: .circle)
                .overlay { Circle().strokeBorder(AppTheme.cardStroke.opacity(0.07)) }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .padding(12)
        .accessibilityLabel("More options for \(trip.title)")
    }
}
