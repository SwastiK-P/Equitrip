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

    @State private var showNewTrip = false
    @State private var showMap = false
    @State private var editing: Trip?
    @State private var inviting: Trip?

    var body: some View {
        ZStack {
            CanvasBackground()

            if store.trips.isEmpty, store.state.isLoading {
                LoadingState(message: "Loading your trips…")
            } else if store.trips.isEmpty, let failure = store.state.failure {
                failedState(failure)
            } else if store.trips.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .fullScreenCover(isPresented: $showNewTrip) {
            NewTripFlow { draft in store.add(draft.makeTrip()) }
        }
        .fullScreenCover(isPresented: $showMap) {
            TripsMapView(onOpenTrip: { store.open($0) })
                .environment(\.tripStore, store)
        }
        .sheet(item: $editing) { trip in
            TripEditorSheet(trip: trip) { store.update($0) }
        }
        .sheet(item: $inviting) { trip in
            TripInviteSheet(trip: trip)
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Trips")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "map", size: 38) { showMap = true }
                .accessibilityLabel("See trips on a map")

            CircleGlyphButton(symbol: "plus", size: 38) { showNewTrip = true }
                .accessibilityLabel("New or join a trip")
        }
        .padding(.horizontal, 20)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                section("Happening now", trips: store.trips.filter { $0.phase == .live })
                section("Coming up", trips: store.trips.filter { $0.phase == .upcoming })
                section("Wrapped up", trips: store.trips.filter { $0.phase == .past })
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func section(_ title: String, trips: [Trip]) -> some View {
        if !trips.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, 6)

                ForEach(trips) { trip in
                    TripPlaceCard(
                        trip: trip,
                        onOpen: { store.itineraryPath.append(trip.id) },
                        onEdit: { editing = trip },
                        onInvite: { inviting = trip }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            IconTile(symbol: "map.fill", tint: AppTheme.accent, size: 58, corner: 19)

            Text("No trips yet")
                .font(AppTheme.display(24))
                .foregroundStyle(AppTheme.ink)

            Text("Start one, or join a trip someone's already planning.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)

            Button("New trip") { showNewTrip = true }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
                .padding(.top, 4)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Card

/// The place card: title block on a tinted panel, photograph inset below it.
///
/// The menu is an overlay rather than a child of the tap target, because a
/// button inside a button swallows one of the two gestures — the card opens
/// the trip, the ellipsis opens the menu, and neither has to guess.
private struct TripPlaceCard: View {
    @Environment(\.tripStore) private var store
    @Environment(\.tripZoomNamespace) private var zoom

    let trip: Trip
    var onOpen: () -> Void
    var onEdit: () -> Void
    var onInvite: () -> Void

    /// The colour of this trip's photograph, once it has been sampled.
    /// `trip.tint` stands in until then — and permanently, for a trip whose
    /// cover never resolves.
    @State private var mount: Color?

    private let corner: CGFloat = 26
    private let inset: CGFloat = 8

    private var panelTint: Color { mount ?? trip.tint }

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
                .font(AppTheme.display(30))
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
        .frame(height: 178)
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
            HStack(spacing: 5) {
                Circle()
                    .fill(trip.phase.tint)
                    .frame(width: 5, height: 5)
                Text("\(trip.phase.label) · \(trip.dateRange)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.32), in: .capsule)
            .background(.ultraThinMaterial, in: .capsule)

            Spacer(minLength: 4)

            AvatarStack(travellers: trip.travellers, size: 24, max: 4)
        }
        .padding(10)
    }

    private var menu: some View {
        Menu {
            Button("Open trip", systemImage: "arrow.forward") { onOpen() }
            Button("Edit trip", systemImage: "pencil") { onEdit() }
            Button("Invite people", systemImage: "person.badge.plus") { onInvite() }
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
