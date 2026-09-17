//
//  AddBookingIntent.swift
//  Equitrip
//

import AppIntents
import Foundation
import GeoToolbox

/// "Add a cooking class at 11 on Saturday to the Goa trip" — the calendar
/// schema's *create event*, as a booking.
///
/// Siri does the language: it pulls the title, the time, the place and the
/// people out of the sentence, asks for whatever's missing, and confirms. This
/// turns the answer into a booking the way the itinerary's own add does, with
/// one deliberate gap: no cost. A spoken booking is a plan, and the price, the
/// split and who paid are the editor's questions — asked with the people and
/// the figures on screen, not guessed from a sentence.
///
/// Organisers only, as on the timeline: the "Add booking" button is theirs.
@AppIntent(schema: .calendar.createEvent)
struct AddBookingIntent {

    var title: String
    var startDate: Date
    var endDate: Date?
    var location: BookingLocation?
    var calendar: TripEntity
    var isAllDay: Bool
    var recurrence: Calendar.RecurrenceRule?
    var attendees: [TravellerAttendee]
    var note: AttributedString?

    @MainActor
    func perform() async throws -> some ReturnsValue<BookingEntity> & ProvidesDialog {
        let store = try await IntentStores.store()
        guard let trip = store.trip(calendar.id) else { throw IntentFailure.tripNotFound }
        guard trip.youAreOrganiser else { throw IntentFailure.organiserOnly(trip.title) }
        guard recurrence == nil else { throw IntentFailure.noRepeats }

        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let people = try BookingPeople.travellers(for: attendees, on: trip)

        var item = ItineraryItem(
            title: name,
            vendor: location?.vendorName ?? "",
            kind: .activity,
            date: Calendar.current.startOfDay(for: startDate),
            time: isAllDay ? nil : startDate,
            participantIDs: people.isEmpty ? Set(trip.travellers.map(\.id)) : people,
            createdByID: Traveller.you.id
        )
        // Split follows the kind, as the editor's default does — a room is
        // shared by who's in it, a flight by everyone.
        item.kind = await ActivityIconSuggester.kind(for: name)
        item.split = item.kind.defaultSplit
        item.suggestedSymbol = await ActivityIconSuggester.symbol(for: name, kind: item.kind)

        store.clearWriteFailure()
        store.addItem(item, to: trip.id)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }

        let saved = store.trip(trip.id) ?? trip
        let when = isAllDay
            ? startDate.formatted(.dateTime.weekday(.wide).day().month(.wide))
            : startDate.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute())
        return .result(
            value: BookingEntity(item, in: saved),
            dialog: "Added \(name) to \(trip.title), \(when). Add what it costs in Equitrip when you know."
        )
    }
}

/// Who a booking is for, from the people Siri named.
enum BookingPeople {

    /// The travellers `attendees` mean on `trip`. A person that came from
    /// this app carries their id; one Siri found by name is matched on it.
    /// Somebody who isn't on the trip is an error, not a silent drop — a
    /// booking quietly missing a person changes what everyone else owes.
    @MainActor
    static func travellers(for attendees: [TravellerAttendee], on trip: Trip) throws -> Set<UUID> {
        var ids: Set<UUID> = []
        for attendee in attendees {
            if let id = attendee.person.travellerID, trip.traveller(id) != nil {
                ids.insert(id)
            } else if let match = TripMatcher.traveller(named: attendee.person.displayName, on: trip) {
                ids.insert(match.id)
            } else {
                throw IntentFailure.notOnTrip(attendee.person.displayName)
            }
        }
        return ids
    }
}

extension BookingLocation {
    /// What goes in a booking's vendor field: the place's name when it has
    /// one, else the address as said.
    var vendorName: String {
        switch self {
        case .address(let address):
            return address
        case .place(let place):
            return place.commonName ?? ""
        }
    }
}
