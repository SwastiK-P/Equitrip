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

    var body: some View {
        ZStack {
            if let departure, let arrival {
                Map(initialPosition: .region(region(departure, arrival)), interactionModes: []) {
                    MapPolyline(coordinates: arc(from: departure.coordinate, to: arrival.coordinate))
                        .stroke(
                            .white,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 7])
                        )

                    Annotation(departure.code, coordinate: departure.coordinate) {
                        pin(departure.code)
                    }

                    Annotation(arrival.code, coordinate: arrival.coordinate) {
                        pin(arrival.code)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .transition(.opacity)
            } else {
                placeholder
            }
        }
        .frame(height: 150)
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
        .allowsHitTesting(false)
        .task(id: routeKey) { await resolve() }
        .animation(.easeOut(duration: 0.3), value: isReady)
    }

    private func pin(_ code: String) -> some View {
        VStack(spacing: 2) {
            Text(code)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Palette.blue, in: .capsule)

            Circle()
                .fill(Palette.blue)
                .frame(width: 11, height: 11)
                .overlay { Circle().strokeBorder(.white, lineWidth: 2.5) }
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(AppTheme.cardStroke.opacity(0.05))

            if flight.departureAirport != nil {
                ProgressView().controlSize(.small).tint(AppTheme.inkTertiary)
            } else {
                Text("Look the flight up to see its route")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkTertiary)
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
