//
//  ExpenseMailGate.swift
//  Equitrip
//

import Foundation

/// What the on-device model is allowed to be asked about.
///
/// The model is the expensive stage and the only one that can be wrong in an
/// interesting way, so everything that can be decided without it is decided
/// here. Three kinds of mail get thrown out before a single token is
/// generated: mail Gmail has already filed as marketing, mail with no money in
/// it at all, and mail whose money is unmistakably going the other way.
///
/// Every rejection carries its reason. Not for the user — this never reaches a
/// screen — but because "why didn't my dinner show up" is otherwise
/// unanswerable, and a filter you can't interrogate is a filter you end up
/// deleting.
enum ExpenseMailGate {

    enum Verdict: Equatable {
        case worthReading
        case rejected(String)

        var passed: Bool { self == .worthReading }
    }

    /// Gmail's own classifications that a debit alert is never in.
    private static let excludedLabels: Set<String> = [
        "CATEGORY_PROMOTIONS", "CATEGORY_SOCIAL", "CATEGORY_FORUMS", "SPAM", "TRASH", "DRAFT"
    ]

    /// Nothing has happened yet, or nothing happened at all.
    private static let notYetWords = [
        "will be debited", "will be charged", "is due", "due on", "payment reminder",
        "auto-pay", "autopay", "mandate", "e-mandate", "scheduled for",
        "failed", "declined", "unsuccessful", "could not be processed", "reversed",
        "otp", "one time password", "one-time password", "verification code",
        "account statement", "e-statement", "monthly summary", "your bill"
    ]

    /// Marketing that made it past Gmail's own filing.
    private static let promotionWords = [
        "offer", "% off", "flat ", "coupon", "sale ends", "limited time",
        "unsubscribe from", "shop now", "explore now", "win ", "lucky draw",
        "pre-approved", "loan offer", "credit card offer", "upgrade your"
    ]

    static func check(_ message: MailMessage) -> Verdict {
        if let label = message.labelIDs.first(where: excludedLabels.contains) {
            return .rejected("Gmail filed it under \(label.replacingOccurrences(of: "CATEGORY_", with: "").lowercased())")
        }

        let text = message.readableText.lowercased()

        guard !AmountScanner.candidates(in: message.readableText).isEmpty else {
            return .rejected("No amount anywhere in the message")
        }

        if let word = notYetWords.first(where: text.contains) {
            return .rejected("Reads as '\(word)' — nothing has been paid")
        }

        // Which way the money went, decided by what the email says *next to
        // the amount* rather than by which words appear in it anywhere. This
        // used to be two keyword lists, and a credit alert whose body happened
        // to contain the heading "Transaction Details" was read as a payment,
        // because the word "transaction" is in the debit list and its presence
        // cancelled the credit check. Proximity settles it: the phrase nearest
        // the figure is the phrase describing the figure.
        switch MoneyDirection.of(message.readableText) {
        case .incoming:
            return .rejected("The amount is described as money coming in")
        case .outgoing:
            break
        case .unclear:
            // Nothing near the amount names a direction. Fall back to the old
            // question — does anything at all say money left — which is weak
            // but only ever reached by mail that says neither clearly.
            guard MoneyDirection.outgoingPhrases.contains(where: text.contains) else {
                return .rejected("Nothing in it says which way the money went")
            }
        }

        // Promotional language *and* no transaction reference is the signature
        // of a marketing mail dressed up with a number in it. A real alert
        // nearly always carries a reference; a real alert that also happens to
        // say "offer" still carries one.
        if promotionWords.contains(where: text.contains), AmountScanner.reference(in: message.readableText) == nil {
            return .rejected("Reads as marketing and has no transaction reference")
        }

        return .worthReading
    }
}

// MARK: - Amounts

/// Finding money in text, deterministically.
///
/// This exists twice over: once as the gate's cheap "is there any money here",
/// and once as the check the model's answer is held against. The second is the
/// important one — a model that copies an amount correctly and a regex that
/// finds the same amount are two independent readings of the same sentence,
/// and an expense is only trusted when they agree.
enum AmountScanner {

    struct Candidate: Hashable {
        let value: Double
        /// The literal text it was written as, for showing provenance.
        let literal: String
        /// Currency the symbol implied, when it implied one.
        let currencyCode: String?
    }

    private static let pattern = #"(?:(₹|rs\.?|inr|\$|usd|€|eur|£|gbp)\s*)([0-9][0-9,]*(?:\.[0-9]{1,2})?)|([0-9][0-9,]*(?:\.[0-9]{1,2})?)\s*(₹|rs\.?|inr|\$|usd|€|eur|£|gbp)\b"#

    static func candidates(in text: String) -> [Candidate] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let range = NSRange(text.startIndex..., in: text)

        var found: [Candidate] = []
        for match in regex.matches(in: text, range: range) {
            let symbol = group(match, 1, in: text) ?? group(match, 4, in: text)
            guard let digits = group(match, 2, in: text) ?? group(match, 3, in: text) else { continue }
            guard let value = Double(digits.replacingOccurrences(of: ",", with: "")), value > 0 else { continue }

            found.append(
                Candidate(value: value, literal: digits, currencyCode: symbol.flatMap { code(for: $0) })
            )
        }
        return found
    }

    /// Where in the text each amount sits, as UTF-16 offsets. `MoneyDirection`
    /// measures against these.
    static func offsets(in text: String) -> [Int] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        return regex
            .matches(in: text, range: NSRange(text.startIndex..., in: text))
            .map { $0.range.location }
    }

    /// Whether a number the model reported is one the text actually contains.
    /// Compared numerically rather than as a string: a model that answers
    /// "480.00" for a mail that says "480" has copied, not invented.
    static func contains(_ value: Double, in text: String) -> Bool {
        candidates(in: text).contains { abs($0.value - value) < 0.005 }
            || looseNumbers(in: text).contains { abs($0 - value) < 0.005 }
    }

    /// Every number in the text, symbol or not. Used only for the containment
    /// check — some banks write "Amount: 480.00" with the currency in a
    /// heading three lines up.
    private static func looseNumbers(in text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: #"[0-9][0-9,]*(?:\.[0-9]{1,2})?"#) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { group($0, 0, in: text) }
            .compactMap { Double($0.replacingOccurrences(of: ",", with: "")) }
    }

    /// The transaction reference, when the mail carries one.
    ///
    /// Every bank labels this differently and most of them stack the labels:
    /// "UPI transaction reference no.: 194910141438" carries four label words
    /// before the number. An earlier pattern here matched the label and
    /// captured the *word* "reference" as the reference — so the rule is now
    /// that the label can be anything up to the punctuation, and the captured
    /// token has to look like an identifier rather than a word.
    static func reference(in text: String) -> String? {
        // The lookahead is load-bearing. Without it the engine matches the
        // label, captures the next word, and — when that word is rejected as
        // not-a-reference — moves past the whole thing instead of trying a
        // longer label. On "UPI transaction reference no.: 194910141438" that
        // meant giving up here and matching "SMS 'BLOCK UPI' to 7308080808"
        // further down: the app reported a helpline number as the reference.
        // Requiring four digits *inside* the pattern makes it backtrack
        // through the label words until it reaches the actual number.
        let fourDigits = #"(?=[A-Za-z0-9]*\d[A-Za-z0-9]*\d[A-Za-z0-9]*\d[A-Za-z0-9]*\d)"#
        let patterns = [
            #"(?:upi|utr|rrn)\b[^\n:]{0,34}?[:\-\s]\s*"# + fourDigits + #"([A-Za-z0-9]{6,25})\b"#,
            #"(?:transaction|txn|ref(?:erence)?)\b[^\n:]{0,34}?[:\-\s]\s*"# + fourDigits + #"([A-Za-z0-9]{6,25})\b"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                guard let value = group(match, 1, in: text), looksLikeReference(value) else { continue }
                return value
            }
        }
        return nil
    }

    /// Mostly digits, and long enough to identify something. A UPI reference
    /// is twelve digits; card and net-banking ones mix in letters but never
    /// read as English.
    private static func looksLikeReference(_ token: String) -> Bool {
        token.count >= 6 && token.filter(\.isNumber).count >= 4
    }

    static func code(for symbol: String) -> String? {
        switch symbol.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: " .")) {
        case "₹", "rs", "inr": "INR"
        case "$", "usd": "USD"
        case "€", "eur": "EUR"
        case "£", "gbp": "GBP"
        default: nil
        }
    }

    private static func group(_ match: NSTextCheckingResult, _ index: Int, in text: String) -> String? {
        guard index < match.numberOfRanges,
              let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }
}


// MARK: - Direction

/// Which way the money went, according to the sentence the amount is in.
///
/// This is the one judgement that has to be right every time, and it is the
/// one a keyword list is worst at — because every bank writes both directions
/// with the same vocabulary. "Rs.90.00 has been successfully credited to your
/// account" and "Rs.350.00 is debited from your account" share the words
/// *transaction*, *UPI*, *reference*, *account* and *Rs*; they differ in one
/// verb, and that verb is next to the number.
///
/// So the rule is proximity, not presence. For each amount in the email, find
/// the nearest phrase that names a direction and let it vote. A phrase forty
/// characters from the figure is describing the figure; a heading two hundred
/// characters away is describing the email. This works the same for HDFC, SBI,
/// ICICI, Axis, a card issuer or a wallet, because none of them put "credited
/// to your account" next to a number that was debited.
enum MoneyDirection {
    case outgoing
    case incoming
    case unclear

    /// Money leaving. Deliberately includes the awkward middles — "trf to",
    /// "towards vpa" — that Indian bank templates use in place of a verb.
    static let outgoingPhrases = [
        "debited from", "is debited", "has been debited", "was debited",
        "debited towards", "debited for", "debited with", "debit of",
        "paid to", "you have paid", "you paid", "payment of", "payment to",
        "sent to", "transferred to", "trf to", "towards vpa", "to vpa",
        "spent at", "spent on", "spent using", "withdrawn from", "withdrawal of",
        "charged to", "charged on", "purchase at", "purchase of", "made a payment"
    ]

    /// Money arriving. `sender:` earns its place: an alert that names a
    /// *sender* is describing somebody paying you, whatever else it says.
    static let incomingPhrases = [
        "credited to", "is credited", "has been credited", "was credited",
        "credited with", "credit of", "received from", "money received",
        "you have received", "amount received", "deposited to", "deposited in",
        "refund of", "refunded to", "reversal of", "cashback of",
        "trf from", "transferred from", "sender:", "from vpa"
    ]

    static func of(_ raw: String) -> MoneyDirection {
        let text = raw.lowercased() as NSString
        let outgoing = offsets(of: outgoingPhrases, in: text)
        let incoming = offsets(of: incomingPhrases, in: text)

        guard !outgoing.isEmpty || !incoming.isEmpty else { return .unclear }

        let amounts = AmountScanner.offsets(in: raw)
        guard !amounts.isEmpty else {
            // No figure to sit next to. Fall back to counting, which is what
            // the whole email is then reduced to.
            if outgoing.count == incoming.count { return .unclear }
            return outgoing.count > incoming.count ? .outgoing : .incoming
        }

        var out = 0
        var incom = 0
        for amount in amounts {
            let toOutgoing = outgoing.map { abs($0 - amount) }.min() ?? Int.max
            let toIncoming = incoming.map { abs($0 - amount) }.min() ?? Int.max
            if toOutgoing == toIncoming { continue }
            if toOutgoing < toIncoming { out += 1 } else { incom += 1 }
        }

        if out == incom { return .unclear }
        return out > incom ? .outgoing : .incoming
    }

    private static func offsets(of phrases: [String], in text: NSString) -> [Int] {
        var found: [Int] = []
        for phrase in phrases {
            var searchFrom = 0
            while searchFrom < text.length {
                let range = text.range(
                    of: phrase,
                    options: [],
                    range: NSRange(location: searchFrom, length: text.length - searchFrom)
                )
                guard range.location != NSNotFound else { break }
                found.append(range.location)
                searchFrom = range.location + max(1, range.length)
            }
        }
        return found
    }
}
