//
//  SettlementEngine.swift
//  Equitrip
//

import SwiftUI

// MARK: - Settlement

/// A direct transfer between two travellers, outside any one booking.
///
/// The ledger already knows who fronted what for a booking; this is the other
/// half — the money that actually moved to close the gap. It starts as one
/// person's claim and stays that way, structurally, until the other side
/// agrees: `status` only ever leaves `.pending` by the recipient's own hand,
/// never the payer's. That asymmetry is the whole feature. A balance nobody
/// can move by typing a number into their own app is a balance worth trusting.
struct Settlement: Identifiable, Hashable {
    enum Status: String, Codable, Hashable {
        case pending, confirmed, declined

        var label: String {
            switch self {
            case .pending: "Pending"
            case .confirmed: "Confirmed"
            case .declined: "Declined"
            }
        }

        var symbol: String {
            switch self {
            case .pending: "clock.fill"
            case .confirmed: "checkmark.seal.fill"
            case .declined: "xmark.seal.fill"
            }
        }

        var tint: Color {
            switch self {
            case .pending: Palette.amber
            case .confirmed: AppTheme.positive
            case .declined: AppTheme.danger
            }
        }
    }

    let id: UUID
    let tripID: UUID
    /// Who sent the money — paying down what they owe.
    let fromID: UUID
    /// Who received it — being paid back.
    let toID: UUID
    var amount: Double
    let currencyCode: String
    var method: PaymentMethod
    /// A screenshot of the transfer, for a method that leaves one.
    var proofURL: URL?
    var note: String
    var status: Status
    let createdByID: UUID
    let createdAt: Date
    var respondedByID: UUID?
    var respondedAt: Date?

    init(
        id: UUID = UUID(),
        tripID: UUID,
        fromID: UUID,
        toID: UUID,
        amount: Double,
        currencyCode: String,
        method: PaymentMethod = .cash,
        proofURL: URL? = nil,
        note: String = "",
        status: Status = .pending,
        createdByID: UUID? = nil,
        createdAt: Date = Date(),
        respondedByID: UUID? = nil,
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.tripID = tripID
        self.fromID = fromID
        self.toID = toID
        self.amount = amount
        self.currencyCode = currencyCode
        self.method = method
        self.proofURL = proofURL
        self.note = note
        self.status = status
        self.createdByID = createdByID ?? fromID
        self.createdAt = createdAt
        self.respondedByID = respondedByID
        self.respondedAt = respondedAt
    }

    /// You're the one who paid.
    var youArePayer: Bool { fromID == Traveller.you.id }
    /// You're the one who's owed a say on it.
    var youAreRecipient: Bool { toID == Traveller.you.id }
    var isPending: Bool { status == .pending }
}

// MARK: - Minimising transfers

/// Turns a trip's outstanding balances into the fewest transfers that clear
/// every one of them.
///
/// Two passes. Finding the *true* minimum is a set-partition problem —
/// NP-hard — so this is the pair worth actually shipping:
///
/// 1. **Cancel exact matches.** Any debtor whose balance exactly mirrors some
///    creditor's settles in one transfer between just the two of them.
/// 2. **Greedy on the remainder.** Sort what's left by size and let the
///    largest creditor absorb as much of the largest debtor's balance as it
///    can, repeating until both lists are spent.
///
/// The first pass is the one worth explaining, because skipping it is the
/// natural-looking mistake: pure greedy (largest against largest, nothing
/// else) is optimal when the whole group nets down cleanly, but it's easy to
/// beat the moment two people's balances happen to match. Five travellers with
/// balances `+8000, +4000, −3000, −4000, −5000` settle in three transfers if
/// the `+4000` and `−4000` clear each other directly first; pure greedy, which
/// always reaches for the *largest* creditor rather than a *matching* one,
/// pairs the `+4000` against a `−5000` instead and needs four transfers to
/// untangle the remainder. That gap doesn't stay theoretical on a group trip —
/// two people splitting one thing evenly is exactly how a matching pair shows
/// up — so the cheap first pass earns its place.
///
/// What's left after both passes always clears in at most `n − 1` transfers
/// for `n` people carrying a balance — the theoretical floor, since each
/// transfer here fully zeroes at least one side of it.
enum SettlementEngine {
    struct Transfer: Identifiable, Hashable {
        let from: UUID
        let to: UUID
        var amount: Double

        var id: String { "\(from.uuidString)→\(to.uuidString)" }
    }

    /// Below this, in a trip's own currency, a balance counts as settled.
    /// Splitting an odd total across a group leaves fractions of a paisa on
    /// the ledger; those shouldn't produce a transfer of their own.
    static let epsilon = 0.01

    /// - Parameter balances: net position per traveller — positive means the
    ///   group owes them, negative means they owe the group. Ledger balance
    ///   plus whatever's already moved through confirmed direct settlements;
    ///   see `Trip.remainingBalance(for:)`, which is what callers should hand
    ///   in rather than the raw ledger figure.
    static func minimalTransfers(balances: [UUID: Double]) -> [Transfer] {
        var debtors = balances
            .filter { $0.value < -epsilon }
            .map { (id: $0.key, amount: -$0.value) }
            .sorted { $0.amount > $1.amount }

        var creditors = balances
            .filter { $0.value > epsilon }
            .map { (id: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        var transfers: [Transfer] = []

        // Pass one: a debt that exactly cancels a credit clears in the one
        // transfer between those two people, rather than being folded into
        // whatever the greedy pass would otherwise route it through.
        for debtorIndex in debtors.indices where debtors[debtorIndex].amount > epsilon {
            guard let creditorIndex = creditors.firstIndex(where: {
                abs($0.amount - debtors[debtorIndex].amount) <= epsilon
            }) else { continue }

            let amount = (debtors[debtorIndex].amount * 100).rounded() / 100
            transfers.append(Transfer(from: debtors[debtorIndex].id, to: creditors[creditorIndex].id, amount: amount))
            debtors[debtorIndex].amount = 0
            creditors[creditorIndex].amount = 0
        }

        // Pass two: largest against largest, on whatever's left. Each step
        // fully clears at least one side, so this can't run longer than the
        // two lists combined.
        var di = 0, ci = 0

        while di < debtors.count, ci < creditors.count {
            if debtors[di].amount <= epsilon { di += 1; continue }
            if creditors[ci].amount <= epsilon { ci += 1; continue }

            let amount = min(debtors[di].amount, creditors[ci].amount)
            // Rounded to the cent: floating-point subtraction below otherwise
            // leaves transfers like ₹499.99999999997 on screen.
            let rounded = (amount * 100).rounded() / 100
            if rounded > epsilon {
                transfers.append(Transfer(from: debtors[di].id, to: creditors[ci].id, amount: rounded))
            }

            debtors[di].amount -= amount
            creditors[ci].amount -= amount
        }

        // Biggest first: it's the payment most likely to need discussing, and
        // the order the two passes leave them in is otherwise arbitrary.
        return transfers.sorted { $0.amount > $1.amount }
    }
}

// MARK: - Trip integration

extension Trip {
    /// What a confirmed direct settlement does to each side's balance: the
    /// payer's debt shrinks (their balance moves toward zero, i.e. up), the
    /// recipient's credit shrinks (theirs moves toward zero, i.e. down) — by
    /// the same amount, because it's the same money.
    ///
    /// Only `.confirmed` rows count. A `.pending` claim is exactly that: a
    /// claim. Letting it move the balance before the other side agrees is the
    /// bug this whole feature exists to not have — it would let anyone zero
    /// out a debt by typing a number into their own app.
    private func confirmedSettlementDelta(for travellerID: UUID) -> Double {
        settlements
            .filter { $0.status == .confirmed }
            .reduce(0) { total, settlement in
                if settlement.fromID == travellerID { return total + settlement.amount }
                if settlement.toID == travellerID { return total - settlement.amount }
                return total
            }
    }

    /// The balance after every settled transfer is accounted for — the figure
    /// the minimiser actually works from, and the one "you owe / you're owed"
    /// should read once settling starts.
    func remainingBalance(for travellerID: UUID) -> Double {
        balance(for: travellerID) + confirmedSettlementDelta(for: travellerID)
    }

    /// The fewest transfers that would clear the trip from here, given what's
    /// already been paid and confirmed.
    var suggestedTransfers: [SettlementEngine.Transfer] {
        let balances = Dictionary(uniqueKeysWithValues: travellers.map { ($0.id, remainingBalance(for: $0.id)) })
        return SettlementEngine.minimalTransfers(balances: balances)
    }

    /// Settlements still waiting on the recipient's answer.
    var pendingSettlements: [Settlement] { settlements.filter { $0.status == .pending } }

    /// Nothing left to move, and there was something to begin with — the
    /// distinction `showsBalance` already draws for the ledger applies here
    /// too, for the same reason.
    var isFullySettled: Bool { showsBalance && suggestedTransfers.isEmpty && pendingSettlements.isEmpty }

    /// A pending claim covering (all or part of) a given suggested transfer,
    /// if the same two people already have one in flight — so the Settle tab
    /// can show "waiting on Priya" instead of offering to ask twice.
    func pendingSettlement(from fromID: UUID, to toID: UUID) -> Settlement? {
        pendingSettlements.first { $0.fromID == fromID && $0.toID == toID }
    }
}
