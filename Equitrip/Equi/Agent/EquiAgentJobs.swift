//
//  EquiAgentJobs.swift
//  Equitrip
//

import Foundation

/// The jobs Equi can do with its hands on the app, written as the path a
/// person would take through the screens.
///
/// Each one checks what it can before taking the screen — an expense with no
/// amount, a settlement with nobody owed — and answers in the chat instead, so
/// a run only starts when it can finish. What the request leaves open and the
/// trip can't settle (who paid, how you paid, which trip) is asked mid-run, at
/// the point on screen where it matters.
@MainActor
enum EquiAgentJobs {

    // MARK: - Log an expense

    static func logExpense(_ request: EquiCommandReader.ExpenseRequest, store: TripStore) -> EquiCommandReader.Reading {
        guard let amount = request.amount else {
            return .reply("How much was it? Tell me the amount and what it was for — like “add ₹1,200 for dinner”.")
        }

        let candidates: [Trip]
        if let trip = request.trip {
            candidates = [trip]
        } else {
            let live = store.trips.filter { $0.phase == .live }
            candidates = live.isEmpty ? store.trips.filter { $0.phase == .upcoming }.sorted { $0.startDate < $1.startDate } : live
        }
        guard !candidates.isEmpty else {
            return .reply("There's no trip running or coming up to add that to. Start one from Home and I'll log it there.")
        }

        // A named payer who isn't on the trip is a mistake to point out, not
        // a question to ask.
        if candidates.count == 1, let name = request.payerName, payer(named: name, on: candidates[0]) == nil {
            return .reply("I couldn't find \(name.capitalized) on \(candidates[0].title) — who paid for it?")
        }

        let title = request.title
        let knownTrip = candidates.count == 1 ? candidates[0] : nil
        let money = knownTrip.map { Money.format(amount, code: $0.currencyCode) } ?? Money.plainAmount(amount)

        return .task(EquiAgentTask(
            title: "Logging an expense",
            symbol: "plus.circle.fill",
            steps: 7 + (request.sharedWith == nil ? 0 : 2),
            opening: "On it — logging \(money) for \(title.lowercased())\(knownTrip.map { " on \($0.title)" } ?? ""). Watch the screen; I'll be right back.",
            tripID: knownTrip?.id,
            cleanup: ["home.sheet.close"]
        ) { agent in
            var trip: Trip
            if let knownTrip {
                trip = knownTrip
            } else {
                let option = try await agent.ask(EquiAgentQuestion(
                    text: "Which trip is “\(title)” for?",
                    options: candidates.prefix(4).map { .init(id: $0.id.uuidString, label: $0.title, symbol: $0.symbol) }
                ))
                guard let picked = candidates.first(where: { $0.id.uuidString == option.id }) else { throw CancellationError() }
                trip = picked
            }
            trip = store.trip(trip.id) ?? trip
            agent.setContext("\(short(trip)) · \(trip.travellers.count.pluralised("person", "people"))", tripID: trip.id)
            let money = Money.format(amount, code: trip.currencyCode)

            try await agent.tap("tab.home", "Opening Home", symbol: "house")
            try await agent.tap("home.expense", "Opening a new expense", symbol: "plus.circle", settle: 0.8)
            try await agent.type(title, into: "quickAdd.title", "Naming it “\(title)”", symbol: "character.cursor.ibeam")
            try await agent.type(Money.plainAmount(amount), into: "quickAdd.amount", "Entering \(money)", symbol: "number")

            // Who it's for: everyone, unless the words named people.
            var participants = Set(trip.travellers.map(\.id))
            var split = SplitMode.equal
            if let names = request.sharedWith {
                let named = names.compactMap { payer(named: $0, on: trip) }
                if !named.isEmpty {
                    let keep = Set(named.map(\.id)).union([Traveller.you.id])
                    for traveller in trip.travellers where !keep.contains(traveller.id) {
                        try await agent.tap("quickAdd.who.\(traveller.id)", "Leaving \(traveller.name) off", symbol: "person.badge.minus", settle: 0.25)
                    }
                    participants = keep
                    split = .participants
                    try await agent.tap("quickAdd.split.participants", "Splitting between \(keep.count)", symbol: "person.2", settle: 0.3)
                }
            }

            // Who paid: said, or asked — never assumed. The sheet starts on
            // "you", which is right most of the time and wrong exactly when
            // it matters.
            var paidBy: Traveller?
            if request.payerIsYou {
                paidBy = trip.traveller(Traveller.you.id)
            } else if let name = request.payerName {
                paidBy = payer(named: name, on: trip)
            }
            if paidBy == nil {
                let people = trip.travellers.sorted { lhs, _ in lhs.id == Traveller.you.id }
                let option = try await agent.ask(EquiAgentQuestion(
                    text: "Who paid \(money) for “\(title)”?",
                    options: people.map { .init(id: $0.id.uuidString, label: $0.id == Traveller.you.id ? "You" : $0.name, traveller: $0) }
                ))
                paidBy = people.first { $0.id.uuidString == option.id }
            }
            guard let payer = paidBy else { throw CancellationError() }
            let payerLabel = payer.id == Traveller.you.id ? "You" : payer.name

            try await agent.tap(
                "quickAdd.payer.\(payer.id)",
                payer.id == Traveller.you.id ? "Marking you as the payer" : "Marking \(payer.name) as the payer",
                symbol: "creditcard",
                settle: 0.35
            )

            let day = QuickAddSheet.day(for: trip)
            try await agent.commit("quickAdd.save", "Adding it to \(trip.title)", symbol: "checkmark.circle") {
                let item = QuickAddSheet.makeItem(
                    title: title,
                    amount: amount,
                    day: day,
                    stamp: Date(),
                    split: split,
                    participants: participants,
                    payerID: payer.id
                )
                store.addItem(item, to: trip.id)
                QuickAddSheet.classify(item) { store.addItem($0, to: trip.id) }
            }

            let heads = split == .participants ? participants.count : trip.travellers.count
            let each = Money.format(Money.wholeShare(of: amount, heads: heads), code: trip.currencyCode)
            let whoPaid = payer.id == Traveller.you.id ? "You paid" : "\(payer.name) paid"
            return EquiAgentOutcome(
                title: "Expense logged",
                headline: title,
                value: money,
                detail: "\(payerLabel) paid · \(each) each · split \(heads) ways",
                chat: "Done — “\(title)” is on \(trip.title) for \(money). \(whoPaid), split \(heads) ways, so that's \(each) each.",
                tripID: trip.id,
                suggestions: ["Where do I stand on \(trip.title)?", "Where's the money going?"]
            )
        })
    }

    /// The trip's name up to its first colon or dash — "Kashi" from "Kashi:
    /// Ghats, Aarti & Old Banaras" — for the Live Activity's one-line slots,
    /// where the whole title truncates to nothing useful.
    static func short(_ trip: Trip) -> String {
        let head = trip.title.split(whereSeparator: { ":—–|".contains($0) }).first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? trip.title
        return head.count >= 3 ? head : trip.title
    }

    private static func payer(named name: String, on trip: Trip) -> Traveller? {
        TripMatcher.traveller(named: name, on: trip)
    }

    // MARK: - Settle up

    /// One transfer you owe, as the Settle tab lists it.
    private struct Debt {
        let trip: Trip
        let to: Traveller
        let amount: Double

        var money: String { Money.format(amount, code: trip.currencyCode) }
    }

    static func settleUp(_ request: EquiCommandReader.SettleRequest, store: TripStore) -> EquiCommandReader.Reading {
        let you = Traveller.you.id
        let trips = request.trip.map { [$0] } ?? TripMatcher.byRelevance(store.trips)
        let named: (Traveller) -> Bool = { person in
            guard let name = request.personName else { return true }
            return person.name == name
        }

        let debts: [Debt] = trips.flatMap { trip in
            trip.suggestedTransfers
                .filter { $0.from == you && trip.pendingSettlement(from: you, to: $0.to) == nil }
                .compactMap { transfer in trip.traveller(transfer.to).map { Debt(trip: trip, to: $0, amount: transfer.amount) } }
        }
        .filter { named($0.to) }

        if debts.isEmpty {
            // Say what *is* true between you, rather than just "no".
            if let name = request.personName {
                for trip in trips {
                    guard let person = trip.travellers.first(where: { $0.name == name }) else { continue }
                    if let pending = trip.pendingSettlement(from: you, to: person.id) {
                        return .reply("You've already told \(person.name) you paid \(Money.format(pending.amount, code: trip.currencyCode)) on \(trip.title) — it's waiting on them to confirm.")
                    }
                    if let owed = trip.suggestedTransfers.first(where: { $0.from == person.id && $0.to == you }) {
                        return .reply("\(person.name) owes you \(Money.format(owed.amount, code: trip.currencyCode)) on \(trip.title), so there's nothing for you to pay.")
                    }
                }
                return .reply("You don't owe \(name) anything right now.")
            }
            return .reply("You don't owe anyone right now — you're square.")
        }

        let single = debts.count == 1 ? debts[0] : nil
        let opening: String
        if let single {
            opening = "On it — settling \(single.money) with \(single.to.name) on \(single.trip.title). I'll take it from here."
        } else {
            opening = "On it — you owe a few people, so I'll check which one as I go."
        }

        return .task(EquiAgentTask(
            title: "Settling up",
            symbol: "arrow.left.arrow.right.circle.fill",
            steps: 6 + (request.amount == nil ? 0 : 1),
            opening: opening,
            tripID: single?.trip.id,
            cleanup: ["settle.sheet.close"]
        ) { agent in
            var debt: Debt
            if let single {
                debt = single
            } else {
                let option = try await agent.ask(EquiAgentQuestion(
                    text: "Who are you settling with?",
                    options: debts.prefix(4).map { .init(id: "\($0.trip.id)|\($0.to.id)", label: "\($0.to.name) · \($0.money)", traveller: $0.to) }
                ))
                guard let picked = debts.first(where: { "\($0.trip.id)|\($0.to.id)" == option.id }) else { throw CancellationError() }
                debt = picked
            }
            agent.setContext("\(short(debt.trip)) · \(debt.money) to \(debt.to.name)", tripID: debt.trip.id)

            // Part of it, if that's what was said — never more than is owed.
            let amount = min(request.amount ?? debt.amount, debt.amount)
            let money = Money.format(amount, code: debt.trip.currencyCode)

            try await agent.tap("tab.settle", "Opening Settle", symbol: "arrow.left.arrow.right")
            await agent.reveal("settle-trip-\(debt.trip.id)", in: "settle.scroll")
            try await agent.tap("settle.pay.\(debt.trip.id).\(debt.to.id)", "Settling up with \(debt.to.name)", symbol: "arrow.up.right.circle", settle: 0.8)

            if amount < debt.amount {
                try await agent.type(Money.plainAmount(amount), into: "settleUp.amount", "Paying \(money) of \(debt.money)", symbol: "number")
            }

            var method = request.method
            if method == nil {
                let options: [PaymentMethod] = [.upi, .cash, .transfer]
                let option = try await agent.ask(EquiAgentQuestion(
                    text: "How did you pay \(debt.to.name) \(money)?",
                    options: options.map { .init(id: $0.rawValue, label: $0.label, symbol: $0.symbol) }
                ))
                method = PaymentMethod(rawValue: option.id)
            }
            guard let method else { throw CancellationError() }

            try await agent.tap("settleUp.method.\(method.rawValue)", "Paid by \(method.label)", symbol: method.symbol, settle: 0.35)
            try await agent.commit("settleUp.submit", "Marking \(money) as paid", symbol: "checkmark.circle") {
                store.createSettlement(tripID: debt.trip.id, toID: debt.to.id, amount: amount, method: method, proofURL: nil, note: "")
            }

            return EquiAgentOutcome(
                title: "Marked as paid",
                headline: "To \(debt.to.name)",
                value: money,
                detail: "\(method.label) · waiting for \(debt.to.name) to confirm",
                chat: "Done — I've told \(debt.to.name) you paid \(money) by \(method.label.lowercased()) on \(debt.trip.title). It moves your balance once they confirm it.",
                tripID: debt.trip.id,
                suggestions: ["Who still owes me?", "Where do I stand on \(debt.trip.title)?"]
            )
        })
    }
}
