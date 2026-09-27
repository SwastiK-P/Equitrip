//
//  ChatMessageEntity.swift
//  Equitrip
//

import AppIntents
import CoreLocation
import Foundation
import UniformTypeIdentifiers
import GeoToolbox
import LinkPresentation

/// One message in a trip's group chat, as Siri knows messages.
///
/// Built from the same `ChatMessage` the thread draws, read through
/// `ChatArchive` so Siri can hand back what it sent, and find a message by
/// its words, without the chat being open. Photos and the app's own
/// components (polls, meetups, checklists, bookings) travel as custom
/// attachments with a description, not as files: the thread draws them live
/// from the trip, and a snapshot handed to another app would go stale.
@AppEntity(schema: .messages.message)
struct ChatMessageEntity: nonisolated Identifiable, nonisolated AppEntity {

    static let defaultQuery = ChatMessageQuery()

    let id: UUID

    var messageType: ChatMessageType
    var author: ChatPersonEntity
    var isRead: Bool
    var attributes: Set<ChatMessageAttribute>
    var conversation: TripConversationEntity
    var date: Date
    var subject: AttributedString?
    var body: AttributedString?
    var attachments: [IntentFile]
    var audioMessage: IntentFile?
    var customAttachments: [ChatComponentAttachment]
    var locations: [PlaceDescriptor]
    var links: [LinkMetadata]
    var messageEffect: ChatMessageEffect?
    var reaction: ChatReadReaction?
    var referencedMessage: ChatMessageEntity?
    var notificationIdentifier: String?

    nonisolated var displayRepresentation: DisplayRepresentation {
        let text = body.map { String($0.characters) } ?? ""
        return DisplayRepresentation(
            title: "\(author.person.displayName)",
            subtitle: "\(text.isEmpty ? (customAttachments.first?.description.map { String($0.characters) } ?? "Message") : text)"
        )
    }

    /// `conversation` is passed in rather than built here, because a batch of
    /// messages from one chat shares one — and building it is a network read.
    @MainActor
    init(_ message: ChatMessage, in trip: Trip, conversation: TripConversationEntity, lastReadAt: Date?) {
        id = message.id
        messageType = .unspecified
        // Somebody who has since left keeps their id, so the entity still
        // points at the same person.
        author = ChatPersonEntity(trip.traveller(message.authorID) ?? Traveller(id: message.authorID, name: "Someone", asset: "Avatar01"))
        isRead = message.isMine || (lastReadAt.map { message.sentAt <= $0 } ?? false)
        var flags: Set<ChatMessageAttribute> = []
        if message.isPinned { flags.insert(.pinned) }
        if message.editedAt != nil { flags.insert(.edited) }
        attributes = flags
        self.conversation = conversation
        date = message.sentAt
        subject = nil
        body = message.body.isEmpty ? nil : AttributedString(message.body)
        attachments = []
        audioMessage = nil
        customAttachments = message.attachment.map { [ChatComponentAttachment(messageID: message.id, attachment: $0)] } ?? []
        if case .place(let place)? = message.attachment {
            locations = [PlaceDescriptor(
                representations: [.coordinate(CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))],
                commonName: place.name
            )]
        } else {
            locations = []
        }
        links = []
        messageEffect = nil
        reaction = nil
        referencedMessage = nil
        notificationIdentifier = nil
    }
}

nonisolated struct ChatMessageQuery: EntityStringQuery {

    func entities(for identifiers: [ChatMessageEntity.ID]) async throws -> [ChatMessageEntity] {
        let store = try await IntentStores.store(fresh: false)
        return try await Self.entities(for: ChatArchive.messages(ids: identifiers), in: store)
    }

    /// Messages whose words match — "the message about the villa code".
    func entities(matching string: String) async throws -> [ChatMessageEntity] {
        let store = try await IntentStores.store(fresh: false)
        let tripIDs = await MainActor.run { store.trips.map(\.id) }
        return try await Self.entities(for: ChatArchive.search(string, in: tripIDs), in: store)
    }

    func suggestedEntities() async throws -> [ChatMessageEntity] {
        let store = try await IntentStores.store(fresh: false)
        let tripIDs = await MainActor.run { TripMatcher.byRelevance(store.trips).prefix(4).map(\.id) }
        return try await Self.entities(for: ChatArchive.recent(in: Array(tripIDs)), in: store)
    }

    @MainActor
    static func entities(for messages: [ChatMessage], in store: TripStore) async throws -> [ChatMessageEntity] {
        let tripIDs = Array(Set(messages.map(\.tripID)))
        let threads = try await ChatArchive.threads(for: tripIDs)
        var conversations: [UUID: TripConversationEntity] = [:]
        for id in tripIDs {
            if let trip = store.trip(id) { conversations[id] = TripConversationEntity(trip, thread: threads[id]) }
        }
        return messages.compactMap { message in
            guard let trip = store.trip(message.tripID), let conversation = conversations[message.tripID] else { return nil }
            return ChatMessageEntity(message, in: trip, conversation: conversation, lastReadAt: threads[message.tripID]?.lastReadAt)
        }
    }
}

/// A chat component — photo, place, poll, meetup, checklist, booking or the
/// balances card — described in words for the system.
@AppEntity(schema: .messages.customAttachment)
struct ChatComponentAttachment: nonisolated Identifiable, nonisolated AppEntity {

    static let defaultQuery = ChatComponentAttachmentQuery()

    /// The message's id: a message carries at most one component.
    let id: UUID

    var sourceName: AttributedString?
    var description: AttributedString?

    nonisolated var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(description.map { String($0.characters) } ?? "Attachment")")
    }

    @MainActor
    init(messageID: UUID, attachment: ChatAttachment) {
        id = messageID
        sourceName = AttributedString("Equitrip")
        description = AttributedString(attachment.previewLabel)
    }
}

nonisolated struct ChatComponentAttachmentQuery: EntityQuery {
    func entities(for identifiers: [ChatComponentAttachment.ID]) async throws -> [ChatComponentAttachment] {
        let messages = try await ChatArchive.messages(ids: identifiers)
        return await MainActor.run {
            messages.compactMap { message in
                message.attachment.map { ChatComponentAttachment(messageID: message.id, attachment: $0) }
            }
        }
    }
}

// MARK: - Schema value types

@AppEnum(schema: .messages.messageType)
enum ChatMessageType: String {
    case unspecified

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .unspecified: "Message"
    ]
}

/// Raw values are persisted — append only.
@AppEnum(schema: .messages.messageAttribute)
enum ChatMessageAttribute: String {
    case pinned
    case edited

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .pinned: "Pinned",
        .edited: "Edited"
    ]
}

/// The chat has no send effects; the schema requires the type all the same.
@AppEnum(schema: .messages.messageEffect)
enum ChatMessageEffect: String {
    case standard

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .standard: "Standard"
    ]
}

/// The reactions in the chat's own reaction bar, in its order. Raw values are
/// persisted — append only.
@AppEnum(schema: .messages.customReaction)
enum ChatTapback: String {
    case love
    case like
    case dislike
    case laugh
    case emphasize
    case question
    case sad

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .love: "❤️ Love",
        .like: "👍 Like",
        .dislike: "👎 Dislike",
        .laugh: "😂 Laugh",
        .emphasize: "‼️ Emphasize",
        .question: "❓ Question",
        .sad: "😢 Sad"
    ]

    /// The emoji `ChatService.react` stores.
    var emoji: String {
        switch self {
        case .love: "❤️"
        case .like: "👍"
        case .dislike: "👎"
        case .laugh: "😂"
        case .emphasize: "‼️"
        case .question: "❓"
        case .sad: "😢"
        }
    }
}

@UnionValue
enum ChatReadReaction {
    case customReaction(ChatTapback)
    case attributedString(AttributedString)
}
