//
//  TripCountdownIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "How long until Goa?" — days to go, or how far into the trip you are,
/// on the trip's own photograph.
///
/// The question people ask about a trip more than any other before it starts,
/// and one the app only ever answered by opening Home.
struct TripCountdownIntent: AppIntent {

    static let title: LocalizedStringResource = "Get Trip Countdown"
    static let description = IntentDescription(
        "Tells you how many days until a trip starts, or which day of it you're on.",
        categoryName: "Itinerary"
    )
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Trip")
    var trip: TripEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get the countdown to \(\.$trip)")
    }

    init() {}

    @MainActor
    func perform() async throws -> some ReturnsValue<Int> & ProvidesDialog & ShowsSnippetIntent {
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

        let days = TripStatusModel.daysUntil(target)
        let spoken: String = switch target.phase {
        case .upcoming:
            days == 1 ? "\(target.title) starts tomorrow." : "\(days) days until \(target.title)."
        case .live:
            "It's \(target.progressLabel.lowercased()) on \(target.title)."
        case .past:
            "\(target.title) wrapped up on \(target.endDate.formatted(.dateTime.day().month(.wide)))."
        }

        return .result(
            value: max(0, days),
            // The card carries the number; the line above it names the trip.
            dialog: IntentDialog(full: "\(spoken)", supporting: "Here's \(target.title)."),
            snippetIntent: TripStatusSnippetIntent(trip: TripEntity(target))
        )
    }
}
