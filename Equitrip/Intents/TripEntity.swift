//
//  TripEntity.swift
//  Equitrip
//

import AppIntents
import CoreSpotlight
import Foundation

/// A trip, as Siri, Spotlight and Shortcuts know it.
///
/// Adopts the calendar domain's *calendar* schema, and that is a fit rather
/// than a stretch: a trip is a shared calendar — a named span of days with a
/// set of people and a list of timed things on it — and a booking is an event
/// on it (`BookingEntity`). Taking the schema is what lets Apple Intelligence
/// understand "add a cooking class to the Goa trip" or "what's on my Rome trip
/// tomorrow" without a phrase written for either; a bespoke entity would only
/// ever answer the sentences somebody thought to register.
///
/// The widgets have their own `TripEntity` in `EquitripWidgets`, read from the
/// snapshot because the extension never signs in. The two never meet: each
/// target's App Intents metadata is its own.
@AppEntity(schema: .calendar.calendar)
struct TripEntity: nonisolated Identifiable, nonisolated IndexedEntity, nonisolated OwnershipProvidingEntity {

    static let defaultQuery = TripEntityQuery()

    /// The server's id — stable across launches, devices and reinstalls, which
    /// is what a saved shortcut or a synced Siri conversation stores.
    let id: UUID

    var title: String

    // Beyond the schema: Siri reads only the schema's fields, but Shortcuts
    // and the Spotlight attribute set below get these too.
    var destination: String
    var startDate: Date
    var endDate: Date
    var travellerNames: [String]

    /// The foreground activity the trip screen reports, so "this trip" means
    /// the one on screen. Declared in `NSUserActivityTypes`.
    static let viewActivityType = "com.swastik.Equitrip.viewTrip"

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(destination) · \(Self.span(from: startDate, to: endDate))",
            image: .init(systemName: "suitcase.rolling.fill")
        )
    }

    /// Everyone on a trip with more than one person on it can see its plan and
    /// its money, so the system should confirm before acting on it for you.
    nonisolated var ownership: EntityOwnership {
        travellerNames.count > 1 ? .shared : []
    }

    nonisolated var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.namedLocation = destination
        set.startDate = startDate
        set.endDate = endDate
        set.contentDescription = "\(destination), \(Self.span(from: startDate, to: endDate)). With \(travellerNames.joined(separator: ", "))."
        set.keywords = ["trip", "travel", destination] + travellerNames
        return set
    }

    @MainActor
    init(_ trip: Trip) {
        // Beyond-the-schema fields before `title` — see `BookingEntity.init`.
        destination = trip.destination
        startDate = trip.startDate
        endDate = trip.endDate
        travellerNames = trip.travellers.map(\.name)
        id = trip.id
        title = trip.title
    }

    nonisolated private static func span(from start: Date, to end: Date) -> String {
        start.formatted(.dateTime.day().month(.abbreviated)) + " – " + end.formatted(.dateTime.day().month(.abbreviated))
    }
}

/// Looks trips up in the signed-in account, whether or not the app is on
/// screen — see `AppContext`.
nonisolated struct TripEntityQuery: EntityStringQuery, IndexedEntityQuery {

    func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            identifiers.compactMap { store.trip($0) }.map(TripEntity.init)
        }
    }

    /// Matched on the words a person actually uses for a trip: its title, or
    /// where it's going. The framework does no filtering of its own here.
    func entities(matching string: String) async throws -> [TripEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            TripMatcher.trips(matching: string, in: store.trips).map(TripEntity.init)
        }
    }

    /// What a picker offers first: the trip under way, then what's next, then
    /// the rest newest first — the order a person reaches for them in.
    func suggestedEntities() async throws -> [TripEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            TripMatcher.byRelevance(store.trips).prefix(12).map(TripEntity.init)
        }
    }

    func reindexEntities(for identifiers: [TripEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndex.reindex()
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await SpotlightIndex.reindex()
    }
}
