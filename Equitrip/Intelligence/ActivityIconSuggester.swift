//
//  ActivityIconSuggester.swift
//  Equitrip
//

import FoundationModels
import Foundation

/// Picks a fitting SF Symbol for a booking from its title.
///
/// "Scuba diving", "Kumbhalgarh Fort", "Sunset boat ride" all land in the
/// `.activity` category and so all drew the same hiking glyph, which made a
/// timeline of activities look like a list of one repeated thing. The model
/// chooses from a fixed menu rather than free-forming a symbol name — an
/// invented SF Symbol renders as nothing at all, so the safe move is to make
/// the wrong answer merely imperfect instead of blank.
@MainActor
enum ActivityIconSuggester {

    /// Every symbol the model may return, keyed by the token it picks.
    /// Verified to exist in SF Symbols; adding to this list is safe, inventing
    /// names at the call site is not.
    static let catalogue: [String: String] = [
        "diving": "figure.pool.swim",
        "swimming": "figure.open.water.swim",
        "beach": "beach.umbrella.fill",
        "boat": "sailboat.fill",
        "ferry": "ferry.fill",
        "hiking": "figure.hiking",
        "climbing": "figure.climbing",
        "mountain": "mountain.2.fill",
        "skiing": "figure.skiing.downhill",
        "cycling": "figure.outdoor.cycle",
        "running": "figure.run",
        "museum": "building.columns.fill",
        "monument": "building.columns",
        "castle": "building.2.fill",
        "temple": "building.columns.circle.fill",
        "park": "leaf.fill",
        "wildlife": "pawprint.fill",
        "forest": "tree.fill",
        "camping": "tent.fill",
        "music": "music.note",
        "theatre": "theatermasks.fill",
        "cinema": "film.fill",
        "shopping": "bag.fill",
        "market": "storefront.fill",
        "spa": "sparkles",
        "gym": "dumbbell.fill",
        "golf": "figure.golf",
        "photography": "camera.fill",
        "sightseeing": "binoculars.fill",
        "nightlife": "wineglass.fill",
        "coffee": "cup.and.saucer.fill",
        "food": "fork.knife",
        "tour": "map.fill",
        "ticket": "ticket.fill",
        "generic": "mappin.and.ellipse"
    ]

    private static var cache: [String: String] = [:]

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Returns an SF Symbol name, or nil to keep the category's default.
    static func symbol(for title: String, kind: ItineraryKind) async -> String? {
        // Only activities are ambiguous. A flight is a plane.
        guard kind == .activity else { return nil }

        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard key.count >= 3 else { return nil }
        if let hit = cache[key] { return hit }

        guard isAvailable else {
            let fallback = keywordMatch(key)
            if let fallback { cache[key] = fallback }
            return fallback
        }

        do {
            let session = LanguageModelSession(
                instructions: """
                    You label travel activities with one category from a fixed list.
                    Answer with exactly one word from the list and nothing else.
                    If none fit well, answer "generic".
                    """
            )

            let tokens = catalogue.keys.sorted().joined(separator: ", ")
            let response = try await session.respond(
                to: "Activity: \"\(title)\"\n\nChoose one of: \(tokens)"
            )

            let answer = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .filter { $0.isLetter }

            // The model occasionally answers in a sentence; only a token that
            // is actually in the catalogue is allowed through.
            guard let symbol = catalogue[answer] else { return keywordMatch(key) }
            cache[key] = symbol
            return symbol
        } catch {
            return keywordMatch(key)
        }
    }

    /// The no-Apple-Intelligence path: plain substring matching on the same
    /// vocabulary, which handles the obvious cases and declines the rest.
    private static func keywordMatch(_ title: String) -> String? {
        for (token, symbol) in catalogue where token != "generic" {
            if title.contains(token) { return symbol }
        }

        let extras: [(String, String)] = [
            ("scuba", "figure.pool.swim"), ("snorkel", "figure.open.water.swim"),
            ("trek", "figure.hiking"), ("safari", "pawprint.fill"),
            ("palace", "building.columns.fill"), ("fort", "building.columns.fill"),
            ("cruise", "sailboat.fill"), ("kayak", "sailboat.fill"),
            ("dinner", "fork.knife"), ("lunch", "fork.knife"),
            ("plantation", "leaf.fill"), ("garden", "leaf.fill"),
            ("dance", "theatermasks.fill"), ("concert", "music.note"),
            ("sunset", "sun.horizon.fill"), ("sunrise", "sun.horizon.fill")
        ]
        for (token, symbol) in extras where title.contains(token) {
            return symbol
        }
        return nil
    }
}
