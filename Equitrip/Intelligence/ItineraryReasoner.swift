//
//  ItineraryReasoner.swift
//  Equitrip
//

import Foundation

/// The judgement pass: what a person reading the itinerary would fix.
///
/// A language model reading "06:30 Airport transfer — Home → Mumbai
/// International Airport, private cab" sees the word *airport* and files it
/// under flights, so the timeline showed someone flying before they'd left the
/// house. That isn't a prompt problem, it's a knowledge problem, and knowledge
/// this fixed belongs in code where it can be read and argued with rather than
/// in an instruction string where it can only be hoped for.
///
/// Everything here is deterministic and only ever *narrows* what the reader
/// produced: it reclassifies, orders, and drops. It never invents a booking, a
/// price or a time.
enum ItineraryReasoner {

    // MARK: - Entry point

    static func refine(_ days: [PlannedDay], destination: String) -> [PlannedDay] {
        days
            .map { day in
                var day = day
                day.items = order(dedupe(day.items.compactMap { clean($0, destination: destination) }))
                return day
            }
            .filter { !$0.items.isEmpty }
            .sorted { $0.date < $1.date }
    }

    // MARK: - One item

    private static func clean(_ item: PlannedItem, destination: String) -> PlannedItem? {
        var item = item
        item.title = tidyTitle(item.title)
        item.detail = tidyDetail(item.detail, title: item.title)

        guard item.title.count >= 2, !isNotABooking(item.title) else { return nil }

        if let ruled = classify(title: item.title, detail: item.detail) {
            item.kind = ruled
        }

        // A photo of a restaurant table or an airport kerb adds nothing; a
        // photo of the Eiffel Tower does.
        if item.kind == .stay || item.kind == .activity {
            if item.photoQuery.isEmpty || item.photoQuery.count < 4 {
                item.photoQuery = destination.isEmpty
                    ? item.title
                    : "\(item.title) \(destination.components(separatedBy: ",")[0])"
            }
        } else {
            item.photoQuery = ""
        }

        return item
    }

    /// Titles arrive with the row's leading time, its trailing price and its
    /// participant count still attached often enough to be worth stripping.
    private static func tidyTitle(_ raw: String) -> String {
        var title = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        title = title.replacingOccurrences(of: "^\\d{1,2}[:.]\\d{2}\\s*(am|pm)?\\s*", with: "",
                                           options: [.regularExpression, .caseInsensitive])
        title = title.replacingOccurrences(
            of: "\\s*(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$",
            with: "", options: [.regularExpression, .caseInsensitive]
        )
        title = title.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " -–—•|:,."))
        return String(title.prefix(60))
    }

    /// A detail that just repeats the title is noise on every row of the list,
    /// and one still carrying the row's price column is worse — the amount then
    /// shows up twice, once as text and once as money.
    private static func tidyDetail(_ raw: String, title: String) -> String {
        var detail = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        detail = detail.replacingOccurrences(
            of: "\\s*(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$",
            with: "", options: [.regularExpression, .caseInsensitive]
        )
        detail = detail.trimmingCharacters(in: CharacterSet(charactersIn: " -–—•|:,."))
        guard !detail.isEmpty, detail.caseInsensitiveCompare(title) != .orderedSame else { return "" }
        return String(detail.prefix(120))
    }

    /// Rows that are really table furniture, in case one survived the document
    /// pass — a summary line that becomes a ₹3,84,000 "booking" is the single
    /// most expensive mistake this screen can make.
    private static func isNotABooking(_ title: String) -> Bool {
        let lower = title.lowercased()
        let openers = [
            "total", "subtotal", "grand total", "estimated", "category", "summary",
            "day total", "per person", "cost", "amount", "price", "participants",
            "payer", "split model", "inclusions", "exclusions", "terms",
            "international flights", "accommodation", "local transportation",
            "activities & attractions", "food & dining", "shopping / personal"
        ]
        if openers.contains(where: { lower == $0 || lower.hasPrefix($0 + " ") }) { return true }
        return title.filter(\.isLetter).count < 2
    }

    // MARK: - Classification

    private struct Rule {
        var kind: ExtractedKind
        var any: [String]
        var unless: [String] = []
    }

    /// Order is the whole design. An airport transfer contains the word
    /// "airport", so `flight` is asked first and told to stand down when the
    /// row also mentions a cab; a hotel check-in and an airport check-in are
    /// separated the same way.
    private static let rules: [Rule] = [
        Rule(
            kind: .stay,
            any: ["check-in", "check in", "checkin", "check-out", "check out", "checkout",
                  "hotel", "resort", "villa", "hostel", "guesthouse", "guest house",
                  "airbnb", "accommodation", "apartment", "lodge", "homestay", "riad",
                  "night stay", "overnight"],
            unless: ["airport", "terminal", "boarding", "flight", "counter", "immigration",
                     "breakfast", "brunch", "lunch", "dinner", "supper", "buffet"]
        ),
        Rule(
            kind: .flight,
            any: ["flight", "airline", "airport", "terminal", "boarding", "departure formalities",
                  "arrival formalities", "immigration", "layover", "fly", "pnr", "aeroplane",
                  "airplane"],
            unless: ["transfer", "cab", "taxi", "shuttle", "pickup", "pick-up", "drop",
                     "metro", "bus", "train", "coach", "rental"]
        ),
        Rule(
            kind: .train,
            any: ["train", "rail", "railway", "eurostar", "tgv", "metro", "subway",
                  "tram", "underground", "platform", "sncf", "shinkansen"]
        ),
        Rule(
            kind: .transfer,
            any: ["transfer", "cab", "taxi", "uber", "ola", "shuttle", "pickup", "pick-up",
                  "drop", "bus", "coach", "car rental", "private car", "self drive",
                  "chauffeur", "limousine", "scooter", "auto"]
        ),
        Rule(
            kind: .meal,
            any: ["breakfast", "brunch", "lunch", "dinner", "supper", "meal", "restaurant",
                  "cafe", "café", "bistro", "coffee", "bakery", "dining", "brasserie",
                  "snack", "buffet", "pub", "eatery"],
            unless: ["formalities", "counter", "market", "tour"]
        ),
        Rule(
            kind: .activity,
            any: ["tour", "visit", "museum", "gallery", "palace", "tower", "cathedral",
                  "basilica", "church", "temple", "monastery", "shrine", "park", "garden",
                  "cruise", "show", "cabaret", "concert", "walk", "sightseeing", "shopping",
                  "market", "monument", "fort", "castle", "beach", "trek", "hike", "diving",
                  "snorkel", "safari", "zoo", "aquarium", "workshop", "experience", "ticket",
                  "entry", "summit", "excursion", "free time", "exploration", "quarter",
                  "district", "viewpoint", "sunset", "sunrise", "spa", "class", "souvenir",
                  "tasting", "food"]
        )
    ]

    /// What a row *is* is what it calls itself, and it calls itself in the first
    /// few words. So the opening of the title is asked first, then the whole
    /// title, then the description — widening only when the narrower reading
    /// says nothing.
    ///
    /// The order is what stops "Shopping / free time — souvenirs and cafés"
    /// being filed as a meal and "Latin Quarter — walking exploration and cafés"
    /// being filed as one too. Both mention a café; neither is one.
    static func classify(title: String, detail: String) -> ExtractedKind? {
        let opening = title
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: " ")

        // Matched narrowly, vetoed broadly. A row named "Check-in and departure
        // formalities" says "check-in" in its first three words and would be
        // filed as a hotel stay; the word "airport" that rules that out is
        // further along the row. So the keyword may be found in the opening,
        // but the objection is heard from the whole row.
        let everything = title + " " + detail

        if let kind = match(opening, vetoedBy: everything) { return kind }
        if let kind = match(title, vetoedBy: everything) { return kind }
        return match(everything, vetoedBy: everything)
    }

    private static func match(_ text: String, vetoedBy veto: String) -> ExtractedKind? {
        let words = tokens(of: text)
        guard !words.isEmpty else { return nil }
        let joined = text.lowercased()

        let vetoWords = tokens(of: veto)
        let vetoJoined = veto.lowercased()

        for rule in rules {
            guard rule.any.contains(where: { hit($0, words: words, joined: joined) }) else { continue }
            guard !rule.unless.contains(where: { hit($0, words: vetoWords, joined: vetoJoined) }) else { continue }
            return rule.kind
        }
        return nil
    }

    private static func tokens(of text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    /// Short keywords match whole words — "bus" must not fire on "business",
    /// and "car" must not fire on "card". Longer ones match as prefixes, which
    /// is what makes "walk" find "walking" and "café" find "cafés" without a
    /// stemmer.
    private static func hit(_ keyword: String, words: [String], joined: String) -> Bool {
        if keyword.contains(" ") || keyword.contains("-") {
            return joined.contains(keyword)
        }
        if keyword.count <= 3 {
            return words.contains(keyword)
        }
        return words.contains { $0.hasPrefix(keyword) }
    }

    // MARK: - Ordering

    /// Clock order, with untimed rows staying where the document put them.
    ///
    /// A stay usually has no time, and sorting it to midnight moved every
    /// hotel to the top of its day, above the flight that got everyone there.
    /// An untimed row instead inherits the time of the row above it, so it
    /// lands where it was written.
    static func order(_ items: [PlannedItem]) -> [PlannedItem] {
        var inherited = 0
        let keyed = items.enumerated().map { index, item -> (key: Int, tie: Int, item: PlannedItem) in
            if let minute = item.minuteOfDay { inherited = minute }
            return (key: inherited, tie: index, item: item)
        }

        return keyed
            .sorted { $0.key == $1.key ? $0.tie < $1.tie : $0.key < $1.key }
            .map(\.item)
    }

    // MARK: - Duplicates

    /// The same booking twice is what a table split across a page break looks
    /// like once it has been read twice.
    static func dedupe(_ items: [PlannedItem]) -> [PlannedItem] {
        var seen = Set<String>()
        var result: [PlannedItem] = []

        for item in items {
            let key = [
                item.title.lowercased().filter { $0.isLetter || $0.isNumber },
                item.clockText,
                String(format: "%.0f", item.amount)
            ].joined(separator: "|")

            guard seen.insert(key).inserted else { continue }
            result.append(item)
        }
        return collapseRestatements(result)
    }

    /// The same booking written down in two different tables.
    ///
    /// A document that lists its hotels in one table and then repeats the
    /// check-in on the day's plan produces two rows for one night — "Tajview
    /// Agra" and "Hotel check-in Tajview Agra", same clock, only one of them
    /// priced. The exact-match pass above can't see it, because neither the
    /// title nor the amount agrees. What does agree is that one name contains
    /// the other, and that is a weak enough signal to insist the clock matches
    /// too before acting on it.
    private static func collapseRestatements(_ items: [PlannedItem]) -> [PlannedItem] {
        var result: [PlannedItem] = []

        for item in items {
            let name = normalised(item.title)
            guard name.count >= 4, !item.clockText.isEmpty else {
                result.append(item)
                continue
            }

            let match = result.firstIndex { existing in
                guard existing.clockText == item.clockText, existing.kind == item.kind else { return false }
                let other = normalised(existing.title)
                guard other.count >= 4 else { return false }
                return other.contains(name) || name.contains(other)
            }

            guard let index = match else {
                result.append(item)
                continue
            }

            // Keep whichever reading knew the price, and the shorter name —
            // the longer one is the shorter one with a category label on it.
            if item.amount > result[index].amount { result[index].amount = item.amount }
            if name.count < normalised(result[index].title).count { result[index].title = item.title }
            if result[index].detail.isEmpty { result[index].detail = item.detail }
        }

        return result
    }

    private static func normalised(_ title: String) -> String {
        title.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
