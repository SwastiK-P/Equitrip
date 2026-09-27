//
//  EquiCommandReader.swift
//  Equitrip
//

import Foundation

/// Reads a message to Equi as a request to *do* something — "add ₹2,400 for
/// dinner", "settle up with Kim" — rather than a question to answer.
///
/// By rule, not by model, for the same reason `EquiFacts` answers in Swift:
/// the parts that matter here are an amount and a person, and a model that
/// reads "₹2,400" as 24,000 once in a hundred times files a wrong expense
/// against a real group. Every figure is copied from the words typed; a name
/// only counts if it's someone on the trip. Anything the words leave open is
/// asked mid-job (`EquiAgent.ask`) rather than guessed.
///
/// Questions stay questions: a message that opens like one ("how much…",
/// "should I settle…") is left to the normal answer path, even if it names a
/// verb this reads.
enum EquiCommandReader {

    enum Reading {
        /// Something Equi can go and do.
        case task(EquiAgentTask)
        /// Clearly a request, but not one that can be done — said why.
        case reply(String)
    }

    struct ExpenseRequest {
        var amount: Double?
        var title: String
        var trip: Trip?
        /// Nil when the words don't say; "me" is `Traveller.you`.
        var payerName: String?
        var payerIsYou: Bool
        /// "split with Kim and Ed" — nil means everyone.
        var sharedWith: [String]?
    }

    struct SettleRequest {
        var personName: String?
        var trip: Trip?
        var amount: Double?
        var method: PaymentMethod?
    }

    static func read(_ text: String, store: TripStore) -> Reading? {
        let folded = fold(text)
        guard !folded.isEmpty, !isQuestion(folded) else { return nil }

        if let request = readSettle(text, folded: folded, trips: store.trips) {
            return EquiAgentJobs.settleUp(request, store: store)
        }
        if let request = readExpense(text, folded: folded, trips: store.trips) {
            return EquiAgentJobs.logExpense(request, store: store)
        }
        return nil
    }

    // MARK: - Expense

    private static let expenseVerbs = #/\b(add|log|record|put|note|track|paid|spent|bought|covered)\b/#

    static func readExpense(_ text: String, folded: String, trips: [Trip]) -> ExpenseRequest? {
        guard folded.contains(expenseVerbs) else { return nil }
        let amount = amount(in: folded)
        // "Add a booking" with no figure is a different job; only an amount,
        // or the words of paying, make this an expense.
        guard amount != nil || folded.contains(#/\b(paid|spent)\b/#) else { return nil }

        let trip = mentionedTrip(in: folded, trips: trips)
        let stripped = removingTripMention(from: folded, trip: trip)

        var payerName: String?
        var payerIsYou = false
        if stripped.contains(#/\b(i|i've|ive|me)\s+(paid|spent|covered|bought)\b|\bpaid by me\b|\bon me\b/#) {
            payerIsYou = true
        } else if let match = stripped.firstMatch(of: #/\bpaid by ([a-z]+)\b/#) {
            payerName = String(match.output.1)
        } else if let match = stripped.firstMatch(of: #/\b([a-z]+) (paid|covered|bought|spent)\b/#),
                  !["we", "they", "you", "i", "who", "just", "was", "been", "have", "has"].contains(String(match.output.1)) {
            payerName = String(match.output.1)
        }

        var sharedWith: [String]?
        if let match = stripped.firstMatch(of: #/\b(?:split|shared?|divided?)\s+(?:it\s+)?(?:with|between|among)\s+(.+?)(?:[.!?]|$)/#)
            ?? stripped.firstMatch(of: #/\bwith\s+(.+?)(?:[.!?]|$)/#) {
            let names = String(match.output.1)
                .replacingOccurrences(of: " and ", with: ",")
                .replacingOccurrences(of: "&", with: ",")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !["me", "everyone", "everybody", "all", "the group", "us"].contains($0) }
            if !names.isEmpty { sharedWith = names }
        }

        return ExpenseRequest(
            amount: amount,
            title: title(in: text, folded: stripped),
            trip: trip,
            payerName: payerName,
            payerIsYou: payerIsYou,
            sharedWith: sharedWith
        )
    }

    /// What it was: the words after "for" or "on", up to the next part of the
    /// sentence. Cased as typed — "Dinner at Thalassa" keeps its capital T.
    static func title(in original: String, folded: String) -> String {
        let pattern = #/\b(?:for|on)\s+(?:a\s+|an\s+|the\s+|some\s+)?(.+?)(?=\s+(?:paid|split|shared|between|with|via|using|by|and\s+[a-z]+\s+paid)\b|[,.!?]|$)/#
        guard let match = folded.firstMatch(of: pattern) else { return "Expense" }
        var phrase = String(match.output.1)
        // An amount that slipped in ("for 500 snacks") isn't part of the name.
        phrase = phrase.replacing(#/(?:₹|rs\.?|inr|\$|€|£)?\s?\d[\d,]*(?:\.\d+)?k?\s*/#, with: "")
            .trimmingCharacters(in: .whitespaces)
        guard phrase.count >= 2 else { return "Expense" }

        // Recover the casing from what was typed.
        if let range = original.range(of: phrase, options: [.caseInsensitive, .diacriticInsensitive]) {
            phrase = String(original[range])
        }
        return phrase.prefix(1).uppercased() + phrase.dropFirst()
    }

    // MARK: - Settle

    private static let settleVerbs = #/\b(settle|settled|square up|squared up|pay back|paid back|pay (?:[a-z]+ )?back|paid (?:[a-z]+ )?back|repay|repaid|clear up|mark (?:that )?i(?:'ve| have)? paid)\b/#

    static func readSettle(_ text: String, folded: String, trips: [Trip]) -> SettleRequest? {
        // "Settle everyone up" is a question about the whole group, which the
        // answer path already handles; this does one transfer at a time.
        guard !folded.contains(#/\b(everyone|everybody|all of us|the group)\b/#) else { return nil }

        let trip = mentionedTrip(in: folded, trips: trips)
        let stripped = removingTripMention(from: folded, trip: trip)

        var personName: String?
        let people = (trip.map { [$0] } ?? trips).flatMap(\.travellers).filter { $0.id != Traveller.you.id }
        let words = Set(stripped.split { !$0.isLetter }.map(String.init))
        for person in people {
            let first = fold(person.name).split(separator: " ").first.map(String.init) ?? ""
            if first.count >= 2, words.contains(first) {
                personName = person.name
                break
            }
        }

        // "I paid Kim 500" is a settlement, not an expense called "Kim" —
        // but only when the word after "paid" is someone on a trip.
        let paidSomeone = personName.map { name in
            let first = fold(name).split(separator: " ").first.map(String.init) ?? ""
            return stripped.contains(try! Regex("\\bi(?:'ve| have)? (?:paid|sent|gave|transferred) \(NSRegularExpression.escapedPattern(for: first))\\b"))
        } ?? false
        guard folded.contains(settleVerbs) || paidSomeone else { return nil }

        return SettleRequest(
            personName: personName,
            trip: trip,
            amount: amount(in: stripped),
            method: method(in: stripped)
        )
    }

    static func method(in folded: String) -> PaymentMethod? {
        if folded.contains(#/\b(upi|gpay|google pay|phonepe|phone pe|paytm|bhim)\b/#) { return .upi }
        if folded.contains(#/\bcash\b/#) { return .cash }
        if folded.contains(#/\b(bank|transfer|neft|imps|rtgs)\b/#) { return .transfer }
        return nil
    }

    // MARK: - Shared

    /// The first amount in the words: a currency mark wins, else the first bare
    /// number that isn't a clock time. "2.4k" is 2,400.
    static func amount(in folded: String) -> Double? {
        let pattern = #/(₹|rs\.?\s?|inr\s?|\$|€|£)?\s?(\d{1,3}(?:,\d{2,3})+|\d+)(\.\d{1,2})?\s?(k\b)?(\s?(?:am|pm)\b|:\d)?/#
        var bare: Double?
        for match in folded.matches(of: pattern) {
            guard match.output.5 == nil else { continue }
            let digits = String(match.output.2).replacingOccurrences(of: ",", with: "") + String(match.output.3 ?? "")
            guard var value = Double(digits), value > 0 else { continue }
            if match.output.4 != nil { value *= 1000 }
            if match.output.1 != nil { return value }
            if bare == nil { bare = value }
        }
        return bare
    }

    /// The trip the words name, by a word of its title or destination.
    static func mentionedTrip(in folded: String, trips: [Trip]) -> Trip? {
        let words = Set(folded.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        let scored = trips.map { trip -> (Trip, Int) in
            let names = Set((fold(trip.title) + " " + fold(trip.destination)).split { !$0.isLetter }.map(String.init))
                .filter { $0.count >= 3 && !tripFiller.contains($0) }
            return (trip, names.intersection(words).count)
        }
        .filter { $0.1 > 0 }
        return scored.max { lhs, rhs in
            lhs.1 != rhs.1 ? lhs.1 < rhs.1 : TripMatcher.byRelevance([lhs.0, rhs.0]).first?.id == rhs.0.id
        }?.0
    }

    /// Drops "to the Goa trip" / "on Goa" so the trip's name doesn't end up in
    /// the expense's.
    private static func removingTripMention(from folded: String, trip: Trip?) -> String {
        guard let trip else { return folded }
        var text = folded
        let names = (fold(trip.title) + " " + fold(trip.destination)).split { !$0.isLetter }.map(String.init)
            .filter { $0.count >= 3 && !tripFiller.contains($0) }
        for name in Set(names) {
            text = text.replacing(
                try! Regex("\\s*\\b(?:to|on|in|for|from|at)?\\s*(?:the|my|our)?\\s*\(NSRegularExpression.escapedPattern(for: name))\\b(?:\\s+(?:trip|holiday|vacation))?"),
                with: ""
            )
        }
        return text.trimmingCharacters(in: .whitespaces)
    }

    private static let tripFiller: Set<String> = ["the", "trip", "trips", "holiday", "vacation", "and", "with", "for", "weekend", "getaway"]

    private static func isQuestion(_ folded: String) -> Bool {
        let first = folded.split(separator: " ").first.map(String.init) ?? ""
        return ["who", "what", "whats", "what's", "when", "where", "why", "how", "which", "should", "do", "does",
                "did", "is", "am", "are", "was", "were", "will", "would", "have", "has"].contains(first)
    }

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
