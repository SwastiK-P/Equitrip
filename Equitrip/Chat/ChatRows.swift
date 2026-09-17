//
//  ChatRows.swift
//  Equitrip
//

import Foundation

/// A `messages` row as Postgres and Realtime send it.
///
/// Every column added after 0001 is optional here, so a thread still loads
/// against a database that hasn't had `0017_chat_components.sql` run yet —
/// it just has nothing but text in it.
nonisolated struct MessageRow: Decodable {
    let id: UUID
    let trip_id: UUID
    let profile_id: UUID
    let body: String
    let created_at: Date
    var reply_to_id: UUID?
    var kind: String?
    var payload: ChatPayload?
    var edited_at: Date?
    var deleted_at: Date?
    var pinned_at: Date?
    var pinned_by: UUID?

    @MainActor var asMessage: ChatMessage {
        ChatMessage(
            id: id,
            tripID: trip_id,
            authorID: profile_id,
            body: body,
            sentAt: created_at,
            replyToID: reply_to_id,
            attachment: ChatAttachment(kind: kind ?? "text", payload: payload),
            editedAt: edited_at,
            deletedAt: deleted_at,
            pinnedAt: pinned_at,
            pinnedByID: pinned_by,
            delivery: .sent
        )
    }
}

nonisolated struct OutgoingMessage: Encodable {
    let id: UUID
    let trip_id: UUID
    let profile_id: UUID
    let body: String
    let reply_to_id: UUID?
    let kind: String
    let payload: ChatPayload

    private enum CodingKeys: String, CodingKey {
        case id, trip_id, profile_id, body, reply_to_id, kind, payload
    }

    /// Plain text leaves out `kind` and `payload`, which are the columns'
    /// defaults anyway — so a text message still sends to a database that
    /// hasn't had 0017 applied, instead of every message failing on a column
    /// that isn't there.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(trip_id, forKey: .trip_id)
        try container.encode(profile_id, forKey: .profile_id)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(reply_to_id, forKey: .reply_to_id)
        if kind != "text" {
            try container.encode(kind, forKey: .kind)
            try container.encode(payload, forKey: .payload)
        }
    }
}

nonisolated struct ResponseRow: Codable {
    let message_id: UUID
    let trip_id: UUID
    let profile_id: UUID
    let choices: [String]

    @MainActor var asResponse: ChatResponse {
        ChatResponse(messageID: message_id, profileID: profile_id, choices: choices)
    }
}

nonisolated struct ReadRow: Codable {
    let trip_id: UUID
    let profile_id: UUID
    let last_read_at: Date
}
