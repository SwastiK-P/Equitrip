//
//  WhatsNextIntent.swift
//  Equitrip
//

import AppIntents
import Foundation
import SwiftUI

/// "What's next on my trip?" — the next few bookings, read out.
///
/// The watch's agenda and the "Up next" widget answer the same question on a
/// screen; this is the answer for when there isn't one — walking out of a
/// hotel, hands full, wondering when the train is.
struct WhatsNextIntent: AppIntent {

    static let title: LocalizedStringResource = "Get What's Next"
    static let description = IntentDescription(
        "Tells you what's coming up next on a trip — times, places and flight details.",
        categoryName: "Itinerary"
    )
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Trip")
    var trip: TripEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get what's next on \(\.$trip)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some ReturnsValue<[BookingEntity]> & ProvidesDialog & ShowsSnippetIntent {
        let store = try await IntentStores.store()
        guard !store.trips.isEmpty else { throw IntentFailure.noTrips }

        let target: Trip
        if let trip {
            guard let found = store.trip(trip.id) else { throw IntentFailure.tripNotFound }
            target = found
        } else if let likeliest = TripMatcher.byRelevance(store.trips).first(where: { $0.phase != .past }) {
            target = likeliest
        } else {
            throw $trip.needsValueError("Which trip?")
        }

        let ahead = UpNextSnippetModel.upcoming(on: target)
        let card = UpNextSnippetIntent(trip: TripEntity(target))

        guard let first = ahead.first else {
            return .result(
                value: [],
                dialog: "Nothing else is booked on \(target.title).",
                snippetIntent: card
            )
        }

        var spoken = "Next on \(target.title): \(Self.phrase(for: first))"
        if ahead.count > 1 {
            spoken += ", then " + ahead.dropFirst().map(Self.phrase(for:)).joined(separator: ", then ")
        }
        spoken += "."

        return .result(
            value: ahead.map { BookingEntity($0, in: target) },
            dialog: IntentDialog(full: "\(spoken)", supporting: "Here's what's next on \(target.title)."),
            snippetIntent: card
        )
    }

    /// "the flight to Rome at 7:40 tomorrow, gate 14, delayed 20 minutes" —
    /// the gate and the delay said out loud too, because with AirPods in
    /// there is no card to read them off.
    @MainActor
    private static func phrase(for item: ItineraryItem) -> String {
        var words = "\(item.title) \(when(item).lowercasedFirst)"
        if let flight = item.flight {
            if let gate = flight.departureGate { words += ", gate \(gate)" }
            if flight.status == .delayed, let minutes = flight.departureDelay, minutes > 0 {
                words += ", delayed \(minutes) minutes"
            } else if flight.status == .cancelled {
                words += ", cancelled"
            }
        }
        return words
    }

    @MainActor
    private static func when(_ item: ItineraryItem) -> String {
        let calendar = Calendar.current
        let dayWord: String
        if calendar.isDateInToday(item.date) { dayWord = "today" }
        else if calendar.isDateInTomorrow(item.date) { dayWord = "tomorrow" }
        else { dayWord = "on " + item.date.formatted(.dateTime.weekday(.wide).day().month(.wide)) }

        guard let time = item.time else { return dayWord.capitalizedFirst }
        return "At \(time.formatted(date: .omitted, time: .shortened)) \(dayWord)"
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
