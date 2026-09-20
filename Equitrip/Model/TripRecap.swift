//
//  TripRecap.swift
//  Equitrip
//

import SwiftUI

/// A finished trip, read back as a story: what it cost, where the money went,
/// who carried it, and whether everyone is square.
///
/// Every figure is a question put to `Trip` — `share(of:for:)`, `paid(by:)`,
/// `remainingBalance(for:)`, `suggestedTransfers` — and never re-derived here.
/// A recap that did its own division would eventually disagree with the ledger
/// it summarises, and the one screen people screenshot to the group chat is
/// the worst place for that to show up.
struct TripRecap {

    /// Whose trip the recap is telling: everybody's, or yours.
    enum Lens: Hashable, CaseIterable {
        case group, you

        var label: String {
            switch self {
            case .group: "The group"
            case .you: "Just you"
            }
        }
    }

    struct Slice: Identifiable {
        let kind: ItineraryKind
        let amount: Double
        let count: Int
        var id: ItineraryKind { kind }
    }

    struct DaySpend: Identifiable {
        let date: Date
        let amount: Double
        /// Outside the trip's own dates — a deposit paid a month early.
        let isOutside: Bool
        var id: Date { date }
    }

    struct Contributor: Identifiable {
        let traveller: Traveller
        let paid: Double
        let paidCount: Int
        let share: Double
        let remaining: Double
        let presence: String?
        var id: UUID { traveller.id }
        var isYou: Bool { traveller.id == Traveller.you.id }
    }

    struct Highlight: Identifiable {
        let symbol: String
        let tint: Color
        let label: String
        let value: String
        let detail: String?
        var id: String { label }
    }

    /// Where the money side landed.
    enum Squaring {
        /// Nobody recorded paying for anything, so there was never a debt.
        case nothingRecorded
        /// Every balance cleared and nothing is waiting on an answer.
        case square(moved: Double, transfers: Int)
        /// Still transfers to make, or claims to confirm.
        case open(transfers: [SettlementEngine.Transfer], pending: [Settlement])
    }

    let trip: Trip

    private var you: UUID { Traveller.you.id }
    private var code: String { trip.currencyCode }

    // MARK: Totals

    func total(_ lens: Lens) -> Double {
        switch lens {
        case .group: trip.projectedCost
        case .you: trip.yourShare
        }
    }

    func amount(of item: ItineraryItem, _ lens: Lens) -> Double {
        switch lens {
        case .group: item.cost
        case .you: trip.share(of: item, for: you)
        }
    }

    /// Whether a booking is part of the story this lens tells. Being a bearer,
    /// not having a price: a free walking tour you were on is still yours.
    func includes(_ item: ItineraryItem, _ lens: Lens) -> Bool {
        switch lens {
        case .group: true
        case .you: trip.bearers(of: item).contains { $0.id == you }
        }
    }

    func items(_ lens: Lens) -> [ItineraryItem] {
        trip.items.filter { includes($0, lens) }
    }

    /// People who were actually on the trip — invitations never answered don't
    /// count towards "each".
    var members: [Traveller] {
        trip.travellers.filter { !trip.invitedIDs.contains($0.id) }
    }

    var perDay: Double { total(.group) / Double(trip.dayCount) }
    var perPerson: Double { members.isEmpty ? 0 : total(.group) / Double(members.count) }

    /// Your part of the whole, 0…1.
    var yourFraction: Double {
        let whole = total(.group)
        return whole > 0 ? min(1, total(.you) / whole) : 0
    }

    var yourPaid: Double { trip.paid(by: you) }
    var yourRemaining: Double { trip.remainingBalance(for: you) }

    /// The days you were there — all of them, unless you left early.
    var yourDays: Int { trip.departureDayIndex(you).map { min($0, trip.dayCount) } ?? trip.dayCount }

    // MARK: Breakdown

    func slices(_ lens: Lens) -> [Slice] {
        let grouped = Dictionary(grouping: items(lens), by: \.kind)
        return grouped
            .map { kind, items in
                Slice(kind: kind, amount: items.reduce(0) { $0 + amount(of: $1, lens) }, count: items.count)
            }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    /// One bar per day of the trip, plus any day outside it that has spending
    /// on it — so the bars add up to the headline rather than quietly losing
    /// the deposit.
    func days(_ lens: Lens) -> [DaySpend] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        let inside = (0..<trip.dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let totals = Dictionary(grouping: items(lens), by: \.day)
            .mapValues { $0.reduce(0) { $0 + amount(of: $1, lens) } }
        let outside = totals.filter { !inside.contains($0.key) && $0.value > 0 }.keys
        let insideSet = Set(inside)

        return (inside + outside).sorted().map {
            DaySpend(date: $0, amount: totals[$0] ?? 0, isOutside: !insideSet.contains($0))
        }
    }

    func biggest(_ lens: Lens) -> ItineraryItem? {
        items(lens).filter { amount(of: $0, lens) > 0 }.max { amount(of: $0, lens) < amount(of: $1, lens) }
    }

    // MARK: People

    var contributors: [Contributor] {
        members
            .map { person in
                Contributor(
                    traveller: person,
                    paid: trip.paid(by: person.id),
                    paidCount: trip.items.filter { $0.paidByID == person.id }.count,
                    share: trip.cost(for: person.id),
                    remaining: trip.remainingBalance(for: person.id),
                    presence: trip.presenceLabel(person.id)
                )
            }
            .sorted { ($0.paid, $0.share) > ($1.paid, $1.share) }
    }

    /// The things you picked up the bill for, largest first.
    var yourPayments: [ItineraryItem] {
        trip.items.filter { $0.paidByID == you && $0.cost > 0 }.sorted { $0.cost > $1.cost }
    }

    // MARK: Highlights

    func highlights(_ lens: Lens) -> [Highlight] {
        var tiles: [Highlight] = []
        let pool = items(lens)

        if let top = biggest(lens) {
            tiles.append(Highlight(
                symbol: "sparkles",
                tint: Palette.amberDeep,
                label: lens == .group ? "Biggest splurge" : "Your biggest spend",
                value: Money.format(amount(of: top, lens).rounded(), code: code),
                detail: top.title
            ))
        }

        let counted: [(ItineraryKind, String, String)] = [
            (.flight, "In the air", "flight"),
            (.stay, "Places stayed", "stay"),
            (.meal, "Around the table", "meal"),
            (.activity, "Out and about", "activity"),
            (.train, "On the rails", "train"),
            (.drive, "On the road", "transfer")
        ]
        for (kind, label, noun) in counted {
            let count = pool.filter { $0.kind == kind }.count
            guard count > 0 else { continue }
            let plural = noun == "activity" ? "activities" : nil
            tiles.append(Highlight(symbol: kind.symbol, tint: kind.tint, label: label, value: count.pluralised(noun, plural), detail: nil))
        }

        if tiles.count < 4 {
            tiles.append(Highlight(
                symbol: "calendar",
                tint: AppTheme.accent,
                label: lens == .group ? "Days away" : "Days you were there",
                value: (lens == .group ? trip.dayCount : yourDays).pluralised("day"),
                detail: nil
            ))
        }
        return Array(tiles.prefix(4))
    }

    // MARK: Settling

    func squaring(_ lens: Lens) -> Squaring {
        guard trip.showsBalance else { return .nothingRecorded }

        let confirmed = trip.settlements.filter { $0.status == .confirmed }
        let me = you
        let involvesYou: (UUID, UUID) -> Bool = { from, to in from == me || to == me }

        switch lens {
        case .group:
            if trip.isFullySettled {
                return .square(moved: confirmed.reduce(0) { $0 + $1.amount }, transfers: confirmed.count)
            }
            return .open(transfers: trip.suggestedTransfers, pending: trip.pendingSettlements)

        case .you:
            let transfers = trip.suggestedTransfers.filter { involvesYou($0.from, $0.to) }
            let pending = trip.pendingSettlements.filter { involvesYou($0.fromID, $0.toID) }
            if transfers.isEmpty, pending.isEmpty {
                let yours = confirmed.filter { involvesYou($0.fromID, $0.toID) }
                return .square(moved: yours.reduce(0) { $0 + $1.amount }, transfers: yours.count)
            }
            return .open(transfers: transfers, pending: pending)
        }
    }

    // MARK: Sharing

    /// Plain text for the share sheet — the recap as a message to the group.
    var shareText: String {
        var lines = ["\(trip.title) — \(trip.dateRange), \(trip.dayCount.pluralised("day"))"]
        lines.append("\(Money.format(total(.group).rounded(), code: code)) across \(trip.items.count.pluralised("booking")), about \(Money.format(perPerson.rounded(), code: code)) each.")
        if let top = slices(.group).first {
            lines.append("Most of it went on \(top.kind.label.lowercased()): \(Money.format(top.amount.rounded(), code: code)).")
        }
        if let payer = contributors.first, payer.paid > 0 {
            lines.append("\(payer.isYou ? "I" : payer.traveller.name) fronted the most: \(Money.format(payer.paid.rounded(), code: code)).")
        }
        if case .square = squaring(.group) { lines.append("Everyone's square.") }
        lines.append("— via Equitrip")
        return lines.joined(separator: "\n")
    }
}
