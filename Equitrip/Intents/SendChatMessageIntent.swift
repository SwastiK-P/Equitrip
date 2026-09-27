//
//  SendChatMessageIntent.swift
//  Equitrip
//

import AppIntents
import CoreLocation
import Foundation
import UniformTypeIdentifiers
import GeoToolbox
import UIKit

/// "Tell the Goa group I'm running ten minutes late" — the messages domain's
/// *send message*, into a trip's group chat.
///
/// The messages domain's *message sending* use case is send and draft
/// together (the build says so if either is missing), with the entities they
/// share — `DraftChatMessageIntent`, `TripConversationEntity`,
/// `ChatMessageEntity`, `ChatPersonEntity`. Edit, unsend and read status were
/// here too and came out: each rebuilt the chat from its newest 400 messages,
/// so older ones were "not found", and read status marked the whole thread
/// rather than the message. Those are for the chat screen, where the message
/// is in front of you.
///
/// Every message goes through `ChatService`, so what Siri sends is the same
/// row, delivered the same way, as one typed into the thread. Siri confirms
/// before sending — the schema asks it to.
///
/// Equitrip has no direct messages. When Siri names people rather than a
/// chat, the message goes to the one trip they share with you, and says so
/// first: "message Ed" becoming a note to the whole Goa group is a surprise
/// nobody should get after the fact.
@AppIntent(schema: .messages.sendMessage)
struct SendChatMessageIntent {

    var content: AttributedString?
    var destination: ChatDestination
    var subject: AttributedString?
    var attachments: [IntentFile]
    var audioMessage: IntentFile?
    var locations: [PlaceDescriptor]
    var links: [URL]
    var scheduledDate: Date?

    @MainActor
    func perform() async throws -> some ReturnsValue<[ChatMessageEntity]> {
        guard scheduledDate == nil else { throw IntentFailure.cannotSchedule }
        guard audioMessage == nil else { throw IntentFailure.noVoiceMessages }

        let store = try await IntentStores.store()
        let resolved = try ChatDestinationResolver.trip(for: destination, in: store)
        let trip = resolved.trip

        let text = ChatComposition.text(content: content, subject: subject, links: links)
        let images = attachments.compactMap { UIImage(data: $0.data) }
        guard !text.isEmpty || !images.isEmpty || !locations.isEmpty else { throw IntentFailure.nothingToSend }

        if resolved.namedPeopleOnly {
            let count = trip.travellers.count
            try await requestConfirmation(
                actionName: .send,
                dialog: "Equitrip chats are one per trip, so this goes to everyone on \(trip.title) — \(count) people. Send it?"
            )
        }

        let chat = ChatService(trip: trip)
        let before = Set(chat.messages.map(\.id))

        // A photo takes the words as its caption, the way the composer sends
        // one; places go as place cards; words with nothing to ride on go alone.
        var caption = text
        for image in images {
            await chat.sendPhoto(image, caption: caption)
            caption = ""
        }
        for place in locations {
            if let card = ChatComposition.place(place) {
                await chat.send("", attachment: .place(card))
            }
        }
        if !caption.isEmpty {
            await chat.send(caption)
        }

        let sent = chat.messages.filter { !before.contains($0.id) }
        guard !sent.isEmpty, sent.allSatisfy({ $0.delivery == .sent }) else {
            throw IntentFailure.messageNotSent
        }

        // The message is out by now. A failed read of the thread's metadata
        // must not turn that into "didn't send" — a retry would post it twice.
        let conversation = (try? await TripConversationQuery.conversations(for: [trip.id], in: store))?.first
            ?? TripConversationEntity(trip, thread: nil)
        return .result(value: sent.map { ChatMessageEntity($0, in: trip, conversation: conversation, lastReadAt: nil) })
    }
}

/// Who a message is for.
///
/// People only. The schema database and Xcode's snippet both list a fourth
/// case, `conversation`, but the Xcode 27.0 build tool rejects any union that
/// has it ("does not match required AppSchemaIntent type"). A group is
/// addressed by its members instead: Siri resolves "the Goa group" to the
/// conversation, and hands over its `recipients` — which is why
/// `ChatDestinationResolver` treats an exact member match as the group itself.
@UnionValue
enum ChatDestination {
    case people([IntentPerson])
    case messagePerson(ChatPersonEntity)
    case messagePeople([ChatPersonEntity])
}

/// Turns a destination into the one trip chat it means.
enum ChatDestinationResolver {

    struct Resolved {
        let trip: Trip
        /// True when the people named are only some of the trip — the send
        /// should say it's going to the whole group.
        let namedPeopleOnly: Bool
    }

    @MainActor
    static func trip(for destination: ChatDestination, in store: TripStore) throws -> Resolved {
        switch destination {
        case .messagePerson(let person):
            return try shared(with: [person.person], in: store)
        case .messagePeople(let people):
            return try shared(with: people.map(\.person), in: store)
        case .people(let people):
            return try shared(with: people, in: store)
        }
    }

    @MainActor
    static func trip(for destination: ChatDestination?, in store: TripStore) throws -> Resolved {
        if let destination { return try trip(for: destination, in: store) }
        guard let trip = TripMatcher.likeliest(in: store.trips) else { throw IntentFailure.noTrips }
        return Resolved(trip: trip, namedPeopleOnly: false)
    }

    /// The trip whose chat the people named are in with you.
    ///
    /// A trip whose other members are exactly those people *is* the group
    /// being addressed — that's how a conversation arrives — and wins
    /// outright. Otherwise the trip they're all on, the one under way first;
    /// and then the send asks before posting to everyone. People are matched
    /// by the id this app gave them, then by email, then by name.
    @MainActor
    private static func shared(with people: [IntentPerson], in store: TripStore) throws -> Resolved {
        let named = people.map(\.displayName)
        var partial: Trip?

        for trip in TripMatcher.byRelevance(store.trips) {
            let matched = people.compactMap { traveller($0, on: trip)?.id }
            guard matched.count == people.count else { continue }

            let others = Set(trip.travellers.map(\.id)).subtracting([Traveller.you.id]).subtracting(trip.invitedIDs)
            if Set(matched).subtracting([Traveller.you.id]) == others {
                return Resolved(trip: trip, namedPeopleOnly: false)
            }
            if partial == nil { partial = trip }
        }

        guard let partial else {
            throw IntentFailure.noSharedTrip(ListFormatter.localizedString(byJoining: named))
        }
        return Resolved(trip: partial, namedPeopleOnly: true)
    }

    @MainActor
    private static func traveller(_ person: IntentPerson, on trip: Trip) -> Traveller? {
        if let id = person.travellerID, let match = trip.traveller(id) { return match }
        if case .emailAddress(let email)? = person.handle?.value,
           let match = trip.travellers.first(where: { $0.email?.caseInsensitiveCompare(email) == .orderedSame }) {
            return match
        }
        return TripMatcher.traveller(named: person.displayName, on: trip)
    }
}

/// The words and cards a Siri message becomes.
enum ChatComposition {

    /// Subject, body and links as one message: the chat has no subject line
    /// and no link previews, and a link dropped silently is worse than a link
    /// on its own line.
    static func text(content: AttributedString?, subject: AttributedString?, links: [URL]) -> String {
        let parts = [subject, content].compactMap { $0.map { String($0.characters) } }
            + links.map(\.absoluteString)
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// A place card for the chat, when the place has a coordinate to pin.
    static func place(_ place: PlaceDescriptor) -> ChatAttachment.Place? {
        guard let coordinate = place.coordinate else { return nil }
        return ChatAttachment.Place(
            name: place.commonName ?? place.address ?? "Pinned place",
            subtitle: place.address ?? "",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}
