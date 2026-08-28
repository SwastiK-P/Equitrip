//
//  ChatService.swift
//  Equitrip
//

import SwiftUI
import Supabase

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
    var delivery: Delivery = .sent

    var isMine: Bool { authorID == Traveller.you.id }
}

/// Live group chat for one trip.
///
/// Messages go through Postgres (they need to persist and be re-read on the
/// next launch); typing goes through Realtime broadcast (it doesn't). Sending
/// is optimistic — the bubble is on screen before the network is consulted,
/// and reconciles when the insert echoes back through the same subscription
/// everyone else receives.
@MainActor
@Observable
final class ChatService {
    private(set) var messages: [ChatMessage] = []
    private(set) var typingNames: [String] = []
    private(set) var isConnected = false
    private(set) var isLoading = true
    private(set) var failure: String?

    private var channel: RealtimeChannelV2?
    private var tasks: [Task<Void, Never>] = []
    private var typingExpiry: [UUID: Date] = [:]
    /// Name as the sender broadcast it, keyed by profile. See
    /// `refreshTypingNames` for why this beats a local lookup.
    private var typingSenders: [UUID: String] = [:]
    private var lastTypingPing = Date.distantPast
    private var sweeper: Task<Void, Never>?

    private let trip: Trip
    private var tripID: UUID { trip.id }
    private var travellers: [Traveller] { trip.travellers }

    private var client: SupabaseClient { AuthService.shared.client }

    /// How long a typing ping stays true. Long enough to survive the gap
    /// between keystrokes, short enough that someone who puts their phone
    /// down stops showing as typing almost immediately.
    private static let typingTTL: TimeInterval = 4

    init(trip: Trip) {
        self.trip = trip
    }

    // MARK: - Lifecycle

    func start() async {
        // The trip is already a real server row — every trip in the app comes
        // from Postgres now — so there's nothing to create first. Straight to
        // history and the live subscription.
        await loadHistory()
        await subscribe()
        startSweeper()
    }

    func stop() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        sweeper?.cancel()
        sweeper = nil
        isConnected = false

        let channel = self.channel
        self.channel = nil
        Task { await channel?.unsubscribe() }
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let rows: [MessageRow] = try await client
                .from("messages")
                .select()
                .eq("trip_id", value: tripID)
                .order("created_at", ascending: true)
                .limit(200)
                .execute()
                .value

            messages = rows.map(\.asMessage)
            failure = nil
        } catch {
            // An empty thread and a thread we couldn't reach look the same on
            // screen otherwise, and silently pretending it's empty invites
            // someone to type into a void.
            failure = "Couldn't load the conversation."
        }
    }

    private func subscribe() async {
        let channel = client.channel("trip-chat:\(tripID.uuidString)")
        self.channel = channel

        let inserts = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: .eq("trip_id", value: tripID.uuidString)
        )
        let typing = channel.broadcastStream(event: "typing")

        do {
            // `subscribe()` swallowed failures, so the header showed a green
            // dot and "connected" whether or not the socket had actually come
            // up. If it can't connect, say so.
            try await channel.subscribeWithError()
            isConnected = true
        } catch {
            isConnected = false
            failure = "Live updates are off. Pull to reload."
            return
        }

        tasks.append(Task { [weak self] in
            for await insert in inserts {
                guard let self else { return }
                guard let row = try? insert.decodeRecord(as: MessageRow.self, decoder: Self.decoder) else { continue }
                await self.merge(row.asMessage)
            }
        })

        tasks.append(Task { [weak self] in
            for await payload in typing {
                guard let self else { return }
                await self.handleTyping(payload)
            }
        })
    }

    // MARK: - Reading

    /// The message a reply is pointing at, for the quote block. Nil once the
    /// original has been deleted, or when it's older than the window we hold.
    func message(_ id: UUID?) -> ChatMessage? {
        guard let id else { return nil }
        return messages.first { $0.id == id }
    }

    func author(of message: ChatMessage) -> Traveller? {
        travellers.first { $0.id == message.authorID }
    }

    /// The people currently typing, for the indicator's avatars.
    ///
    /// Only those this device can put a face to. A name arrives with the
    /// broadcast and is enough for the label, but an avatar needs the actual
    /// traveller, so somebody who joined moments ago shows as a name with no
    /// face rather than not at all.
    var typingPeople: [Traveller] {
        typingExpiry.keys
            .compactMap { id in travellers.first { $0.id == id } }
            .sorted { $0.name < $1.name }
    }

    /// Name to put on a quote block. Falls back rather than showing an empty
    /// string for someone who has since left the trip.
    func authorName(of message: ChatMessage) -> String {
        if message.isMine { return "You" }
        return author(of: message)?.name ?? "Someone"
    }

    // MARK: - Sending

    func send(_ text: String, replyingTo parent: ChatMessage? = nil) async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        let optimistic = ChatMessage(
            id: UUID(),
            tripID: tripID,
            authorID: Traveller.you.id,
            body: body,
            sentAt: Date(),
            replyToID: parent?.id,
            delivery: .sending
        )
        messages.append(optimistic)

        await deliver(optimistic)
    }

    /// Re-sends a message that failed. Same id, so a partial success upstream
    /// can't produce a duplicate.
    func retry(_ message: ChatMessage) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].delivery = .sending
        await deliver(messages[index])
    }

    private func deliver(_ message: ChatMessage) async {
        guard let profile = try? await SupabaseRepository.shared.resolveProfile() else {
            mark(message.id, as: .failed)
            return
        }

        do {
            let row = OutgoingMessage(
                id: message.id,
                trip_id: tripID,
                profile_id: profile,
                body: message.body,
                reply_to_id: message.replyToID
            )
            _ = try await client.from("messages").insert(row).execute()
            mark(message.id, as: .sent)
            failure = nil
        } catch {
            mark(message.id, as: .failed)
        }
    }

    private func mark(_ id: UUID, as delivery: ChatMessage.Delivery) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].delivery = delivery
    }

    /// The insert we made ourselves arrives back through the subscription, so
    /// it's matched on id rather than appended — otherwise every message you
    /// send would appear twice.
    private func merge(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            // Keep whatever delivery state we're already showing: the echo is
            // proof it landed, and downgrading a `.sent` bubble back through
            // an animation serves nobody.
            var incoming = message
            incoming.delivery = .sent
            messages[index] = incoming
        } else {
            messages.append(message)
            messages.sort { $0.sentAt < $1.sentAt }
        }
    }

    // MARK: - Typing

    /// Throttled: a broadcast per keystroke would be dozens of packets for one
    /// sentence, and the indicator only needs refreshing before its TTL lapses.
    func noteTyping() {
        guard Date().timeIntervalSince(lastTypingPing) > 1.5 else { return }
        lastTypingPing = Date()

        Task { [weak self] in
            guard let self, let channel = self.channel else { return }
            await channel.broadcast(
                event: "typing",
                message: [
                    "profile_id": AnyJSON.string(Traveller.you.id.uuidString),
                    "name": .string(Traveller.you.name)
                ]
            )
        }
    }

    private func handleTyping(_ message: JSONObject) async {
        // `broadcastStream` yields the whole broadcast *envelope* —
        // `{"type": "broadcast", "event": "typing", "payload": { ...ours... }}`
        // — not the object we handed `broadcast(event:message:)`. Reading the
        // fields straight off the top level found nothing every single time,
        // so this guard always failed and the indicator could never appear.
        // Falling back to the message itself keeps this working if a future
        // SDK version unwraps it for us.
        let body = message["payload"]?.objectValue ?? message

        guard let rawID = body["profile_id"]?.stringValue,
              let id = UUID(uuidString: rawID),
              id != Traveller.you.id
        else { return }

        if let name = body["name"]?.stringValue, !name.isEmpty {
            typingSenders[id] = name
        }

        typingExpiry[id] = Date().addingTimeInterval(Self.typingTTL)
        refreshTypingNames()
    }

    /// Expiry is time-based rather than relying on a "stopped typing" message,
    /// which never arrives when someone force-quits mid-sentence.
    private func startSweeper() {
        sweeper?.cancel()
        sweeper = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                await self.refreshTypingNames()
            }
        }
    }

    private func refreshTypingNames() {
        let now = Date()
        typingExpiry = typingExpiry.filter { $0.value > now }
        typingSenders = typingSenders.filter { typingExpiry[$0.key] != nil }

        // The broadcast carries the sender's own name, so prefer it. The local
        // traveller list is a second way to silently lose the indicator:
        // somebody who joined a minute ago isn't in this device's copy of the
        // trip yet, and `compactMap` would just drop them.
        let names = typingExpiry.keys.compactMap { id in
            typingSenders[id] ?? travellers.first { $0.id == id }?.name
        }
        if names.sorted() != typingNames.sorted() { typingNames = names.sorted() }
    }

    // MARK: - Wire

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = ISO8601DateFormatter.supabase.date(from: text) { return date }
            if let date = ISO8601DateFormatter.supabaseFractional.date(from: text) { return date }
            return Date()
        }
        return decoder
    }()
}

private struct MessageRow: Decodable {
    let id: UUID
    let trip_id: UUID
    let profile_id: UUID
    let body: String
    let created_at: Date
    var reply_to_id: UUID?

    var asMessage: ChatMessage {
        ChatMessage(
            id: id,
            tripID: trip_id,
            authorID: profile_id,
            body: body,
            sentAt: created_at,
            replyToID: reply_to_id,
            delivery: .sent
        )
    }
}

private struct OutgoingMessage: Encodable {
    let id: UUID
    let trip_id: UUID
    let profile_id: UUID
    let body: String
    let reply_to_id: UUID?
}

extension ISO8601DateFormatter {
    static let supabase: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let supabaseFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
