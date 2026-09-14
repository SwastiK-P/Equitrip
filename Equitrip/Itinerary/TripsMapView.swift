//
//  TripsMapView.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// Every trip, on one map.
///
/// A list answers "what have I got planned"; a map answers a question the list
/// can't — where these trips *are* relative to each other, and to you. Each
/// pin carries the trip's own cover photograph, because a row of identical
/// markers would just be the list again with worse information density.
struct TripsMapView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pane) private var pane

    @State private var pins: [TripPin] = []
    @State private var selection: UUID?
    @State private var camera: MapCameraPosition = .automatic
    @State private var isResolving = true
    /// Set when the sheet's "Open trip" is used, so the map can hand off.
    var onOpenTrip: (Trip) -> Void = { _ in }

    struct TripPin: Identifiable {
        let id: UUID
        let trip: Trip
        let coordinate: CLLocationCoordinate2D
    }

    private var selected: TripPin? {
        pins.first { $0.id == selection }
    }

    var body: some View {
        ZStack(alignment: .top) {
            map

            topBar
        }
        .overlay(alignment: pane.isRegular ? .bottomLeading : .bottom) {
            if let selected {
                TripMapCard(
                    trip: selected.trip,
                    onOpen: {
                        dismiss()
                        onOpenTrip(selected.trip)
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) { selection = nil }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(pane.isRegular ? 18 : 0)
            }
        }
        // Applied to the whole composite, not to the card inside it. The
        // ZStack still *lays out* within the safe area even though the map
        // draws past it, so a bottom-aligned overlay anchors to the safe-area
        // edge — and `ignoresSafeArea` on the card had no room to expand into.
        // Extending the container is what actually lets the modal reach the
        // screen edge instead of leaving a strip of map under it.
        .ignoresSafeArea(edges: .bottom)
        .task { await resolve() }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: selection)
    }

    // MARK: - Map

    private var map: some View {
        Map(position: $camera, selection: $selection) {
            ForEach(pins) { pin in
                Annotation(pin.trip.title, coordinate: pin.coordinate) {
                    TripPinView(
                        trip: pin.trip,
                        isSelected: pin.id == selection
                    )
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            selection = pin.id
                            focus(on: pin)
                        }
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .ignoresSafeArea()
        .overlay {
            if isResolving && pins.isEmpty { loading }
        }
    }

    private var loading: some View {
        VStack(spacing: 10) {
            ProgressView().controlSize(.large).tint(.white)
            Text("Placing your trips")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(22)
        .background(.black.opacity(0.45), in: .rect(cornerRadius: 20, style: .continuous))
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            CircleGlyphButton(symbol: "xmark", size: 40) { dismiss() }
                .accessibilityLabel("Close map")

            Spacer(minLength: 0)

            if pins.count > 1 {
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        selection = nil
                        fitAll()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text("Fit all")
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    /// Nudges the camera so the selected pin sits in the upper half — the card
    /// takes the lower half, and a pin hidden behind it is the classic mistake
    /// with this layout.
    private func focus(on pin: TripPin) {
        let offsetCentre = CLLocationCoordinate2D(
            latitude: pin.coordinate.latitude - 2.2,
            longitude: pin.coordinate.longitude
        )
        camera = .region(
            MKCoordinateRegion(
                center: offsetCentre,
                span: MKCoordinateSpan(latitudeDelta: 9, longitudeDelta: 9)
            )
        )
    }

    // MARK: - Geocoding

    private func resolve() async {
        defer { isResolving = false }

        var resolved: [TripPin] = []
        for trip in store.trips {
            let query = trip.destination.isEmpty ? trip.title : trip.destination
            guard let coordinate = await Self.coordinate(for: query) else { continue }
            resolved.append(TripPin(id: trip.id, trip: trip, coordinate: coordinate))
        }

        pins = resolved
        fitAll()
    }

    /// Frames every pin at once, with extra breathing room on the left and
    /// right — `.automatic`'s own fit ran pins right up to the screen edge,
    /// which crops a trip's cover art badly for anything near the antimeridian
    /// of the group.
    private func fitAll() {
        guard !pins.isEmpty else {
            camera = .automatic
            return
        }

        let lats = pins.map(\.coordinate.latitude)
        let lons = pins.map(\.coordinate.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            camera = .automatic
            return
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Single-pin trips would otherwise collapse the span to zero, so a
        // floor keeps that case zoomed out to something sensible.
        let latSpread = Swift.max(maxLat - minLat, 4)
        let lonSpread = Swift.max(maxLon - minLon, 4)

        camera = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(
                    latitudeDelta: latSpread * 1.35,
                    longitudeDelta: lonSpread * 1.9
                )
            )
        )
    }

    /// Cached across the session — the same handful of destinations would
    /// otherwise be geocoded again on every open.
    private nonisolated(unsafe) static var cache: [String: CLLocationCoordinate2D] = [:]

    private static func coordinate(for query: String) async -> CLLocationCoordinate2D? {
        if let hit = cache[query] { return hit }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]

        guard let response = try? await MKLocalSearch(request: request).start(),
              let coordinate = response.mapItems.first?.placemark.coordinate else { return nil }

        cache[query] = coordinate
        return coordinate
    }
}

// MARK: - Pin

/// The cover photograph, as a map pin. Selection lifts and enlarges it rather
/// than recolouring, so the thing you tapped is unmistakable at a glance.
private struct TripPinView: View {
    let trip: Trip
    let isSelected: Bool

    private var size: CGFloat { isSelected ? 62 : 48 }

    var body: some View {
        VStack(spacing: 0) {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(width: size, height: size)
            .clipShape(.circle)
            .overlay {
                Circle().strokeBorder(.white, lineWidth: isSelected ? 3.5 : 3)
            }
            .shadow(color: .black.opacity(0.32), radius: isSelected ? 10 : 5, y: 3)

            // The stem, so the circle reads as pinned to a point rather than
            // floating over it.
            Triangle()
                .fill(.white)
                .frame(width: 12, height: 7)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 2)
                .offset(y: -1)
        }
        .overlay(alignment: .topTrailing) {
            if trip.phase == .live {
                Circle()
                    .fill(AppTheme.positive)
                    .frame(width: 13, height: 13)
                    .overlay { Circle().strokeBorder(.white, lineWidth: 2.5) }
                    .offset(x: 2, y: -2)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Detail card

/// The selected trip, as a glass modal across the foot of the map.
///
/// Built as chrome rather than as content, which is what the two attempts
/// before it got wrong. A floating opaque card reads as a tooltip dropped on
/// the map; a full-width opaque panel reads as a second screen that has
/// swallowed the bottom third of the first one. Neither is what this is — it's
/// a control layer over a map you are still looking at and still panning, and
/// Liquid Glass is the material the rest of this app's navigation layer is
/// already made of.
///
/// So: edge to edge, so it belongs to the screen instead of hovering inside
/// it; rounded only along the top, so it reads as having come up from beneath;
/// and glass, so France is still visible through it and the map never stops
/// being the thing you're using.
private struct TripMapCard: View {
    @Environment(\.pane) private var pane

    let trip: Trip
    let onOpen: () -> Void
    let onClose: () -> Void

    private let corner: CGFloat = 34

    /// A sheet on a phone, a floating panel on iPad.
    ///
    /// The card came up from the bottom edge because on a phone that is the
    /// only place a second layer can come from. On iPad the map is a room
    /// rather than a strip, and a 1200pt bar pinned to the floor hides the
    /// southern third of it to say four things about one trip. Unpinned, it
    /// becomes what Maps itself uses: a panel in the corner, rounded all
    /// round, with the map carrying on behind and beside it.
    private var floats: Bool { pane.isRegular }

    var body: some View {
        VStack(spacing: 0) {
            if !floats { grabber }
            headline
            facts
            openButton
        }
        .frame(maxWidth: floats ? 380 : .infinity)
        .glassEffect(
            .regular,
            in: UnevenRoundedRectangle(
                topLeadingRadius: corner,
                bottomLeadingRadius: floats ? corner : 0,
                bottomTrailingRadius: floats ? corner : 0,
                topTrailingRadius: corner,
                style: .continuous
            )
        )
        .overlay(alignment: .topTrailing) { closeButton }
        .padding(.top, floats ? 18 : 0)
    }

    /// Not draggable — the map's own pins are how you change selection. It's
    /// here because a bar across the bottom of a screen with a rounded top and
    /// no grabber reads as furniture rather than as something dismissible, and
    /// the close button alone is easy to miss on a busy map.
    private var grabber: some View {
        Capsule()
            .fill(AppTheme.inkTertiary.opacity(0.35))
            .frame(width: 38, height: 5)
            .padding(.top, 9)
            .padding(.bottom, 14)
    }

    private var headline: some View {
        HStack(spacing: 14) {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(width: 68, height: 68)
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(region)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                Text(trip.title)
                    .font(AppTheme.display(23))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 5) {
                    Circle()
                        .fill(trip.phase.tint)
                        .frame(width: 5, height: 5)

                    Text("\(trip.phase.label) · \(trip.dateRange)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.trailing, 30)
    }

    /// The three things worth knowing before deciding to open it. On glass
    /// these sit on their own translucent tray rather than floating loose —
    /// small grey type directly on a blurred map is the one thing glass is bad
    /// at holding.
    private var facts: some View {
        HStack(spacing: 0) {
            fact(value: "\(trip.dayCount)", label: trip.dayCount == 1 ? "day" : "days")

            divider

            fact(
                value: "\(trip.bookingCount)",
                label: trip.bookingCount == 1 ? "booking" : "bookings"
            )

            divider

            VStack(spacing: 5) {
                AvatarStack(travellers: trip.travellers, size: 24, max: 4, departedIDs: trip.departedIDs)

                Text("going")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 13)
        .background(.white.opacity(0.28), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.10))
            .frame(width: 1, height: 26)
    }

    private func fact(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private var openButton: some View {
        Button(action: onOpen) {
            HStack(spacing: 7) {
                Text("Open trip")
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        // Clears the home indicator, since the modal extends beneath it —
        // which a floating panel doesn't, so it takes a plain card inset.
        .padding(.bottom, pane.isRegular ? 20 : 30)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.inkSecondary)
                .frame(width: 30, height: 30)
                .contentShape(.circle)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 16)
        .padding(.top, 14)
        .accessibilityLabel("Close")
    }

    /// "Manali, Himachal Pradesh, India" is a geocoder's answer, not a caption
    /// — the same trim the Trips list makes.
    private var region: String {
        let parts = trip.destination
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let first = parts.first else { return trip.dateRange }
        guard parts.count > 2, let last = parts.last else { return parts.joined(separator: ", ") }
        return "\(first), \(last)"
    }
}
