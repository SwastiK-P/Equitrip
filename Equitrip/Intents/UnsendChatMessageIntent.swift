//
//  UnsendChatMessageIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Unsend that" — the messages domain's *unsend message*.
///
/// The thread's own unsend: the row stays so a reply pointing at it reads
/// "deleted", and the server blanks what it said. Your own messages only.
@AppIntent(schema: .messages.unsendMessage)
struct UnsendChatMessageIntent {

    var message: ChatMessageEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = try await IntentStores.store()
        guard let trip = store.trip(message.conversation.id) else { throw IntentFailure.tripNotFound }

        let chat = ChatService(trip: trip)
        await chat.reload()
        guard let current = chat.message(message.id) else { throw IntentFailure.messageNotFound }
        guard current.isMine else { throw IntentFailure.notYours }
        guard !current.isDeleted else { return .result() }

        await chat.unsend(current)
        guard chat.message(message.id)?.isDeleted == true else {
            throw IntentFailure.notSaved(chat.failure ?? "Try again from the chat.")
        }
        return .result()
    }
}
