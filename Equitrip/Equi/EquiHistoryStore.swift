//
//  EquiHistoryStore.swift
//  Equitrip
//

import Foundation
import Supabase

/// One past conversation, as the history list needs it.
///
/// Deliberately not the messages: the list shows what a thread was about and
/// when it was last spoken to, and loading every turn of every conversation to
/// draw a list of titles is a lot of reading for text nobody has asked to see.
/// The turns arrive when a thread is opened.
struct EquiConversationSummary: Identifiable, Equatable {
    let id: UUID
    var title: String
    let startedAt: Date
    var updatedAt: Date
}

/// Equi's conversations, on the server.
///
/// Equi's tab held its transcript in `@State` until now, which meant the
/// assistant forgot everything the moment the app was relaunched — including
/// answers the user had no other way back to. This is the memory: a thread per
/// conversation, its turns underneath, in Postgres like everything else in the
/// app, so the history is the same on the phone and on the iPad.
///
/// Writes are fire-and-forget from the view's point of view and optimistic on
/// screen: a bubble appears the instant it is typed, and the insert follows.
/// A failed write costs the transcript its memory of that turn, never the
/// conversation you are having — which is why `failure` is surfaced in the
/// history sheet rather than thrown into the thread.
///
/// The conversation row is created lazily, on the first message. Opening the
/// tab and reading the empty state should not litter the history with empty
/// threads, and the title is the first question, which doesn't exist until
/// then either. See `ensureConversation`.
@MainActor
@Observable
final class EquiHistoryStore {
    /// Every past conversation, newest first.
    private(set) var conversations: [EquiConversationSummary] = []
    /// The turns of the conversation on screen.
    private(set) var messages: [EquiMessage] = []
    /// Nil until this conversation has a row — i.e. until its first message.
    private(set) var conversationID: UUID?
    private(set) var isLoadingList = false
    private(set) var isLoadingThread = false
    /// Why the history isn't what it should be. Shown in the history sheet.
    private(set) var failure: String?

    /// In flight while the conversation row is being created. Held so the
    /// user's turn and the reply that follows a second later join the *same*
    /// creation rather than each making a conversation of their own — the
    /// classic way a chat ends up with one thread per message.
    private var creation: Task<UUID, Error>?

    private var client: SupabaseClient { AuthService.shared.client }

    /// Enough threads to scroll through and not so many that the sheet pays
    /// for a year of questions nobody will scroll to.
    private static let listLimit = 100

    // MARK: - Reading

    func loadConversations() async {
        isLoadingList = true
        defer { isLoadingList = false }

        do {
            let profile = try await SupabaseRepository.shared.resolveProfile()
            let rows: [EquiConversationRow] = try await client
                .from("equi_conversations")
                .select()
                .eq("profile_id", value: profile)
                .order("updated_at", ascending: false)
                .limit(Self.listLimit)
                .execute()
                .value

            conversations = rows.map(\.asSummary)
            failure = nil
        } catch {
            guard !isCancellation(error) else { return }
            // An empty history and a history we couldn't reach look identical
            // on screen, and quietly showing "nothing here yet" invites
            // somebody to conclude their conversations are gone.
            failure = "Couldn't load your conversations."
        }
    }

    /// Opens a past conversation into the thread.
    func open(_ summary: EquiConversationSummary) async {
        creation?.cancel()
        creation = nil
        conversationID = summary.id
        isLoadingThread = true
        defer { isLoadingThread = false }

        do {
            let rows: [EquiMessageRow] = try await client
                .from("equi_messages")
                .select()
                .eq("conversation_id", value: summary.id)
                .order("created_at", ascending: true)
                .execute()
                .value

            // Guard against a second open winning the race while this one was
            // in flight — the reply would land in the wrong thread.
            guard conversationID == summary.id else { return }
            messages = rows.map(\.asMessage)
            failure = nil
        } catch {
            guard !isCancellation(error) else { return }
            failure = "Couldn't open that conversation."
        }
    }

    // MARK: - Writing

    /// Clears the thread without touching what's already saved.
    func startNewConversation() {
        creation?.cancel()
        creation = nil
        conversationID = nil
        messages.removeAll()
    }

    /// Appends a turn and saves it.
    ///
    /// Used for the user's own message and for anything Equi says in one go
    /// (an unavailable model, an error). A streamed reply lands through
    /// `beginReply`/`stream`/`finishReply` instead, so the row is written once
    /// rather than on every token.
    func append(_ message: EquiMessage) {
        messages.append(message)
        persist(message)
    }

    /// Starts an empty reply bubble to stream into. Nothing is saved yet.
    func beginReply(_ message: EquiMessage) {
        messages.append(message)
    }

    /// Lands a chunk of a streaming reply in place. Local only.
    func stream(_ id: UUID, text: String, card: EquiCard?) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].text = text
        messages[index].card = card
    }

    /// Saves a streamed reply now that it has stopped moving.
    func finishReply(_ id: UUID) {
        guard let message = messages.first(where: { $0.id == id }) else { return }
        persist(message)
    }

    func delete(_ summary: EquiConversationSummary) async {
        conversations.removeAll { $0.id == summary.id }
        if conversationID == summary.id { startNewConversation() }

        do {
            try await client.from("equi_conversations").delete().eq("id", value: summary.id).execute()
            failure = nil
        } catch {
            failure = "Couldn't delete that conversation."
            await loadConversations()
        }
    }

    // MARK: - Plumbing

    private func persist(_ message: EquiMessage) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let conversation = try await self.ensureConversation(titledAfter: message)
                let profile = try await SupabaseRepository.shared.resolveProfile()
                let row = EquiMessageRow(
                    id: message.id,
                    conversation_id: conversation,
                    profile_id: profile,
                    is_user: message.isUser,
                    body: message.text,
                    card_kind: message.card?.kind.storageKey,
                    card_trip_id: message.card?.tripID,
                    created_at: message.sentAt
                )
                // Upsert, not insert: a reply that is saved and then corrected
                // — the error text replacing a half-streamed answer — writes
                // the same id twice, and the second one is the true one.
                try await self.client.from("equi_messages").upsert(row).execute()
                self.touch(conversation)
                self.failure = nil
            } catch {
                guard !self.isCancellation(error) else { return }
                self.failure = "Couldn't save the last message to your history."
            }
        }
    }

    /// The open conversation's id, creating the row on first use.
    ///
    /// Everything that wants to write goes through here and through the one
    /// `creation` task, so the user's question and Equi's answer — which race
    /// by about a second — end up in one thread.
    private func ensureConversation(titledAfter message: EquiMessage) async throws -> UUID {
        if let conversationID { return conversationID }
        if let creation { return try await creation.value }

        let title = Self.title(from: message.text)
        let task = Task { @MainActor [client] in
            let profile = try await SupabaseRepository.shared.resolveProfile()
            let row: EquiConversationRow = try await client
                .from("equi_conversations")
                .insert(NewEquiConversation(profile_id: profile, title: title))
                .select()
                .single()
                .execute()
                .value
            return row.id
        }
        creation = task

        do {
            let id = try await task.value
            conversationID = id
            creation = nil
            conversations.insert(
                EquiConversationSummary(id: id, title: title, startedAt: Date(), updatedAt: Date()),
                at: 0
            )
            return id
        } catch {
            // Left unset so the next message tries again rather than the
            // whole conversation being written off over one bad moment.
            creation = nil
            throw error
        }
    }

    /// Mirrors what the trigger just did to `updated_at`, so the history list
    /// reorders without a round trip to be told what it already knows.
    private func touch(_ id: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].updatedAt = Date()
        let summary = conversations.remove(at: index)
        conversations.insert(summary, at: 0)
    }

    /// The first question, trimmed to something that fits on a line.
    ///
    /// Cut on a word boundary: "How much have we spent on f…" reads as a
    /// question; the same cut mid-word reads as a bug.
    private static func title(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "New conversation" }
        guard trimmed.count > 64 else { return trimmed }

        let clipped = trimmed.prefix(64)
        if let space = clipped.lastIndex(of: " "), clipped.distance(from: clipped.startIndex, to: space) > 24 {
            return clipped[..<space] + "…"
        }
        return clipped + "…"
    }

    /// A pull superseded by another, or by the sheet closing, is not a failure
    /// worth putting on screen.
    private func isCancellation(_ error: Error) -> Bool {
        Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled
    }
}

// MARK: - Rows

nonisolated struct EquiConversationRow: Decodable {
    let id: UUID
    let title: String
    let created_at: Date
    let updated_at: Date

    var asSummary: EquiConversationSummary {
        EquiConversationSummary(id: id, title: title, startedAt: created_at, updatedAt: updated_at)
    }
}

nonisolated struct NewEquiConversation: Encodable {
    let profile_id: UUID
    let title: String
}

nonisolated struct EquiMessageRow: Codable {
    let id: UUID
    let conversation_id: UUID
    let profile_id: UUID
    let is_user: Bool
    let body: String
    let card_kind: String?
    let card_trip_id: UUID?
    let created_at: Date

    /// `@MainActor` like `MessageRow.asMessage`: `EquiMessage` and `EquiCard`
    /// are the view's own types and isolated with it.
    @MainActor var asMessage: EquiMessage {
        EquiMessage(
            id: id,
            text: body,
            isUser: is_user,
            card: EquiCard(storageKey: card_kind, tripID: card_trip_id),
            sentAt: created_at
        )
    }
}
