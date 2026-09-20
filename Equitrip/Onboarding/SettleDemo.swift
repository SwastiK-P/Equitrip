//
//  SettleDemo.swift
//  Equitrip
//

import SwiftUI

/// The trip onboarding argues with.
///
/// Nine real expenses across five people, and every figure on the second
/// screen is derived from them rather than typed in beside them. That matters
/// more than it sounds: a hand-written "you owe ₹3,000" next to a hand-written
/// list of receipts is a promise the app hasn't made yet, and the first time
/// somebody adds a tenth receipt to make the scatter look better the two stop
/// agreeing. Here the totals, the balances and the payments all fall out of
/// `expenses`, so the pitch is the product doing its actual job on a small
/// input — and it stays true whatever anybody edits.
struct SettleDemo {

    // MARK: - Pieces

    struct Expense: Identifiable {
        let id = UUID()
        let title: String
        let kind: ItineraryKind
        let amount: Double
        let payer: Traveller

        /// Where it lands in the pile, in unit coordinates of the stage.
        ///
        /// Hand-placed, not random, and not on any grid either. Random
        /// reliably stacks two receipts on one spot, leaves a bald patch
        /// somewhere else, reshuffles every launch so nobody can tune it, and
        /// gives a different composition to every person who opens the app.
        /// But the first pass at placing them by hand fell into two tidy
        /// columns alternating down the page, which is worse than random: a
        /// pattern that regular stops reading as a mess at all, and the mess
        /// is the entire argument the page is making. So the x values wander
        /// across the full width, the vertical gaps are all different sizes,
        /// and consecutive receipts land far apart — which also gives the
        /// deal somewhere to go, since they arrive in this order.
        ///
        /// The x values run wide enough that several receipts hang off the
        /// side of the screen. That's the point: a pile that fits neatly
        /// inside the margins is a list with the rows knocked askew, and this
        /// has to look like more than the screen can hold. Reading every
        /// figure isn't the job — three or four of them is enough to see what
        /// kind of thing they are.
        ///
        /// They lie flat. Each one carried a couple of degrees of tilt at
        /// first, on the theory that scattered paper doesn't land square —
        /// but nine slightly crooked cards read as a rendering fault rather
        /// than a pile, and the position alone already says scattered.
        let spot: UnitPoint
    }

    /// One payment that clears part of the trip.
    struct Transfer: Identifiable {
        let from: Traveller
        let to: Traveller
        let amount: Double

        /// Derived from the pair rather than a fresh `UUID`, because the list
        /// is recomputed on every pass — minted ids would make SwiftUI think
        /// three different rows had arrived each time and replay the reveal.
        var id: String { "\(from.id)-\(to.id)" }
    }

    // MARK: - Trip

    let name: String
    let currency: String
    let people: [Traveller]
    let expenses: [Expense]

    /// Computed once at construction. Both are read from inside `body`, and
    /// a settlement pass per frame is work nobody asked for.
    let transfers: [Transfer]
    /// What each person laid out, biggest first — the card's "who paid" strip,
    /// and the thing the payments underneath are the consequence of.
    let paid: [(person: Traveller, amount: Double)]

    init(name: String, currency: String, people: [Traveller], expenses: [Expense]) {
        self.name = name
        self.currency = currency
        self.people = people
        self.expenses = expenses

        let total = expenses.reduce(0) { $0 + $1.amount }

        // The demo splits everything across the whole group, so one share
        // each. Anything cleverer belongs in `Trip`, which already has it.
        let laidOut = people.map { person in
            (
                person: person,
                amount: expenses.filter { $0.payer.id == person.id }.reduce(0) { $0 + $1.amount }
            )
        }
        let byID = Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })
        // Whole shares, with the leftover on whoever laid out the most, so the
        // balances still net to zero.
        let holder = laidOut.indices.max { laidOut[$0].amount < laidOut[$1].amount } ?? 0
        let shares = Money.evenSplit(total, heads: people.count, holder: holder)
        let balances = Dictionary(uniqueKeysWithValues: zip(laidOut, shares).map { ($0.person.id, $0.amount - $1) })

        self.paid = laidOut.sorted { $0.amount > $1.amount }
        // The real minimiser, not a copy of it — see `SettlementEngine`, which
        // now carries the two-pass reasoning this file used to own alone.
        self.transfers = SettlementEngine.minimalTransfers(balances: balances)
            .compactMap { transfer in
                guard let from = byID[transfer.from], let to = byID[transfer.to] else { return nil }
                return Transfer(from: from, to: to, amount: transfer.amount)
            }
    }

    // MARK: - Figures

    var total: Double { expenses.reduce(0) { $0 + $1.amount } }

    /// Every debt the group is carrying before anything is netted off: each
    /// expense leaves everyone who wasn't the payer owing the payer a slice of
    /// it. This is the number the card is claiming to beat, and it's why the
    /// claim isn't marketing — nine receipts really are thirty-six IOUs.
    var grossDebts: Int { expenses.count * Swift.max(0, people.count - 1) }

    // MARK: - Goa

    static let goa = SettleDemo(
        name: "Goa escape",
        currency: "INR",
        people: [.you, .ed, .krishna, .mattew, .kim],
        expenses: [
            // Paid: you 18,000 · Ed 14,000 · Kim 7,000 · Krishna 6,000 ·
            // Mattew 5,000. Total 50,000, so 10,000 each — which nets to
            // three payments rather than four, because Krishna's 4,000 debt
            // cancels Ed's 4,000 credit outright. Worth preserving if these
            // are ever edited: it's the difference between the card's
            // headline claim and a list with an awkward fourth line in it.
            //
            // Listed biggest first, which is also the order they're dealt in.
            .init(
                title: "Beach villa", kind: .stay, amount: 12_000, payer: .you,
                spot: UnitPoint(x: 0.38, y: 0.03)
            ),
            .init(
                title: "Flights", kind: .flight, amount: 11_000, payer: .ed,
                spot: UnitPoint(x: 0.74, y: 0.13)
            ),
            .init(
                title: "Seafood dinner", kind: .meal, amount: 6_000, payer: .krishna,
                spot: UnitPoint(x: 0.18, y: 0.24)
            ),
            .init(
                title: "Scuba diving", kind: .activity, amount: 5_000, payer: .kim,
                spot: UnitPoint(x: 0.62, y: 0.33)
            ),
            .init(
                title: "Airport cabs", kind: .drive, amount: 5_000, payer: .mattew,
                spot: UnitPoint(x: 0.84, y: 0.45)
            ),
            .init(
                title: "Bike rentals", kind: .drive, amount: 3_500, payer: .you,
                spot: UnitPoint(x: 0.22, y: 0.51)
            ),
            .init(
                title: "Kayaks", kind: .activity, amount: 3_000, payer: .ed,
                spot: UnitPoint(x: 0.55, y: 0.62)
            ),
            .init(
                title: "Beach lunch", kind: .meal, amount: 2_500, payer: .you,
                spot: UnitPoint(x: 0.16, y: 0.74)
            ),
            .init(
                title: "Sunset cruise", kind: .activity, amount: 2_000, payer: .kim,
                spot: UnitPoint(x: 0.72, y: 0.86)
            )
        ]
    )
}
