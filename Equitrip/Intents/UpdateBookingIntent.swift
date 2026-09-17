//
//  UpdateBookingIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Move the Rome train to 10" — the calendar schema's *update event*.
///
/// Every field is optional, and absent means "leave it": a sentence changes
/// one or two things about a booking, never all of them. Location is the one
/// field where "clear it" and "didn't mention it" differ, so it reads the
/// parameter's value state rather than just its value.
///
/// Changing who's on a booking that has a cost is changing what people owe,
/// so that one change asks again, out loud, with the figure in the question —
/// Siri's own confirmation says "update the booking", which isn't the same
/// thing as "change four people's balances".
@AppIntent(schema: .calendar.updateEvent)
struct UpdateBookingIntent {

    var event: BookingEntity
    var title: String?
    var attendees: [TravellerAttendee]?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool?
    var calendar: TripEntity?
    var recurrence: Calendar.RecurrenceRule?
    var note: String?
    var location: BookingLocation?
    var span: BookingSpan?

    @MainActor
    func perform() async throws -> some ReturnsValue<BookingEntity> & ProvidesDialog {
        let store = try await IntentStores.store()
        guard let trip = store.trip(event.calendar.id),
              let before = trip.items.first(where: { $0.id == event.id })
        else { throw IntentFailure.bookingNotFound }

        guard trip.youAreOrganiser else { throw IntentFailure.organiserOnly(trip.title) }
        if let calendar, calendar.id != trip.id { throw IntentFailure.cannotMoveTrips }
        guard recurrence == nil else { throw IntentFailure.noRepeats }

        var item = before

        if let title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { item.title = trimmed }
        }

        if case .set(let place) = $location.valueState {
            item.vendor = place?.vendorName ?? ""
        }

        // A new start moves the day and the clock together; "all day" drops the
        // clock and keeps the day.
        if let startDate {
            item.date = Calendar.current.startOfDay(for: startDate)
            item.time = (isAllDay ?? (item.time == nil)) ? nil : startDate
        } else if let isAllDay {
            if isAllDay {
                item.time = nil
            } else if item.time == nil {
                item.time = .at(9, 0, on: item.date)
            }
        }

        if let attendees {
            let people = try BookingPeople.travellers(for: attendees, on: trip)
            item.participantIDs = people.isEmpty ? Set(trip.travellers.map(\.id)) : people

            let sharesMove = item.cost > 0 && item.participantIDs != before.participantIDs
                && (item.split == .participants || item.split == .custom || item.split == .individual)
            if sharesMove {
                // Before the write, and a cancel throws: nothing changes unless
                // the person says yes to the money moving.
                try await requestConfirmation(
                    actionName: .set,
                    dialog: "That changes who shares the \(Money.format(item.cost, code: trip.currencyCode)) for \(item.title). Update it?"
                )
            }
        }

        guard item != before else {
            return .result(value: BookingEntity(before, in: trip), dialog: "\(before.title) already looks like that.")
        }

        store.clearWriteFailure()
        store.updateItem(item, in: trip.id)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }

        let saved = store.trip(trip.id) ?? trip
        return .result(value: BookingEntity(item, in: saved), dialog: "Updated \(item.title) on \(trip.title).")
    }
}
