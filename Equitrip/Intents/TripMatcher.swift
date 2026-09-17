//
//  TripMatcher.swift
//  Equitrip
//

import Foundation

/// Which trip, booking or person a few spoken words mean.
///
/// Siri hands an entity query the raw words — "goa", "the Rome one", "Ed's
/// flight" — and does no matching of its own. Neither does Visual
/// Intelligence, which hands over whatever text was on the page. So the
/// matching lives here, once, rather than in each query that needs it.
///
/// Deliberately plain: word overlap on titles, destinations, vendors and
/// names, case- and accent-blind. A trip list is a handful of items a person
/// named themselves; an embedding model would be answering a question nobody
/// has.
enum TripMatcher {

    /// Trips whose title or destination the words point at, best first.
    static func trips(matching text: String, in trips: [Trip]) -> [Trip] {
        let query = words(text).subtracting(fillerWords)
        guard !query.isEmpty else { return byRelevance(trips) }

        return trips
            .map { trip in (trip, score(query, against: [trip.title, trip.destination])) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// Bookings whose title, vendor, kind or flight number the words point
    /// at, best first; ties go to whatever happens soonest.
    static func bookings(matching text: String, in trips: [Trip]) -> [(trip: Trip, item: ItineraryItem)] {
        let query = words(text).subtracting(fillerWords)
        guard !query.isEmpty else { return [] }

        var scored: [(trip: Trip, item: ItineraryItem, score: Int)] = []
        for trip in trips {
            for item in trip.items {
                let fields: [String] = [item.title, item.vendor, item.kind.label, item.flight?.number ?? "", trip.title]
                let score = score(query, against: fields)
                if score > 0 { scored.append((trip, item, score)) }
            }
        }
        scored.sort { lhs, rhs in
            lhs.score != rhs.score ? lhs.score > rhs.score : start(of: lhs.item) < start(of: rhs.item)
        }
        return scored.map { (trip: $0.trip, item: $0.item) }
    }

    /// The traveller on `trip` a spoken name means, if exactly one fits.
    static func traveller(named name: String, on trip: Trip) -> Traveller? {
        let query = words(name)
        guard !query.isEmpty else { return nil }
        if query.contains("me") || query.contains("i") || CurrentUser.isYou(name) {
            return trip.traveller(Traveller.you.id)
        }
        let hits = trip.travellers.filter { !words($0.name).isDisjoint(with: query) }
        return hits.count == 1 ? hits[0] : nil
    }

    /// The order a person reaches for trips in: the one under way, then
    /// what's next soonest first, then the rest newest first.
    static func byRelevance(_ trips: [Trip]) -> [Trip] {
        let live = trips.filter { $0.phase == .live }
        let upcoming = trips.filter { $0.phase == .upcoming }.sorted { $0.startDate < $1.startDate }
        let past = trips.filter { $0.phase == .past }.sorted { $0.startDate > $1.startDate }
        return live + upcoming + past
    }

    /// The trip a request with no trip named most likely means.
    static func likeliest(in trips: [Trip]) -> Trip? {
        byRelevance(trips).first
    }

    static func start(of item: ItineraryItem) -> Date {
        item.time ?? item.date
    }

    // MARK: - Scoring

    private static func score(_ query: Set<String>, against fields: [String]) -> Int {
        var total = 0
        for field in fields where !field.isEmpty {
            let fieldWords = words(field)
            let overlap = query.intersection(fieldWords).count
            total += overlap * 2
            // Half-typed or run-together words: "bali" in "Balinese", "goa" in "goatrip".
            let joined = fieldWords.joined(separator: " ")
            total += query.filter { $0.count >= 3 && !fieldWords.contains($0) && joined.contains($0) }.count
        }
        return total
    }

    private static func words(_ text: String) -> Set<String> {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return Set(folded.split { !$0.isLetter && !$0.isNumber }.map(String.init))
    }

    /// Words that name the category rather than the thing: "the Goa *trip*".
    private static let fillerWords: Set<String> = ["the", "my", "our", "a", "an", "trip", "trips", "holiday", "vacation", "one", "to", "in", "on", "for", "of"]
}
