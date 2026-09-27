//
//  PlaceSearchTool.swift
//  Equitrip
//

import Foundation
import FoundationModels

/// The model's own Maps search, for an indoor swap: it knows a heritage walk
/// in Varanasi suits a history museum or a silk-weaving workshop, which a
/// category sweep can't guess. Results go into the shared `ScoutPool`, and
/// back to the model as short lines.
nonisolated struct PlaceSearchTool: Tool {
    let name = "searchPlaces"
    let description = "Searches Apple Maps near the booking for indoor places matching a short query, such as 'history museum' or 'silk weaving workshop'. Returns place names with their kind and distance."

    @Generable
    nonisolated struct Arguments {
        @Guide(description: "Two to four words naming an indoor place to look for")
        var query: String
    }

    let latitude: Double
    let longitude: Double
    let city: String
    let maxKm: Double
    let pool: ScoutPool
    let progress: @Sendable (String) async -> Void

    @concurrent
    func call(arguments: Arguments) async throws -> String {
        let query = String(arguments.query.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        guard !query.isEmpty else { return "Give a few words to search for." }
        await progress("Searching Maps for “\(query)”")

        let found = await ScoutPlace.search("\(query), \(city)", latitude: latitude, longitude: longitude)
            .filter { $0.distanceKm(fromLatitude: latitude, longitude: longitude) <= maxKm }
        await pool.add(found)
        guard !found.isEmpty else { return "Nothing found for \(query) nearby." }
        return found.prefix(5)
            .map { $0.line(fromLatitude: latitude, longitude: longitude) }
            .joined(separator: "\n")
    }
}
