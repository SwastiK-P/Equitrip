//
//  FlightRouteMap.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// The route, drawn on a map: two pins and the great-circle arc between them.
///
/// Airport coordinates are resolved by name through MapKit rather than shipped
/// as a table — the flight API gives us IATA codes and full airport names, and
/// a local database would be stale the moment an airport moved terminals.
///
/// Always dark, whatever the app's appearance. A route map is a diagram, not a
/// place you're navigating: on the light map the landmass and the sea sit at
/// almost the same value, so the one line that matters — the arc — had nothing
/// to read against. Dark ground makes it the brightest thing in the frame, and
/// keeps a full-width map from being the loudest card on the screen.
struct FlightRouteMap: View {
    let flight: FlightDetails

    @State private var departure: Endpoint?
    @State private var arrival: Endpoint?
    @State private var didResolve = false

    struct Endpoint: Identifiable {
        let id = UUID()
        let code: String
        let coordinate: CLLocationCoordinate2D
    }

    private var isReady: Bool { departure != nil && arrival != nil }

    /// The one colour on the map. Bright enough to sit on the dark ground
    /// without the neon look a fully saturated blue takes on against it.
    private static let routeTint = Color(red: 0.42, green: 0.68, blue: 1)
    private static let ground = Color(red: 0.055, green: 0.06, blue: 0.09)

    var body: some View {
        ZStack {
            // Painted first so the frame is already dark while MapKit loads
            // its tiles — otherwise the card flashes white on every appearance.
            Self.ground

            if let departure, let arrival {
                Map(initialPosition: .region(region(departure, arrival)), interactionModes: []) {
                    // Two passes: a wide, soft stroke under a crisp dashed one,
                    // so the line reads as lit rather than drawn on.
                    MapPolyline(coordinates: arc(from: departure.coordinate, to: arrival.coordinate))
                        .stroke(
                            Self.routeTint.opacity(0.30),
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )

                    MapPolyline(coordinates: arc(from: departure.coordinate, to: arrival.coordinate))
                        .stroke(
                            Self.routeTint,
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [7, 7])
                        )

                    Annotation(departure.code, coordinate: departure.coordinate) {
                        pin(departure.code)
                    }

                    Annotation(arrival.code, coordinate: arrival.coordinate) {
                        pin(arrival.code)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                // MapKit reads its appearance from the environment rather than
                // from a style option, so this — not `.mapStyle` — is what
                // makes the tiles themselves dark.
                .environment(\.colorScheme, .dark)
                .transition(.opacity)
            } else {
                placeholder
            }
        }
        .frame(height: 168)
        .overlay(alignment: .bottom) { routeCaption }
        .clipShape(.rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        }
        .allowsHitTesting(false)
        .task(id: routeKey) { await resolve() }
        .animation(.easeOut(duration: 0.3), value: isReady)
    }

    /// The two codes and the word between them, on a scrim at the foot of the
    /// map. The pins say where; this says what you're looking at, and survives
    /// a route so short that the two pins overlap.
    @ViewBuilder
    private var routeCaption: some View {
        if let from = flight.departureAirport, let to = flight.arrivalAirport {
            HStack(spacing: 8) {
                Text(from)
                Image(systemName: "airplane")
                    .font(.system(size: 10, weight: .bold))
                Text(to)

                Spacer(minLength: 6)

                Text(FlightLookupService.display(flight.number))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .font(.system(size: 11.5, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(
                    colors: [.clear, Self.ground.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func pin(_ code: String) -> some View {
        VStack(spacing: 2) {
            Text(code)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Self.ground)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Self.routeTint, in: .capsule)

            Circle()
                .fill(Self.routeTint)
                .frame(width: 10, height: 10)
                .overlay { Circle().strokeBorder(Self.ground, lineWidth: 2.5) }
                .shadow(color: Self.routeTint.opacity(0.7), radius: 5)
        }
    }

    private var placeholder: some View {
        ZStack {
            // A faint grid stands in for the map: the frame stays a map-shaped
            // dark rectangle rather than an empty grey box that pops when the
            // tiles arrive.
            GridScrim()
                .stroke(.white.opacity(0.06), lineWidth: 1)

            if flight.departureAirport != nil {
                ProgressView().controlSize(.small).tint(.white.opacity(0.5))
            } else {
                Text("Look the flight up to see its route")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }

    // MARK: - Geometry

    private var routeKey: String {
        "\(flight.departureAirport ?? "")-\(flight.arrivalAirport ?? "")"
    }

    /// Frames both ends with enough margin that the pins aren't against the
    /// edge, and never zooms in so far that a short hop fills the world.
    private func region(_ from: Endpoint, _ to: Endpoint) -> MKCoordinateRegion {
        let centre = CLLocationCoordinate2D(
            latitude: (from.coordinate.latitude + to.coordinate.latitude) / 2,
            longitude: (from.coordinate.longitude + to.coordinate.longitude) / 2
        )
        let latitudeSpan = abs(from.coordinate.latitude - to.coordinate.latitude) * 2.2
        let longitudeSpan = abs(from.coordinate.longitude - to.coordinate.longitude) * 1.6

        return MKCoordinateRegion(
            center: centre,
            span: MKCoordinateSpan(
                latitudeDelta: max(4, latitudeSpan),
                longitudeDelta: max(4, longitudeSpan)
            )
        )
    }

    /// A flight path bows rather than running straight, so the line is drawn
    /// as a shallow curve — the same shape a route map uses.
    private func arc(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let steps = 48
        let lift = 0.18

        return (0...steps).map { step in
            let t = Double(step) / Double(steps)
            // Zero at both ends, widest in the middle.
            let bow = sin(t * .pi) * lift

            let latitude = from.latitude + (to.latitude - from.latitude) * t
            let longitude = from.longitude + (to.longitude - from.longitude) * t
            let separation = hypot(to.latitude - from.latitude, to.longitude - from.longitude)

            return CLLocationCoordinate2D(
                latitude: latitude + bow * separation,
                longitude: longitude
            )
        }
    }

    // MARK: - Lookup

    private func resolve() async {
        guard !didResolve,
              let departureCode = flight.departureAirport,
              let arrivalCode = flight.arrivalAirport else { return }
        didResolve = true

        async let from = coordinate(
            code: departureCode,
            name: flight.departureAirportName,
            city: flight.departureCity
        )
        async let to = coordinate(
            code: arrivalCode,
            name: flight.arrivalAirportName,
            city: flight.arrivalCity
        )

        let (resolvedFrom, resolvedTo) = await (from, to)
        guard let resolvedFrom, let resolvedTo else { return }

        departure = Endpoint(code: departureCode, coordinate: resolvedFrom)
        arrival = Endpoint(code: arrivalCode, coordinate: resolvedTo)
    }

    private func coordinate(code: String, name: String?, city: String?) async -> CLLocationCoordinate2D? {
        // "Heathrow Airport" finds the airport; "LHR" alone often finds a
        // street. The city narrows it when the name is generic.
        let query = [name.map { "\($0) Airport" }, city, code]
            .compactMap { $0 }
            .joined(separator: " ")

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest

        guard let response = try? await MKLocalSearch(request: request).start() else { return nil }
        return response.mapItems.first?.placemark.coordinate
    }
}

/// Evenly spaced meridians and parallels, for the state before the real tiles
/// arrive.
private struct GridScrim: Shape {
    var step: CGFloat = 34

    func path(in rect: CGRect) -> Path {
        var path = Path()

        var x = rect.minX + step
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }

        var y = rect.minY + step
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }

        return path
    }
}
