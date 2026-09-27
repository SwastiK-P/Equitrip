//
//  IndoorScout.swift
//  Equitrip
//

import Foundation
import FoundationModels

/// Somewhere under a roof near a booking the weather threatens: found on
/// Apple Maps, ranked by the on-device model with tools, checked by Swift.
///
/// Fastest source first. A category sweep of the booking's surroundings
/// (museums, cinemas, libraries — or restaurants and cafés, for a meal) runs
/// alongside two worded searches, and that list alone is the answer on a
/// device without Apple Intelligence. With it, the model gets the list plus
/// two tools — its own Maps search (`PlaceSearchTool`) and a travel-time
/// check (`TravelTimeTool`) — so a heritage walk can become the city's
/// history museum rather than the nearest cinema. The model hands back names
/// only: one Maps never returned is dropped, and every figure on screen —
/// distance, minutes to get there — is measured by MapKit.
enum IndoorScout {

    struct Candidate: Identifiable, Hashable {
        let place: ScoutPlace
        let distanceKm: Double
        var minutes: Int?
        var onFoot = true

        var id: String { place.key }
        var name: String { place.name }
        var symbol: String { place.category?.symbol ?? "building.2.fill" }

        /// "1.2 km · 14 min on foot".
        var distanceLabel: String {
            let km = distanceKm < 1 ? "\(Int((distanceKm * 1000 / 50).rounded()) * 50) m" : String(format: "%.1f km", distanceKm)
            guard let minutes else { return km }
            return "\(km) · \(minutes) min \(onFoot ? "on foot" : "by road")"
        }

        var shortDistance: String {
            if let minutes { return "\(minutes) min \(onFoot ? "walk" : "drive")" }
            return distanceKm < 1 ? "\(Int((distanceKm * 1000 / 50).rounded()) * 50) m" : String(format: "%.1f km", distanceKm)
        }
    }

    struct Result {
        var candidates: [Candidate]
        /// The order came from the model, not from distance alone.
        var rankedByModel: Bool
    }

    @Generable
    nonisolated struct Ranking {
        @Guide(description: "Up to three place names, best swap first, copied exactly from the candidates or search results", .maximumCount(3))
        var names: [String]
    }

    private static let nearKm = 3.0
    private static let farKm = 8.0

    /// The best few places, ready to offer. `progress` is told each step as
    /// it starts, the model's tool calls included.
    static func scout(
        for item: ItineraryItem,
        at spot: TwinGeocoder.Place,
        city: String,
        trip: Trip,
        progress: @escaping @Sendable (String, String) async -> Void
    ) async throws -> Result {
        let lat = spot.point.latitude, lon = spot.point.longitude
        let isMeal = item.kind == .meal
        let categories = isMeal ? ScoutPlace.Category.meals : ScoutPlace.Category.sights
        let pool = ScoutPool()

        await progress("Looking for places under a roof near \(spot.locality ?? spot.name)", "map")
        let words = isMeal ? ["restaurant"] : ["museum", "art gallery"]
        async let sweep = ScoutPlace.sweep(latitude: lat, longitude: lon, radius: nearKm * 1000, categories: categories)
        async let first = ScoutPlace.search("\(words[0]), \(city)", latitude: lat, longitude: lon)
        async let second = words.count > 1 ? ScoutPlace.search("\(words[1]), \(city)", latitude: lat, longitude: lon) : []
        await pool.add(await sweep + first + second)

        var usable = filter(await pool.all, for: item, trip: trip, lat: lat, lon: lon, categories: categories)
        if usable.count < 3 {
            try Task.checkCancellation()
            await progress("Not much close by — widening to \(Int(farKm)) km", "arrow.up.left.and.arrow.down.right")
            await pool.add(await ScoutPlace.sweep(latitude: lat, longitude: lon, radius: farKm * 1000, categories: categories))
            usable = filter(await pool.all, for: item, trip: trip, lat: lat, lon: lon, categories: categories)
        }
        try Task.checkCancellation()

        let byScore = usable.sorted { score($0, for: item) > score($1, for: item) }
        var ranked: [Candidate] = []
        var rankedByModel = false

        if EquiIntelligence.availability == .ready, !byScore.isEmpty {
            await progress("Asking Apple Intelligence what suits “\(item.title)”", "apple.intelligence")
            let names = await rank(item: item, spot: spot, city: city, shortlist: Array(byScore.prefix(8)), pool: pool, lat: lat, lon: lon, progress: progress)
            try Task.checkCancellation()
            // The model may have found better places with its own searches:
            // they pass the same checks as everything else.
            let checked = filter(await pool.all, for: item, trip: trip, lat: lat, lon: lon, categories: categories)
            for name in names {
                guard let place = await pool.place(named: name),
                      let candidate = checked.first(where: { $0.id == place.key }),
                      !ranked.contains(candidate) else { continue }
                ranked.append(candidate)
            }
            rankedByModel = !ranked.isEmpty
        }
        for candidate in byScore where ranked.count < 3 && !ranked.contains(candidate) {
            ranked.append(candidate)
        }
        guard !ranked.isEmpty else { return Result(candidates: [], rankedByModel: false) }

        await progress("Checking how long each one takes to reach", "figure.walk")
        ranked = await withTaskGroup(of: (Int, Candidate).self) { group in
            for (index, candidate) in ranked.enumerated() {
                group.addTask {
                    var timed = candidate
                    if let known = await pool.time(for: candidate.id) {
                        timed.minutes = known.minutes
                        timed.onFoot = known.onFoot
                    } else {
                        let onFoot = candidate.distanceKm <= 2.5
                        timed.minutes = await candidate.place.minutes(fromLatitude: lat, longitude: lon, onFoot: onFoot)
                        timed.onFoot = onFoot
                    }
                    return (index, timed)
                }
            }
            var out = ranked
            for await (index, timed) in group { out[index] = timed }
            return out
        }
        return Result(candidates: ranked, rankedByModel: rankedByModel)
    }

    /// The booking's new title: the place's name, with what it is added when
    /// the name alone wouldn't tell the twin it's indoors.
    static func title(for candidate: Candidate, replacing item: ItineraryItem) -> String {
        if exposure(of: candidate.name, replacing: item) == .indoor { return candidate.name }
        if let noun = candidate.place.category?.noun { return "\(candidate.name) · \(noun)" }
        return candidate.name
    }

    // MARK: - Model

    private static func rank(
        item: ItineraryItem,
        spot: TwinGeocoder.Place,
        city: String,
        shortlist: [Candidate],
        pool: ScoutPool,
        lat: Double,
        lon: Double,
        progress: @escaping @Sendable (String, String) async -> Void
    ) async -> [String] {
        let say: @Sendable (String) async -> Void = { await progress($0, "magnifyingglass") }
        let session = LanguageModelSession(
            tools: [
                PlaceSearchTool(latitude: lat, longitude: lon, city: city, maxKm: farKm, pool: pool, progress: say),
                TravelTimeTool(latitude: lat, longitude: lon, pool: pool, progress: say)
            ],
            instructions: """
            You choose an indoor replacement for a travel group's outdoor plan that bad weather threatens. \
            Prefer places that keep the spirit of the original plan (a heritage walk suits a history museum), then closer ones. \
            You may call searchPlaces once or twice for ideas that fit better, and travelTime to compare. \
            Answer only with names copied exactly from the candidates or from tool results.
            """
        )

        var prompt = "Original plan: \(item.title)"
        if let vendor = item.vendorName, vendor != item.title { prompt += " with \(vendor)" }
        prompt += ", \(DateFormatter.cached("EEE d MMM").string(from: item.date))"
        if let time = item.timeLabel { prompt += " at \(time)" }
        prompt += ", at \(spot.name), \(city).\nCandidates:\n"
        prompt += shortlist.map { "- " + $0.place.line(fromLatitude: lat, longitude: lon) }.joined(separator: "\n")

        do {
            return try await withThrowingTaskGroup(of: [String].self) { group in
                group.addTask {
                    try await session.respond(to: prompt, generating: Ranking.self, options: GenerationOptions(temperature: 0.3)).content.names
                }
                // Tool calls are network round trips; a model still thinking
                // after this long loses to the list Swift already has.
                group.addTask {
                    try await Task.sleep(for: .seconds(20))
                    return []
                }
                let first = try await group.next() ?? []
                group.cancelAll()
                return first
            }
        } catch {
            return []
        }
    }

    // MARK: - Checks

    /// Within reach, not already on the trip, and actually indoors.
    private static func filter(
        _ places: [ScoutPlace],
        for item: ItineraryItem,
        trip: Trip,
        lat: Double,
        lon: Double,
        categories: [ScoutPlace.Category]
    ) -> [Candidate] {
        let booked = trip.items.flatMap { [$0.title.lowercased(), $0.vendor.lowercased()] }.filter { $0.count >= 3 }
        return places.compactMap { place in
            let km = place.distanceKm(fromLatitude: lat, longitude: lon)
            guard km <= farKm else { return nil }
            if let category = place.category, !categories.contains(category) { return nil }
            guard !booked.contains(where: { $0.contains(place.key) || place.key.contains($0) }) else { return nil }
            let candidate = Candidate(place: place, distanceKm: km)
            guard exposure(of: title(for: candidate, replacing: item), vendor: place.name, replacing: item) == .indoor else { return nil }
            return candidate
        }
    }

    private static func exposure(of title: String, vendor: String? = nil, replacing item: ItineraryItem) -> WeatherExposure {
        var probe = item
        probe.title = title
        probe.vendor = vendor ?? title
        return WeatherExposure.of(probe)
    }

    /// Closeness, weighed against how well the kind of place suits what it
    /// replaces. The fallback order, and the model's tiebreak.
    private static func score(_ candidate: Candidate, for item: ItineraryItem) -> Double {
        let words = "\(item.title) \(item.vendor)".lowercased()
        func has(_ list: [String]) -> Bool { list.contains { words.contains($0) } }
        let fit: Double
        switch candidate.place.category {
        case .museum: fit = has(["heritage", "history", "temple", "fort", "ghat", "old", "walk", "tour", "palace"]) ? 3 : 2
        case .library: fit = has(["heritage", "history", "old"]) ? 1.5 : 0.8
        case .theatre, .musicVenue: fit = has(["aarti", "sunset", "evening", "night", "show", "festival"]) ? 2.5 : 1.2
        case .aquarium, .planetarium: fit = has(["beach", "boat", "snorkel", "park", "safari", "nature", "star"]) ? 2.5 : 1.2
        case .cinema, .bowling, .spa: fit = 1
        case .restaurant, .cafe, .bakery: fit = 2
        case nil: fit = 0.5
        }
        return fit - candidate.distanceKm * 0.35
    }
}
