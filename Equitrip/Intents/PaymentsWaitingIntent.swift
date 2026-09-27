//
//  PaymentsWaitingIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Did anyone pay me?" — the payments people say they've made to you, with
/// a card to confirm them on.
///
/// Settling up only finishes when the person paid says yes, and that yes was
/// only ever given inside the app or on the watch. A claim sat there until
/// somebody opened the Settle tab; this is the version that takes one tap
/// from wherever you are.
struct PaymentsWaitingIntent: AppIntent {

    static let title: LocalizedStringResource = "Check Payments"
    static let description = IntentDescription(
        "Shows payments people say they've made to you, so you can confirm them.",
        categoryName: "Money"
    )
    static var supportedModes: IntentModes { .background }

    init() {}

    @MainActor
    func perform() async throws -> some ReturnsValue<Int> & ProvidesDialog & ShowsSnippetIntent {
        let store = try await IntentStores.store()
        let waiting = store.settlementsAwaitingYou

        let spoken: String
        if waiting.isEmpty {
            spoken = "Nobody's waiting for you to confirm a payment."
        } else {
            let said = waiting.prefix(3).map { entry in
                let name = entry.trip.traveller(entry.settlement.fromID)?.name ?? "Someone"
                return "\(name) says they paid you \(Money.format(entry.settlement.amount, code: entry.settlement.currencyCode)) on \(entry.trip.title)"
            }
            var sentence = ListFormatter.localizedString(byJoining: said)
            if waiting.count > 3 { sentence += ", and \(waiting.count - 3) more" }
            spoken = sentence + "."
        }

        return .result(
            value: waiting.count,
            dialog: IntentDialog(
                full: "\(spoken)",
                supporting: waiting.isEmpty ? "Nothing to confirm." : "\(waiting.count == 1 ? "One payment" : "\(waiting.count) payments") to confirm."
            ),
            snippetIntent: SettleRequestsSnippetIntent()
        )
    }
}
