//
//  EquiContext.swift
//  Equitrip
//

import Foundation

/// Turns everything the app knows about the user's trips into the plain-text
/// briefing Equi is given before answering.
///
/// This is deliberately not scoped to "the current trip" — a question like
/// "which trip is cheapest?" or "do I owe anyone money anywhere?" needs the
/// whole portfolio, not just whichever one happens to be selected. It's
/// rebuilt fresh on every turn (see `EquiSession`) rather than baked into the
/// session once, so an expense added mid-conversation is visible on the very
/// next question.
enum EquiContext {

    /// Caps so a traveller with years of trips on the books doesn't blow past
    /// the on-device model's context window — which is small (a few thousand
    /// tokens shared across instructions, prompt *and* reply), so this errs
    /// well on the side of too little rather than risk a request that fails
    /// outright with `exceededContextWindowSize`. Ordered newest-first by
    /// `TripStore`, so a cap always drops the *oldest* trips and bookings —
    /// the ones least likely to be what's being asked about.
    ///
    /// `compact` is the fallback used after a context-window overflow: just
    /// the current trip, sharply trimmed. See `EquiIntelligence`.
    private static let maxTrips = 4
    private static let maxItemsPerTrip = 14
    private static let compactMaxItems = 8

    @MainActor
    static func build(store: TripStore, compact: Bool = false) -> String {
        let you = Traveller.you
        var lines: [String] = []

        lines.append("You are Equi, the trip assistant built into Equitrip, a group travel-planning and expense-splitting app.")
        lines.append("You're talking with \(you.name)\(you.email.map { " (\($0))" } ?? "") — everything below is their data.")
        lines.append("Today is \(longFormatter.string(from: Date())).")
        lines.append("")
        lines.append("Style: reply like a sharp, friendly travel buddy — a sentence or two by default, a short list only when the question genuinely calls for one. Never pad with disclaimers. Use the trip's own currency symbol. Never invent a trip, booking, amount or person that isn't listed below; if the answer isn't in this data, say so plainly instead of guessing.")
        lines.append("")
        lines.append(cardGuidance)

        guard !store.trips.isEmpty else {
            lines.append("")
            lines.append("They have no trips yet — if asked, tell them to start one from the Home tab.")
            return lines.joined(separator: "\n")
        }

        // Compact mode answers about one trip only — the one most likely to
        // be what a follow-up question meant — rather than every trip
        // trimmed further, which tends to lose the very detail being asked
        // about.
        let trips = compact
            ? Array([store.selectedTrip ?? store.currentTrip ?? store.trips.first].compactMap { $0 })
            : Array(store.trips.prefix(maxTrips))
        let itemCap = compact ? compactMaxItems : maxItemsPerTrip

        if !compact, store.trips.count > maxTrips {
            lines.append("")
            lines.append("(Showing their \(maxTrips) most recent trips of \(store.trips.count) total.)")
        }

        for trip in trips {
            lines.append(contentsOf: describe(trip: trip, for: you.id, itemCap: itemCap))
        }

        return lines.joined(separator: "\n")
    }

    /// What the `card` field on `EquiAnswer` means, in the model's terms.
    ///
    /// Phrased around the *question being asked* rather than around the card's
    /// contents, because that's the judgement being asked for: the model can
    /// see all this data already, so the only thing it's deciding is whether
    /// the answer is better looked at than read out.
    private static let cardGuidance = """
    You can also draw a card under your reply, by setting `card` (and naming the trip in `tripTitle`). Pick the one that answers the question at a glance:
    - `trip` — they asked about a trip as a whole: which one is next, when it is, what it's shaping up to cost.
    - `balance` — they asked about what they owe, what they're owed, or how to settle up.
    - `itinerary` — they asked what's happening next, today, or tomorrow.
    - `spending` — they asked where the money is going, or what's eating the budget.
    - `people` — they asked who's on a trip, who has paid for things, or how the group stands.
    - `text` — anything else. Advice, chit-chat, a yes or no, or a question about something not in the data.
    When you draw a card, keep the reply to a short sentence introducing it — the card already shows the figures, so don't read them out again.
    """

    // MARK: - Per trip

    @MainActor
    private static func describe(trip: Trip, for youID: UUID, itemCap: Int) -> [String] {
        var lines: [String] = ["", "### \(trip.title) — \(trip.destination)"]

        lines.append(
            "Dates: \(longFormatter.string(from: trip.startDate)) – \(longFormatter.string(from: trip.endDate)) "
            + "(\(trip.phase.label), \(trip.dayCount) days), currency \(trip.currencyCode)."
        )

        let names = trip.travellers.map { $0.id == youID ? "\($0.name) (the user)" : $0.name }
        lines.append("Travellers: \(names.joined(separator: ", ")).")
        lines.append("Projected cost so far: \(trip.projectedLabel).")

        if trip.showsBalance {
            let owe = trip.owed(by: youID)
            let owedToYou = trip.owedTo(youID)
            lines.append(
                "Money: the user owes \(Money.format(owe, code: trip.currencyCode)) and is owed "
                + "\(Money.format(owedToYou, code: trip.currencyCode)) on this trip."
            )

            let transfers = trip.suggestedTransfers
            if transfers.isEmpty {
                lines.append("Everyone is settled up here.")
            } else {
                let list = transfers.prefix(6).map { transfer in
                    let from = trip.traveller(transfer.from)?.name ?? "Someone"
                    let to = trip.traveller(transfer.to)?.name ?? "someone"
                    return "\(from) → \(to): \(Money.format(transfer.amount, code: trip.currencyCode))"
                }
                lines.append("Outstanding settlements: \(list.joined(separator: "; ")).")
            }
        }

        if trip.items.isEmpty {
            lines.append("Nothing booked yet.")
        } else {
            lines.append("Itinerary (\(trip.items.count) booking\(trip.items.count == 1 ? "" : "s")):")
            let sorted = trip.items.sorted { $0.date < $1.date }
            for item in sorted.prefix(itemCap) {
                lines.append(describeLine(item: item, trip: trip))
            }
            if sorted.count > itemCap {
                lines.append("… and \(sorted.count - itemCap) more bookings not shown.")
            }
        }

        return lines
    }

    private static func describeLine(item: ItineraryItem, trip: Trip) -> String {
        var pieces = [dayFormatter.string(from: item.day)]
        if let time = item.timeLabel { pieces.append(time) }
        pieces.append("\(item.kind.label): \(item.title)")
        if let vendor = item.vendorName { pieces.append("at \(vendor)") }
        if item.cost > 0 { pieces.append(Money.format(item.cost, code: trip.currencyCode)) }
        if let payer = item.paidByID.flatMap(trip.traveller) { pieces.append("paid by \(payer.name)") }
        if item.isDisputed { pieces.append("disputed") }
        return "- " + pieces.joined(separator: ", ")
    }

    // MARK: - Formatting

    private static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f
    }()
}
