//
//  OnscreenEntities.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// Tells Siri and Apple Intelligence what "this" is.
///
/// "Add a dinner to this trip", "who paid for this?", "send this to the
/// group" — every one of those needs the system to know which entity is on
/// screen, and it can only know if the screen says so. A detail screen
/// reports its one entity through the foreground `NSUserActivity`; a screen
/// of many rows reports each row on the row.
///
/// Kept as modifiers here rather than written inline in each screen: the trip
/// timeline's body is already about as much as the type checker will take in
/// one expression, and the annotation is the same three lines everywhere.
extension View {

    /// The trip a full screen is showing.
    func onscreenTrip(_ trip: Trip?) -> some View {
        let update = OnscreenActivity.trip(trip)
        return userActivity(TripEntity.viewActivityType, isActive: trip != nil, update)
    }

    /// The booking a detail sheet is showing.
    func onscreenBooking(_ item: ItineraryItem) -> some View {
        let update = OnscreenActivity.booking(item)
        return userActivity(BookingEntity.viewActivityType, update)
    }

    /// A trip's group chat, open.
    func onscreenChat(_ trip: Trip) -> some View {
        let update = OnscreenActivity.chat(trip)
        return userActivity(TripConversationEntity.viewActivityType, update)
    }

    /// One booking among many — a row on the timeline or the ledger.
    func bookingRowEntity(_ itemID: UUID) -> some View {
        let identifier = EntityIdentifier(for: BookingEntity.self, identifier: itemID)
        return appEntityIdentifier(identifier)
    }
}

/// The activity updates, built outside the view expressions that use them.
private enum OnscreenActivity {

    static func trip(_ trip: Trip?) -> (NSUserActivity) -> Void {
        let title = trip?.title
        // Not `trip.map { … }`: inferring `EntityIdentifier`'s generic
        // initialiser through a closure crashes the Xcode 27.0 compiler.
        var identifier: EntityIdentifier?
        if let trip { identifier = EntityIdentifier(for: TripEntity.self, identifier: trip.id) }
        return { [identifier] activity in
            activity.title = title
            activity.appEntityIdentifier = identifier
        }
    }

    static func chat(_ trip: Trip) -> (NSUserActivity) -> Void {
        let title = "\(trip.title) chat"
        let identifier = EntityIdentifier(for: TripConversationEntity.self, identifier: trip.id)
        return { activity in
            activity.title = title
            activity.appEntityIdentifier = identifier
        }
    }

    static func booking(_ item: ItineraryItem) -> (NSUserActivity) -> Void {
        let title = item.title
        let identifier = EntityIdentifier(for: BookingEntity.self, identifier: item.id)
        return { activity in
            activity.title = title
            activity.appEntityIdentifier = identifier
        }
    }
}
