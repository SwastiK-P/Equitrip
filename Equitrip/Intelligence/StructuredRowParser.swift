//
//  StructuredRowParser.swift
//  Equitrip
//

import Foundation

/// The no-Apple-Intelligence path, and the safety net under the model.
///
/// This replaces the old line-by-line keyword sweep, which had no idea what a
/// day was: it walked every line in the file, kept anything carrying a price,
/// and so turned the cost-summary table at the back into seven more bookings.
/// It now reads the same `ItineraryDocument` the model does — one dated day at
/// a time, appendix already excluded — which is where most of the accuracy
/// came from. What's left is genuinely dumb pattern matching on a row, and it
/// is honest about that: no title, no row.
enum StructuredRowParser {

    static func items(in day: ItineraryDocument.DaySection) -> [PlannedItem] {
        day.lines.enumerated().compactMap { index, line in
            item(from: line, on: day.date ?? Date(), hint: day.hint(at: index))
        }
    }

    private static func item(from line: String, on date: Date, hint: ExtractedKind?) -> PlannedItem? {
        var rest = line

        // Time first, because it's the row's leading column and stripping it
        // is what makes the rest of the line a title.
        var minuteOfDay: Int?
        if let leading = rest.range(of: "^\\d{1,2}[:.]\\d{2}\\s*(am|pm)?\\s",
                                   options: [.regularExpression, .caseInsensitive]) {
            if let parsed = TravelDate.time(in: String(rest[leading])) {
                minuteOfDay = parsed.hour * 60 + parsed.minute
            }
            rest.removeSubrange(leading)
        }

        let amount = ItineraryDocument.amount(in: rest) ?? 0
        let participants = trailingCount(in: rest)

        rest = rest.replacingOccurrences(
            of: "\\s*(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$",
            with: "", options: [.regularExpression, .caseInsensitive]
        )
        rest = rest.replacingOccurrences(of: "\\s+(included|free|complimentary)\\s*\\d{0,2}\\s*$",
                                         with: "", options: [.regularExpression, .caseInsensitive])
        rest = rest.trimmingCharacters(in: .whitespacesAndNewlines)

        let split = splitTitle(rest)
        guard split.title.count >= 2 else { return nil }

        return PlannedItem(
            title: split.title,
            detail: split.detail,
            day: date,
            minuteOfDay: minuteOfDay,
            // The row's own words first, then what the table it sat under
            // said, and only then a shrug. A hotel row is a hotel's name and
            // nothing else, so the heading is the only thing that knows.
            kind: ItineraryReasoner.classify(title: split.title, detail: split.detail) ?? hint ?? .other,
            amount: amount,
            participantCount: participants,
            photoQuery: ""
        )
    }

    /// Itinerary rows are "name, then everything else". Without a delimiter to
    /// go on, the first few words are the name — which is the same guess a
    /// person makes reading the table, and it fails the same way.
    static func splitTitle(_ text: String) -> (title: String, detail: String) {
        for delimiter in [" — ", " – ", " - ", ": ", " | "] {
            guard let range = text.range(of: delimiter) else { continue }
            return (
                String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces),
                String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            )
        }

        let words = text.components(separatedBy: " ").filter { !$0.isEmpty }
        guard words.count > 4 else { return (text, "") }

        // Three words is the length of nearly every row name in a real
        // itinerary: "Airport transfer", "Palace of Versailles", "Seine cruise".
        // But a fixed cut lands mid-phrase often enough to matter — "Agra Fort
        // +", "India Gate Guided" — so the edge is walked forward off a word
        // that can't end a name, and over the noun a name is usually built on.
        var cut = 3
        while cut < words.count, cut < 6, joiners.contains(words[cut - 1].lowercased()) {
            cut += 1
        }
        if cut < words.count, cut < 6,
           typeNouns.contains(words[cut].lowercased().trimmingCharacters(in: .punctuationCharacters)) {
            cut += 1
        }

        let head = words.prefix(cut).joined(separator: " ")
        let tail = words.dropFirst(cut).joined(separator: " ")
        return (head, tail)
    }

    /// Words a booking's name never ends on.
    private static let joiners: Set<String> = [
        "+", "&", "and", "at", "of", "to", "the", "a", "an", "in", "on",
        "for", "with", "via", "-", "–", "—", "→"
    ]

    /// The noun a booking's name is usually built on, worth one more word to
    /// reach: "India Gate Guided **Tour**".
    private static let typeNouns: Set<String> = [
        "tour", "tours", "train", "flight", "transfer", "museum", "cruise",
        "temple", "fort", "palace", "market", "experience", "tasting", "show",
        "walk", "visit", "safari", "trek", "class", "workshop", "gallery",
        "cathedral", "basilica", "garden", "park", "beach", "check-in", "checkin"
    ]

    private static func trailingCount(in line: String) -> Int {
        guard let range = line.range(of: "\\b(\\d{1,2})\\s*$", options: .regularExpression),
              let value = Int(line[range].trimmingCharacters(in: .whitespaces)),
              (1...30).contains(value) else { return 0 }
        return value
    }
}
