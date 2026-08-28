//
//  ItineraryDocument.swift
//  Equitrip
//

import Foundation

/// A booking document read for its *shape*, before anything reads it for meaning.
///
/// This is the pass that was missing. Handing a whole PDF to a language model
/// and asking for "every booking" makes it responsible for three jobs at once:
/// finding where the itinerary starts, keeping track of which day it's on, and
/// deciding what each row is. It reliably fails the first two — it turns the
/// cost-summary table at the back into seven more bookings, and it drifts a day
/// at a time once the list gets long.
///
/// So the structure is worked out here, deterministically, where it can be
/// checked: which lines are the trip header, which lines belong to which dated
/// day, and which lines are the appendix that must never become bookings. The
/// model is then asked one small question per day, with the date supplied
/// rather than inferred. That's the difference between 69 rows and 45.
struct ItineraryDocument {

    /// One dated block of the itinerary.
    struct DaySection: Identifiable {
        var id: Int { number }
        /// 1-based, in document order — not necessarily the "DAY n" label.
        var number: Int
        /// Nil when the document never gave this day a resolvable date, which
        /// is rare and always recoverable from the day's position in the span.
        var date: Date?
        /// The line under the date header: "Montmartre | Sacré-Cœur".
        var heading: String
        /// The rows, cleaned of table furniture and totals.
        var lines: [String]

        var body: String { lines.joined(separator: "\n") }

        /// The rows with their price and participant columns taken off.
        ///
        /// Those two are read straight from the text — they're the one part of
        /// a row that needs no interpretation — so sending them to the model
        /// only gives it something to copy into the wrong field, which is
        /// exactly what it did: every description came back ending "₹4,800 4".
        var promptBody: String {
            lines.map { line in
                line
                    .replacingOccurrences(
                        of: "\\s*(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$",
                        with: "", options: [.regularExpression, .caseInsensitive]
                    )
                    .replacingOccurrences(
                        of: "\\s+(included|free|complimentary|n/a)\\s*\\d{0,2}\\s*$",
                        with: "", options: [.regularExpression, .caseInsensitive]
                    )
                    .trimmingCharacters(in: .whitespaces)
            }
            .joined(separator: "\n")
        }
    }

    var preamble: [String] = []
    var days: [DaySection] = []
    /// Cost summaries, ledger tables, terms — read for context, never for items.
    var appendix: [String] = []

    /// How many people the document says are travelling. A count, deliberately,
    /// not names: see `namedTravellers`.
    var travellerCount: Int?
    /// Only names actually written down. Empty for a document that says
    /// "4 people" and never names them — which is most of them.
    var namedTravellers: [String] = []
    var currencyCode: String?
    var startDate: Date?
    var endDate: Date?
    var title: String?
    var destinationHint: String?

    /// The whole cleaned body, lowercased, for checking that a name the model
    /// produced is one the document actually contains.
    var haystack: String = ""

    var isStructured: Bool { days.count >= 2 }

    var itemLineCount: Int { days.reduce(0) { $0 + $1.lines.count } }

    // MARK: - Parse

    static func parse(_ raw: String, referenceDate: Date = Date()) -> ItineraryDocument {
        var document = ItineraryDocument()

        let cleaned = stripFurniture(raw.components(separatedBy: .newlines))
            .flatMap(explodeRunTogetherRows)
            .filter { !$0.isEmpty }

        document.haystack = cleaned.joined(separator: "\n").lowercased()
        document.rawTail = cleaned

        // Where each day starts. Everything before the first one is the trip
        // header; everything after the last day's rows is the appendix.
        let markers = dayMarkers(in: cleaned, referenceDate: referenceDate)

        guard let first = markers.first else {
            // No day headers at all — an email confirmation, a single booking.
            // One section covering everything still beats a flat blob, because
            // the appendix split and the row cleaning below still apply.
            let split = splitAppendix(cleaned)
            document.preamble = Array(split.body.prefix(12))
            document.appendix = split.appendix
            if !split.body.isEmpty {
                document.days = [
                    DaySection(number: 1, date: nil, heading: "", lines: cleanRows(split.body))
                ]
            }
            document.absorbHeaderFacts(referenceDate: referenceDate)
            return document
        }

        document.preamble = Array(cleaned[cleaned.startIndex..<first.index])

        for (offset, marker) in markers.enumerated() {
            let start = marker.index + 1
            let end = offset + 1 < markers.count ? markers[offset + 1].index : cleaned.count
            guard start <= end else { continue }

            var block = Array(cleaned[start..<end])

            // The appendix only ever trails the last day, but a "COST SUMMARY"
            // heading can legitimately appear mid-document in a long agent
            // itinerary, so every block is checked.
            let split = splitAppendix(block)
            block = split.body
            document.appendix.append(contentsOf: split.appendix)

            let heading = block.first.flatMap { isRow($0) || isFurniture($0) ? nil : $0 } ?? ""
            if !heading.isEmpty { block.removeFirst() }

            document.days.append(
                DaySection(
                    number: offset + 1,
                    date: marker.date,
                    heading: heading,
                    lines: cleanRows(block)
                )
            )
        }

        document.inferMissingDates(referenceDate: referenceDate)
        document.repairOrphanedAmounts()
        document.absorbHeaderFacts(referenceDate: referenceDate)
        document.days.removeAll { $0.lines.isEmpty }

        return document
    }

    // MARK: - Furniture

    /// Page headers and footers repeat on every page and carry nothing. Left in,
    /// they cost context and give the model a plausible-looking row to invent
    /// a booking from.
    private static func stripFurniture(_ lines: [String]) -> [String] {
        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespaces) }

        var frequency: [String: Int] = [:]
        for line in trimmed where line.count < 90 { frequency[line, default: 0] += 1 }

        return trimmed.filter { line in
            guard !line.isEmpty else { return false }
            if line.range(of: "\\bpage\\s+\\d+\\b", options: [.regularExpression, .caseInsensitive]) != nil,
               line.count < 90 { return false }
            // A short line that appears on most pages is a running header.
            if (frequency[line] ?? 0) >= 3, line.count < 90 { return false }
            return true
        }
    }

    /// PDF text extraction sometimes emits a whole table body as one line, with
    /// every row run together. A line carrying three or more clock times is that
    /// case and nothing else — a single booking doesn't have three start times.
    private static func explodeRunTogetherRows(_ line: String) -> [String] {
        guard line.count > 100 else { return [line] }

        let pattern = "(?<![\\d:])\\d{1,2}:\\d{2}(?![\\d:])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [line] }
        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, range: range)
        guard matches.count >= 3 else { return [line] }

        var pieces: [String] = []
        var cursor = line.startIndex
        for match in matches {
            guard let start = Range(match.range, in: line)?.lowerBound, start > cursor else { continue }
            pieces.append(String(line[cursor..<start]))
            cursor = start
        }
        pieces.append(String(line[cursor...]))

        return pieces
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Day markers

    private struct DayMarker {
        var index: Int
        var date: Date?
    }

    private static func dayMarkers(in lines: [String], referenceDate: Date) -> [DayMarker] {
        var markers: [DayMarker] = []

        for (index, line) in lines.enumerated() {
            guard looksLikeDayHeader(line) else { continue }
            // A date on the header wins; failing that, the line under it often
            // carries one ("Day 3" / "14 September 2026").
            let date = TravelDate.first(in: line, referenceDate: referenceDate)
                ?? (index + 1 < lines.count && lines[index + 1].count < 60
                    ? TravelDate.first(in: lines[index + 1], referenceDate: referenceDate)
                    : nil)
            markers.append(DayMarker(index: index, date: date))
        }

        return markers
    }

    private static func looksLikeDayHeader(_ line: String) -> Bool {
        guard line.count <= 110 else { return false }
        if line.range(of: "^day\\s*\\d+\\b", options: [.regularExpression, .caseInsensitive]) != nil { return true }

        // Otherwise the line has to be essentially just a date —
        // "Saturday, 12 September 2026". The opening matters: "Check-in 12 Sep"
        // is a booking that mentions a date, not a heading that is one, and
        // treating it as a heading would start a new day in the middle of one.
        guard !isRow(line), amount(in: line) == nil else { return false }
        guard line.filter({ $0.isLetter }).count <= 32 else { return false }
        guard TravelDate.first(in: line, referenceDate: Date()) != nil else { return false }

        let opening = "monday|tuesday|wednesday|thursday|friday|saturday|sunday"
            + "|mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun"
            + "|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec"
        return line.range(
            of: "^(?:\\d{1,2}\\b|\\d{4}-|(?:\(opening)))",
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    // MARK: - Appendix

    private static let appendixHeadings = [
        "trip cost summary", "cost summary", "price summary", "summary of costs",
        "ledger-ready structure", "ledger ready structure",
        "terms and conditions", "terms & conditions", "cancellation policy",
        "payment schedule", "inclusions", "exclusions", "what's included",
        "important information", "booking conditions", "category"
    ]

    private static func splitAppendix(_ lines: [String]) -> (body: [String], appendix: [String]) {
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            guard appendixHeadings.contains(where: { lower.hasPrefix($0) }) else { continue }
            // Only a heading, not a sentence that happens to open with one.
            guard line.count <= 60 else { continue }
            return (Array(lines[..<index]), Array(lines[index...]))
        }
        return (lines, [])
    }

    // MARK: - Row cleaning

    private static func cleanRows(_ lines: [String]) -> [String] {
        // A day's total often gets extracted onto the end of its last row.
        // Left there it reads as a second price for that booking.
        let rows = lines
            .map {
                $0.replacingOccurrences(
                    of: "\\s*\\b(?:day\\s+)?(?:total|subtotal)\\s*[:\\-].*$",
                    with: "", options: [.regularExpression, .caseInsensitive]
                ).trimmingCharacters(in: .whitespaces)
            }
            .filter { !isFurniture($0) }

        // In a timetable every booking starts with a clock time, so anything
        // that doesn't is wrapped prose — the second line of a footnote, a
        // stray column header. Only applied when the day is clearly a table,
        // so free-form itineraries keep their untimed entries.
        let timed = rows.filter(isRow)
        guard timed.count >= 2, Double(timed.count) / Double(rows.count) >= 0.6 else { return rows }
        return timed
    }

    /// Column headers, day totals and the editorial asides a nicely-typeset
    /// itinerary is full of. Each one of these became a booking before.
    private static func isFurniture(_ line: String) -> Bool {
        let lower = line.lowercased()

        if lower.hasPrefix("day total") || lower.hasPrefix("total for") { return true }
        if lower.range(of: "^(sub)?total\\b", options: .regularExpression) != nil { return true }
        if lower.range(
            of: "^(note|notes|sharing example|prototype note|important|tip|disclaimer|please note)\\b\\s*:",
            options: .regularExpression
        ) != nil { return true }

        // "TIME ITEM DETAILS GROUP COST PARTICIPANTS" and its many variants.
        let headerWords = ["time", "item", "details", "description", "cost", "amount",
                           "participants", "pax", "activity", "price", "category", "payer",
                           "split model", "group cost"]
        let words = lower
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
        if words.count >= 3, !words.isEmpty,
           words.allSatisfy({ word in headerWords.contains(where: { $0.contains(word) }) }) {
            return true
        }

        // A bare amount with no subject. Real ones get spliced back onto their
        // row by `repairOrphanedAmounts`; whatever is left is a stray column.
        if isOrphanAmount(line) { return true }

        return line.filter { $0.isLetter || $0.isNumber }.count < 3
    }

    private static func isRow(_ line: String) -> Bool {
        line.range(of: "^\\d{1,2}:\\d{2}\\b", options: .regularExpression) != nil
    }

    // MARK: - Orphaned amounts

    private static func isOrphanAmount(_ line: String) -> Bool {
        line.range(
            of: "^(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}$",
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    /// A table whose cost column got extracted separately from its rows.
    ///
    /// This happens in real booking PDFs more often than it should: the text
    /// comes out as a block of rows with no prices, followed by a block of
    /// prices with no rows. They are always in the same order, so when the two
    /// counts agree the amounts can be put back where they came from. When they
    /// don't agree nothing is guessed — a wrong price is worse than a missing
    /// one, because it becomes somebody's share of the bill.
    private mutating func repairOrphanedAmounts() {
        var blocks = orphanAmountBlocks()
        guard !blocks.isEmpty else { return }

        for dayIndex in days.indices {
            let needing = days[dayIndex].lines.indices.filter {
                Self.amount(in: days[dayIndex].lines[$0]) == nil && Self.isRow(days[dayIndex].lines[$0])
            }
            guard needing.count >= 2,
                  let match = blocks.firstIndex(where: { $0.count == needing.count })
            else { continue }

            for (offset, lineIndex) in needing.enumerated() {
                days[dayIndex].lines[lineIndex] += " " + blocks[match][offset]
            }
            blocks.remove(at: match)
        }
    }

    /// Runs of consecutive amount-only lines, in document order.
    private func orphanAmountBlocks() -> [[String]] {
        var blocks: [[String]] = []
        var current: [String] = []

        for line in rawTail {
            if Self.isOrphanAmount(line) {
                current.append(line)
            } else if !current.isEmpty {
                blocks.append(current)
                current = []
            }
        }
        if !current.isEmpty { blocks.append(current) }

        return blocks.filter { $0.count >= 2 }
    }

    /// Every line the day sections were built from, before furniture was
    /// dropped — the orphaned amounts live here.
    private var rawTail: [String] = []

    // MARK: - Header facts

    private mutating func absorbHeaderFacts(referenceDate: Date) {
        let header = preamble.joined(separator: "\n")

        travellerCount = Self.travellerCount(in: header) ?? Self.participantColumnCount(in: days)
        namedTravellers = Self.explicitNames(in: preamble)
        currencyCode = Self.currency(in: header) ?? Self.currency(in: haystack)
        title = Self.labelled("trip|tour|package|itinerary name", in: preamble)
        destinationHint = Self.labelled("destination|route|going to", in: preamble)

        let dates = days.compactMap(\.date).sorted()
        startDate = dates.first ?? TravelDate.first(in: header, referenceDate: referenceDate)
        endDate = dates.last ?? startDate
    }

    /// "TRAVELLERS 4 people", "4 adults", "Pax: 6".
    static func travellerCount(in text: String) -> Int? {
        let patterns = [
            "(?:travell?ers?|passengers?|guests?|pax|party size|group size|adults?)\\s*[:\\-]?\\s*(\\d{1,2})\\b",
            "\\b(\\d{1,2})\\s*(?:people|persons?|adults?|travell?ers?|passengers?|guests?|pax)\\b"
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range),
                  let found = Range(match.range(at: 1), in: text),
                  let value = Int(text[found]), (1...30).contains(value) else { continue }
            return value
        }
        return nil
    }

    /// Falls back to the participants column: the number that ends most rows.
    private static func participantColumnCount(in days: [DaySection]) -> Int? {
        var tally: [Int: Int] = [:]
        for day in days {
            for line in day.lines {
                guard let match = line.range(of: "\\b(\\d{1,2})\\s*$", options: .regularExpression),
                      let value = Int(line[match].trimmingCharacters(in: .whitespaces)),
                      (1...30).contains(value) else { continue }
                tally[value, default: 0] += 1
            }
        }
        guard let best = tally.max(by: { $0.value < $1.value }), best.value >= 3 else { return nil }
        return best.key
    }

    /// Names only when the document writes them out. A list of names after
    /// "Passengers:" is a fact; a headcount is not a licence to invent four.
    private static func explicitNames(in lines: [String]) -> [String] {
        let labels = "passengers?|travell?ers?|guests?|names?|party|in the name of|lead passenger"
        var found: [String] = []

        for line in lines {
            guard line.range(of: "^(?:\(labels))\\s*[:\\-]", options: [.regularExpression, .caseInsensitive]) != nil
            else { continue }

            let tail = line.drop { $0 != ":" && $0 != "-" }.dropFirst()
            // A count where names should be means the document didn't name them.
            guard tail.rangeOfCharacter(from: .letters) != nil else { continue }

            for piece in tail.components(separatedBy: CharacterSet(charactersIn: ",/&+;")) {
                let name = piece
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: .punctuationCharacters)
                guard name.count >= 2, name.count <= 28,
                      name.first?.isUppercase == true,
                      name.rangeOfCharacter(from: .decimalDigits) == nil,
                      !found.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame })
                else { continue }
                found.append(name)
            }
        }
        return Array(found.prefix(12))
    }

    private static func labelled(_ labels: String, in lines: [String]) -> String? {
        for line in lines {
            guard let match = line.range(
                of: "^(?:\(labels))\\s*[:\\-]?\\s+",
                options: [.regularExpression, .caseInsensitive]
            ) else { continue }
            let value = line[match.upperBound...].trimmingCharacters(in: .whitespaces)
            guard value.count >= 3, value.count <= 60 else { continue }
            return value
        }
        return nil
    }

    static func currency(in text: String) -> String? {
        if text.contains("₹") || text.range(of: "\\binr\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "INR" }
        if text.contains("€") || text.range(of: "\\beur\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "EUR" }
        if text.contains("£") || text.range(of: "\\bgbp\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "GBP" }
        if text.contains("$") || text.range(of: "\\busd\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "USD" }
        if text.range(of: "\\baed\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "AED" }
        if text.range(of: "\\bthb\\b", options: [.regularExpression, .caseInsensitive]) != nil { return "THB" }
        return nil
    }

    static func amount(in line: String) -> Double? {
        guard let regex = try? NSRegularExpression(
            pattern: "(?:₹|rs\\.?|inr|\\$|usd|€|eur|£|gbp)\\s*([\\d,]+(?:\\.\\d{1,2})?)",
            options: .caseInsensitive
        ) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let found = Range(match.range(at: 1), in: line) else { return nil }
        return Double(line[found].replacingOccurrences(of: ",", with: ""))
    }

    // MARK: - Dates

    /// A day whose header never carried a date takes its place in the sequence.
    /// "DAY 4" with days 1 and 7 dated is not ambiguous.
    private mutating func inferMissingDates(referenceDate: Date) {
        guard days.contains(where: { $0.date == nil }) else { return }
        guard let anchorIndex = days.firstIndex(where: { $0.date != nil }),
              let anchor = days[anchorIndex].date else { return }

        for index in days.indices where days[index].date == nil {
            days[index].date = Calendar.current.date(
                byAdding: .day, value: index - anchorIndex, to: anchor
            )
        }
    }
}

// MARK: - Date reading

/// Dates as travel documents write them, which is every way at once.
enum TravelDate {

    private static let months = [
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12
    ]

    /// The first date in a line, or nil. A year that isn't written is taken
    /// from `referenceDate`, rolling forward — a booking dated "14 March" in
    /// December is next March, not one that already happened.
    static func first(in line: String, referenceDate: Date) -> Date? {
        for form in forms {
            guard let regex = try? NSRegularExpression(pattern: form.pattern, options: .caseInsensitive)
            else { continue }
            let range = NSRange(line.startIndex..., in: line)
            for match in regex.matches(in: line, range: range) {
                guard let parts = form.read(match, line) else { continue }
                if let date = make(parts, referenceDate: referenceDate) { return date }
            }
        }
        return nil
    }

    private struct Parts {
        var day: Int
        var month: Int
        var year: Int?
    }

    private struct Form {
        var pattern: String
        var read: (NSTextCheckingResult, String) -> Parts?
    }

    private static let forms: [Form] = [
        // 2026-09-12
        Form(pattern: "\\b(\\d{4})-(\\d{2})-(\\d{2})\\b") { match, text in
            guard let y = match.number(text, 1), let m = match.number(text, 2),
                  let d = match.number(text, 3) else { return nil }
            return Parts(day: d, month: m, year: y)
        },
        // 12 September 2026 / 12 Sep 2026 / 12th September 2026
        Form(pattern: "\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+([a-z]{3,9})\\.?,?\\s*(\\d{4})?\\b") { match, text in
            guard let d = match.number(text, 1), let name = match.string(text, 2),
                  let m = month(name) else { return nil }
            return Parts(day: d, month: m, year: match.number(text, 3))
        },
        // September 12, 2026 / Sep 12 2026
        Form(pattern: "\\b([a-z]{3,9})\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?,?\\s*(\\d{4})?\\b") { match, text in
            guard let name = match.string(text, 1), let m = month(name),
                  let d = match.number(text, 2) else { return nil }
            return Parts(day: d, month: m, year: match.number(text, 3))
        },
        // 12/09/2026 — day first, which is how everywhere but the US writes it.
        Form(pattern: "\\b(\\d{1,2})[/.](\\d{1,2})[/.](\\d{2,4})\\b") { match, text in
            guard let d = match.number(text, 1), let m = match.number(text, 2),
                  var y = match.number(text, 3) else { return nil }
            if y < 100 { y += 2000 }
            return Parts(day: d, month: m, year: y)
        }
    ]

    private static func month(_ name: String) -> Int? {
        months[String(name.prefix(3)).lowercased()]
    }

    private static func make(_ parts: Parts, referenceDate: Date) -> Date? {
        guard (1...31).contains(parts.day), (1...12).contains(parts.month) else { return nil }

        let calendar = Calendar.current
        var components = DateComponents()
        components.day = parts.day
        components.month = parts.month

        if let year = parts.year {
            guard (2000...2100).contains(year) else { return nil }
            components.year = year
            return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
        }

        // No year written. Take this year, and roll forward if that has already
        // been and gone by more than a couple of months.
        let thisYear = calendar.component(.year, from: referenceDate)
        components.year = thisYear
        guard let candidate = calendar.date(from: components) else { return nil }
        if candidate < calendar.date(byAdding: .month, value: -2, to: referenceDate)! {
            components.year = thisYear + 1
            return calendar.date(from: components).map { calendar.startOfDay(for: $0) }
        }
        return calendar.startOfDay(for: candidate)
    }

    /// "06:30", "6:30 PM", "1830 hrs".
    static func time(in line: String) -> (hour: Int, minute: Int)? {
        guard let regex = try? NSRegularExpression(
            pattern: "\\b(\\d{1,2})[:.](\\d{2})\\s*(am|pm)?\\b", options: .caseInsensitive
        ) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              var hour = match.number(line, 1), let minute = match.number(line, 2) else { return nil }

        if let meridiem = match.string(line, 3)?.lowercased() {
            if meridiem == "pm", hour < 12 { hour += 12 }
            if meridiem == "am", hour == 12 { hour = 0 }
        }
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        return (hour, minute)
    }
}

// MARK: - Regex helpers

extension NSTextCheckingResult {
    func string(_ source: String, _ index: Int) -> String? {
        guard index < numberOfRanges, let range = Range(range(at: index), in: source) else { return nil }
        return String(source[range])
    }

    func number(_ source: String, _ index: Int) -> Int? {
        string(source, index).flatMap { Int($0) }
    }
}
