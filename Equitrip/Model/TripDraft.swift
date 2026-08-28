//
//  TripDraft.swift
//  Equitrip
//

import SwiftUI

/// The mutable thing the creation flow builds up.
///
/// Both routes into the flow — a parsed PDF and a hand-filled form — land here,
/// so the review screen and the save path only ever deal with one shape.
struct TripDraft {
    var title: String = ""
    var destination: String = ""
    var startDate: Date = Calendar.current.startOfDay(for: Date())
    var endDate: Date = Date.daysFromToday(3)
    var currencyCode: String = "INR"
    var travellers: [Traveller] = [.you]
    var items: [ItineraryItem] = []
    var cover: TripPhoto?

    /// Whether the on-device model produced this, for the review screen's note.
    var wasImported = false
    var usedFallbackParser = false
    var sourceFileName: String?

    /// How many people the document said were travelling. Kept separate from
    /// `travellers` on purpose: the count is a fact the document gave us, the
    /// names are not, and conflating the two is what used to put four invented
    /// strangers on somebody's trip.
    var expectedTravellerCount = 0
    /// The names, if any, that were actually written in the document.
    var namesFromDocument: [String] = []

    /// Whether the trip still needs someone to say who is coming.
    var needsParticipants: Bool {
        expectedTravellerCount > travellers.count
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && endDate >= startDate
    }

    /// What to ask the photo service for. The destination is a better search
    /// term than the trip's nickname — "Goa, India" finds beaches, "Goa
    /// escape" finds stock photos of people escaping.
    var coverQuery: String {
        let place = destination.trimmingCharacters(in: .whitespaces)
        return place.isEmpty ? title : place
    }

    var dayCount: Int {
        max(1, (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1)
    }

    /// A glyph and colour picked from the destination, so a trip has an
    /// identity before anyone has chosen one for it.
    var inferredSymbol: String {
        let text = (destination + " " + title).lowercased()
        if text.containsAny("ski", "snow", "alps", "manali", "aspen", "winter") { return "snowflake" }
        if text.containsAny("beach", "goa", "bali", "maldives", "island", "coast") { return "beach.umbrella.fill" }
        if text.containsAny("trek", "hike", "mountain", "camp", "himalaya") { return "mountain.2.fill" }
        if text.containsAny("backwater", "cruise", "lake", "boat", "kerala") { return "ferry.fill" }
        if text.containsAny("safari", "forest", "wildlife", "national park") { return "leaf.fill" }
        if text.containsAny("tokyo", "paris", "london", "city", "york", "dubai") { return "building.2.fill" }
        return "suitcase.fill"
    }

    var inferredTint: Color {
        switch inferredSymbol {
        case "snowflake": Palette.blue
        case "beach.umbrella.fill": Palette.amber
        case "mountain.2.fill": Palette.teal
        case "ferry.fill": Palette.violet
        case "leaf.fill": Palette.green
        case "building.2.fill": Palette.indigo
        default: AppTheme.accent
        }
    }

    var totalCost: Double { items.reduce(0) { $0 + $1.cost } }

    // MARK: - Save

    func makeTrip() -> Trip {
        // Everyone is on every booking unless the item says otherwise; the
        // review screen is where that gets narrowed down.
        let everyone = Set(travellers.map(\.id))
        let resolved = items.map { item -> ItineraryItem in
            var copy = item
            if copy.participantIDs.isEmpty { copy.participantIDs = everyone }
            return copy
        }

        return Trip(
            title: title.trimmingCharacters(in: .whitespaces),
            destination: destination.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            currencyCode: currencyCode,
            symbol: inferredSymbol,
            tint: inferredTint,
            travellers: travellers,
            items: resolved,
            cover: cover
        )
    }

    // MARK: - From an extraction

    /// Folds a finished (or abandoned) extraction into a draft. Anything the
    /// reader left blank keeps the draft's default rather than becoming empty.
    static func from(_ progress: TripExtractor.Progress, fileName: String?, usedFallback: Bool) -> TripDraft {
        var draft = TripDraft()
        draft.wasImported = true
        draft.usedFallbackParser = usedFallback
        draft.sourceFileName = fileName

        if !progress.title.isEmpty { draft.title = progress.title }
        if !progress.destination.isEmpty { draft.destination = progress.destination }
        if progress.currencyCode.count == 3 { draft.currencyCode = progress.currencyCode.uppercased() }

        draft.expectedTravellerCount = progress.travellerCount
        draft.namesFromDocument = progress.travellerNames

        // A name written in a document is a clue about who to add, not a person
        // who can be added. Travellers are identified by the address they use
        // for Equitrip, so an import starts with exactly one traveller — you —
        // and the next screen asks for the rest.
        draft.travellers = [.you]

        let ids = Set(draft.travellers.map(\.id))
        draft.items = progress.items.map { $0.asItineraryItem(participantIDs: ids) }

        // Trust the bookings over anything the reader said about the span.
        let dates = draft.items.map(\.day).sorted()
        if let first = dates.first, let last = dates.last {
            draft.startDate = first
            draft.endDate = last
        }

        if draft.title.isEmpty {
            draft.title = draft.destination.isEmpty
                ? "Imported trip"
                : "\(draft.destination.components(separatedBy: ",")[0]) trip"
        }

        return draft
    }

}

// MARK: - Bridging the model's output

extension PlannedItem {
    /// Turns one read row into a real itinerary item. The day is already
    /// settled by this point — `ItineraryDocument` owns dates, so there is no
    /// longer a date string here to fail to parse.
    func asItineraryItem(participantIDs: Set<UUID>) -> ItineraryItem {
        let resolvedKind = kind.asItineraryKind
        let query = photoQuery.trimmingCharacters(in: .whitespaces)
        let start = Calendar.current.startOfDay(for: day)

        return ItineraryItem(
            title: title,
            vendor: detail,
            kind: resolvedKind,
            date: start,
            time: minuteOfDay.map { .at($0 / 60, $0 % 60, on: start) },
            cost: max(0, amount),
            // A row the document marked for fewer people than are on the trip
            // is not an even split, and defaulting it to one would quietly
            // charge everybody for somebody's souvenirs.
            split: participantCount == 1 ? .individual : resolvedKind.defaultSplit,
            participantIDs: participantIDs,
            photoQuery: query.isEmpty ? nil : query
        )
    }
}

extension ExtractedKind {
    var asItineraryKind: ItineraryKind {
        switch self {
        case .flight: .flight
        case .train: .train
        case .transfer: .drive
        case .stay: .stay
        case .activity: .activity
        case .meal: .meal
        case .other: .other
        }
    }
}

// MARK: - Helpers

private extension String {
    func containsAny(_ needles: String...) -> Bool {
        needles.contains { contains($0) }
    }
}
