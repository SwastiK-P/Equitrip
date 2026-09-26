//
//  ChatPersonEntity.swift
//  Equitrip
//

import AppIntents
import Foundation

/// A traveller, as the messages domain knows people — the author of a message
/// and a member of a conversation.
///
/// The server's profile id is both the entity id and the person's
/// application-defined identifier, so "reply to Ed" resolves to the Ed on the
/// trip rather than whichever Ed is in Contacts. The email is the handle, so
/// Siri can still line the two up.
@AppEntity(schema: .messages.messagePerson)
struct ChatPersonEntity: nonisolated Identifiable, nonisolated AppEntity {

    static let defaultQuery = ChatPersonQuery()

    let id: UUID

    var person: IntentPerson

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(person.displayName)", image: .init(systemName: "person.crop.circle"))
    }

    @MainActor
    init(_ traveller: Traveller) {
        id = traveller.id
        person = IntentPerson.traveller(traveller)
    }
}

nonisolated struct ChatPersonQuery: EntityStringQuery {

    func entities(for identifiers: [ChatPersonEntity.ID]) async throws -> [ChatPersonEntity] {
        let store = try await IntentStores.store(fresh: false)
        return await MainActor.run {
            let wanted = Set(identifiers)
            return Self.everyone(in: store.trips).filter { wanted.contains($0.id) }.map(ChatPersonEntity.init)
        }
    }

    func entities(matching string: String) async throws -> [ChatPersonEntity] {
        let store = try await IntentStores.store(fresh: false)
        return await MainActor.run {
            Self.everyone(in: TripMatcher.byRelevance(store.trips))
                .filter { $0.name.localizedStandardContains(string) || ($0.email?.localizedStandardContains(string) ?? false) }
                .map(ChatPersonEntity.init)
        }
    }

    func suggestedEntities() async throws -> [ChatPersonEntity] {
        let store = try await IntentStores.store(fresh: false)
        return await MainActor.run {
            Self.everyone(in: TripMatcher.byRelevance(store.trips))
                .filter { $0.id != Traveller.you.id }
                .prefix(12)
                .map(ChatPersonEntity.init)
        }
    }

    @MainActor
    private static func everyone(in trips: [Trip]) -> [Traveller] {
        var seen: Set<UUID> = []
        return trips.flatMap(\.travellers).filter { seen.insert($0.id).inserted }
    }
}
