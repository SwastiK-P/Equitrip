//
//  RemoveBookingIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Cancel the cooking class on the Goa trip" — the calendar schema's
/// *delete event*.
///
/// Siri confirms a delete on its own. A booking somebody has already paid for
/// gets a second, specific question, because removing it isn't tidying the
/// plan: it takes a payment off everyone's balance, and the general "delete
/// this event?" says nothing about that. The removal still files its audit
/// entry and notifies the trip, through `TripStore.removeItem`.
@AppIntent(schema: .calendar.deleteEvent)
struct RemoveBookingIntent {

    var entity: BookingEntity
    var span: BookingSpan?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = try await IntentStores.store()
        guard let trip = store.trip(entity.calendar.id),
              let item = trip.items.first(where: { $0.id == entity.id })
        else { throw IntentFailure.bookingNotFound }

        guard trip.youAreOrganiser else { throw IntentFailure.organiserOnly(trip.title) }

        if item.cost > 0, let payerID = item.paidByID {
            let payer = payerID == Traveller.you.id ? "your" : "\(trip.traveller(payerID)?.name ?? "someone")'s"
            try await requestConfirmation(
                actionName: .do,
                dialog: "\(item.title) has \(payer) \(Money.format(item.cost, code: trip.currencyCode)) payment on it. Removing it changes everyone's balance. Remove it anyway?"
            )
        }

        store.clearWriteFailure()
        store.removeItem(item.id, in: trip.id)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }
        return .result(dialog: "Removed \(item.title) from \(trip.title).")
    }
}
