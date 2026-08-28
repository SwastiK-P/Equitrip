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
        .overlay(alignment: .bottom) {
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
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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
                        camera = .automatic
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

/// Deliberately under half the screen: the map is the point, and a sheet that
/// swallows it turns this back into a list.
private struct TripMapCard: View {
    let trip: Trip
    let onOpen: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            cover

            VStack(spacing: 13) {
                HStack(spacing: 0) {
                    cell(value: "\(trip.dayCount)", label: trip.dayCount == 1 ? "day" : "days")
                    divider
                    cell(value: "\(trip.bookingCount)", label: trip.bookingCount == 1 ? "booking" : "bookings")
                    divider
                    // Nothing to settle until the trip has started — see
                    // `Trip.showsBalance`.
                    if trip.showsBalance {
                        cell(value: trip.netLabel, label: trip.netCaption, tone: trip.netTone)
                    } else {
                        cell(value: Money.format(trip.yourShare, code: trip.currencyCode), label: "your share")
                    }
                }

                Button(action: onOpen) {
                    HStack(spacing: 7) {
                        Text("Open trip")
                            .font(.system(size: 15.5, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12.5, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.glassProminent)
                .tint(AppTheme.accent)
            }
            .padding(16)
        }
        .background(AppTheme.card, in: .rect(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.06))
        }
        .shadow(color: .black.opacity(0.22), radius: 22, y: 10)
    }

    private var cover: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint
        )
        .frame(height: 116)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                .frame(height: 80)
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(trip.dateRange) · \(trip.destination)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
            .padding(14)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(.black.opacity(0.4), in: .circle)
            }
            .buttonStyle(.plain)
            .padding(10)
        }
        .clipShape(.rect(topLeadingRadius: 26, topTrailingRadius: 26))
    }

    private var divider: some View {
        Rectangle().fill(AppTheme.cardStroke.opacity(0.10)).frame(width: 1, height: 26)
    }

    private func cell(value: String, label: String, tone: Color = AppTheme.ink) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
