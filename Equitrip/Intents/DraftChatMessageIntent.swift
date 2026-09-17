//
//  DraftChatMessageIntent.swift
//  Equitrip
//

import AppIntents
import Foundation
import UniformTypeIdentifiers
import GeoToolbox

/// "Draft a message to the Rome group" — the words land in the chat's
/// composer, unsent, with the thread open underneath them.
///
/// A draft is the person's to read over, so this never posts. It opens the
/// app, because a draft nobody can see isn't one. With no chat named it opens
/// the trip most likely meant — the one under way, else the next.
@AppIntent(schema: .messages.draftMessage)
struct DraftChatMessageIntent {

    var destination: ChatDestination?
    var subject: AttributedString?
    var content: AttributedString?
    var attachments: [IntentFile]
    var audioMessage: IntentFile?
    var locations: [PlaceDescriptor]
    var links: [URL]
    var scheduledDate: Date?

    static var supportedModes: IntentModes { .foreground(.immediate) }

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = try await IntentStores.store()
        let trip = try ChatDestinationResolver.trip(for: destination, in: store).trip
        let text = ChatComposition.text(content: content, subject: subject, links: links)
        AppNavigator.shared.go(.chat(tripID: trip.id, draft: text))
        return .result()
    }
}
