//
//  BookingMailFacts.swift
//  Equitrip
//

import Foundation

// MARK: - Gate

/// Whether an email says a booking was cancelled or changed, decided before
/// anything is asked to read it for detail.
///
/// The hard part is not finding the word "cancel" — every booking confirmation
/// ever sent contains it, in "free cancellation until 25 Sep" and "to cancel
/// your booking, click here". So cancellation is recognised by *status*
/// phrases ("has been cancelled", "cancellation confirmed"), and the
/// conditional and policy sentences are masked out before those are looked
/// for. "If your flight is cancelled, you'll be offered a refund" contains
/// "is cancelled"; it is also boilerplate at the foot of a reschedule notice,
/// and reading it as a cancellation would take a flight off the plan that is
/// still flying.
enum BookingMailGate {

    enum Verdict: Equatable {
        case cancellation
        case change
        case rejected(String)

        var passed: Bool { if case .rejected = self { false } else { true } }
    }

    private static let excludedLabels: Set<String> = [
        "CATEGORY_PROMOTIONS", "CATEGORY_SOCIAL", "CATEGORY_FORUMS", "SPAM", "TRASH", "DRAFT"
    ]

    /// Sentences that talk about cancelling without anything having been
    /// cancelled. Removed from the text before status phrases are looked for.
    private static let hypotheticals = [
        #"\b(?:if|in case|should you|you can|you may|free|to cancel|wish to|want to|option to|allowed to|how to|unless)\b[^.\n]{0,40}?\bcancel\w*"#,
        #"\bcancel\w*\s+(?:policy|policies|charges apply|fee applies|window|is free|until|before|anytime|allowed|permitted|protection|insurance)"#,
        #"\bnon[- ]?cancell?able\b"#,
        #"\b(?:modification|amendment|date change|change|reschedul\w*)\s+(?:fee|fees|charge|charges|policy|policies|allowed|permitted|is free|window)"#,
        #"\b(?:cancell?ation|modification|change)\s*(?:/|or|and|&)\s*(?:cancell?ation|modification|change|refund|reschedul\w*)\b"#,
        #"\b(?:to|can|may|wish to|want to|option to|how to|free)\s+(?:modify|change|reschedule|amend)\b[^.\n]{0,40}"#
    ]

    /// Something *was* cancelled.
    static let cancellationPhrases = [
        "has been cancelled", "has been canceled", "have been cancelled", "have been canceled",
        "is cancelled", "is canceled", "was cancelled", "was canceled", "been cancelled", "been canceled",
        "stands cancelled", "now cancelled",
        "cancellation confirmed", "cancellation confirmation", "cancellation successful",
        "cancellation is confirmed", "cancellation request has been processed",
        "successfully cancelled", "cancelled successfully", "successfully canceled",
        "booking cancelled", "booking canceled", "reservation cancelled", "reservation canceled",
        "flight cancelled", "flight canceled", "ticket cancelled", "ticket canceled",
        "tour cancelled", "tour canceled", "trip cancelled", "event cancelled",
        "we have cancelled", "we've cancelled", "has been called off",
        "your cancellation", "cancellation of your"
    ]

    /// Something about it moved.
    static let changePhrases = [
        "rescheduled", "re-scheduled", "schedule change", "schedule has changed", "schedule has been changed",
        "time change", "timing change", "change in timing", "change in schedule", "change in your flight",
        "revised schedule", "revised timing", "revised departure", "revised itinerary", "revised booking",
        "new departure time", "new timing", "new time", "new schedule", "new date",
        "retimed", "has been moved", "been moved to", "preponed", "postponed", "delayed to",
        "departure time has changed", "will now depart", "now departs", "now depart",
        "modified", "modification", "amended", "amendment",
        "booking updated", "updated booking", "booking has been updated", "reservation has been updated",
        "has been updated", "has been changed", "have been changed", "changes to your booking",
        "change to your booking", "date change", "date has been changed", "updated itinerary"
    ]

    /// Mail that is never about a booking changing, however it's worded.
    private static let neverWords = [
        "otp", "one time password", "one-time password", "verification code"
    ]

    private static let promotionWords = [
        "% off", "coupon", "sale ends", "limited time", "shop now", "book now and save",
        "explore now", "lucky draw", "unsubscribe from"
    ]

    static func check(_ message: MailMessage) -> Verdict {
        if let label = message.labelIDs.first(where: excludedLabels.contains) {
            return .rejected("Gmail filed it under \(label.replacingOccurrences(of: "CATEGORY_", with: "").lowercased())")
        }

        let text = BookingText.normalise(message.readableText)

        if let word = neverWords.first(where: { BookingText.containsWord($0, in: text) }) {
            return .rejected("Reads as '\(word)' — not a booking")
        }

        if promotionWords.contains(where: text.contains),
           BookingText.reference(in: message.readableText) == nil,
           BookingText.flightNumbers(in: message.readableText).isEmpty {
            return .rejected("Reads as marketing and names no booking")
        }

        // Read before masking: "to cancel" is otherwise the start of an
        // instruction, and here it's the operator saying they did.
        if ["we had to cancel", "we have had to cancel", "had to be cancelled"].contains(where: text.contains) {
            return .cancellation
        }

        let masked = masking(text)
        if cancellationPhrases.contains(where: masked.contains) { return .cancellation }
        if changePhrases.contains(where: masked.contains) { return .change }
        return .rejected("Nothing in it says a booking was cancelled or changed")
    }

    static func masking(_ lowercased: String) -> String {
        var text = lowercased
        for pattern in hypotheticals {
            text = text.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        return text
    }
}

// MARK: - Facts

/// What a booking email says, read by rule: which booking (flight numbers, a
/// reference), what it was, what it is now, and any money named alongside.
///
/// Every value here is text the email contains — a date, a clock time, an
/// amount with a currency — sorted by the words written next to it. Which of
/// two times is the old one is the whole problem, and it's answered the way a
/// person reads it: "from 07:05 to 09:40", "Revised: 09:40", "earlier 07:05",
/// a "New schedule" heading over the lines beneath it. A value nothing labels
/// is kept separately as *stated* and only used when the email gives nothing
/// better — a hotel's "your booking has been modified — check-in 29 Sep" has
/// no "new" anywhere, and still says what the booking now is.
struct BookingMailFacts: Hashable {
    var isCancellation = false
    /// Normalised: "6E5307".
    var flightNumbers: Set<String> = []
    /// PNR, booking id or confirmation number, when the mail gives one.
    var reference: String?
    /// flight, train, stay, activity or drive, when the vocabulary is clear.
    var category: String?

    var previousDay: Date?
    var previousMinute: Int?
    var newDay: Date?
    var newMinute: Int?
    /// The booking's own moment — check-in, departure — when nothing marks it old or new.
    var statedDay: Date?
    var statedMinute: Int?
    /// Every day and clock time anywhere in the mail. Matching only: a
    /// cancellation that names "28 Sep, 07:05" is naming the booking.
    var mentionedDays: Set<Date> = []
    var mentionedMinutes: Set<Int> = []

    /// A total the mail calls new, revised or updated.
    var revisedTotal: Double?
    /// A total with no such word — "Total amount: ₹58,500".
    var statedTotal: Double?
    var refund: Double?
    var cancellationCharge: Double?
    var currencyCode: String?

    var hasNewSchedule: Bool { newDay != nil || newMinute != nil }

    static func read(_ raw: String, isCancellation: Bool, referenceDate: Date) -> BookingMailFacts {
        var facts = BookingMailFacts()
        facts.isCancellation = isCancellation
        facts.flightNumbers = BookingText.flightNumbers(in: raw)
        facts.reference = BookingText.reference(in: raw)
        facts.category = BookingText.category(of: BookingText.normalise(raw), hasFlightNumber: !facts.flightNumbers.isEmpty)

        let lines = raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var carried: Role?
        var carriedFor = 0
        var previousLabel: String?

        for line in lines {
            let lower = BookingText.normalise(line)
            if lower.isEmpty {
                continue
            }

            let values = ScheduleValue.all(in: line, referenceDate: referenceDate)
            let amounts = AmountScanner.located(in: line)

            for value in values {
                switch value.kind {
                case .day(let day): facts.mentionedDays.insert(day)
                case .minute(let minute): facts.mentionedMinutes.insert(minute)
                }
            }

            // A line that labels without holding values — "New schedule",
            // "Your original booking" — speaks for the few lines under it.
            let lineRole = Role.headed(lower)
            if values.isEmpty, amounts.isEmpty, let lineRole {
                carried = lineRole
                carriedFor = 6
                previousLabel = lower
                continue
            }

            if !isNoise(lower), !values.isEmpty {
                let roles = Role.assign(values, in: line, lower: lower)
                let isSecondary = isSecondaryMoment(lower)

                for (value, role) in zip(values, roles) {
                    let resolved = role ?? (carriedFor > 0 ? carried : nil)
                    switch (resolved, value.kind) {
                    case (.old, .day(let day)): if facts.previousDay == nil { facts.previousDay = day }
                    case (.old, .minute(let minute)): if facts.previousMinute == nil { facts.previousMinute = minute }
                    case (.new, .day(let day)): if facts.newDay == nil, !isSecondary { facts.newDay = day }
                    case (.new, .minute(let minute)): if facts.newMinute == nil, !isSecondary { facts.newMinute = minute }
                    case (nil, .day(let day)):
                        if facts.statedDay == nil, isPrimaryMoment(lower), !isSecondary { facts.statedDay = day }
                    case (nil, .minute(let minute)):
                        if facts.statedMinute == nil, isPrimaryMoment(lower), !isSecondary { facts.statedMinute = minute }
                    }
                }
            }

            if !amounts.isEmpty {
                read(amounts, in: line, labelAbove: previousLabel, into: &facts)
            }

            if carriedFor > 0 { carriedFor -= 1 }
            previousLabel = amounts.isEmpty && values.isEmpty ? lower : nil
        }

        return facts
    }

    // MARK: Lines

    /// Dates on these lines describe the email, not the booking.
    private static func isNoise(_ line: String) -> Bool {
        ["booked on", "booking date", "date of booking", "issued on", "issue date", "transaction date",
         "payment date", "paid on", "sent on", "generated on", "refund will", "within 7", "working days",
         "business days", "valid till", "valid until", "expires on"]
            .contains(where: line.contains)
    }

    /// The moment the booking is *at*: where a stated date or time counts.
    private static func isPrimaryMoment(_ line: String) -> Bool {
        ["check-in", "check in", "checkin", "departure", "departs", "depart", "departing", "date",
         "pickup", "pick-up", "pick up", "reporting", "start", "starts", "time", "journey", "travel on",
         "scheduled", "slot", "show time", "tour on", "on "]
            .contains(where: line.contains)
    }

    /// A check-out or an arrival on a line of its own is the booking's other
    /// end, never the moment it's filed under.
    private static func isSecondaryMoment(_ line: String) -> Bool {
        let secondary = ["check-out", "check out", "checkout", "arrival", "arrives", "arrive", "arriving", "drop"]
        guard secondary.contains(where: line.contains) else { return false }
        return !["check-in", "check in", "checkin", "depart"].contains(where: line.contains)
    }

    // MARK: Money

    private enum AmountRole { case refund, charge, revised, stated, ignored }

    /// Label phrases for amounts. Order within a role doesn't matter; which
    /// label is *first* in the text before the figure does — "Refund amount
    /// (after deducting cancellation charges): ₹48,600" is a refund.
    private static let amountLabels: [(String, AmountRole)] = [
        ("non-refundable", .charge), ("non refundable", .charge),
        ("cancellation charge", .charge), ("cancellation fee", .charge), ("cancellation penalty", .charge),
        ("penalty", .charge), ("deduction", .charge), ("deducted", .charge), ("retained", .charge),
        ("refund", .refund), ("will be credited", .refund), ("credited back", .refund), ("reversed", .refund),
        ("new total", .revised), ("revised total", .revised), ("revised fare", .revised),
        ("revised amount", .revised), ("revised price", .revised), ("updated total", .revised),
        ("updated amount", .revised), ("updated price", .revised), ("new amount", .revised), ("new price", .revised),
        ("fare difference", .ignored), ("difference", .ignored), ("additional", .ignored), ("extra", .ignored),
        ("balance due", .ignored), ("pay the", .ignored), ("original", .ignored), ("previous", .ignored),
        ("old ", .ignored), ("earlier", .ignored), ("taxes", .ignored), ("gst", .ignored), ("per night", .ignored),
        ("per person", .ignored), ("convenience fee", .ignored),
        ("grand total", .stated), ("total amount", .stated), ("total price", .stated), ("total fare", .stated),
        ("total cost", .stated), ("amount paid", .stated), ("total paid", .stated), ("booking amount", .stated)
    ]

    private static func read(
        _ amounts: [(candidate: AmountScanner.Candidate, range: NSRange)],
        in line: String,
        labelAbove: String?,
        into facts: inout BookingMailFacts
    ) {
        let lower = BookingText.normalise(line) as NSString
        var segmentStart = 0

        for amount in amounts {
            let end = max(segmentStart, amount.range.location)
            var segment = lower.substring(with: NSRange(location: segmentStart, length: end - segmentStart))
            segmentStart = amount.range.location + amount.range.length

            // "Refund amount" on one line and "₹48,600" on the next.
            if segment.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)).isEmpty,
               let labelAbove {
                segment = labelAbove
            }

            var role = role(of: segment)
            // "₹1,200 will be refunded": the label can follow the figure.
            if role == .ignored || role == .stated {
                let after = trailing(lower, from: amount.range.location + amount.range.length, amounts: amounts)
                if let late = lateRole(of: after) { role = late }
            }
            if facts.currencyCode == nil { facts.currencyCode = amount.candidate.currencyCode }
            let value = amount.candidate.value

            switch role {
            case .refund: if facts.refund == nil { facts.refund = value }
            case .charge: if facts.cancellationCharge == nil { facts.cancellationCharge = value }
            case .revised: if facts.revisedTotal == nil { facts.revisedTotal = value }
            case .stated: if facts.statedTotal == nil { facts.statedTotal = value }
            case .ignored: break
            }
        }
    }

    /// Up to the next figure or the end of the sentence, whichever is first.
    private static func trailing(
        _ line: NSString,
        from start: Int,
        amounts: [(candidate: AmountScanner.Candidate, range: NSRange)]
    ) -> String {
        let nextAmount = amounts.map(\.range.location).filter { $0 >= start }.min() ?? line.length
        var end = min(nextAmount, start + 40, line.length)
        let sentence = line.range(of: ".", options: [], range: NSRange(location: start, length: max(0, end - start)))
        if sentence.location != NSNotFound, sentence.location > start + 1 { end = sentence.location }
        return line.substring(with: NSRange(location: start, length: max(0, end - start)))
    }

    /// Only the unmistakable after-the-figure phrasings.
    private static func lateRole(of text: String) -> AmountRole? {
        if ["will be refunded", "is refundable", "has been refunded", "refunded", "will be credited",
            "to be refunded", "as refund", "refund has been", "refund will"].contains(where: text.contains) { return .refund }
        if ["as cancellation", "cancellation fee", "cancellation charge", "will be retained",
            "is non-refundable", "will be deducted", "has been deducted"].contains(where: text.contains) { return .charge }
        return nil
    }

    /// The earliest label in the segment wins, and a bare "total" only counts
    /// when nothing more specific is there — "Total refund" is a refund.
    private static func role(of segment: String) -> AmountRole {
        var best: (location: Int, length: Int, role: AmountRole)?
        let text = segment as NSString

        for (phrase, role) in amountLabels {
            let found = text.range(of: phrase)
            guard found.location != NSNotFound else { continue }
            if let current = best {
                let earlier = found.location < current.location
                let longerAtSameSpot = found.location == current.location && found.length > current.length
                // "non-refundable" and "refund" overlap; the containing phrase wins.
                let contains = found.location <= current.location
                    && found.location + found.length >= current.location + current.length
                if earlier || longerAtSameSpot || contains { best = (found.location, found.length, role) }
            } else {
                best = (found.location, found.length, role)
            }
        }

        if let best { return best.role }
        return BookingText.containsWord("total", in: segment) ? .stated : .ignored
    }
}

// MARK: - Schedule values

/// A date or a clock time, and where on its line it sits.
struct ScheduleValue: Hashable {
    enum Kind: Hashable {
        case day(Date)
        /// Minutes past midnight.
        case minute(Int)
    }

    let kind: Kind
    let range: NSRange

    static func all(in line: String, referenceDate: Date) -> [ScheduleValue] {
        let days = TravelDate.matches(in: line, referenceDate: referenceDate).map {
            ScheduleValue(kind: .day($0.date), range: NSRange($0.range, in: line))
        }
        // Amounts first: "₹12.50" is not ten to one.
        let money = AmountScanner.located(in: line).map(\.range)

        let clocks = TravelDate.clockMatches(in: line).compactMap { hit -> ScheduleValue? in
            let range = NSRange(hit.range, in: line)
            // "12.09.2026" reads as a clock as well as a date. The date wins.
            if days.contains(where: { NSIntersectionRange($0.range, range).length > 0 }) { return nil }
            if money.contains(where: { NSIntersectionRange($0, range).length > 0 }) { return nil }
            // A span's second half is the arrival; the match already covers it.
            return ScheduleValue(kind: .minute(hit.minute), range: NSRange(location: range.location, length: min(range.length, 8)))
        }

        return (days + clocks).sorted { $0.range.location < $1.range.location }
    }
}

// MARK: - Old and new

private enum Role: Hashable {
    case old, new

    static let oldMarkers = [
        "old", "original", "originally", "previous", "previously", "earlier", "was", "were",
        "instead of", "initially", "erstwhile", "existing"
    ]
    static let newMarkers = [
        "new", "revised", "updated", "now", "rescheduled to", "changed to", "moved to", "shifted to",
        "postponed to", "preponed to", "delayed to", "current", "latest", "amended", "modified to"
    ]
    /// Place names that start with a marker word.
    static let places = ["new delhi", "new york", "new jersey", "new zealand", "new jalpaiguri", "new town"]

    /// A line that is only a heading: "New schedule", "Original flight details".
    static func headed(_ line: String) -> Role? {
        let cleaned = scrub(line)
        let words = cleaned.split(separator: " ").count
        guard words <= 6 else { return nil }
        let first = firstMarker(in: cleaned as NSString, before: (cleaned as NSString).length, within: .max)
        return first
    }

    /// Verbs that say the booking *moved*. "from 28 Sep to 29 Sep" after one
    /// of these is a before and an after.
    private static let movement = ["chang", "reschedul", "moved", "postpon", "prepon", "shift", "delay", "retim", "revis"]
    /// Verbs that say it was edited, which is weaker: "your modified stay:
    /// from 28 Sep to 1 Oct" is a check-in and a check-out.
    private static let edited = ["updat", "modif", "amend"]
    private static let spanWords = ["stay", "night", "check-out", "checkout", "check out", "duration"]
    private static let arrows: Set<String> = ["→", "->", "⇒", "=>", "➝", "➔", "»"]

    /// One role per value, or nil where nothing on the line says.
    ///
    /// Three readings, strongest first. An arrow between two values of the
    /// same kind ("07:05 → 09:40") is a before and an after — but only when
    /// nothing else sits between them, because "BOM 07:05 → VNS 09:15" is a
    /// departure and an arrival. "from A to B" on a line that says something
    /// moved is the same pair in words. Everything else takes the nearest
    /// old/new word written before it.
    static func assign(_ values: [ScheduleValue], in line: String, lower: String) -> [Role?] {
        let text = scrub(lower) as NSString
        var roles = [Role?](repeating: nil, count: values.count)

        // Arrows.
        for (index, value) in values.enumerated() {
            guard let nextIndex = values[(index + 1)...].firstIndex(where: { sameKind($0, value) }) else { continue }
            let next = values[nextIndex]
            let gapStart = value.range.location + value.range.length
            guard next.range.location >= gapStart else { continue }

            // Other-kind values between the pair ("28 Sep 07:05 → 28 Sep 09:40")
            // are part of the pair, not a reason to doubt it.
            var gap = text.substring(with: NSRange(location: gapStart, length: next.range.location - gapStart))
            for between in values[(index + 1)..<nextIndex] {
                let local = NSRange(location: between.range.location - gapStart, length: between.range.length)
                if local.location >= 0, local.location + local.length <= (gap as NSString).length {
                    gap = (gap as NSString).replacingCharacters(in: local, with: String(repeating: " ", count: local.length))
                }
            }
            let bare = gap.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: ",|:")))
            if arrows.contains(bare) {
                roles[index] = roles[index] ?? .old
                roles[nextIndex] = .new
            }
        }

        // from … to …
        let moved = movement.contains(where: lower.contains)
        let editedOnly = !moved && edited.contains(where: lower.contains)
        let isSpan = spanWords.contains(where: lower.contains)
        if moved || (editedOnly && !isSpan),
           let regex = try? NSRegularExpression(pattern: #"\bfrom\b(.{1,40}?)\bto\b(.{1,40})"#),
           let match = regex.firstMatch(in: text as String, range: NSRange(location: 0, length: text.length)) {
            let oldSpan = match.range(at: 1), newSpan = match.range(at: 2)
            for (index, value) in values.enumerated() where roles[index] == nil {
                if NSLocationInRange(value.range.location, oldSpan) { roles[index] = .old }
                else if NSLocationInRange(value.range.location, newSpan) {
                    // "to 09:40, earlier 07:05": a marker inside the new half still wins.
                    roles[index] = firstMarker(in: text, before: value.range.location, within: 25) ?? .new
                }
            }
        }

        // Nearest word.
        for (index, value) in values.enumerated() where roles[index] == nil {
            roles[index] = firstMarker(in: text, before: value.range.location, within: 40)
        }

        // A row that *starts* with its label — "Old schedule: 6E 5307 | 28 Sep
        // 2026 | Departure 07:05" — labels everything on it, however far along.
        if roles.contains(where: { $0 == nil }),
           let leading = firstMarker(in: text, before: min(text.length, 24), within: 24),
           !roles.contains(where: { $0 != nil && $0 != leading }) {
            roles = roles.map { $0 ?? leading }
        }
        return roles
    }

    /// The marker nearest before `location`, if it ends within `within` characters of it.
    private static func firstMarker(in text: NSString, before location: Int, within: Int) -> Role? {
        var best: (end: Int, role: Role)?
        let limit = min(location, text.length)
        let prefix = text.substring(to: limit) as NSString

        for (markers, role) in [(oldMarkers, Role.old), (newMarkers, Role.new)] {
            for marker in markers {
                guard let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: marker))\\b") else { continue }
                for match in regex.matches(in: prefix as String, range: NSRange(location: 0, length: prefix.length)) {
                    let end = match.range.location + match.range.length
                    guard limit - end <= within else { continue }
                    if best == nil || end > best!.end { best = (end, role) }
                }
            }
        }
        return best?.role
    }

    private static func sameKind(_ a: ScheduleValue, _ b: ScheduleValue) -> Bool {
        switch (a.kind, b.kind) {
        case (.day, .day), (.minute, .minute): true
        default: false
        }
    }

    /// Same length out as in, so ranges still line up.
    private static func scrub(_ line: String) -> String {
        var text = line
        for place in places {
            text = text.replacingOccurrences(of: place, with: String(repeating: "x", count: place.count))
        }
        return text
    }
}

// MARK: - Text helpers

/// Small readings shared by the gate, the facts and the matcher.
enum BookingText {

    /// Lowercased, with curly quotes and non-breaking spaces flattened. Same
    /// UTF-16 length as the input, so positions carry across.
    static func normalise(_ raw: String) -> String {
        raw.lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    static func containsWord(_ word: String, in text: String) -> Bool {
        text.range(of: "\\b\(NSRegularExpression.escapedPattern(for: word))\\b", options: .regularExpression) != nil
    }

    /// Words a shouty template writes in capitals that look like airline codes.
    private static let notAirlines: Set<String> = [
        "ON", "AT", "TO", "OF", "IN", "IS", "NO", "BY", "AM", "PM", "UP", "OR", "AN", "AS", "IF", "IT",
        "BE", "WE", "MY", "DO", "GO", "SO", "RS", "ID", "HR", "US", "OK", "TV", "PH", "ST", "ND", "RD", "TH"
    ]

    /// "6E 5307", "6E-5307", "AI101" → "6E5307", "AI101". Leading zeros dropped.
    static func flightNumbers(in text: String) -> Set<String> {
        guard let regex = try? NSRegularExpression(pattern: #"\b([A-Z]{2}|[A-Z][0-9]|[0-9][A-Z])[\s-]?([0-9]{2,4})\b"#) else { return [] }
        var found: Set<String> = []
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let code = match.string(text, 1), !notAirlines.contains(code),
                  let digits = match.string(text, 2), let number = Int(digits) else { continue }
            found.insert("\(code)\(number)")
        }
        return found
    }

    /// PNR, booking id or confirmation number.
    static func reference(in text: String) -> String? {
        let pattern = #"(?:pnr|booking\s*(?:id|reference|ref|number|no)|confirmation\s*(?:number|no|code|id)|reservation\s*(?:number|no|id|code)|itinerary\s*(?:id|number|no)|order\s*id)\s*(?:no\.?|number|#)?\s*[:#\-]?\s*([A-Z0-9][A-Z0-9\-]{4,19})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let value = match.string(text, 1) else { continue }
            // A reference has digits or is all capitals; "number" is neither.
            let hasDigit = value.contains(where: \.isNumber)
            let isShouted = value == value.uppercased() && value.contains(where: \.isLetter)
            if hasDigit || isShouted { return value }
        }
        return nil
    }

    private static let categoryWords: [(String, [String])] = [
        ("flight", ["flight", "airline", "boarding", "pnr", "terminal", "indigo", "air india", "vistara", "akasa", "spicejet", "airport"]),
        ("train", ["train", "irctc", "coach", "berth", "railway", "rail"]),
        ("stay", ["hotel", "check-in", "check in", "room", "stay", "property", "resort", "homestay", "guest house", "nights"]),
        ("activity", ["tour", "experience", "activity", "tickets", "darshan", "safari", "cruise", "boat", "museum", "show"]),
        ("drive", ["cab", "taxi", "chauffeur", "car rental", "pickup", "pick-up", "driver"])
    ]

    static func category(of lower: String, hasFlightNumber: Bool) -> String? {
        var counts: [(String, Int)] = categoryWords.map { category, words in
            (category, words.reduce(0) { $0 + occurrences(of: $1, in: lower) })
        }
        if hasFlightNumber, let index = counts.firstIndex(where: { $0.0 == "flight" }) { counts[index].1 += 3 }
        let sorted = counts.sorted { $0.1 > $1.1 }
        guard let top = sorted.first, top.1 > 0 else { return nil }
        if sorted.count > 1, sorted[1].1 == top.1 { return nil }
        return top.0
    }

    private static func occurrences(of word: String, in text: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: word))") else { return 0 }
        return regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    /// "7:05 AM" for minutes past midnight, without a formatter — this file
    /// is also compiled into the test harness, where the app's helpers aren't.
    static func clock(_ minute: Int) -> String {
        let hour = minute / 60, mins = minute % 60
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", twelve, mins, hour < 12 ? "AM" : "PM")
    }
}
