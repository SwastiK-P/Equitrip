//
//  EquiFacts.swift
//  Equitrip
//

import Foundation

/// Swift's answer to an `EquiQuery`: the facts that answer it, a sentence
/// that says so, the card to draw, and what to ask next.
///
/// Every figure here is a question put to `Trip` — `owed(by:)`, `paid(by:)`,
/// `suggestedTransfers`, `TripRecap` — never arithmetic of Equi's own. The
/// model is handed `lines` and asked to phrase an answer from them; when it
/// can't run, or says a figure that isn't in them, `headline` is the answer.
/// Keeping the lines to the one question is also what keeps the on-device
/// model on track: four trips' worth of bookings was more than it could keep
/// apart.
@MainActor
struct EquiFacts {
    /// A complete answer in one or two sentences, written by Swift.
    var headline: String
    /// What the model may draw on, one fact a line.
    var lines: [String] = []
    var card: EquiCard?
    /// Follow-up questions offered as chips under the answer.
    var suggestions: [String] = []
    /// Advice and small talk: the model may speak from general knowledge,
    /// never about bookings or money that aren't in `lines`.
    var allowsGeneralKnowledge = false
    /// The trip a follow-up question with no trip named is about.
    var focusTripID: UUID?

    @MainActor
    static func answer(_ query: EquiQuery, store: TripStore) -> EquiFacts {
        guard !store.trips.isEmpty else {
            return EquiFacts(
                headline: "You don't have any trips yet — start one from Home and I'll keep track of the plan and the money.",
                lines: ["The user has no trips yet. They can start one from the Home tab."],
                suggestions: [],
                allowsGeneralKnowledge: query.topic == .advice || query.topic == .chat
            )
        }

        let trips = query.tripIDs.compactMap { store.trip($0) }

        switch query.topic {
        case .chat: return chat(about: trips.first, store: store)
        case .advice: return advice(for: trips.first)
        case .trips: return compare(trips, query: query)
        default: break
        }

        guard let trip = trips.first else { return missing(query, store: store) }
        if trips.count > 1, query.topic == .balance { return balanceAcross(trips) }
        if trips.count > 1, query.topic == .spending { return compare(trips, query: query) }

        var facts: EquiFacts
        switch query.topic {
        case .schedule: facts = schedule(trip, query: query)
        case .bookings: facts = bookings(trip, category: query.category)
        case .spending: facts = spending(trip, category: query.category, asksBudget: query.asksBudget)
        case .balance: facts = balance(trip, personID: query.personID)
        case .people: facts = people(trip, personID: query.personID)
        case .gaps: facts = gaps(trip)
        default: facts = overview(trip)
        }
        facts.lines.insert(contentsOf: tripLines(trip), at: 0)
        facts.focusTripID = trip.id
        return facts
    }

    // MARK: - One trip

    private static func overview(_ trip: Trip) -> EquiFacts {
        let code = trip.currencyCode
        var lines: [String] = []
        let headline: String
        var suggestions: [String]

        switch trip.phase {
        case .upcoming:
            let booked = trip.items.isEmpty
                ? "Nothing's booked yet."
                : "\(trip.items.count.pluralised("booking")) so far, \(trip.projectedLabel) planned — your share is \(Money.format(trip.yourShare, code: code))."
            headline = "\(trip.title) starts \(startsIn(trip)): \(trip.dayCount.pluralised("day")) in \(trip.destination), \(trip.dateRange). \(booked)"
            lines.append("Bookings: \(trip.items.count), planned cost \(trip.projectedLabel), the user's share \(Money.format(trip.yourShare, code: code)).")
            if let first = trip.items.sorted(by: Trip.chronological).first {
                lines.append("First booking: \(describe(first, in: trip)).")
            }
            let open = EquiPlanCheck(trip: trip).gaps.count
            if open > 0 { lines.append("\(open.pluralised("gap")) in the plan (nights with no stay, empty days, no travel booked).") }
            suggestions = ["What's still unbooked?", "Where am I staying?", "What should I pack?"]

        case .live:
            let next = trip.upcoming(limit: 2)
            var sentence = "You're on \(trip.progressLabel.lowercased()) in \(trip.destination)."
            if let first = next.first { sentence += " Next up: \(first.title) \(when(first))." }
            headline = sentence
            lines.append("Progress: \(trip.progressLabel).")
            for item in next { lines.append("Coming up: \(describe(item, in: trip)).") }
            lines.append(contentsOf: moneyLines(trip))
            suggestions = ["What's on tomorrow?", "Who still owes me?", "How much on food so far?"]

        case .past:
            let recap = TripRecap(trip: trip)
            let total = Money.format(recap.total(.group).rounded(), code: code)
            let each = Money.format(recap.perPerson.rounded(), code: code)
            headline = "\(trip.title) wrapped up \(endedAgo(trip)): \(trip.dayCount.pluralised("day")) in \(trip.destination), \(total) across \(trip.items.count.pluralised("booking")) — about \(each) each."
            lines.append("Total spent: \(total) across \(trip.items.count.pluralised("booking")); about \(each) per person; \(Money.format(recap.perDay.rounded(), code: code)) per day.")
            lines.append("The user's share: \(Money.format(recap.total(.you).rounded(), code: code)); they paid \(Money.format(recap.yourPaid, code: code)).")
            if let top = recap.biggest(.group) {
                lines.append("Biggest single cost: \(top.title), \(Money.format(top.cost, code: code)).")
            }
            if let top = recap.contributors.first, top.paid > 0 {
                lines.append("Paid the most: \(name(top.traveller)), \(Money.format(top.paid, code: code)).")
            }
            lines.append(squaringLine(recap))
            suggestions = ["Who paid the most?", "Did everyone settle up?", "Compare my trips"]
        }

        return EquiFacts(
            headline: headline,
            lines: lines,
            card: EquiCard(kind: trip.phase == .past ? .recap : .trip, tripID: trip.id),
            suggestions: suggestions
        )
    }

    private static func schedule(_ trip: Trip, query: EquiQuery) -> EquiFacts {
        let calendar = Calendar.current

        if query.day != .any {
            let offset = query.day == .today ? 0 : 1
            let date = calendar.startOfDay(for: Date.daysFromToday(offset))
            let word = query.day == .today ? "Today" : "Tomorrow"
            let items = trip.items.filter { $0.day == date }.sorted(by: Trip.chronological)
            let inTrip = date >= calendar.startOfDay(for: trip.startDate) && date <= calendar.startOfDay(for: trip.endDate)

            let headline: String
            if items.isEmpty {
                headline = inTrip
                    ? "\(word) is clear on \(trip.title) — nothing's booked."
                    : "Nothing on \(word.lowercased()) — \(trip.title) \(trip.phase == .past ? "ended \(endedAgo(trip))" : "starts \(startsIn(trip))")."
            } else {
                let list = items.prefix(3).map { item in item.timeLabel.map { "\(item.title) at \($0)" } ?? item.title }
                headline = "\(word) you've got \(items.count.pluralised("thing")): \(joined(list))."
            }
            return EquiFacts(
                headline: headline,
                lines: ["\(word) is \(DateFormatter.cached("EEEE d MMM").string(from: date))."]
                    + (items.isEmpty ? ["Nothing is booked that day."] : items.map { "\(word): \(describe($0, in: trip))." }),
                card: inTrip ? EquiCard(kind: .itinerary, tripID: trip.id, day: date) : EquiCard(kind: .trip, tripID: trip.id),
                suggestions: ["What's up next?", "Where am I staying?", "Any gaps in the plan?"]
            )
        }

        if let category = query.category {
            let all = trip.items.filter { $0.kind == category }.sorted(by: Trip.chronological)
            let ahead = all.filter { ($0.time ?? $0.date.endOfDay) >= Date() }
            let noun = category.label.lowercased()
            guard let target = ahead.first ?? all.last else {
                return EquiFacts(
                    headline: "There's no \(noun) booked on \(trip.title) yet.",
                    lines: ["No \(noun) bookings on this trip."],
                    card: EquiCard(kind: .bookings, tripID: trip.id, category: category),
                    suggestions: ["What's still unbooked?", "What's up next?"]
                )
            }
            var headline = "\(ahead.isEmpty ? "Your last" : "Your next") \(noun) is \(target.title) \(when(target))"
            if let flight = target.flight {
                if let from = flight.departureCity ?? flight.departureAirport, let to = flight.arrivalCity ?? flight.arrivalAirport {
                    headline += ", \(from) to \(to)"
                }
                if let landing = flight.scheduledArrival {
                    headline += ", landing at \(DateFormatter.cached("HH:mm").string(from: landing))"
                }
            }
            headline += "."
            return EquiFacts(
                headline: headline,
                lines: all.prefix(8).map { "\(category.label): \(describe($0, in: trip))." },
                card: EquiCard(kind: .bookings, tripID: trip.id, category: category),
                suggestions: category == .stay
                    ? ["When do I fly?", "What's up next?"]
                    : ["Where am I staying?", "What's on tomorrow?", "Any gaps in the plan?"]
            )
        }

        let next = trip.upcoming(limit: 3)
        let headline: String
        if trip.items.isEmpty {
            headline = "Nothing's booked on \(trip.title) yet."
        } else if trip.phase == .past {
            let last = trip.items.sorted(by: Trip.chronological).last
            headline = "\(trip.title) is over — the last thing on it was \(last?.title ?? "the trip home")."
        } else if let first = next.first {
            var sentence = "Next up: \(first.title) \(when(first))"
            if next.count > 1 { sentence += ", then \(next[1].title) \(when(next[1]))" }
            headline = sentence + "."
        } else {
            headline = "Nothing else is booked on \(trip.title)."
        }
        return EquiFacts(
            headline: headline,
            lines: next.map { "Coming up: \(describe($0, in: trip))." },
            card: EquiCard(kind: .itinerary, tripID: trip.id),
            suggestions: ["What's on tomorrow?", "Where am I staying?", "Any gaps in the plan?"]
        )
    }

    private static func bookings(_ trip: Trip, category: ItineraryKind?) -> EquiFacts {
        let items = trip.items
            .filter { category == nil || $0.kind == category }
            .sorted(by: Trip.chronological)
        let card = EquiCard(kind: .bookings, tripID: trip.id, category: category)

        guard !items.isEmpty else {
            let noun = category.map { plural($0) } ?? "bookings"
            return EquiFacts(
                headline: "No \(noun) booked on \(trip.title) yet.",
                lines: ["No \(noun) on this trip."],
                card: card,
                suggestions: ["What's still unbooked?", "What's up next?"]
            )
        }

        let headline: String
        switch category {
        case .stay:
            let stays = items.map { item -> String in
                let nights = nights(of: item, in: trip).map { ", \($0.pluralised("night"))" } ?? ""
                return "\(item.vendorName ?? item.title) (from \(DateFormatter.cached("EEE d MMM").string(from: item.day))\(nights))"
            }
            headline = items.count == 1
                ? "You're staying at \(stays[0])."
                : "You're staying at \(items.count) places: \(joined(stays))."
        case .some(let kind):
            let list = items.prefix(3).map { "\($0.title) on \(DateFormatter.cached("EEE d MMM").string(from: $0.day))" }
            headline = "\(items.count.pluralised(kind.label.lowercased(), plural(kind))) booked: \(joined(list))\(items.count > 3 ? ", and more" : "")."
        case nil:
            let counts = Dictionary(grouping: items, by: \.kind)
                .sorted { $0.value.count > $1.value.count }
                .map { $0.value.count.pluralised($0.key.label.lowercased(), plural($0.key)) }
            headline = "\(items.count.pluralised("booking")) on \(trip.title): \(joined(counts))."
        }

        return EquiFacts(
            headline: headline,
            lines: items.prefix(10).map { "Booked: \(describe($0, in: trip))." },
            card: card,
            suggestions: category == .stay
                ? ["When do I fly?", "Any gaps in the plan?", "Where's the money going?"]
                : ["Where am I staying?", "Where's the money going?", "Any gaps in the plan?"]
        )
    }

    private static func spending(_ trip: Trip, category: ItineraryKind?, asksBudget: Bool) -> EquiFacts {
        let code = trip.currencyCode
        let total = trip.projectedCost
        let card = EquiCard(kind: .spending, tripID: trip.id, category: category)
        let recap = TripRecap(trip: trip)
        let verb = trip.phase == .upcoming ? "planned" : "spent"

        guard total > 0 else {
            return EquiFacts(
                headline: "Nothing on \(trip.title) has a price on it yet.",
                lines: ["No booking on this trip has a cost yet."],
                card: card,
                suggestions: ["What's still unbooked?", "What's up next?"]
            )
        }

        var lines = [
            "Total \(verb): \(trip.projectedLabel) across \(trip.items.count.pluralised("booking")).",
            "The user's share: \(Money.format(trip.yourShare, code: code)).",
            "There's no budget set in the app, so there's nothing to compare the total against."
        ]
        for slice in recap.slices(.group) {
            let percent = Int((slice.amount / total * 100).rounded())
            lines.append("\(slice.kind.label): \(Money.format(slice.amount, code: code)) (\(percent)%, \(slice.count.pluralised("booking"))).")
        }

        var headline: String
        if let category {
            let items = trip.items.filter { $0.kind == category && $0.cost > 0 }
            let amount = items.reduce(0) { $0 + $1.cost }
            let yours = items.reduce(0) { $0 + trip.share(of: $1, for: Traveller.you.id) }
            if items.isEmpty {
                headline = "Nothing \(verb) on \(category.label.lowercased()) on \(trip.title) yet — the trip's at \(trip.projectedLabel) overall."
            } else {
                let percent = Int((amount / total * 100).rounded())
                headline = "\(Money.format(amount, code: code)) \(verb) on \(category.label.lowercased()) across \(items.count.pluralised("booking")) — \(percent)% of \(trip.projectedLabel). Your part of it is \(Money.format(yours, code: code))."
                if let top = items.max(by: { $0.cost < $1.cost }) {
                    lines.append("Biggest \(category.label.lowercased()) cost: \(top.title), \(Money.format(top.cost, code: code)).")
                }
            }
        } else {
            let slices = recap.slices(.group)
            var sentence = "\(trip.projectedLabel) \(verb) on \(trip.title) so far"
            if let top = slices.first {
                let percent = Int((top.amount / total * 100).rounded())
                sentence += ", and \(top.kind.label.lowercased()) is the biggest chunk at \(Money.format(top.amount, code: code)) (\(percent)%)"
            }
            headline = sentence + ". Your share is \(Money.format(trip.yourShare, code: code))."
            if asksBudget {
                headline = "There's no budget set in Equitrip, so I can't say if you're over — but \(trip.projectedLabel) is \(verb) on \(trip.title), and your share is \(Money.format(trip.yourShare, code: code))."
            }
            if let top = recap.biggest(.group) {
                lines.append("Biggest single cost: \(top.title), \(Money.format(top.cost, code: code)).")
            }
        }

        return EquiFacts(
            headline: headline,
            lines: lines,
            card: card,
            suggestions: category == nil
                ? ["How much on food?", "Who paid the most?", "What do I owe?"]
                : ["Where's the money going?", "Who paid the most?", "What do I owe?"]
        )
    }

    private static func balance(_ trip: Trip, personID: UUID?) -> EquiFacts {
        let code = trip.currencyCode
        let you = Traveller.you.id
        let card = EquiCard(kind: .balance, tripID: trip.id, personID: personID)
        let suggestions = ["Who paid the most?", "Where's the money going?", "What's up next?"]

        guard trip.hasPayments else {
            return EquiFacts(
                headline: "Nobody has logged a payment on \(trip.title) yet, so nobody owes anything. Your share of the plan is \(Money.format(trip.yourShare, code: code)).",
                lines: ["No payments recorded yet, so there are no debts.", "The user's share of the planned cost: \(Money.format(trip.yourShare, code: code))."],
                card: card,
                suggestions: suggestions
            )
        }

        let transfers = trip.suggestedTransfers
        var lines = moneyLines(trip)
        let headline: String

        if let personID, let person = trip.traveller(personID) {
            let theyPay = transfers.first { $0.from == personID && $0.to == you }
            let youPay = transfers.first { $0.from == you && $0.to == personID }
            let net = trip.balance(for: personID)
            if let theyPay {
                headline = "\(person.name) owes you \(Money.format(theyPay.amount, code: code)) on \(trip.title)."
            } else if let youPay {
                headline = "You owe \(person.name) \(Money.format(youPay.amount, code: code)) on \(trip.title)."
            } else if abs(net) < SettlementEngine.epsilon {
                headline = "\(person.name) is all square on \(trip.title) — nothing owed either way."
            } else if net > 0 {
                headline = "Nothing between you and \(person.name) — they're owed \(Money.format(net, code: code)) by the others on \(trip.title)."
            } else {
                headline = "Nothing between you and \(person.name) — they owe \(Money.format(-net, code: code)) to the others on \(trip.title)."
            }
            lines.append("\(person.name)'s net balance: \(Money.format(net, code: code, signed: true)) (positive means they get money back).")
        } else {
            let youPay = transfers.filter { $0.from == you }
            let youGet = transfers.filter { $0.to == you }
            var parts: [String] = []
            if !youPay.isEmpty {
                parts.append("you owe " + joined(youPay.map { "\(trip.traveller($0.to)?.name ?? "someone") \(Money.format($0.amount, code: code))" }))
            }
            if !youGet.isEmpty {
                parts.append(joined(youGet.map { "\(trip.traveller($0.from)?.name ?? "someone") \(Money.format($0.amount, code: code))" }) + (youGet.count == 1 ? " owes you" : " owe you"))
            }
            if parts.isEmpty {
                let others = transfers.count
                headline = "You're all square on \(trip.title)" + (others > 0 ? " — \(others.pluralised("payment")) between the others are still open." : ", and so is everyone else.")
            } else {
                let sentence = parts.joined(separator: ", and ")
                headline = "On \(trip.title), " + sentence + "."
            }
        }

        let pending = trip.pendingSettlements.count
        if pending > 0 { lines.append("\(pending.pluralised("payment")) marked as sent and waiting to be confirmed.") }

        return EquiFacts(headline: headline, lines: lines, card: card, suggestions: suggestions)
    }

    private static func people(_ trip: Trip, personID: UUID?) -> EquiFacts {
        let code = trip.currencyCode
        let card = EquiCard(kind: .people, tripID: trip.id, personID: personID)
        let recap = TripRecap(trip: trip)
        var lines = recap.contributors.map { person in
            "\(name(person.traveller)): paid \(Money.format(person.paid, code: code)) for \(person.paidCount.pluralised("booking")), share \(Money.format(person.share, code: code))\(person.presence.map { ", \($0)" } ?? "")."
        }
        let invited = trip.travellers.filter { trip.invitedIDs.contains($0.id) }
        if !invited.isEmpty { lines.append("Invited but not joined yet: \(joined(invited.map(\.name))).") }

        let headline: String
        if let personID, let person = trip.traveller(personID) {
            let paid = trip.paid(by: personID)
            let count = trip.items.filter { $0.paidByID == personID }.count
            let share = trip.cost(for: personID)
            let net = trip.balance(for: personID)
            let standing = abs(net) < SettlementEngine.epsilon
                ? "they're square"
                : net > 0 ? "they get \(Money.format(net, code: code)) back" : "they owe \(Money.format(-net, code: code))"
            headline = "\(person.name) has paid \(Money.format(paid, code: code)) across \(count.pluralised("booking")) on \(trip.title); their share is \(Money.format(share, code: code)), so \(standing)."
        } else {
            let members = recap.members
            var sentence = "\(members.count.pluralised("person", "people")) on \(trip.title): \(joined(members.map { name($0) }))"
            if let top = recap.contributors.first, top.paid > 0 {
                sentence += ". \(top.isYou ? "You've" : "\(top.traveller.name) has") paid the most so far, \(Money.format(top.paid, code: code))"
            }
            headline = sentence + "."
        }

        return EquiFacts(
            headline: headline,
            lines: lines,
            card: card,
            suggestions: personID == nil
                ? ["What do I owe?", "Where's the money going?"]
                : ["Who else is on the trip?", "What do I owe?"]
        )
    }

    private static func gaps(_ trip: Trip) -> EquiFacts {
        let gaps = EquiPlanCheck(trip: trip).gaps
        let card = EquiCard(kind: .gaps, tripID: trip.id)
        let day = DateFormatter.cached("EEE d MMM")

        guard !gaps.isEmpty else {
            return EquiFacts(
                headline: "Nothing obviously missing on \(trip.title) — every night has a stay, every day has something on, and travel's booked both ways.",
                lines: ["No gaps found: stays cover every night, every day has a booking, travel there and back is booked."],
                card: card,
                suggestions: ["What's up next?", "What should I pack?"]
            )
        }

        var parts: [String] = []
        if gaps.contains(where: { $0.kind == .noWayThere }) { parts.append("no way there booked") }
        let nights = gaps.filter { $0.kind == .noStay }
        if !nights.isEmpty { parts.append("no stay for \(nights.count.pluralised("night")) (from \(day.string(from: nights[0].date)))") }
        let empty = gaps.filter { $0.kind == .emptyDay }
        if !empty.isEmpty { parts.append("\(empty.count.pluralised("day")) with nothing planned") }
        if gaps.contains(where: { $0.kind == .noWayBack }) { parts.append("no way home booked") }

        return EquiFacts(
            headline: "A few things look open on \(trip.title): \(joined(parts)).",
            lines: gaps.map { "\($0.label): \(day.string(from: $0.date))." },
            card: card,
            suggestions: ["Where am I staying?", "What's up next?", "What should I pack?"]
        )
    }

    // MARK: - Several trips

    private static func compare(_ trips: [Trip], query: EquiQuery) -> EquiFacts {
        let set: EquiCard.TripSet? = switch query.scope {
        case .allPast: .past
        case .allUpcoming: .upcoming
        case .named: nil
        default: .all
        }
        let card = EquiCard(
            kind: .trips,
            tripSet: set,
            tripIDs: query.scope == .named ? trips.map(\.id) : [],
            metric: query.byCost || query.topic == .spending ? .cost : nil
        )
        let suggestions = ["Tell me about my last trip", "What's my next trip?", "Which trip cost the most?"]

        guard !trips.isEmpty else {
            let headline = query.scope == .allPast
                ? "You haven't finished a trip yet."
                : "There's nothing coming up — no upcoming trips on the books."
            return EquiFacts(headline: headline, lines: [headline], card: nil, suggestions: suggestions)
        }

        // Ranked in the lines themselves when the question is a ranking: the
        // model asked "which came second?" of a list in date order got it
        // wrong, the numbers all present and the order its own.
        let ranking = query.byCost || query.topic == .spending
        let ordered = ranking ? trips.sorted { $0.projectedCost > $1.projectedCost } : trips
        let lines = ordered.prefix(10).enumerated().map { index, trip in
            (ranking ? "Number \(index + 1) by cost: " : "")
                + "\"\(trip.title)\" — \(trip.destination), \(DateFormatter.cached("d MMM yyyy").string(from: trip.startDate)), \(trip.dayCount.pluralised("day")), \(trip.phase.label.lowercased()); cost \(trip.projectedLabel), the user's share \(Money.format(trip.yourShare, code: trip.currencyCode))."
        }

        let headline: String
        if ranking {
            let currencies = Set(trips.map(\.currencyCode))
            let ranked = trips.sorted { $0.projectedCost > $1.projectedCost }
            if currencies.count > 1 {
                headline = "Your trips are in different currencies, so here they are side by side — \(ranked[0].title) is the biggest number at \(ranked[0].projectedLabel)."
            } else if ranked.count > 2 {
                let low = ranked[ranked.count - 1]
                headline = "\(ranked[0].title) comes to the most at \(ranked[0].projectedLabel), then \(ranked[1].title) at \(ranked[1].projectedLabel); \(low.title) is the least at \(low.projectedLabel)."
            } else if ranked.count == 2 {
                headline = "\(ranked[0].title) comes to more — \(ranked[0].projectedLabel), against \(ranked[1].projectedLabel) for \(ranked[1].title)."
            } else {
                headline = "\(ranked[0].title) comes to \(ranked[0].projectedLabel)."
            }
        } else if query.scope == .named {
            headline = trips.map { "\($0.title) is \($0.dayCount.pluralised("day")) at \($0.projectedLabel)" }.joined(separator: "; ") + "."
        } else {
            let live = trips.filter { $0.phase == .live }.count
            let upcoming = trips.filter { $0.phase == .upcoming }.count
            let past = trips.filter { $0.phase == .past }.count
            switch query.scope {
            case .allPast:
                headline = "You've been on \(past.pluralised("trip")): \(joined(trips.prefix(4).map { "\($0.title) (\(DateFormatter.cached("MMM yyyy").string(from: $0.startDate)))" }))\(past > 4 ? " and more" : "")."
            case .allUpcoming:
                headline = "Coming up: \(joined(trips.prefix(4).map { "\($0.title) (\($0.phase == .live ? "under way" : "starts \(startsIn($0))"))" }))."
            default:
                var counts: [String] = []
                if live > 0 { counts.append("\(live) under way") }
                if upcoming > 0 { counts.append("\(upcoming) coming up") }
                if past > 0 { counts.append("\(past) wrapped up") }
                headline = "You have \(trips.count.pluralised("trip")) — \(joined(counts))."
            }
        }

        return EquiFacts(headline: headline, lines: lines, card: card, suggestions: suggestions)
    }

    private static func balanceAcross(_ trips: [Trip]) -> EquiFacts {
        let open = trips.filter { $0.hasPayments && abs($0.netBalance) >= SettlementEngine.epsilon }
        let card = EquiCard(kind: .trips, tripSet: .all, metric: .balance)
        let suggestions = ["Who paid the most?", "Tell me about my last trip"]

        guard !open.isEmpty else {
            return EquiFacts(
                headline: "You're square everywhere — nobody owes anybody on any of your trips.",
                lines: ["The user is square on every trip."],
                card: card,
                suggestions: suggestions
            )
        }

        let lines = open.map { trip in
            "\"\(trip.title)\": \(trip.netBalance > 0 ? "the user gets back" : "the user owes") \(Money.format(abs(trip.netBalance), code: trip.currencyCode))."
        }
        let owes = open.filter { $0.netBalance < 0 }
        let gets = open.filter { $0.netBalance > 0 }
        var parts: [String] = []
        if !owes.isEmpty { parts.append("you owe on " + joined(owes.map { "\($0.title) (\(Money.format(-$0.netBalance, code: $0.currencyCode)))" })) }
        if !gets.isEmpty { parts.append("you're owed on " + joined(gets.map { "\($0.title) (\(Money.format($0.netBalance, code: $0.currencyCode)))" })) }

        return EquiFacts(
            headline: "Across your trips, " + parts.joined(separator: ", and ") + ".",
            lines: lines,
            card: card,
            suggestions: suggestions
        )
    }

    // MARK: - No trip, or no data

    @MainActor
    private static func missing(_ query: EquiQuery, store: TripStore) -> EquiFacts {
        let resolveNext = EquiQueryReader.resolve(.next, trips: store.trips, focus: nil).first
        let resolvePrevious = EquiQueryReader.resolve(.previous, trips: store.trips, focus: nil).first

        switch query.scope {
        case .previous:
            var headline = "You haven't finished a trip yet"
            if let next = resolveNext { headline += " — \(next.title) is next, starting \(startsIn(next))" }
            return EquiFacts(
                headline: headline + ".",
                lines: [headline + "."],
                card: resolveNext.map { EquiCard(kind: .trip, tripID: $0.id) },
                suggestions: ["What's my next trip?", "Show my trips"],
                focusTripID: resolveNext?.id
            )
        case .next:
            var headline = "There's no trip coming up"
            if let last = resolvePrevious { headline += " — your last was \(last.title), which ended \(endedAgo(last))" }
            return EquiFacts(
                headline: headline + ".",
                lines: [headline + "."],
                card: resolvePrevious.map { EquiCard(kind: .recap, tripID: $0.id) },
                suggestions: ["Tell me about my last trip", "Show my trips"],
                focusTripID: resolvePrevious?.id
            )
        default:
            return EquiFacts(
                headline: "I couldn't tell which trip you meant — try its name?",
                lines: ["It wasn't clear which trip the user meant."],
                suggestions: ["Show my trips"]
            )
        }
    }

    @MainActor
    private static func chat(about trip: Trip?, store: TripStore) -> EquiFacts {
        var lines = ["Equi can answer questions about the user's trips: plans, bookings, costs, who paid, who owes."]
        lines.append("Their trips: " + joined(TripMatcher.byRelevance(store.trips).prefix(5).map { "\($0.title) (\($0.phase.label.lowercased()))" }) + ".")
        return EquiFacts(
            headline: "Hi! Ask me anything about your trips — what's next, where you're staying, who owes whom.",
            lines: lines,
            card: nil,
            suggestions: ["What's up next?", "Who still owes me?", "Tell me about my last trip"],
            allowsGeneralKnowledge: true,
            focusTripID: trip?.id
        )
    }

    private static func advice(for trip: Trip?) -> EquiFacts {
        guard let trip else {
            return EquiFacts(
                headline: "Tell me which trip you're thinking of and I'll help you plan for it.",
                suggestions: ["Show my trips"],
                allowsGeneralKnowledge: true
            )
        }
        var lines = tripLines(trip)
        let byKind = Dictionary(grouping: trip.items, by: \.kind)
        for (kind, items) in byKind.sorted(by: { $0.value.count > $1.value.count }) {
            lines.append("\(plural(kind).capitalized) booked: \(joined(items.prefix(4).map(\.title))).")
        }
        return EquiFacts(
            headline: "I can't check live info from here, but \(trip.title) runs \(trip.dateRange) in \(trip.destination) — \(trip.dayCount.pluralised("day")) to plan around.",
            lines: lines,
            card: nil,
            suggestions: ["What's still unbooked?", "Where am I staying?", "What's up next?"],
            allowsGeneralKnowledge: true,
            focusTripID: trip.id
        )
    }

    // MARK: - Lines

    private static func tripLines(_ trip: Trip) -> [String] {
        let dates = DateFormatter.cached("EEE d MMM yyyy")
        var status: String
        switch trip.phase {
        case .upcoming: status = "upcoming, starts \(startsIn(trip))"
        case .live: status = "under way now, \(trip.progressLabel.lowercased())"
        case .past: status = "finished, ended \(endedAgo(trip))"
        }
        let members = trip.travellers.filter { !trip.invitedIDs.contains($0.id) }
        return [
            "Trip: \"\(trip.title)\" in \(trip.destination), \(dates.string(from: trip.startDate)) to \(dates.string(from: trip.endDate)) (\(trip.dayCount.pluralised("day"))), \(status). Currency \(trip.currencyCode).",
            "On the trip: \(joined(members.map { name($0) }))."
        ]
    }

    private static func moneyLines(_ trip: Trip) -> [String] {
        let code = trip.currencyCode
        guard trip.hasPayments else { return ["No payments recorded yet."] }
        var lines = [
            "The user owes \(Money.format(trip.owed(by: Traveller.you.id), code: code)) and is owed \(Money.format(trip.owedTo(Traveller.you.id), code: code))."
        ]
        let transfers = trip.suggestedTransfers
        if transfers.isEmpty {
            lines.append("Everyone is settled up.")
        } else {
            lines.append("Payments that would settle everyone: " + transfers.prefix(6).map {
                "\(name(trip.traveller($0.from))) pays \(name(trip.traveller($0.to))) \(Money.format($0.amount, code: code))"
            }.joined(separator: "; ") + ".")
        }
        return lines
    }

    private static func squaringLine(_ recap: TripRecap) -> String {
        switch recap.squaring(.group) {
        case .nothingRecorded: "No payments were recorded, so nobody owes anything."
        case .square: "Everyone is settled up."
        case .open(let transfers, let pending): "Still open: \(transfers.count.pluralised("payment")) to make, \(pending.count) waiting for confirmation."
        }
    }

    // MARK: - Words

    private static func describe(_ item: ItineraryItem, in trip: Trip) -> String {
        var pieces = [DateFormatter.cached("EEE d MMM").string(from: item.day)]
        if let time = item.timeLabel { pieces.append(time) }
        pieces.append("\(item.kind.label.lowercased()): \(item.title)")
        if let vendor = item.vendorName { pieces.append("with \(vendor)") }
        if let flight = item.flight {
            pieces.append("flight \(flight.number)")
            if let from = flight.departureAirport, let to = flight.arrivalAirport { pieces.append("\(from) to \(to)") }
            if let landing = flight.scheduledArrival { pieces.append("lands \(DateFormatter.cached("HH:mm").string(from: landing))") }
        }
        if item.kind == .stay, let nights = nights(of: item, in: trip) { pieces.append(nights.pluralised("night")) }
        if item.cost > 0 { pieces.append(Money.format(item.cost, code: trip.currencyCode)) }
        if let payer = item.paidByID.flatMap(trip.traveller) { pieces.append("paid by \(name(payer))") }
        if item.isDisputed { pieces.append("disputed") }
        return pieces.joined(separator: ", ")
    }

    /// How many nights a stay covers: up to the next stay, or the end of the
    /// trip. Bookings carry a check-in date, not a length.
    static func nights(of stay: ItineraryItem, in trip: Trip) -> Int? {
        let calendar = Calendar.current
        let next = trip.items
            .filter { $0.kind == .stay && $0.day > stay.day }
            .map(\.day)
            .min() ?? calendar.startOfDay(for: trip.endDate)
        let nights = calendar.dateComponents([.day], from: stay.day, to: next).day ?? 0
        return nights > 0 ? nights : nil
    }

    /// "today at 14:00", "tomorrow", "on Tue 12 Oct at 09:40".
    private static func when(_ item: ItineraryItem) -> String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(item.day) { day = "today" }
        else if calendar.isDateInTomorrow(item.day) { day = "tomorrow" }
        else { day = "on " + DateFormatter.cached("EEE d MMM").string(from: item.day) }
        return item.timeLabel.map { "\(day) at \($0)" } ?? day
    }

    private static func startsIn(_ trip: Trip) -> String {
        let days = daysBetween(Date(), trip.startDate)
        switch days {
        case ..<1: return "today"
        case 1: return "tomorrow"
        case 2...13: return "in \(days) days"
        default: return "on \(DateFormatter.cached("d MMM yyyy").string(from: trip.startDate))"
        }
    }

    private static func endedAgo(_ trip: Trip) -> String {
        let days = daysBetween(trip.endDate, Date())
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        case 2...13: return "\(days) days ago"
        default: return "on \(DateFormatter.cached("d MMM yyyy").string(from: trip.endDate))"
        }
    }

    private static func daysBetween(_ from: Date, _ to: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day ?? 0
    }

    private static func name(_ traveller: Traveller?) -> String {
        guard let traveller else { return "someone" }
        return traveller.id == Traveller.you.id ? "you" : traveller.name
    }

    private static func plural(_ kind: ItineraryKind) -> String {
        switch kind {
        case .flight: "flights"
        case .train: "trains"
        case .drive: "transfers"
        case .stay: "stays"
        case .activity: "activities"
        case .meal: "meals"
        case .other: "other bookings"
        }
    }

    /// "a", "a and b", "a, b and c".
    private static func joined(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        default: return items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1]
        }
    }
}
