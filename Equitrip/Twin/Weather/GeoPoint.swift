//
//  GeoPoint.swift
//  Equitrip
//

import CoreLocation

/// A coordinate that can be stored, hashed and compared.
///
/// `CLLocationCoordinate2D` is none of those, and the twin keys its caches,
/// its weather and its map pins by place — so it keeps its own.
struct GeoPoint: Hashable, Codable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Great-circle distance in kilometres.
    func distance(to other: GeoPoint) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1000
    }

    /// Where Weather Union has stations: India, roughly. Checked before
    /// spending one of the day's thousand calls on somewhere it can't answer.
    var isInWeatherUnionCoverage: Bool {
        (6.0...37.6).contains(latitude) && (68.0...97.5).contains(longitude)
    }

    /// A point `km` away on `bearing` degrees — for the storm a scenario moves.
    func offset(km: Double, bearing: Double) -> GeoPoint {
        let radius = 6371.0
        let angular = km / radius
        let theta = bearing * .pi / 180
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        let lat2 = asin(sin(lat1) * cos(angular) + cos(lat1) * sin(angular) * cos(theta))
        let lon2 = lon1 + atan2(sin(theta) * sin(angular) * cos(lat1), cos(angular) - sin(lat1) * sin(lat2))
        return GeoPoint(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
}
