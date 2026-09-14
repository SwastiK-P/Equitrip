//
//  ItineraryConsistency.swift
//  Equitrip
//

import Foundation

/// The arithmetic pass over a plan: what two clock times, read side by side,
/// say about each other.
///
/// Everything here is deterministic and works entirely off data the bookings
/// already carry. That division is deliberate and it's the same one
/// `ItineraryReasoner` draws: a model asked whether 2:00 PM plus two hours
/// runs into 3:00 PM will mostly say yes, and mostly is not a standard you can
/// hold a warning to. Clashes, gaps and duplicates are subtraction, so they
/// are done by subtraction, and `ItineraryInspector` is left the questions
/// that actually need judgement.
///
/// The one thing this cannot do honestly is know how long anything takes —
/// `ItineraryItem` has a start and no end. So durations are assumed from the
/// category, every assumption is marked, and the copy hedges wherever one was
/// used. A warning that overstates its own certainty is worse than no warning,
/// because the second time it's wrong nobody reads the first line again.
enum ItineraryConsistency {

    // MARK: - Assumed durations

    /// How long a booking of each kind tends to take.
    ///
    /// Rounded, and rounded *down* where there was a choice: the cost of
    /// guessing long is a clash that isn't real, which trains people to
    /// dismiss the card.
    static func assumedDuration(_ kind: ItineraryKind) -> TimeInterval {
        switch kind {
        case .flight: 2.5 * 3600
        case .train: 3 * 3600
        case .drive: 3600
        case .meal: 1.5 * 3600
        case .activity: 2 * 3600
        case .stay: 0
        case .other: 3600
        }
    }

    /// When a booking starts and when it's likely to be over.
    struct Span {
        var start: Date
        var end: Date
        /// True when `end` came from the table above rather than from the
        /// booking itself. Only a looked-up flight knows its own end.
        var isEstimated: Bool
    }

    /// The span of a booking, or nil when it doesn't have one.
    ///
    /// Two kinds of nil, both meaning "don't reason about this". An untimed
    /// booking has no position within its day to clash with anything. And a
    /// stay is an anchor rather than an appointment — it runs all night by
    /// definition, so treating it as an occupied block would have every hotel
    /// clash with every dinner.
    static func span(of item: ItineraryItem) -> Span? {
        guard item.kind != .stay, let time = item.time else { return nil }

        if let flight = item.flight,
           let departure = flight.scheduledDeparture,
           let arrival = flight.scheduledArrival,
           arrival > departure {
            return Span(start: departure, end: arrival, isEstimated: false)
        }

        return Span(
            start: time,
            end: time.addingTimeInterval(assumedDuration(item.kind)),
            isEstimated: true
        )
    }

    // MARK: - Entry point

    /// Everything wrong with a plan that can be established by arithmetic.
    static func check(_ items: [ItineraryItem], span tripSpan: ClosedRange<Date>) -> [ItineraryIssue] {
        let timeline = items.sorted { Trip.chronological($0, $1) }
        guard !timeline.isEmpty else { return [] }

        let clashes = clashes(in: timeline)

        var issues = clashes.map(\.issue)
        issues += connections(in: timeline, alreadyClashing: Set(clashes.map(\.pair)))
        issues += arrivals(in: timeline, alreadyClashing: Set(clashes.map(\.pair)))
        issues += flightContradictions(in: timeline)
        issues += missingFirstNight(in: timeline)
        issues += duplicates(in: timeline)
        issues += packedDays(in: timeline)
        issues += outOfSpan(in: timeline, span: tripSpan)
        issues += untimedAmongTimed(in: timeline)

        return ordered(issues)
    }

    /// Worst first, then in the order you'd walk into them.
    ///
    /// Also where the ceiling lives. A list of twenty warnings is a list
    /// nobody reads, and the review screen's job is the bookings — the card
    /// is there to catch the eye, not to become the screen.
    static func ordered(_ issues: [ItineraryIssue], limit: Int = 8) -> [ItineraryIssue] {
        issues
            .sorted {
                $0.severity == $1.severity ? $0.anchor < $1.anchor : $0.severity > $1.severity
            }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - R1 · Two things at once

    private struct Pair: Hashable {
        let a: UUID
        let b: UUID

        init(_ x: UUID, _ y: UUID) {
            // Normalised so a pair is the same pair whichever way round it
            // was found — the connection rule looks these up by identity.
            (a, b) = x.uuidString < y.uuidString ? (x, y) : (y, x)
        }
    }

    /// Bookings whose times run into each other.
    ///
    /// Compared across the whole trip rather than within each day, because the
    /// case worth catching most is the one a per-day pass structurally can't
    /// see: a flight that takes off at eleven at night and lands after
    /// midnight, against a breakfast booked for the morning it lands on.
    private static func clashes(in timeline: [ItineraryItem]) -> [(pair: Pair, issue: ItineraryIssue)] {
        let grace: TimeInterval = 15 * 60
        let maxReported = 4

        var found: [(pair: Pair, issue: ItineraryIssue)] = []
        var reportedFor: [UUID: Int] = [:]

        for (index, earlier) in timeline.enumerated() {
            guard let first = span(of: earlier) else { continue }

            for later in timeline[(index + 1)...] {
                guard found.count < maxReported else { return found }
                guard let second = span(of: later) else { continue }
                guard second.start < first.end.addingTimeInterval(-grace) else { continue }

                // Two bookings with the same name on the same day are the
                // duplicate rule's story, and it tells it far better — a
                // headline reading "Louvre Museum clashes with Louvre Museum"
                // is technically true and tells the reader nothing.
                guard !sameBooking(earlier, later) else { continue }

                // One booking can only be blamed so many times before the card
                // is four sentences about the same afternoon.
                guard (reportedFor[earlier.id] ?? 0) < 2, (reportedFor[later.id] ?? 0) < 2 else { continue }
                reportedFor[earlier.id, default: 0] += 1
                reportedFor[later.id, default: 0] += 1

                let overlap = min(first.end, second.end).timeIntervalSince(second.start)
                let minutes = Int(overlap / 60)
                let label = earlier.kind.label.lowercased()
                let hedge = first.isEstimated
                    ? "\(earlier.title) starts at \(clock(first.start)) and \(article(label)) \(label) usually runs about \(phrase(assumedDuration(earlier.kind)))"
                    : "\(earlier.title) runs \(clock(first.start)) to \(clock(first.end))"

                found.append((
                    Pair(earlier.id, later.id),
                    ItineraryIssue(
                        severity: minutes >= 60 ? .likelyWrong : .worthChecking,
                        symbol: "calendar.badge.exclamationmark",
                        headline: "\(later.title) clashes with \(earlier.title)",
                        problem: "\(hedge), but \(later.title) starts at \(clock(second.start)) — around \(phrase(overlap)) of overlap.",
                        fix: "Move \(later.title) later in the day, or check whether \(earlier.title) really runs that long.",
                        itemIDs: [later.id, earlier.id],
                        origin: .rules,
                        anchor: second.start
                    )
                ))
            }
        }

        return found
    }

    // MARK: - R2 · Connections you won't make

    /// A departure booked so soon after the thing before it that you'd have to
    /// leave in the middle.
    ///
    /// Only departures, and only the booking immediately before one. Applying
    /// this to everything would report every busy afternoon; the reason it's
    /// worth saying about a flight is that a flight doesn't wait.
    private static func connections(in timeline: [ItineraryItem], alreadyClashing: Set<Pair>) -> [ItineraryIssue] {
        var issues: [ItineraryIssue] = []

        for (index, item) in timeline.enumerated() where index > 0 {
            guard item.kind == .flight || item.kind == .train, let departure = item.time else { continue }

            // The nearest booking behind this one that occupies real time.
            guard let previous = timeline[..<index].last(where: { span(of: $0) != nil }),
                  let before = span(of: previous)
            else { continue }

            // An outright overlap is the clash rule's story, not this one's.
            guard !alreadyClashing.contains(Pair(previous.id, item.id)) else { continue }

            let required: TimeInterval = item.kind == .flight ? 120 * 60 : 45 * 60
            let slack = departure.timeIntervalSince(before.end)
            guard slack >= 0, slack < required else { continue }

            let advice = item.kind == .flight
                ? "Airlines want you at the airport a good two hours ahead"
                : "That leaves nothing for getting to the platform"

            issues.append(
                ItineraryIssue(
                    severity: .likelyWrong,
                    symbol: "clock.badge.exclamationmark",
                    headline: "Tight run to \(item.title)",
                    problem: "\(previous.title) is likely to finish around \(clock(before.end)), about \(Int(slack / 60).pluralised("minute")) before \(item.title) leaves at \(clock(departure)).",
                    fix: "\(advice) — move \(previous.title) earlier, or take a later \(item.kind.label.lowercased()).",
                    itemIDs: [item.id, previous.id],
                    origin: .rules,
                    anchor: departure
                )
            )
        }

        return issues
    }

    // MARK: - R2b · Landing into the next thing

    /// The other end of a journey: something booked so soon after a flight or
    /// a train gets in that the journey would have to run to time and the
    /// airport would have to be empty.
    ///
    /// The mirror of the rule above, and the one that catches what a plan
    /// built backwards from arrival times misses — a tour booked for eleven
    /// against a flight that lands at half ten reads fine on paper and is an
    /// hour of baggage hall in practice.
    private static func arrivals(in timeline: [ItineraryItem], alreadyClashing: Set<Pair>) -> [ItineraryIssue] {
        var issues: [ItineraryIssue] = []

        for (index, item) in timeline.enumerated() {
            guard item.kind == .flight || item.kind == .train, let journey = span(of: item) else { continue }
            guard let next = timeline[(index + 1)...].first(where: { span(of: $0) != nil }),
                  let following = span(of: next)
            else { continue }

            // An outright overlap is the clash rule's story, not this one's.
            guard !alreadyClashing.contains(Pair(item.id, next.id)) else { continue }

            let required: TimeInterval = item.kind == .flight ? 90 * 60 : 30 * 60
            let slack = following.start.timeIntervalSince(journey.end)
            guard slack >= 0, slack < required else { continue }

            let landing = journey.isEstimated
                ? "\(item.title) leaves at \(clock(journey.start)) and \(article(item.kind.label.lowercased())) \(item.kind.label.lowercased()) usually takes about \(phrase(assumedDuration(item.kind))), so it likely gets in around \(clock(journey.end))"
                : "\(item.title) gets in at \(clock(journey.end))"

            issues.append(
                ItineraryIssue(
                    // Hedged down when the arrival was assumed rather than
                    // looked up: an estimate is not grounds for telling
                    // somebody their morning is impossible.
                    severity: journey.isEstimated ? .worthChecking : .likelyWrong,
                    symbol: "arrow.down.right.circle.fill",
                    headline: "\(next.title) starts soon after \(item.title) lands",
                    problem: "\(landing) — about \(Int(slack / 60).pluralised("minute")) before \(next.title) starts at \(clock(following.start)).",
                    fix: item.kind == .flight
                        ? "Getting out of an airport eats most of that — check the real arrival time, or move \(next.title) later."
                        : "That's little time to get off and across town — move \(next.title) later if you can.",
                    itemIDs: [next.id, item.id],
                    origin: .rules,
                    anchor: following.start
                )
            )
        }

        return issues
    }

    // MARK: - R3 · Flights arguing with themselves

    /// Where a looked-up flight disagrees with the booking it's attached to.
    ///
    /// The booking editor overwrites `time` from the airline on lookup, so a
    /// drift means somebody edited the time afterwards — which is either a
    /// correction the lookup should be redone for, or a mistake.
    private static func flightContradictions(in timeline: [ItineraryItem]) -> [ItineraryIssue] {
        var issues: [ItineraryIssue] = []

        for item in timeline {
            guard let flight = item.flight else { continue }

            if flight.status == .cancelled {
                issues.append(
                    ItineraryIssue(
                        severity: .likelyWrong,
                        symbol: "airplane.circle.fill",
                        headline: "\(item.title) is cancelled",
                        problem: "The airline has flight \(flight.number) down as cancelled, but it's still on the plan.",
                        fix: "Rebook it and update this booking, or take it off the itinerary.",
                        itemIDs: [item.id],
                        origin: .rules,
                        anchor: item.time ?? item.date
                    )
                )
            }

            if let departure = flight.scheduledDeparture,
               let booked = item.time,
               abs(booked.timeIntervalSince(departure)) > 20 * 60 {
                issues.append(
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        headline: "\(item.title) doesn't match the airline",
                        problem: "The booking says \(clock(booked)), but flight \(flight.number) is scheduled to depart at \(clock(departure)).",
                        fix: "Set the booking to the airline's time, or look the flight up again to refresh it.",
                        itemIDs: [item.id],
                        origin: .rules,
                        anchor: booked
                    )
                )
            }

            // A saved arrival that precedes its own departure isn't a travel
            // problem, it's the lookup having lost a day boundary. Worth
            // saying because everything downstream of it is then wrong too.
            if let departure = flight.scheduledDeparture,
               let arrival = flight.scheduledArrival,
               arrival <= departure {
                issues.append(
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                        headline: "\(item.title) lands before it leaves",
                        problem: "The saved arrival time is earlier than the departure time, which normally means the lookup lost the date it crosses.",
                        fix: "Look flight \(flight.number) up again to refresh its times.",
                        itemIDs: [item.id],
                        origin: .rules,
                        anchor: departure
                    )
                )
            }
        }

        return issues
    }

    // MARK: - R4 · Nowhere to sleep

    /// Nights at the start of the trip with no stay booked.
    ///
    /// Deliberately narrow. A stay is stored as a single check-in with no
    /// checkout and no night count, so the only reading that doesn't invent
    /// facts is that a stay runs until the next one — which makes every gap
    /// between stays covered, and leaves exactly one real hole: the nights
    /// before the first check-in. And it only asks at all when the plan has a
    /// stay somewhere in it, because a trip that tracks no accommodation isn't
    /// missing any.
    private static func missingFirstNight(in timeline: [ItineraryItem]) -> [ItineraryIssue] {
        guard let firstStay = timeline.first(where: { $0.kind == .stay }) else { return [] }
        guard let earliest = timeline.map(\.day).min(), earliest < firstStay.day else { return [] }

        let nights = Calendar.current.dateComponents([.day], from: earliest, to: firstStay.day).day ?? 0
        guard nights >= 1 else { return [] }

        return [
            ItineraryIssue(
                severity: .worthChecking,
                symbol: "bed.double.circle.fill",
                headline: "No stay for the first \(nights == 1 ? "night" : "\(nights) nights")",
                problem: "The plan starts on \(dayLabel(earliest)) but the first stay, \(firstStay.title), checks in on \(dayLabel(firstStay.day)).",
                fix: "Add where you're sleeping until then, or move the check-in earlier if it's already booked.",
                itemIDs: [firstStay.id],
                origin: .rules,
                anchor: earliest
            )
        ]
    }

    // MARK: - R5 · The same booking twice

    /// What a table split across a page break looks like once it's been read
    /// twice. `ItineraryReasoner.dedupe` drops these during import; by the
    /// time they're on this screen they're the user's bookings, so they get
    /// reported rather than deleted.
    private static func duplicates(in timeline: [ItineraryItem]) -> [ItineraryIssue] {
        var seen: [String: [ItineraryItem]] = [:]

        for item in timeline {
            let name = normalised(item.title)
            guard name.count >= 3 else { continue }
            seen["\(name)|\(item.day.timeIntervalSince1970)", default: []].append(item)
        }

        return seen.values.filter { $0.count > 1 }.prefix(2).map { group in
            let first = group[0]
            return ItineraryIssue(
                severity: .worthChecking,
                symbol: "doc.on.doc.fill",
                headline: "\(first.title) is on the plan twice",
                problem: "\(group.count) bookings called \(first.title) sit on \(dayLabel(first.day)). A document read from a table that ran over a page break usually produces this.",
                fix: "Delete the spare, unless you really did book it twice.",
                itemIDs: group.map(\.id),
                origin: .rules,
                anchor: first.time ?? first.date
            )
        }
    }

    // MARK: - R6 · Days with too much in them

    private static func packedDays(in timeline: [ItineraryItem]) -> [ItineraryIssue] {
        let byDay = Dictionary(grouping: timeline) { $0.day }

        return byDay.keys.sorted().compactMap { day -> ItineraryIssue? in
            let items = byDay[day] ?? []
            let spans = items.compactMap { span(of: $0) }
            let hours = spans.reduce(0) { $0 + $1.end.timeIntervalSince($1.start) } / 3600

            guard spans.count > 6 || hours > 14 else { return nil }

            return ItineraryIssue(
                severity: .worthChecking,
                symbol: "calendar.badge.clock",
                headline: "\(dayLabel(day)) looks packed",
                problem: "\(spans.count.pluralised("booking")) on one day, adding up to roughly \(Int(hours.rounded()).pluralised("hour")) before any travel between them.",
                fix: "Worth moving one or two onto a quieter day.",
                itemIDs: items.map(\.id),
                origin: .rules,
                anchor: day
            )
        }
        .prefix(2)
        .map { $0 }
    }

    // MARK: - R7 · Bookings outside the trip

    private static func outOfSpan(in timeline: [ItineraryItem], span tripSpan: ClosedRange<Date>) -> [ItineraryIssue] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: tripSpan.lowerBound)
        let end = calendar.startOfDay(for: tripSpan.upperBound)

        return timeline
            .filter { $0.day < start || $0.day > end }
            .prefix(2)
            .map { item in
                ItineraryIssue(
                    severity: .likelyWrong,
                    symbol: "calendar.badge.minus",
                    headline: "\(item.title) falls outside the trip",
                    problem: "It's dated \(dayLabel(item.day)), but the trip runs \(dayLabel(start)) to \(dayLabel(end)).",
                    fix: "Change its date, or widen the trip's dates on the previous step.",
                    itemIDs: [item.id],
                    origin: .rules,
                    anchor: item.date
                )
            }
    }

    // MARK: - R8 · No time on a day that runs on times

    /// A booking with no time is fine on its own and a puzzle on a day where
    /// everything else has one — it sorts to the top of the day and sits above
    /// bookings that happen in the morning, with nothing saying whether that's
    /// where it belongs.
    private static func untimedAmongTimed(in timeline: [ItineraryItem]) -> [ItineraryIssue] {
        let byDay = Dictionary(grouping: timeline) { $0.day }

        return byDay.keys.sorted().flatMap { day -> [ItineraryIssue] in
            let items = byDay[day] ?? []
            let timed = items.filter { $0.time != nil }
            guard timed.count >= 3 else { return [] }

            return items
                .filter { $0.time == nil && $0.kind != .stay }
                .map { item in
                    ItineraryIssue(
                        severity: .worthChecking,
                        symbol: "questionmark.circle.fill",
                        headline: "\(item.title) has no time",
                        problem: "\(dayLabel(day)) has \(timed.count.pluralised("other booking")) with times on it, so there's no telling where this one fits.",
                        fix: "Give it a start time so it lands in the right place on the day.",
                        itemIDs: [item.id],
                        origin: .rules,
                        anchor: day
                    )
                }
        }
        .prefix(2)
        .map { $0 }
    }

    // MARK: - Helpers

    /// The key the duplicate rule groups on, so the clash rule can ask the
    /// same question and stay out of its way.
    private static func normalised(_ title: String) -> String {
        title.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    private static func sameBooking(_ a: ItineraryItem, _ b: ItineraryItem) -> Bool {
        let name = normalised(a.title)
        return name.count >= 3 && name == normalised(b.title) && a.day == b.day
    }

    /// "an activity", "a flight". The categories are a fixed list, so this is
    /// a vowel check rather than anything cleverer.
    private static func article(_ word: String) -> String {
        "aeiou".contains(word.lowercased().first ?? "x") ? "an" : "a"
    }

    // MARK: - Formatting

    /// Every figure in every message above comes through here. The model
    /// never writes one.
    private static func clock(_ date: Date) -> String {
        DateFormatter.cached("h:mm a").string(from: date)
    }

    private static func dayLabel(_ date: Date) -> String {
        DateFormatter.cached("EEE d MMM").string(from: date)
    }

    private static func phrase(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        guard minutes >= 60 else { return minutes.pluralised("minute") }
        let hours = Double(minutes) / 60
        let rounded = (hours * 2).rounded() / 2
        return rounded == rounded.rounded()
            ? Int(rounded).pluralised("hour")
            : String(format: "%.1f hours", rounded)
    }
}
