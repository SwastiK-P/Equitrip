//
//  ChatMessage.swift
//  Equitrip
//

import SwiftUI

/// One message in a trip's group chat: text, or text plus a component.
///
/// Edit, unsend and pin state live on the message itself rather than in side
/// tables, because every one of them changes how the bubble is drawn and they
/// arrive through the same realtime update as the row they belong to.
struct ChatMessage: Identifiable, Equatable {
    /// Where a message is on its way to the server.
    ///
    /// Three states, not a bool: "sent" and "didn't send" used to look the
    /// same because a failure quietly deleted the bubble, so a message you'd
    /// typed just vanished. A failed message stays on screen and offers to go
    /// again.
    enum Delivery: Equatable {
        case sending, sent, failed
    }

    let id: UUID
    let tripID: UUID
    let authorID: UUID
    var body: String
    let sentAt: Date
    /// The message this one answers, if any. Flat rather than nested — see
    /// the note in `0003_message_replies.sql`.
    var replyToID: UUID?
    /// Nil for plain text. A kind this build doesn't know arrives as
    /// `.unsupported` rather than being dropped — see `ChatAttachment`.
    var attachment: ChatAttachment?
    var editedAt: Date?
    var deletedAt: Date?
    var pinnedAt: Date?
    var pinnedByID: UUID?
    var delivery: Delivery = .sent

    var isMine: Bool { authorID == Traveller.you.id }
    var isDeleted: Bool { deletedAt != nil }
    var isPinned: Bool { pinnedAt != nil && !isDeleted }

    /// Text you can edit in place. Components are re-sent rather than edited:
    /// changing a poll's options under votes already cast would quietly move
    /// people's answers.
    var isEditable: Bool { isMine && !isDeleted && attachment == nil && delivery == .sent }

    /// One to three emoji and nothing else, drawn large with no bubble — the
    /// way every messaging app has taught people a lone emoji reaction should look.
    var isEmojiOnly: Bool {
        guard attachment == nil, !isDeleted, replyToID == nil else { return false }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 3 else { return false }
        return trimmed.allSatisfy { character in
            character.unicodeScalars.contains { $0.properties.isEmojiPresentation }
                || (character.unicodeScalars.count > 1 && character.unicodeScalars.first?.properties.isEmoji == true)
        }
    }

    /// One line for quote blocks, the pinned banner and search results, so a
    /// reply to a poll says "Which beach?" rather than nothing.
    var preview: String {
        if isDeleted { return "Message deleted" }
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let attachment else { return text }
        let label = attachment.previewLabel
        return text.isEmpty ? label : "\(label) · \(text)"
    }
}

/// One person's current answer to a poll, meetup or bring-list.
struct ChatResponse: Hashable {
    let messageID: UUID
    let profileID: UUID
    let choices: [String]
}
