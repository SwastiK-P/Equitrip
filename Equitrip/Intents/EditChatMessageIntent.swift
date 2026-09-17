//
//  EditChatMessageIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Change that to eight o'clock" — the messages domain's *edit sent message*.
///
/// Held to the thread's own rule (`ChatMessage.isEditable`): only your own
/// text messages, never a component, never one that's been unsent. Checked
/// against the message as the server has it now, not as Siri last saw it.
@AppIntent(schema: .messages.editSentMessage)
struct EditChatMessageIntent {

    var message: ChatMessageEntity
    var content: AttributedString

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = try await IntentStores.store()
        guard let trip = store.trip(message.conversation.id) else { throw IntentFailure.tripNotFound }

        let chat = ChatService(trip: trip)
        await chat.reload()
        guard let current = chat.message(message.id), !current.isDeleted else { throw IntentFailure.messageNotFound }
        guard current.isMine else { throw IntentFailure.notYours }

        let text = String(content.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw IntentFailure.nothingToSend }
        guard current.isEditable else { throw IntentFailure.notSaved("Only a text message can be edited.") }
        guard text != current.body else { return .result() }

        await chat.edit(current, to: text)
        // `edit` puts the old words back when the server refuses them.
        guard chat.message(message.id)?.body == text else {
            throw IntentFailure.notSaved(chat.failure ?? "Try again from the chat.")
        }
        return .result()
    }
}
