//
//  SiriDonations.swift
//  Equitrip
//

import AppIntents
import Foundation

/// Tells Siri what people do in the app, so it can learn the habits and offer
/// the next one — "log an expense on Goa" on the lock screen after dinner, the
/// trip chat when the group's usually messaging.
///
/// None of this happens by itself. The system donates only the intents *it*
/// runs; a tap in the app that does the same thing teaches it nothing unless
/// it's donated here. Donated after the action, with the same parameters an
/// intent would need to repeat it — and never from inside `perform()`, where
/// the system has already done it.
@MainActor
enum SiriDonations {

    /// A new expense from quick add. Only the shapes `LogExpenseIntent` can
    /// replay — split across everyone, or carried by the payer — and only on
    /// the first save: the sheet saves again once the category's inferred,
    /// and that second save is the app, not the person.
    static func expenseLogged(_ item: ItineraryItem, on tripID: UUID, in store: TripStore) {
        guard let trip = store.trip(tripID),
              !trip.items.contains(where: { $0.id == item.id }),
              item.cost > 0,
              let payerID = item.paidByID,
              let payer = trip.traveller(payerID)
        else { return }

        let split: ExpenseSplit
        switch item.split {
        case .equal: split = .everyone
        case .individual where item.participantIDs == [payerID]: split = .payerOnly
        default: return
        }

        let intent = LogExpenseIntent(
            amount: item.cost,
            purpose: item.title,
            trip: TripEntity(trip),
            payer: TravellerEntity(payer),
            split: split
        )
        _ = IntentDonationManager.shared.donate(intent: intent)
    }

    /// A trip opened from Home or the trip list.
    static func tripOpened(_ trip: Trip) {
        _ = IntentDonationManager.shared.donate(intent: OpenTripIntent(target: TripEntity(trip)))
    }

    /// A message typed into a trip's chat — addressed the way Siri addresses a
    /// group, by its members (see `ChatDestination`).
    static func messageSent(_ text: String, in trip: Trip) {
        let members = trip.travellers
            .filter { $0.id != Traveller.you.id && !trip.invitedIDs.contains($0.id) }
            .map(ChatPersonEntity.init)
        guard !members.isEmpty, !text.isEmpty else { return }

        let intent = SendChatMessageIntent()
        intent.content = AttributedString(text)
        intent.destination = .messagePeople(members)
        _ = IntentDonationManager.shared.donate(intent: intent)
    }
}
