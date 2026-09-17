//
//  TravelDate.swift
//  Equitrip
//

import Foundation

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

    /// Every date in a line, in the order they appear, with where each one
    /// sits.
    ///
    /// `first(in:)` answers "what date is this line about"; this answers "which
    /// parts of this line are dates", which is a different question and the one
    /// a table row needs — a stay row carries a check-in and a check-out, and
    /// both have to come out of the text before what's left is a hotel's name.
    static func matches(in line: String, referenceDate: Date) -> [(date: Date, range: Range<String.Index>)] {
        var found: [(date: Date, range: Range<String.Index>)] = []

        for form in forms {
            guard let regex = try? NSRegularExpression(pattern: form.pattern, options: .caseInsensitive)
            else { continue }
            let full = NSRange(line.startIndex..., in: line)
            for match in regex.matches(in: line, range: full) {
                guard let range = Range(match.range, in: line),
                      let parts = form.read(match, line),
                      let date = make(parts, referenceDate: referenceDate) else { continue }
                found.append((date, range))
            }
        }

        // Two forms can read the same text. Earliest wins; overlaps are dropped.
        var kept: [(date: Date, range: Range<String.Index>)] = []
        for hit in found.sorted(by: { $0.range.lowerBound < $1.range.lowerBound }) {
            if let last = kept.last, hit.range.lowerBound < last.range.upperBound { continue }
            kept.append(hit)
        }
        return kept
    }

    /// "08:00", and "08:00–10:10" as one match rather than two — a row's time
    /// column is a span, and the second half of it is not a separate booking.
    static func clockMatches(in line: String) -> [(minute: Int, range: Range<String.Index>)] {
        let pattern = "\\b(\\d{1,2})[:.](\\d{2})\\s*(am|pm)?"
            + "(?:\\s*[–—-]\\s*\\d{1,2}[:.]\\d{2}\\s*(?:am|pm)?)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return [] }

        let full = NSRange(line.startIndex..., in: line)
        return regex.matches(in: line, range: full).compactMap { match in
            guard let range = Range(match.range, in: line),
                  var hour = match.number(line, 1),
                  let minute = match.number(line, 2) else { return nil }

            if let meridiem = match.string(line, 3)?.lowercased() {
                if meridiem == "pm", hour < 12 { hour += 12 }
                if meridiem == "am", hour == 12 { hour = 0 }
            }
            guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
            return (hour * 60 + minute, range)
        }
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
