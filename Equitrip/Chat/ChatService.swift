//
//  ChatService.swift
//  Equitrip
//

import SwiftUI
import Supabase

/// Live group chat for one trip.
///
/// Messages, answers and read positions go through Postgres (they
/// need to persist and be re-read on the next launch); typing goes through
/// Realtime broadcast (it doesn't). Every write is optimistic — the change is
/// on screen before the network is consulted, and reconciles when the row
/// echoes back through the same subscription everyone else receives.
@MainActor
@Observable
final class ChatService {
    private(set) var messages: [ChatMessage] = []
    /// Keyed by message: everyone's answer to a poll, meetup or bring-list.
    private(set) var responses: [UUID: [ChatResponse]] = [:]
    /// How far each other person has read, by profile.
    private(set) var readPositions: [UUID: Date] = [:]
    private(set) var typingNames: [String] = []
    private(set) var isConnected = false
    private(set) var isLoading = true
    private(set) var failure: String?

    /// Photos picked but not yet uploaded, so the bubble shows the picture
    /// immediately and a failed upload can be retried without asking again.
    private(set) var localImages: [UUID: UIImage] = [:]

    private var channel: RealtimeChannelV2?
    private var extrasChannel: RealtimeChannelV2?
    private var tasks: [Task<Void, Never>] = []
    private var typingExpiry: [UUID: Date] = [:]
    /// Name as the sender broadcast it, keyed by profile. See
    /// `refreshTypingNames` for why this beats a local lookup.
    private var typingSenders: [UUID: String] = [:]
    private var lastTypingPing = Date.distantPast
    private var sweeper: Task<Void, Never>?
    private var lastMarkedRead = Date.distantPast

    private let tripID: UUID
    /// Replaced by the view whenever the store's copy of the trip changes, so
    /// somebody who joined mid-conversation gets a name and a face.
    var travellers: [Traveller]

    private var client: SupabaseClient { AuthService.shared.client }

    /// How long a typing ping stays true. Long enough to survive the gap
    /// between keystrokes, short enough that someone who puts their phone
    /// down stops showing as typing almost immediately.
    private static let typingTTL: TimeInterval = 4

    /// The newest this many messages are loaded. Asked for newest-first and
    /// reversed: ascending with a limit returned the *oldest* 200, so a long
    /// thread opened on messages from the week the trip was planned.
    private static let historyLimit = 400

    init(trip: Trip) {
        self.tripID = trip.id
        self.travellers = trip.travellers
    }

    // MARK: - Lifecycle

    func start() async {
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

        let channels = [self.channel, extrasChannel].compactMap { $0 }
        self.channel = nil
        extrasChannel = nil
        Task { for channel in channels { await channel.unsubscribe() } }
    }

    func reload() async {
        await loadHistory()
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let rows: [MessageRow] = try await client
                .from("messages")
                .select()
                .eq("trip_id", value: tripID)
                .order("created_at", ascending: false)
                .limit(Self.historyLimit)
                .execute()
                .value

            // Keep anything still on its way up: a reload mid-send must not
            // make the bubble you just typed disappear.
            let pending = messages.filter { $0.delivery != .sent }
            messages = (rows.reversed().map(\.asMessage) + pending.filter { p in !rows.contains { $0.id == p.id } })
                .sorted { $0.sentAt < $1.sentAt }
            failure = nil
        } catch {
            // A refresh superseded by another pull, or the screen closing, is
            // not a failure — and saying "couldn't load" over a thread that's
            // plainly on screen is worse than saying nothing.
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled
                || "\(error)".localizedCaseInsensitiveContains("cancelled") {
                return
            }
            // An empty thread and a thread we couldn't reach look the same on
            // screen otherwise, and silently pretending it's empty invites
            // someone to type into a void.
            failure = "Couldn't load the conversation."
            return
        }

        // The extras are loaded separately and allowed to fail on their own.
        // A database without 0017 has no such tables, and that should cost the
        // thread its extras, not its messages.
        async let responseRows: [ResponseRow]? = rows(from: "message_responses")
        async let readRows: [ReadRow]? = rows(from: "chat_reads")

        let (loadedResponses, loadedReads) = await (responseRows, readRows)

        if let loadedResponses {
            responses = Dictionary(grouping: loadedResponses.map(\.asResponse).filter { !$0.choices.isEmpty }, by: \.messageID)
        }
        if let loadedReads {
            readPositions = Dictionary(
                loadedReads.filter { $0.profile_id != Traveller.you.id }.map { ($0.profile_id, $0.last_read_at) },
                uniquingKeysWith: max
            )
        }
    }

    /// Every row of one of the chat's side tables for this trip, or nil when
    /// the table can't be read.
    private func rows<Row: Decodable>(from table: String) async -> [Row]? {
        try? await client.from(table).select().eq("trip_id", value: tripID).execute().value
    }

    private func subscribe() async {
        let channel = client.channel("trip-chat:\(tripID.uuidString)")
        self.channel = channel

        let tripFilter = RealtimePostgresFilter.eq("trip_id", value: tripID.uuidString)

        let inserts = channel.postgresChange(InsertAction.self, schema: "public", table: "messages", filter: tripFilter)
        let updates = channel.postgresChange(UpdateAction.self, schema: "public", table: "messages", filter: tripFilter)
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

        listen(inserts) { (service, row: MessageRow) in service.merge(row.asMessage) }
        listen(updates) { (service, row: MessageRow) in service.merge(row.asMessage) }

        tasks.append(Task { [weak self] in
            for await payload in typing {
                guard let self else { return }
                self.handleTyping(payload)
            }
        })

        await subscribeToExtras(filter: tripFilter)
    }

    /// Answers and read positions, on a channel of their own.
    ///
    /// Separate so that a database without 0017's tables — where Realtime
    /// refuses the whole subscription — costs the thread its "Seen", and not
    /// its messages and typing indicator.
    private func subscribeToExtras(filter: RealtimePostgresFilter) async {
        let channel = client.channel("trip-chat-extras:\(tripID.uuidString)")
        extrasChannel = channel

        let responseInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "message_responses", filter: filter)
        let responseUpdates = channel.postgresChange(UpdateAction.self, schema: "public", table: "message_responses", filter: filter)
        let readInserts = channel.postgresChange(InsertAction.self, schema: "public", table: "chat_reads", filter: filter)
        let readUpdates = channel.postgresChange(UpdateAction.self, schema: "public", table: "chat_reads", filter: filter)

        guard (try? await channel.subscribeWithError()) != nil else {
            extrasChannel = nil
            Task { await channel.unsubscribe() }
            return
        }

        listen(responseInserts) { (service, row: ResponseRow) in service.merge(row) }
        listen(responseUpdates) { (service, row: ResponseRow) in service.merge(row) }
        listen(readInserts) { (service, row: ReadRow) in service.merge(row) }
        listen(readUpdates) { (service, row: ReadRow) in service.merge(row) }
    }

    private func listen<Action: HasRecord & Sendable, Row: Decodable>(
        _ stream: AsyncStream<Action>,
        apply: @escaping (ChatService, Row) -> Void
    ) {
        tasks.append(Task { [weak self] in
            for await action in stream {
                guard let self else { return }
                guard let row = try? action.decodeRecord(as: Row.self, decoder: Self.decoder) else { continue }
                apply(self, row)
            }
        })
    }

    // MARK: - Reading

    /// The message a reply is pointing at, for the quote block. Nil once the
    /// original is older than the window we hold.
    func message(_ id: UUID?) -> ChatMessage? {
        guard let id else { return nil }
        return messages.first { $0.id == id }
    }

    func author(of message: ChatMessage) -> Traveller? {
        if message.isMine { return Traveller.you }
        return travellers.first { $0.id == message.authorID }
    }

    /// Name to put on a quote block. Falls back rather than showing an empty
    /// string for someone who has since left the trip.
    func authorName(of message: ChatMessage) -> String {
        if message.isMine { return "You" }
        return author(of: message)?.name ?? "Someone"
    }

    func traveller(_ id: UUID) -> Traveller? {
        if id == Traveller.you.id { return Traveller.you }
        return travellers.first { $0.id == id }
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

    var pinnedMessages: [ChatMessage] {
        messages.filter(\.isPinned).sorted { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }
    }

    func myChoices(for message: ChatMessage) -> [String] {
        responses[message.id]?.first { $0.profileID == Traveller.you.id }?.choices ?? []
    }

    /// Who has chosen a given option, in trip order.
    func people(choosing option: String, on message: ChatMessage) -> [Traveller] {
        (responses[message.id] ?? [])
            .filter { $0.choices.contains(option) }
            .compactMap { traveller($0.profileID) }
    }

    /// Everyone who has answered at all — a poll's turnout.
    func respondents(to message: ChatMessage) -> Int {
        (responses[message.id] ?? []).filter { !$0.choices.isEmpty }.count
    }

    /// Where each other person's "seen" avatar sits: under the last message
    /// they had read, keyed by that message.
    ///
    /// Only messages that finished sending count — a read position can't be
    /// past a bubble that isn't on the server yet.
    func readMarkers() -> [UUID: [Traveller]] {
        let sent = messages.filter { $0.delivery == .sent }
        var markers: [UUID: [Traveller]] = [:]

        for (profileID, readAt) in readPositions {
            guard let person = travellers.first(where: { $0.id == profileID }),
                  let last = sent.last(where: { $0.sentAt <= readAt.addingTimeInterval(1) })
            else { continue }
            markers[last.id, default: []].append(person)
        }
        return markers.mapValues { $0.sorted { $0.name < $1.name } }
    }

    /// People who have read up to or past a message, for the info panel.
    func seen(_ message: ChatMessage) -> [Traveller] {
        readPositions
            .filter { $0.value.addingTimeInterval(1) >= message.sentAt && $0.key != message.authorID }
            .compactMap { id, _ in travellers.first { $0.id == id } }
            .sorted { $0.name < $1.name }
    }

    func search(_ query: String) -> [ChatMessage] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        return Array(messages
            .filter { !$0.isDeleted && $0.preview.localizedStandardContains(needle) }
            .reversed())
    }

    // MARK: - Sending

    func send(_ text: String, attachment: ChatAttachment? = nil, replyingTo parent: ChatMessage? = nil) async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty || attachment != nil else { return }

        let optimistic = ChatMessage(
            id: UUID(),
            tripID: tripID,
            authorID: Traveller.you.id,
            body: body,
            sentAt: Date(),
            replyToID: parent?.id,
            attachment: attachment,
            delivery: .sending
        )
        messages.append(optimistic)

        await deliver(optimistic)
    }

    /// Sends a photo: on screen from the local image at once, uploaded, then
    /// inserted pointing at the uploaded copy.
    func sendPhoto(_ image: UIImage, caption: String, replyingTo parent: ChatMessage? = nil) async {
        let id = UUID()
        localImages[id] = image

        let optimistic = ChatMessage(
            id: id,
            tripID: tripID,
            authorID: Traveller.you.id,
            body: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            sentAt: Date(),
            replyToID: parent?.id,
            // A placeholder URL until the upload says where it lives. The card
            // draws `localImages[id]` first, so this is never fetched.
            attachment: .photo(.init(url: URL(fileURLWithPath: "/"), width: image.size.width, height: image.size.height)),
            delivery: .sending
        )
        messages.append(optimistic)

        await uploadAndDeliver(optimistic)
    }

    /// Re-sends a message that failed. Same id, so a partial success upstream
    /// can't produce a duplicate.
    func retry(_ message: ChatMessage) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
        messages[index].delivery = .sending

        if localImages[message.id] != nil {
            await uploadAndDeliver(messages[index])
        } else {
            await deliver(messages[index])
        }
    }

    /// Drops a message that never made it, for someone who'd rather not retry.
    func discard(_ message: ChatMessage) {
        guard message.delivery == .failed else { return }
        messages.removeAll { $0.id == message.id }
        localImages[message.id] = nil
    }

    private func uploadAndDeliver(_ message: ChatMessage) async {
        guard let image = localImages[message.id], let data = image.jpegForUpload(maxDimension: 2048, quality: 0.82) else {
            mark(message.id, as: .failed)
            return
        }

        do {
            let url = try await MediaStore.shared.uploadChatPhoto(data, messageID: message.id, tripID: tripID)
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
            messages[index].attachment = .photo(.init(url: url, width: image.size.width, height: image.size.height))
            await deliver(messages[index])
        } catch {
            failure = (error as? LocalizedError)?.errorDescription
            mark(message.id, as: .failed)
        }
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
                reply_to_id: message.replyToID,
                kind: message.attachment?.kind ?? "text",
                payload: message.attachment?.payload ?? ChatPayload()
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

    // MARK: - Changing a message

    func edit(_ message: ChatMessage, to text: String) async {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard message.isEditable, !body.isEmpty, body != message.body,
              let index = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        let before = messages[index]
        messages[index].body = body
        messages[index].editedAt = Date()

        do {
            _ = try await client.from("messages").update(["body": body]).eq("id", value: message.id).execute()
        } catch {
            restore(before, saying: "Couldn't save that edit.")
        }
    }

    /// Unsend. The row stays — a reply pointing at it should say "deleted",
    /// not "no longer available" — and the server blanks what it said.
    func unsend(_ message: ChatMessage) async {
        guard message.isMine, !message.isDeleted,
              let index = messages.firstIndex(where: { $0.id == message.id })
        else { return }

        let before = messages[index]
        messages[index].deletedAt = Date()
        messages[index].body = ""
        messages[index].attachment = nil
        messages[index].pinnedAt = nil

        do {
            _ = try await client
                .from("messages")
                .update(["deleted_at": ISO8601DateFormatter.supabase.string(from: Date())])
                .eq("id", value: message.id)
                .execute()
        } catch {
            restore(before, saying: "Couldn't delete that message.")
        }
    }

    /// However many messages a trip can have pinned at once. Past this, the
    /// banner's "All" list would outgrow what a thumb can skim in one glance.
    static let pinLimit = 3

    func setPinned(_ message: ChatMessage, _ pinned: Bool) async {
        guard !message.isDeleted, let index = messages.firstIndex(where: { $0.id == message.id }) else { return }

        if pinned, pinnedMessages.count >= Self.pinLimit {
            GlassToastCenter.shared.show(.init(
                symbol: "pin.slash.fill",
                tint: AppTheme.danger,
                title: "Only \(Self.pinLimit) pins at a time",
                subtitle: "Unpin one to pin this."
            ))
            return
        }

        let before = messages[index]
        messages[index].pinnedAt = pinned ? Date() : nil
        messages[index].pinnedByID = pinned ? Traveller.you.id : nil

        do {
            _ = try await client
                .rpc("set_message_pin", params: [
                    "p_message": AnyJSON.string(message.id.uuidString),
                    "p_pinned": .bool(pinned)
                ])
                .execute()
        } catch {
            restore(before, saying: pinned ? "Couldn't pin that." : "Couldn't unpin that.")
        }
    }

    private func restore(_ message: ChatMessage, saying failureText: String) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        }
        GlassToastCenter.shared.show(.init(
            symbol: "exclamationmark.triangle.fill",
            tint: AppTheme.danger,
            title: failureText,
            subtitle: "Check your connection and try again."
        ))
    }

    /// The insert we made ourselves arrives back through the subscription, so
    /// it's matched on id rather than appended — otherwise every message you
    /// send would appear twice.
    private func merge(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            // The echo is proof it landed, and downgrading a `.sent` bubble
            // back through an animation serves nobody.
            var incoming = message
            incoming.delivery = .sent
            messages[index] = incoming
            localImages[message.id] = nil
        } else {
            messages.append(message)
            messages.sort { $0.sentAt < $1.sentAt }
        }
    }

    // MARK: - Answers

    func vote(_ optionID: String, on message: ChatMessage) async {
        guard case .poll(let poll) = message.attachment else { return }
        var choices = myChoices(for: message)

        if choices.contains(optionID) {
            choices.removeAll { $0 == optionID }
        } else if poll.allowsMultiple {
            choices.append(optionID)
        } else {
            choices = [optionID]
        }
        await respond(to: message, with: choices)
    }

    func rsvp(_ answer: ChatAttachment.RSVP, to message: ChatMessage) async {
        let current = myChoices(for: message)
        await respond(to: message, with: current == [answer.rawValue] ? [] : [answer.rawValue])
    }

    /// "I've got this one" on a bring-list. Several people can cover the same
    /// item — two bottles of sunscreen is a smaller problem than none.
    func toggleCovered(_ itemID: String, on message: ChatMessage) async {
        var choices = myChoices(for: message)
        if choices.contains(itemID) {
            choices.removeAll { $0 == itemID }
        } else {
            choices.append(itemID)
        }
        await respond(to: message, with: choices)
    }

    private func respond(to message: ChatMessage, with choices: [String]) async {
        guard !message.isDeleted, message.delivery == .sent else { return }
        let before = responses[message.id]

        apply(ResponseRow(message_id: message.id, trip_id: tripID, profile_id: Traveller.you.id, choices: choices))
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        do {
            let profile = try await SupabaseRepository.shared.resolveProfile()
            let row = ResponseRow(message_id: message.id, trip_id: tripID, profile_id: profile, choices: choices)
            _ = try await client
                .from("message_responses")
                .upsert(row, onConflict: "message_id,profile_id")
                .execute()
        } catch {
            responses[message.id] = before
            GlassToastCenter.shared.show(.init(
                symbol: "exclamationmark.triangle.fill",
                tint: AppTheme.danger,
                title: "Your answer didn't save",
                subtitle: "Check your connection and try again."
            ))
        }
    }

    private func merge(_ row: ResponseRow) {
        guard row.trip_id == tripID else { return }
        apply(row)
    }

    private func apply(_ row: ResponseRow) {
        var list = responses[row.message_id] ?? []
        list.removeAll { $0.profileID == row.profile_id }
        if !row.choices.isEmpty { list.append(row.asResponse) }
        responses[row.message_id] = list.isEmpty ? nil : list
    }

    // MARK: - Read positions

    /// Records that you've seen everything currently in the thread.
    ///
    /// Stamped with the newest message's own time rather than the clock, so
    /// "seen" is measured on the same timeline as the messages it's compared
    /// against — a phone whose clock runs slow would otherwise never catch up.
    func markRead() async {
        guard let newest = messages.last(where: { $0.delivery == .sent })?.sentAt,
              newest > lastMarkedRead
        else { return }
        lastMarkedRead = newest

        guard let profile = try? await SupabaseRepository.shared.resolveProfile() else { return }
        let row = ReadRow(trip_id: tripID, profile_id: profile, last_read_at: newest)
        _ = try? await client.from("chat_reads").upsert(row, onConflict: "trip_id,profile_id").execute()
    }

    private func merge(_ row: ReadRow) {
        guard row.trip_id == tripID, row.profile_id != Traveller.you.id else { return }
        readPositions[row.profile_id] = max(readPositions[row.profile_id] ?? .distantPast, row.last_read_at)
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

    private func handleTyping(_ message: JSONObject) {
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
                self.refreshTypingNames()
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
            if let date = lenientDate(text) { return date }
            return Date()
        }
        return decoder
    }()

    /// Postgres' own spelling of a timestamp, which Realtime passes through
    /// untouched: `2026-09-15 10:04:31.418226+00`. A space for the `T`,
    /// microseconds, and an offset with no minutes — three things
    /// `ISO8601DateFormatter` rejects. Falling through to `Date()` put every
    /// realtime read position at "now", so "Seen" jumped to the newest message
    /// the moment anybody opened the thread.
    private nonisolated static func lenientDate(_ raw: String) -> Date? {
        var text = raw.replacingOccurrences(of: " ", with: "T")

        if let dot = text.firstIndex(of: "."),
           let zone = text[dot...].firstIndex(where: { $0 == "+" || $0 == "-" || $0 == "Z" }) {
            let fraction = text[text.index(after: dot)..<zone]
            text.replaceSubrange(text.index(after: dot)..<zone, with: String(fraction.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0))
        }

        if let zone = text.lastIndex(where: { $0 == "+" || $0 == "-" }), text.distance(from: zone, to: text.endIndex) == 3 {
            text += ":00"
        }

        // Local formatters: this runs inside the decoder, off the main actor,
        // where the shared ones can't be reached.
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let whole = ISO8601DateFormatter()
        whole.formatOptions = [.withInternetDateTime]
        return fractional.date(from: text) ?? whole.date(from: text)
    }
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
