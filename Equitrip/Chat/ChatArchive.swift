//
//  ChatArchive.swift
//  Equitrip
//

import Foundation
import Supabase

/// Trip chats, read without opening them — for Siri.
///
/// `ChatService` is one open thread: a history load, a realtime channel and a
/// typing sweeper, alive while its screen is. Siri needs something smaller and
/// wider — the newest message in each of your trip chats, whether you've read
/// it, a message looked up by id days later — and none of it should open a
/// socket. Sending and changing messages still goes through `ChatService`, so
/// a message Siri sends is the same row, delivered the same way, as one typed.
@MainActor
enum ChatArchive {

    /// One trip chat at a glance.
    struct Thread {
        let tripID: UUID
        let latest: ChatMessage?
        /// When you last read this chat, from any device. Nil when never.
        let lastReadAt: Date?

        /// Read when there's nothing newer from somebody else than your read
        /// position — your own messages don't make a chat unread.
        var isRead: Bool {
            guard let latest, !latest.isMine else { return true }
            guard let lastReadAt else { return false }
            return latest.sentAt <= lastReadAt
        }
    }

    private static var client: SupabaseClient { AuthService.shared.client }

    /// The newest message and your read position for each trip.
    static func threads(for tripIDs: [UUID]) async throws -> [UUID: Thread] {
        guard !tripIDs.isEmpty else { return [:] }

        // One newest-row read per trip, side by side. A single "newest N
        // across all trips" read looked cheaper, and called a quiet trip's
        // chat empty whenever a busy one filled the page.
        let newest = try await withThrowingTaskGroup(of: (UUID, ChatMessage?).self) { group in
            for tripID in tripIDs {
                group.addTask { (tripID, try await latestMessage(in: tripID)) }
            }
            var found: [UUID: ChatMessage] = [:]
            for try await (tripID, message) in group {
                found[tripID] = message
            }
            return found
        }
        let positions = await readPositions(for: tripIDs)

        return Dictionary(uniqueKeysWithValues: tripIDs.map {
            ($0, Thread(tripID: $0, latest: newest[$0], lastReadAt: positions[$0]))
        })
    }

    private static func latestMessage(in tripID: UUID) async throws -> ChatMessage? {
        let rows: [MessageRow] = try await client
            .from("messages")
            .select()
            .eq("trip_id", value: tripID)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first?.asMessage
    }

    /// Messages by id, oldest first. Unsent ones included — an entity Siri
    /// already holds should resolve to "deleted", not vanish.
    static func messages(ids: [UUID]) async throws -> [ChatMessage] {
        guard !ids.isEmpty else { return [] }
        let rows: [MessageRow] = try await client
            .from("messages")
            .select()
            .in("id", values: ids)
            .execute()
            .value
        return rows.map(\.asMessage).sorted { $0.sentAt < $1.sentAt }
    }

    /// Recent messages whose text contains `text`, newest first.
    static func search(_ text: String, in tripIDs: [UUID], limit: Int = 20) async throws -> [ChatMessage] {
        guard !tripIDs.isEmpty else { return [] }
        // `%` and `_` are ILIKE wildcards; a person saying "50% off" means the
        // characters.
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        let rows: [MessageRow] = try await client
            .from("messages")
            .select()
            .in("trip_id", values: tripIDs)
            .is("deleted_at", value: nil)
            .ilike("body", pattern: "%\(escaped)%")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map(\.asMessage)
    }

    /// The newest messages across `tripIDs`, newest first.
    static func recent(in tripIDs: [UUID], limit: Int = 15) async throws -> [ChatMessage] {
        guard !tripIDs.isEmpty else { return [] }
        let rows: [MessageRow] = try await client
            .from("messages")
            .select()
            .in("trip_id", values: tripIDs)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map(\.asMessage)
    }

    /// Your own read position per trip. Allowed to fail on its own: a
    /// database without the reads table costs "unread", not the answer.
    private static func readPositions(for tripIDs: [UUID]) async -> [UUID: Date] {
        guard let profile = try? await SupabaseRepository.shared.resolveProfile() else { return [:] }
        let rows: [ReadRow]? = try? await client
            .from("chat_reads")
            .select()
            .in("trip_id", values: tripIDs)
            .eq("profile_id", value: profile)
            .execute()
            .value
        return Dictionary((rows ?? []).map { ($0.trip_id, $0.last_read_at) }, uniquingKeysWith: max)
    }
}
