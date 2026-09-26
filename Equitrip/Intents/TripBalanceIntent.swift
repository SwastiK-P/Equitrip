//
//  TripBalanceIntent.swift
//  Equitrip
//

import AppIntents
import Foundation
import SwiftUI

/// "Where do I stand on the Goa trip?" — answered out loud, without opening
/// the app.
///
/// The same figure the Settle tab leads with: what's left after confirmed
/// transfers (`remainingBalance`), broken into the fewest payments that would
/// clear it. Spoken as who pays whom, not as a signed number, because "minus
/// two thousand four hundred" is not a sentence anyone says.
///
/// With no trip named and none under way, it answers for every trip at once —
/// the question Home's hero answers.
struct TripBalanceIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Trip Balance"
    static let description = IntentDescription(
        "Tells you what you owe or are owed on a trip, and who needs to pay whom to settle up.",
        categoryName: "Money"
    )
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Trip")
    var trip: TripEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get my balance on \(\.$trip)")
    }

    init() {}

    init(trip: TripEntity?) {
        self.trip = trip
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<Double> & ProvidesDialog & ShowsSnippetIntent {
        let store = try await IntentStores.store()
        guard !store.trips.isEmpty else { throw IntentFailure.noTrips }

        let chosen: Trip?
        if let trip {
            guard let found = store.trip(trip.id) else { throw IntentFailure.tripNotFound }
            chosen = found
        } else {
            let live = store.trips.filter { $0.phase == .live }
            chosen = live.count == 1 ? live[0] : nil
        }

        let answer = chosen.map(Self.answer(for:)) ?? Self.portfolioAnswer(store)
        return .result(
            value: answer.net,
            dialog: IntentDialog(full: "\(answer.full)", supporting: "\(answer.supporting)"),
            snippetIntent: BalanceSnippetIntent(trip: chosen.map(TripEntity.init))
        )
    }

    private struct Answer {
        var net: Double
        var full: String
        var supporting: String
    }

    /// One trip: what's left after confirmed transfers, and who pays whom.
    @MainActor
    private static func answer(for trip: Trip) -> Answer {
        let you = Traveller.you.id
        let net = trip.remainingBalance(for: you)
        let transfers = trip.suggestedTransfers
            .filter { $0.from == you || $0.to == you }
            .map { transfer in
                let other = transfer.from == you ? transfer.to : transfer.from
                return (name: trip.traveller(other)?.name ?? "Someone", amount: transfer.amount, youPay: transfer.from == you)
            }
        let waiting = trip.pendingSettlements.filter(\.youAreRecipient).count
        var full = sentence(net: net, transfers: transfers, code: trip.currencyCode, trip: trip.title)
        if waiting > 0 {
            full += waiting == 1
                ? " One payment is waiting for you to confirm."
                : " \(waiting) payments are waiting for you to confirm."
        }
        return Answer(
            net: net,
            full: full,
            // The card shows the figures; the line above it only has to
            // say which trip they're for.
            supporting: net == 0 ? "All square on \(trip.title)." : "Here's where you stand on \(trip.title)."
        )
    }

    /// Every trip at once, in the most common currency, from what's still
    /// *left* on each — the same figure the single-trip answer uses. The
    /// store's portfolio totals count what was ever owed, so somebody who had
    /// paid everything back was still told they owed it.
    @MainActor
    private static func portfolioAnswer(_ store: TripStore) -> Answer {
        let code = store.primaryCurrency
        let you = Traveller.you.id
        let balances = store.trips.filter { $0.currencyCode == code }.map { $0.remainingBalance(for: you) }
        let owed = balances.filter { $0 > 0 }.reduce(0, +)
        let owe = -balances.filter { $0 < 0 }.reduce(0, +)
        let full: String = switch (owed > 0, owe > 0) {
        case (false, false): "You're all square across your trips."
        case (true, false): "Across your trips, you're owed \(Money.format(owed, code: code))."
        case (false, true): "Across your trips, you owe \(Money.format(owe, code: code))."
        case (true, true): "Across your trips, you're owed \(Money.format(owed, code: code)) and you owe \(Money.format(owe, code: code))."
        }
        return Answer(net: owed - owe, full: full, supporting: "Here's every trip.")
    }

    /// "On Goa, you owe Ed ₹1,200 and Priya ₹800."
    static func sentence(net: Double, transfers: [(name: String, amount: Double, youPay: Bool)], code: String, trip: String) -> String {
        guard net != 0, !transfers.isEmpty else {
            return "You're all square on \(trip)."
        }
        let pay = transfers.filter(\.youPay).map { "\($0.name) \(Money.format($0.amount, code: code))" }
        let get = transfers.filter { !$0.youPay }.map { "\($0.name) \(Money.format($0.amount, code: code))" }

        var parts: [String] = []
        if !pay.isEmpty { parts.append("you owe \(ListFormatter.localizedString(byJoining: pay))") }
        if !get.isEmpty { parts.append("\(ListFormatter.localizedString(byJoining: get)) \(get.count == 1 ? "owes" : "owe") you") }
        return "On \(trip), " + parts.joined(separator: ", and ") + "."
    }
}
