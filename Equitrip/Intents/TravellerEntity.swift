//
//  TravellerEntity.swift
//  Equitrip
//

import AppIntents
import Foundation

/// A person on one of your trips, for the places Siri needs to ask "who?" —
/// who paid, mostly.
///
/// Not the calendar schema's attendee (`TravellerAttendee`), which exists only
/// inside a booking and can't be picked on its own. This one is looked up by
/// name across every trip, and an intent then checks the person is actually
/// on the trip it's acting on.
struct TravellerEntity: nonisolated Identifiable, nonisolated AppEntity {

    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Traveller"
    nonisolated static let defaultQuery = TravellerEntityQuery()

    let id: UUID

    @Property(title: "Name")
    var name: String

    let isYou: Bool

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(isYou ? "You" : name)",
            image: .init(systemName: "person.crop.circle")
        )
    }

    init(id: UUID, name: String, isYou: Bool) {
        self.id = id
        self.isYou = isYou
        self.name = name
    }

    @MainActor
    init(_ traveller: Traveller) {
        self.init(id: traveller.id, name: traveller.name, isYou: traveller.id == Traveller.you.id)
    }
}

nonisolated struct TravellerEntityQuery: EntityStringQuery {

    func entities(for identifiers: [TravellerEntity.ID]) async throws -> [TravellerEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            let wanted = Set(identifiers)
            return Self.everyone(in: store.trips).filter { wanted.contains($0.id) }.map(TravellerEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [TravellerEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            let people = Self.everyone(in: TripMatcher.byRelevance(store.trips))
            let query = string.trimmingCharacters(in: .whitespaces)
            if ["me", "i", "myself"].contains(query.lowercased()) {
                return people.filter { $0.id == Traveller.you.id }.map(TravellerEntity.init)
            }
            return people.filter { $0.name.localizedStandardContains(query) }.map(TravellerEntity.init)
        }
    }

    /// You first, then the people on the trip you're most likely talking about.
    func suggestedEntities() async throws -> [TravellerEntity] {
        let store = try await IntentStores.store()
        return await MainActor.run {
            Self.everyone(in: TripMatcher.byRelevance(store.trips)).prefix(12).map(TravellerEntity.init)
        }
    }

    /// Everyone across `trips`, once each, you first.
    @MainActor
    private static func everyone(in trips: [Trip]) -> [Traveller] {
        var seen: Set<UUID> = []
        var people: [Traveller] = []
        for traveller in [Traveller.you] + trips.flatMap(\.travellers) where seen.insert(traveller.id).inserted {
            people.append(traveller)
        }
        return people
    }
}
