//
//  TripConversationEntity.swift
//  Equitrip
//

import AppIntents
import Foundation

/// A trip's group chat, as Siri knows conversations.
///
/// Equitrip has exactly one conversation per trip and no direct messages, so
/// the conversation's id *is* the trip's id. That's what lets "tell the Goa
/// group I'm running late" work: Siri resolves "the Goa group" against these,
/// and the send lands in the same thread `TripChatView` shows.
///
/// Part of the messages domain, which is all-or-nothing — see
/// `SendChatMessageIntent` for the rest of the set.
@AppEntity(schema: .messages.conversation)
struct TripConversationEntity: nonisolated Identifiable, nonisolated AppEntity {

    static let defaultQuery = TripConversationQuery()

    let id: UUID

    var recipients: [ChatPersonEntity]
    var displayName: String
    var previewText: AttributedString
    var conversationName: String?
    var isRead: Bool
    var attributes: Set<ConversationAttribute>
    var dateLastActive: Date?

    static let viewActivityType = "com.swastik.Equitrip.viewChat"

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(String(previewText.characters))",
            image: .init(systemName: "bubble.left.and.bubble.right.fill")
        )
    }

    @MainActor
    init(_ trip: Trip, thread: ChatArchive.Thread?) {
        id = trip.id
        recipients = trip.travellers
            .filter { $0.id != Traveller.you.id && !trip.invitedIDs.contains($0.id) }
            .map(ChatPersonEntity.init)
        displayName = trip.title
        conversationName = trip.title
        previewText = AttributedString(Self.preview(of: thread?.latest, in: trip))
        isRead = thread?.isRead ?? true
        attributes = [ConversationAttribute(trip.phase)]
        dateLastActive = thread?.latest?.sentAt
    }

    /// "Ed: lobby at 7" — what a lock-screen preview would say.
    @MainActor
    private static func preview(of message: ChatMessage?, in trip: Trip) -> String {
        guard let message else { return "No messages yet" }
        let author = message.isMine ? "You" : trip.traveller(message.authorID)?.name ?? "Someone"
        return "\(author): \(message.preview)"
    }
}

nonisolated struct TripConversationQuery: EntityStringQuery {

    func entities(for identifiers: [TripConversationEntity.ID]) async throws -> [TripConversationEntity] {
        let store = try await IntentStores.store()
        return try await Self.conversations(for: identifiers, in: store)
    }

    /// "The Goa group", "Rome chat" — matched on the trip it belongs to.
    func entities(matching string: String) async throws -> [TripConversationEntity] {
        let store = try await IntentStores.store()
        let ids = await MainActor.run { TripMatcher.trips(matching: string, in: store.trips).map(\.id) }
        return try await Self.conversations(for: ids, in: store)
    }

    func suggestedEntities() async throws -> [TripConversationEntity] {
        let store = try await IntentStores.store()
        let ids = await MainActor.run { TripMatcher.byRelevance(store.trips).prefix(10).map(\.id) }
        return try await Self.conversations(for: Array(ids), in: store)
    }

    @MainActor
    static func conversations(for tripIDs: [UUID], in store: TripStore) async throws -> [TripConversationEntity] {
        let trips = tripIDs.compactMap { store.trip($0) }
        let threads = try await ChatArchive.threads(for: trips.map(\.id))
        return trips.map { TripConversationEntity($0, thread: threads[$0.id]) }
    }
}

/// Where the trip is in its life, as the schema's app-defined attribute set.
/// Raw values are persisted — append only.
@AppEnum(schema: .messages.conversationAttribute)
enum ConversationAttribute: String {
    case underway
    case upcoming
    case wrappedUp

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .underway: "Trip under way",
        .upcoming: "Upcoming trip",
        .wrappedUp: "Past trip"
    ]

    init(_ phase: Trip.Phase) {
        switch phase {
        case .live: self = .underway
        case .upcoming: self = .upcoming
        case .past: self = .wrappedUp
        }
    }
}

/// Opens a trip's chat — for Siri's "open the Goa chat", and for a
/// conversation picked in a Siri answer.
@AppIntent(schema: .system.open)
struct OpenTripChatIntent: OpenIntent {

    static let title: LocalizedStringResource = "Open Trip Chat"
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Chat")
    var target: TripConversationEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        AppNavigator.shared.go(.chat(tripID: target.id, draft: nil))
        return .result()
    }
}
