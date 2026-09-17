//
//  MarkChatReadIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Mark the Goa chat as read" — the messages domain's *set read status*.
///
/// Read only goes one way here. The chat keeps one read position per person —
/// "seen up to here", shared with everyone as read receipts — and marking a
/// message unread would mean moving that back and un-seeing it for the whole
/// group. So "read" moves it forward to the message, and "unread" says it
/// can't.
@AppIntent(schema: .messages.setMessageReadStatus)
struct MarkChatReadIntent {

    var message: ChatMessageEntity
    var isRead: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        guard isRead else { throw IntentFailure.cannotMarkUnread }

        let store = try await IntentStores.store()
        guard let trip = store.trip(message.conversation.id) else { throw IntentFailure.tripNotFound }

        let chat = ChatService(trip: trip)
        await chat.reload()
        await chat.markRead()
        return .result()
    }
}
