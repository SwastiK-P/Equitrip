//
//  RespondToSettlementIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Confirm" on a Siri card: yes, that payment reached me.
///
/// Confirm only. Saying a payment *didn't* arrive is a claim about somebody
/// else, and the app keeps it on the review sheet, next to their proof — the
/// card's "Review" goes there. The checks are the watch's (`WatchBridge`):
/// the request still exists, it's still pending, and it's yours to answer —
/// the recipient-only rule the database enforces too, said here in words.
///
/// It waits for the server before it returns. The card is drawn again the
/// moment this finishes, and a "Confirmed" that later rolls back is the one
/// answer worse than a slow one.
struct RespondToSettlementIntent: AppIntent {

    static let title: LocalizedStringResource = "Confirm Payment"
    static let isDiscoverable = false

    @Parameter(title: "Payment")
    var settlementID: String

    @Parameter(title: "Trip")
    var tripID: String

    init() {}

    init(settlementID: UUID, tripID: UUID) {
        self.settlementID = settlementID.uuidString
        self.tripID = tripID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let settlementUUID = UUID(uuidString: settlementID),
              let tripUUID = UUID(uuidString: tripID)
        else { throw IntentFailure.settlementNotFound }

        let store = try await IntentStores.store()
        if store.trip(tripUUID) == nil { await store.sync(includeInvitations: false) }

        guard let settlement = store.trip(tripUUID)?.settlements.first(where: { $0.id == settlementUUID }) else {
            throw IntentFailure.settlementNotFound
        }
        guard settlement.status == .pending else { throw IntentFailure.alreadyAnswered }
        guard settlement.youAreRecipient else { throw IntentFailure.notYourSettlement }

        store.clearWriteFailure()
        store.respondToSettlement(settlement, with: .confirmed, in: tripUUID)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }

        SettlementAnswers.remember(settlementUUID)
        return .result()
    }
}

/// Payments confirmed from a card in this run of the app, so the card can
/// show the row as "Confirmed" rather than have it vanish from under the
/// finger that just pressed it.
@MainActor
enum SettlementAnswers {
    private(set) static var recent: [UUID] = []

    static func remember(_ id: UUID) {
        recent.removeAll { $0 == id }
        recent.append(id)
        if recent.count > 12 { recent.removeFirst() }
    }
}
