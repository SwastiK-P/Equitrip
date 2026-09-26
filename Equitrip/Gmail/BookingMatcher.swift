//
//  BookingMatcher.swift
//  Equitrip
//

import Foundation

/// Which booking an email is about — or an honest "can't tell".
///
/// Deterministic, and deliberately so. Picking the wrong booking is the one
/// mistake this feature can't be forgiven for: moving the wrong flight, or
/// cancelling the hotel instead of the boat ride, changes what a whole group
/// believes about its trip. So every booking on every eligible trip is scored
/// against the email on evidence a person could check — the flight number,
/// the booking's name written out in the mail, the old time the mail says it
/// used to be at, the kind of thing it is, the passengers it names — and each
/// piece of evidence that counted is kept as a reason the card can show.
///
/// Passenger names mostly decide *which trip*. Two trips can carry the same
/// flight (the same group planning twice, or a solo copy of a group trip); the
/// one whose travellers the airline lists is the one it's writing about. When
/// the top two are still too close to call, the answer is `.ambiguous` and the
/// person picks — a guess that reads as certainty is worse than a question.
///
/// Works on plain values (`Booking`, `TripPeople`) rather than the app's
/// models, so it compiles into the test harness with Foundation alone.
enum BookingMatcher {

    struct Booking: Hashable {
        var tripID: UUID
        var itemID: UUID
        var title: String
        var vendor: String
        /// `ItineraryKind.rawValue`: flight, train, drive, stay, activity, meal, other.
        var category: String
        var day: Date
        /// Minutes past midnight, when the booking has a time.
        var minute: Int?
        var flightNumbers: Set<String>
    }

    struct TripPeople: Hashable {
        var tripID: UUID
        var names: [String]
    }

    struct Match: Hashable {
        var booking: Booking
        var score: Double
        var reasons: [String]
        var isStrong: Bool
    }

    enum Outcome: Equatable {
        case matched(Match, certain: Bool)
        /// Best first. Two or more, all plausible.
        case ambiguous([Match])
        case none
    }

    /// Below this nothing is claimed.
    static let threshold = 3.5
    /// The winner has to be clear of the runner-up by this much.
    static let margin = 1.0

    static func match(
        text raw: String,
        facts: BookingMailFacts,
        bookings: [Booking],
        trips: [TripPeople]
    ) -> Outcome {
        guard !bookings.isEmpty else { return .none }

        let text = searchable(raw)
        let words = Set(text.split(separator: " ").map(String.init))
        let weights = tokenWeights(bookings)

        let peopleScore: [UUID: (score: Double, named: [String])] = Dictionary(
            uniqueKeysWithValues: trips.map { trip in (trip.tripID, people(trip.names, in: text, words: words)) }
        )

        var scored: [Match] = bookings.map { booking in
            score(booking, text: text, words: words, facts: facts, weights: weights, people: peopleScore[booking.tripID])
        }
        scored.sort { $0.score > $1.score }

        guard let best = scored.first, best.score >= threshold, best.isStrong else { return .none }

        let close = scored.dropFirst().filter { $0.score >= threshold && best.score - $0.score < margin }
        if !close.isEmpty {
            return .ambiguous(Array(([best] + close).prefix(4)))
        }

        let runnerUp = scored.dropFirst().first?.score ?? 0
        let certain = best.score - runnerUp >= 2 && best.score >= 6
        return .matched(best, certain: certain)
    }

    // MARK: - Scoring

    private static func score(
        _ booking: Booking,
        text: String,
        words: Set<String>,
        facts: BookingMailFacts,
        weights: [String: Double],
        people: (score: Double, named: [String])?
    ) -> Match {
        var score = 0.0
        var reasons: [String] = []
        // Identity: something that names *this* booking rather than anything
        // on the trip. Time, kind and people only ever sharpen an identity;
        // on their own they'd match every 7 AM activity to a 7 AM email.
        var strong = false

        // Flight number — the one identifier that's unambiguous by design.
        let sharedFlights = booking.flightNumbers.intersection(facts.flightNumbers)
        if let flight = sharedFlights.first {
            score += 6
            strong = true
            reasons.append("Flight \(spaced(flight))")
        } else if !booking.flightNumbers.isEmpty, !facts.flightNumbers.isEmpty {
            // Both name a flight and they're different flights.
            score -= 4
        }

        // The booking's name, written out.
        let titleWords = significant(booking.title)
        let run = longestRun(of: orderedWords(booking.title), in: text)
        if run.count >= 2, run.contains(where: { !stopWords.contains($0) && $0.count >= 3 }) {
            score += min(4.5, 1.5 * Double(run.count))
            strong = true
            // "Flight 6E 5307" already said it.
            if sharedFlights.isEmpty { reasons.append("“\(run.joined(separator: " ").capitalized)”") }
        }

        let titleWeight = titleWords.reduce(0) { $0 + (weights[$1] ?? 1) }
        if titleWeight > 0 {
            let matched = titleWords.filter { words.contains($0) }
            let fraction = matched.reduce(0) { $0 + (weights[$1] ?? 1) } / titleWeight
            score += 3 * fraction
            if fraction >= 0.5, matched.contains(where: { $0.count >= 5 && (weights[$0] ?? 1) >= 1.2 }) { strong = true }
        }

        let detailWords = significant(booking.vendor).subtracting(titleWords)
        if !detailWords.isEmpty {
            let matched = detailWords.filter { words.contains($0) }
            score += Double(min(matched.count, 3)) * 0.4
        }

        // What kind of thing it is.
        if let category = facts.category {
            if category == booking.category || (category == "activity" && booking.category == "meal") {
                score += 1
            } else if booking.category != "other" {
                score -= 1.5
            }
        }

        // When the mail says it was.
        if let previous = facts.previousDay {
            if previous == booking.day { score += 1.5; reasons.append("Was on \(dayText(previous))") } else { score -= 1 }
        } else if facts.mentionedDays.contains(booking.day) {
            score += 1
            reasons.append(dayText(booking.day))
        }

        if let minute = booking.minute {
            if let previous = facts.previousMinute {
                if previous == minute { score += 2; reasons.append("Was \(BookingText.clock(minute))") } else { score -= 1 }
            } else if facts.mentionedMinutes.contains(minute) {
                score += 0.75
                if !facts.hasNewSchedule { reasons.append(BookingText.clock(minute)) }
            }
        }

        // Who's travelling.
        if let people, people.score > 0 {
            score += people.score
            reasons.append(people.named.count == 1 ? "\(people.named[0]) named" : "\(people.named.joined(separator: ", ")) named")
        }

        return Match(booking: booking, score: score, reasons: reasons, isStrong: strong)
    }

    /// Full names count for more than first names; a trip scores at most 3.6.
    private static func people(_ names: [String], in text: String, words: Set<String>) -> (score: Double, named: [String]) {
        var total = 0.0
        var named: [String] = []
        for name in names {
            let full = searchable(name)
            let parts = full.split(separator: " ").map(String.init)
            guard let first = parts.first, first.count >= 3, first != "you" else { continue }

            if parts.count >= 2, text.contains(" \(full) ") || text.hasPrefix("\(full) ") {
                total += 1.2
                named.append(String(name.split(separator: " ").first ?? ""))
            } else if words.contains(first) {
                total += 1
                named.append(String(name.split(separator: " ").first ?? ""))
            }
        }
        return (min(total, 3.6), named)
    }

    // MARK: - Words

    static let stopWords: Set<String> = [
        "the", "and", "for", "with", "from", "into", "via", "at", "to", "of", "on", "in", "a", "an", "by",
        "hotel", "check", "checkin", "checkout", "out", "stay", "booking", "room", "rooms", "night", "nights",
        "flight", "train", "tour", "trip", "day", "lunch", "dinner", "breakfast", "ride", "tickets", "ticket",
        "entry", "visit", "guide", "local", "private", "shared", "cab", "taxi", "transfer", "economy",
        "deluxe", "half", "full", "your", "our", "new", "old", "class", "seat", "seats"
    ]

    /// Lowercased, punctuation to spaces, padded so " word " finds whole words.
    static func searchable(_ raw: String) -> String {
        let lowered = BookingText.normalise(raw)
        let mapped = lowered.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        let collapsed = String(mapped).split(separator: " ").joined(separator: " ")
        return " \(collapsed) "
    }

    private static func orderedWords(_ raw: String) -> [String] {
        searchable(raw).split(separator: " ").map(String.init)
    }

    private static func significant(_ raw: String) -> Set<String> {
        Set(orderedWords(raw).filter { $0.count >= 3 && !stopWords.contains($0) && !$0.allSatisfy(\.isNumber) })
    }

    /// The longest run of the title's consecutive words that appears, as a
    /// run, in the mail. "Hotel Ganges View check-in" → "hotel ganges view".
    private static func longestRun(of words: [String], in text: String) -> [String] {
        var best: [String] = []
        guard !words.isEmpty else { return best }
        for start in words.indices {
            for end in stride(from: words.count, to: start, by: -1) where end - start > best.count {
                let run = Array(words[start..<end])
                if text.contains(" \(run.joined(separator: " ")) ") {
                    best = run
                    break
                }
            }
        }
        return best
    }

    /// Words that appear in every booking ("varanasi", "ghat") say little
    /// about which one; words in only one say a lot.
    private static func tokenWeights(_ bookings: [Booking]) -> [String: Double] {
        var frequency: [String: Int] = [:]
        for booking in bookings {
            for word in significant(booking.title + " " + booking.vendor) { frequency[word, default: 0] += 1 }
        }
        let count = Double(max(bookings.count, 1))
        return frequency.mapValues { 0.5 + log(1 + count / Double($0)) }
    }

    private static func spaced(_ flight: String) -> String {
        guard flight.count > 2 else { return flight }
        return "\(flight.prefix(2)) \(flight.dropFirst(2))"
    }

    private static func dayText(_ day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: day)
    }
}
