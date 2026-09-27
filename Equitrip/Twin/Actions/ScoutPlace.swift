//
//  ScoutPlace.swift
//  Equitrip
//

import MapKit

/// A place Apple Maps returned while looking for somewhere under a roof, as
/// plain values off the main actor — the model's tools run there, and build
/// and share these between calls.
///
/// Also where the MapKit calls live, so the category sweep, the named search
/// and the travel-time check are the same code whether Swift or the model
/// asked for them.
nonisolated struct ScoutPlace: Hashable, Sendable {

    /// The kinds of place worth swapping to: things to do indoors, or for a
    /// meal, somewhere to eat indoors. Anything else Maps returns is dropped.
    enum Category: String, Sendable, CaseIterable {
        case museum, aquarium, library, cinema, theatre, planetarium, musicVenue, spa, bowling
        case restaurant, cafe, bakery

        static let sights: [Category] = [.museum, .aquarium, .library, .cinema, .theatre, .planetarium, .musicVenue, .spa, .bowling]
        static let meals: [Category] = [.restaurant, .cafe, .bakery]

        init?(_ category: MKPointOfInterestCategory?) {
            guard let category, let match = Self.allCases.first(where: { $0.mapKit == category }) else { return nil }
            self = match
        }

        var mapKit: MKPointOfInterestCategory {
            switch self {
            case .museum: .museum
            case .aquarium: .aquarium
            case .library: .library
            case .cinema: .movieTheater
            case .theatre: .theater
            case .planetarium: .planetarium
            case .musicVenue: .musicVenue
            case .spa: .spa
            case .bowling: .bowling
            case .restaurant: .restaurant
            case .cafe: .cafe
            case .bakery: .bakery
            }
        }

        var label: String {
            switch self {
            case .musicVenue: "music venue"
            default: rawValue
            }
        }

        /// Added to a booking's title when the name alone doesn't say it's
        /// indoors — the twin reads exposure from the words in the title.
        var noun: String? {
            switch self {
            case .museum: "Museum"
            case .aquarium: "Aquarium"
            case .library: "Library"
            case .cinema: "Cinema"
            case .theatre: "Theatre"
            case .planetarium: "Planetarium"
            case .musicVenue: "Live show"
            case .spa: "Spa"
            case .bowling: "Bowling"
            case .restaurant, .cafe, .bakery: nil
            }
        }

        var symbol: String {
            switch self {
            case .museum: "building.columns.fill"
            case .aquarium: "fish.fill"
            case .library: "books.vertical.fill"
            case .cinema: "film.fill"
            case .theatre: "theatermasks.fill"
            case .planetarium: "moon.stars.fill"
            case .musicVenue: "music.mic"
            case .spa: "leaf.fill"
            case .bowling: "figure.bowling"
            case .restaurant: "fork.knife"
            case .cafe: "cup.and.saucer.fill"
            case .bakery: "birthday.cake.fill"
            }
        }
    }

    let name: String
    let category: Category?
    let latitude: Double
    let longitude: Double
    let locality: String?

    var key: String { name.lowercased() }

    func distanceKm(fromLatitude lat: Double, longitude lon: Double) -> Double {
        CLLocation(latitude: latitude, longitude: longitude).distance(from: CLLocation(latitude: lat, longitude: lon)) / 1000
    }

    /// One line for the model: name, kind, distance.
    func line(fromLatitude lat: Double, longitude lon: Double) -> String {
        "\(name) (\(category?.label ?? "place"), \(String(format: "%.1f", distanceKm(fromLatitude: lat, longitude: lon))) km)"
    }

    // MARK: - Maps

    /// Every place of these kinds within `radius` metres — no query words, so
    /// nothing is missed for being named in another language.
    static func sweep(latitude: Double, longitude: Double, radius: CLLocationDistance, categories: [Category]) async -> [ScoutPlace] {
        let request = MKLocalPointsOfInterestRequest(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            radius: radius
        )
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: categories.map(\.mapKit))
        let items = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
        return items.compactMap(place)
    }

    /// A search in words, around a point.
    static func search(_ query: String, latitude: Double, longitude: Double, spanKm: Double = 16) async -> [ScoutPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        let degrees = spanKm / 111
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: degrees, longitudeDelta: degrees)
        )
        let items = (try? await MKLocalSearch(request: request).start().mapItems) ?? []
        return items.compactMap(place)
    }

    /// Minutes from a point to this place, on foot or by road, as Maps routes it.
    func minutes(fromLatitude lat: Double, longitude lon: Double, onFoot: Bool) async -> Int? {
        let request = MKDirections.Request()
        request.source = MKMapItem(location: CLLocation(latitude: lat, longitude: lon), address: nil)
        request.destination = MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        request.transportType = onFoot ? .walking : .automobile
        guard let eta = try? await MKDirections(request: request).calculateETA() else { return nil }
        return max(1, Int((eta.expectedTravelTime / 60).rounded()))
    }

    private static func place(_ item: MKMapItem) -> ScoutPlace? {
        guard let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), name.count >= 3 else { return nil }
        let coordinate = item.location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate), abs(coordinate.latitude) > 0.01 || abs(coordinate.longitude) > 0.01 else { return nil }
        return ScoutPlace(
            name: name,
            category: Category(item.pointOfInterestCategory),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            locality: item.addressRepresentations?.cityName
        )
    }
}
