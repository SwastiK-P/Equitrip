//
//  IntentStores.swift
//  Equitrip
//

import AppIntents
import Foundation

/// The store an intent acts through, or the reason Siri should give instead.
///
/// `AppContext` answers "is there a store?"; an intent needs that answer in
/// the one form Siri and Shortcuts can speak. A plain `Error` reaches the
/// person as "something went wrong", so every failure here is either one of
/// the system's own (`signin`) or an `IntentFailure` with real words in it.
nonisolated enum IntentStores {

    /// `fresh: false` for snippets and entity lookups, which run many times
    /// over one request and must not each cost a round trip — see
    /// `AppContext.store(fresh:)`.
    static func store(fresh: Bool = true) async throws -> TripStore {
        guard let store = await AppContext.shared.store(fresh: fresh) else {
            throw AppIntentError.UserActionRequired.signin
        }
        // A sync that failed on an empty store means we know nothing — and
        // answering "you have no trips" to that is worse than saying so.
        if let failure = await MainActor.run(body: { store.trips.isEmpty ? store.state.failure : nil }) {
            throw IntentFailure.couldNotLoad(failure)
        }
        return store
    }
}

/// Failures an intent explains in its own words.
nonisolated enum IntentFailure: Error, CustomLocalizedStringResourceConvertible {
    case couldNotLoad(String)
    case tripNotFound
    case bookingNotFound
    case noTrips
    case notSaved(String)
    case notYours
    case notOnTrip(String)
    case modelUnavailable(String)
    case messageNotFound
    case messageNotSent
    case organiserOnly(String)
    case noRepeats
    case cannotMoveTrips
    case cannotMarkUnread
    case cannotSchedule
    case noVoiceMessages
    case noSharedTrip(String)
    case nothingToSend
    case settlementNotFound
    case alreadyAnswered
    case notYourSettlement

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .cannotSchedule: "Equitrip can't schedule messages. It'll send as soon as you say."
        case .noVoiceMessages: "Equitrip chats don't take voice messages yet."
        case .noSharedTrip(let names): "You're not on a trip with \(names)."
        case .nothingToSend: "There's nothing to send."
        case .settlementNotFound: "That payment isn't on the trip any more."
        case .alreadyAnswered: "That payment has already been answered."
        case .notYourSettlement: "Only the person who was paid can confirm that."
        case .organiserOnly(let trip): "You can only change bookings you added to \(trip)."
        case .noRepeats: "Equitrip bookings don't repeat. Add each one on its own day."
        case .cannotMoveTrips: "A booking can't move to a different trip. Remove it and add it to the other one."
        case .cannotMarkUnread: "Equitrip can't mark a chat as unread."
        case .couldNotLoad(let reason): "Couldn't reach your trips. \(reason)"
        case .tripNotFound: "That trip isn't in Equitrip any more."
        case .bookingNotFound: "That booking isn't on the trip any more."
        case .noTrips: "You're not on any trips yet. Start one in Equitrip."
        case .notSaved(let reason): "That didn't save. \(reason)"
        case .notYours: "Only the person who sent that can change it."
        case .notOnTrip(let name): "\(name) isn't on that trip."
        case .modelUnavailable(let reason): "\(reason)"
        case .messageNotFound: "That message isn't in the chat any more."
        case .messageNotSent: "The message didn't send. Open the chat to try again."
        }
    }
}
