//
//  TwinGeocoder.swift
//  Equitrip
//

import MapKit

/// Where a trip's bookings are, for the map and for the weather.
///
/// Bookings carry names, not coordinates, so each is searched on Apple Maps
/// near the trip's destination: the vendor if there is one ("Taj Exotica"),
/// the title otherwise ("Dudhsagar Falls"). A hit more than 120 km from the
/// destination is almost always a same-named place elsewhere, so it's
/// dropped and the booking sits at the destination, marked approximate —
/// the map draws those pins hollow rather than pretending. Flights are the
/// exception: they're placed at their departure airport, wherever that is,
/// because that's where the weather that grounds them happens.
///
/// Answers are kept on the phone: a trip's places don't move, and searching
/// twenty names on every open would be slow and rude to MapKit's quota.
enum TwinGeocoder {

    struct Place: Hashable, Codable {
        var name: String
        var point: GeoPoint
        /// The town or neighbourhood Apple Maps put it in — what social
        /// signals are matched against.
        var locality: String?
        var isApproximate: Bool
    }

    private static let cacheKey = "twin.geocode.v2"
    private static var cache: [String: Place] = {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let map = try? JSONDecoder().decode([String: Place].self, from: data) else { return [:] }
        return map
    }()

    private static func remember(_ place: Place, for key: String) {
        cache[key] = place
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }

    static func destination(of trip: Trip) async -> Place? {
        let query = trip.destination.isEmpty ? trip.title : trip.destination
        let key = "dest|\(query.lowercased())"
        if let hit = cache[key] { return hit }
        guard let found = await search(query, near: nil) else { return nil }
        let name = query.split(separator: ",").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? query
        let place = Place(name: name, point: found.point, locality: found.locality ?? name, isApproximate: false)
        remember(place, for: key)
        return place
    }

    static func place(for item: ItineraryItem, around destination: Place) async -> Place {
        let queries = searchQueries(for: item)
        for query in queries {
            let key = "item|\(query.lowercased())|\(destination.name.lowercased())"
            if let hit = cache[key] { return hit }

            let isFlight = item.kind == .flight
            guard let found = await search(isFlight ? query : "\(query), \(destination.name)", near: isFlight ? nil : destination.point)
            else { continue }
            guard isFlight || found.point.distance(to: destination.point) <= 120 else { continue }

            let place = Place(name: query, point: found.point, locality: found.locality, isApproximate: false)
            remember(place, for: key)
            return place
        }
        // Remembered too, so a booking Maps can't place isn't searched for
        // again, query by query, every time the twin opens.
        let approximate = Place(name: destination.name, point: destination.point, locality: destination.locality, isApproximate: true)
        if let first = queries.first {
            remember(approximate, for: "item|\(first.lowercased())|\(destination.name.lowercased())")
        }
        return approximate
    }

    static func searchQueries(for item: ItineraryItem) -> [String] {
        if item.kind == .flight, let flight = item.flight {
            return [flight.departureAirportName, flight.departureAirport.map { "\($0) airport" }].compactMap { $0 }
        }
        var list: [String] = []
        if let vendor = item.vendorName { list.append(vendor) }
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty, item.kind != .drive { list.append(title) }
        return list
    }

    private static func search(_ query: String, near point: GeoPoint?) async -> (point: GeoPoint, locality: String?)? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let point {
            request.region = MKCoordinateRegion(
                center: point.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.2, longitudeDelta: 1.2)
            )
        }
        guard let item = try? await MKLocalSearch(request: request).start().mapItems.first else { return nil }
        let coordinate = item.location.coordinate
        // A result with no real location comes back at (0, 0), in the Gulf
        // of Guinea — which then drags the whole map there.
        guard CLLocationCoordinate2DIsValid(coordinate),
              abs(coordinate.latitude) > 0.01 || abs(coordinate.longitude) > 0.01 else { return nil }
        return (GeoPoint(coordinate), item.addressRepresentations?.cityName)
    }
}
