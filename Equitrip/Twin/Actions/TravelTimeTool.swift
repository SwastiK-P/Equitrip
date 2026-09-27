//
//  TravelTimeTool.swift
//  Equitrip
//

import Foundation
import FoundationModels

/// How long it takes to get from the threatened booking to a place already
/// found, routed by Maps — on foot under 2.5 km, by road beyond. Lets the
/// model weigh "a better fit" against "twenty minutes further in the rain".
nonisolated struct TravelTimeTool: Tool {
    let name = "travelTime"
    let description = "Returns how many minutes it takes to get from the booking's spot to a place already listed or found by searchPlaces."

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "A place name exactly as the candidates or a search listed it")
        var place: String
    }

    let latitude: Double
    let longitude: Double
    let pool: ScoutPool
    let progress: @Sendable (String) async -> Void

    @concurrent
    func call(arguments: Arguments) async throws -> String {
        guard let place = await pool.place(named: arguments.place) else {
            return "Unknown place. Use a name from the candidates or from searchPlaces."
        }
        if let known = await pool.time(for: place.key) {
            return "\(place.name): \(known.minutes) min \(known.onFoot ? "on foot" : "by road")"
        }
        let km = place.distanceKm(fromLatitude: latitude, longitude: longitude)
        let onFoot = km <= 2.5
        await progress("Timing the way to \(place.name)")
        guard let minutes = await place.minutes(fromLatitude: latitude, longitude: longitude, onFoot: onFoot) else {
            return "\(place.name): \(String(format: "%.1f", km)) km away, no route found."
        }
        await pool.setTime(minutes, onFoot: onFoot, for: place.key)
        return "\(place.name): \(minutes) min \(onFoot ? "on foot" : "by road")"
    }
}
