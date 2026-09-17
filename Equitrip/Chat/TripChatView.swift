//
//  TripChatView.swift
//  Equitrip
//

import SwiftUI
import PhotosUI

/// A trip's group chat.
///
/// Home opens the thread for the trip happening now; each trip's own screen
/// opens its thread, because most of a trip is decided in the chat weeks before
/// anyone packs — which dates, which villa, who's bringing the speaker.
///
/// The thread is built around replies. A group planning a trip talks about six
/// things at once — the flight, the villa deposit, who's diving — and a flat
/// wall of messages loses which answer belongs to which question. Quoting the
/// message you're answering is the cheapest way to keep that legible without
/// forking the conversation into threads nobody reads.
///
/// And it's built around the trip. A message can carry the trip's own things —
/// a booking, the balances — drawn live from the ledger, plus the things a
/// group needs to decide together: polls, meetups, bring-lists, places.
struct TripChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store
    @Environment(\.scenePhase) private var scenePhase

    /// The trip as it was when the chat opened. Read through `liveTrip`, which
    /// prefers the store's current copy so cards follow the ledger.
    let trip: Trip

    @State private var chat: ChatService
    @State private var draft = ""
    @State private var replyTarget: ChatMessage?
    @State private var editTarget: ChatMessage?
    /// Briefly lit after jumping to a message, so the eye can find it.
    @State private var highlighted: UUID?
    /// A message to scroll to, set from outside the scroll view — the details
    /// sheet, the pinned banner.
    @State private var pendingJump: UUID?
    /// Which pinned message the banner is currently showing — tapping it
    /// advances this, cycling through the pinned set one at a time.
    @State private var pinCycleIndex = 0
    @State private var trayOpen = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var choosingPhoto = false
    @State private var sheet: ChatSheet?
    @State private var viewingPhoto: ReceiptRef?
    @State private var deleting: ChatMessage?
    @State private var isAtBottom = true
    /// Messages from other people that arrived while you were scrolled up.
    @State private var unseenCount = 0
    @FocusState private var composerFocused: Bool

    /// `draft` is words already in the composer when the thread opens — how
    /// Siri's "draft a message to the Goa group" arrives. Left unsent: a draft
    /// is the person's to read over, not the app's to post.
    init(trip: Trip, draft: String = "") {
        self.trip = trip
        _chat = State(initialValue: ChatService(trip: trip))
        _draft = State(initialValue: draft)
    }

    private var liveTrip: Trip { store.trip(trip.id) ?? trip }

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollViewReader { proxy in
                thread(proxy: proxy)
                    .onChange(of: pendingJump) { _, id in
                        guard let id else { return }
                        pendingJump = nil
                        jump(to: id, using: proxy)
                    }
            }

            if chat.isLoading, chat.messages.isEmpty {
                LoadingState(message: "Loading the conversation…")
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { composer }
        .task { await chat.start(); await chat.markRead() }
        .onDisappear { chat.stop() }
        // "Tell them I'm on my way" — see `OnscreenEntities`.
        .onscreenChat(trip)
        .onChange(of: liveTrip.travellers) { _, travellers in chat.travellers = travellers }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, isAtBottom { Task { await chat.markRead() } }
        }
        .photosPicker(isPresented: $choosingPhoto, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            send(photo: item)
        }
        .onChange(of: composerFocused) { _, focused in
            if focused, trayOpen {
                withAnimation(.snappy(duration: 0.26)) { trayOpen = false }
            }
        }
        // Resign before any sheet goes up. UIKit hands first responder back
        // to whatever held it when the sheet was presented, so a keyboard
        // that was up at the time would rise again the moment it closes.
        .onChange(of: sheet?.id) { _, id in
            if id != nil { composerFocused = false }
        }
        .sheet(item: $sheet) { sheet in
            sheetContent(sheet)
        }
        .fullScreenCover(item: $viewingPhoto) { photo in
            ReceiptPreview(url: photo.url, caption: nil)
        }
        .confirmationDialog(
            "Delete this message for everyone?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible,
            presenting: deleting
        ) { message in
            Button("Delete for everyone", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                Task { await chat.unsend(message) }
            }
        } message: { _ in
            Text("Everyone on the trip will see that a message was deleted.")
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: chat.messages.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: chat.typingNames)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: replyTarget?.id)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: editTarget?.id)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: currentPinned?.id)
    }

    private static let bottomAnchor = "chat-bottom"

    // MARK: - Thread

    private func thread(proxy: ScrollViewProxy) -> some View {
        let markers = chat.readMarkers()
        let actions = rowActions(proxy: proxy)

        return ScrollView {
            LazyVStack(spacing: 0) {
                threadOpening

                ForEach(Array(chat.messages.enumerated()), id: \.element.id) { index, message in
                    let group = grouping(at: index)

                    if group.showsDayBreak {
                        ChatDayDivider(date: message.sentAt)
                    }

                    ChatBubbleRow(
                        message: message,
                        trip: liveTrip,
                        chat: chat,
                        run: group.run,
                        isHighlighted: highlighted == message.id,
                        seenBy: markers[message.id] ?? [],
                        actions: actions
                    )
                    .id(message.id)
                }

                if !chat.typingNames.isEmpty {
                    TypingBubble(names: chat.typingNames, people: chat.typingPeople)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                Color.clear
                    .frame(height: 6)
                    .id(Self.bottomAnchor)
            }
            .padding(.horizontal, 14)
            // A group thread is a column of speech, and speech reads
            // badly at 1200pt: a bubble that wide puts the sender's
            // avatar and the end of their sentence a foot apart, and
            // a run of one-word replies turns into a stack of tiny
            // capsules stranded in a field of peach.
            .readableWidth()
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .defaultScrollAnchor(.bottom)
        .refreshable { await chat.reload() }
        // Read from the scroll position, not from the bottom row appearing.
        // That row lives in a lazy stack, and a sheet rising over the thread
        // resizes it: the row dropped out of the lazy window, `isAtBottom`
        // flipped, the jump button's animation re-laid the stack, the row came
        // back — and the app spun at 100% CPU with the sheet never presenting.
        // A value derived from geometry, with slack, can't chase its own tail.
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.visibleRect.maxY >= geometry.contentSize.height - 60
        } action: { _, atBottom in
            guard atBottom != isAtBottom else { return }
            isAtBottom = atBottom
            if atBottom {
                unseenCount = 0
                Task { await chat.markRead() }
            }
        }
        .onChange(of: chat.messages.count) { old, new in
            guard new > old else { return }
            let newest = chat.messages.last
            if isAtBottom || newest?.isMine == true {
                scrollToBottom(proxy)
            } else {
                unseenCount += new - old
            }
        }
        .onChange(of: chat.typingNames) { _, _ in
            if isAtBottom { scrollToBottom(proxy) }
        }
        .onChange(of: composerFocused) { _, focused in
            if focused { scrollToBottom(proxy) }
        }
        .onChange(of: trayOpen) { _, open in
            if open { scrollToBottom(proxy) }
        }
        .overlay(alignment: .bottomTrailing) {
            if !isAtBottom, !chat.messages.isEmpty {
                JumpToLatestButton(unseen: unseenCount) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    scrollToBottom(proxy)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isAtBottom)
    }

    private func rowActions(proxy: ScrollViewProxy) -> ChatRowActions {
        ChatRowActions(
            reply: { begin(replyTo: $0) },
            jump: { jump(to: $0, using: proxy) },
            retry: { message in Task { await chat.retry(message) } },
            discard: { chat.discard($0) },
            pin: { message, pinned in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await chat.setPinned(message, pinned) }
            },
            edit: { begin(editing: $0) },
            delete: { deleting = $0 },
            info: { sheet = .info($0) },
            openBooking: { sheet = .booking($0) },
            openPhoto: { url, _ in viewingPhoto = ReceiptRef(url: url) }
        )
    }

    // MARK: - Actions

    private func begin(replyTo message: ChatMessage) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if editTarget != nil {
            editTarget = nil
            draft = ""
        }
        replyTarget = message
        composerFocused = true
    }

    private func begin(editing message: ChatMessage) {
        replyTarget = nil
        editTarget = message
        draft = message.body
        trayOpen = false
        composerFocused = true
    }

    private func cancelContext() {
        if editTarget != nil { draft = "" }
        editTarget = nil
        replyTarget = nil
    }

    private func jump(to id: UUID, using proxy: ScrollViewProxy) {
        guard chat.message(id) != nil else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            proxy.scrollTo(id, anchor: .center)
            highlighted = id
        }

        // Long enough to notice, short enough not to become a selection state.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))
            withAnimation(.easeOut(duration: 0.4)) { highlighted = nil }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }

    private func sendDraft() {
        let text = draft
        draft = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if let editing = editTarget {
            editTarget = nil
            Task { await chat.edit(editing, to: text) }
            return
        }

        let parent = replyTarget
        replyTarget = nil
        Task { await chat.send(text, replyingTo: parent) }
        SiriDonations.messageSent(text.trimmingCharacters(in: .whitespacesAndNewlines), in: liveTrip)
    }

    private func send(_ attachment: ChatAttachment) {
        let parent = replyTarget
        replyTarget = nil
        trayOpen = false
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task { await chat.send("", attachment: attachment, replyingTo: parent) }
    }

    /// A picked photo goes with whatever's in the field as its caption — the
    /// "look at this view" people were already typing when they reached for it.
    private func send(photo item: PhotosPickerItem) {
        let caption = draft
        let parent = replyTarget
        draft = ""
        replyTarget = nil
        trayOpen = false

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                GlassToastCenter.shared.show(.init(
                    symbol: "photo.badge.exclamationmark",
                    tint: AppTheme.danger,
                    title: "Couldn't read that photo",
                    subtitle: "Try picking it again."
                ))
                return
            }
            await chat.sendPhoto(image, caption: caption, replyingTo: parent)
        }
    }

    private func use(_ tool: ChatComposeTool) {
        composerFocused = false
        switch tool {
        case .photo: choosingPhoto = true
        case .place: sheet = .place
        case .booking: sheet = .bookingPicker
        case .poll: sheet = .poll
        case .meetup: sheet = .meetup
        case .checklist: sheet = .checklist
        case .balances: send(.balances)
        }
    }

    // MARK: - Sheets

    enum ChatSheet: Identifiable {
        case poll, meetup, checklist, place, bookingPicker, people, invite
        case booking(ItineraryItem)
        case info(ChatMessage)
        case details(ChatDetailsSheet.Shelf)

        var id: String {
            switch self {
            case .poll: "poll"
            case .meetup: "meetup"
            case .checklist: "checklist"
            case .place: "place"
            case .bookingPicker: "booking-picker"
            case .people: "people"
            case .invite: "invite"
            case .booking(let item): "booking-\(item.id)"
            case .info(let message): "info-\(message.id)"
            case .details(let shelf): "details-\(shelf.rawValue)"
            }
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ChatSheet) -> some View {
        switch sheet {
        case .poll:
            ChatPollComposer(onSend: send)
        case .meetup:
            ChatMeetupComposer(trip: liveTrip, onSend: send)
        case .checklist:
            ChatChecklistComposer(trip: liveTrip, onSend: send)
        case .place:
            ChatPlacePicker(trip: liveTrip, onPick: send)
        case .bookingPicker:
            ChatBookingPicker(trip: liveTrip) { send(.booking(itemID: $0.id)) }
        case .people:
            ChatPeopleSheet(
                trip: liveTrip,
                chat: chat,
                onMention: { person in
                    self.sheet = nil
                    mention(person)
                },
                onInvite: {
                    self.sheet = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        self.sheet = .invite
                    }
                }
            )
        case .invite:
            TripInviteSheet(trip: liveTrip)
        case .booking(let item):
            ItineraryItemDetailView(item: liveTrip.items.first { $0.id == item.id } ?? item, trip: liveTrip)
        case .info(let message):
            ChatMessageInfoSheet(message: chat.message(message.id) ?? message, chat: chat, trip: liveTrip)
        case .details(let shelf):
            ChatDetailsSheet(
                chat: chat,
                trip: liveTrip,
                startOn: shelf,
                onJump: { id in
                    // After the sheet's own dismissal, or the scroll runs
                    // underneath an animation and lands short.
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        pendingJump = id
                    }
                },
                onOpenPhoto: { url, _ in
                    self.sheet = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        viewingPhoto = ReceiptRef(url: url)
                    }
                }
            )
        }
    }

    // MARK: - Header

    /// The pinned message the banner shows. Clamped rather than trusted,
    /// since `pinCycleIndex` can outrun the set — someone unpins one, or a
    /// realtime pin from someone else shrinks it — between one tap and the next.
    private var currentPinned: ChatMessage? {
        let pins = chat.pinnedMessages
        guard !pins.isEmpty else { return nil }
        return pins[min(pinCycleIndex, pins.count - 1)]
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            header

            if let pinned = currentPinned {
                let pins = chat.pinnedMessages
                PinnedBanner(
                    message: pinned,
                    authorName: chat.authorName(of: pinned),
                    index: pinCycleIndex,
                    count: pins.count,
                    onOpen: {
                        pendingJump = pinned.id
                        if pins.count > 1 { pinCycleIndex = (pinCycleIndex + 1) % pins.count }
                    },
                    onShowAll: { sheet = .details(.pinned) }
                )
                .padding(.horizontal, 14)
                .readableWidth()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.bottom, 10)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CircleGlyphButton(symbol: "chevron.down", size: 36) { dismiss() }
                .accessibilityLabel("Close chat")

            Button { sheet = .details(.pinned) } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(liveTrip.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusTint)
                            .frame(width: 5, height: 5)

                        Text(subtitle)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(chat.failure == nil ? AppTheme.inkTertiary : AppTheme.danger)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows pinned messages, photos, places and plans")

            CircleGlyphButton(symbol: "magnifyingglass", size: 36) { sheet = .details(.pinned) }
                .accessibilityLabel("Search and shared items")

            Button { sheet = .people } label: {
                AvatarStack(travellers: liveTrip.travellers, size: 28, max: 3, departedIDs: liveTrip.departedIDs)
                    .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("People on this trip")
        }
        .padding(.horizontal, 18)
        .readableWidth()
        .padding(.top, 6)
    }

    private var statusTint: Color {
        if chat.failure != nil { return AppTheme.danger }
        return chat.isConnected ? AppTheme.positive : AppTheme.inkTertiary
    }

    private var subtitle: String {
        if let failure = chat.failure { return failure }
        if !chat.isConnected { return "Connecting…" }
        if !chat.typingNames.isEmpty { return typingSummary }
        return liveTrip.travellers.count == 1 ? "Just you" : headcount
    }

    private var typingSummary: String {
        let names = chat.typingNames
        switch names.count {
        case 1: return "\(names[0]) is typing…"
        case 2: return "\(names[0]) and \(names[1]) are typing…"
        default: return "\(names.count) people are typing…"
        }
    }

    // MARK: - Thread opening

    /// A short marker for the top of the thread rather than a bare edge, so
    /// scrolling to the beginning lands somewhere deliberate. On a thread with
    /// no messages it gives way to `ChatThreadOpening`, which is the whole
    /// screen.
    @ViewBuilder
    private var threadOpening: some View {
        if chat.messages.isEmpty {
            // The thread is bottom-anchored, which is right once there are
            // messages and wrong when there are none — an empty thread would
            // pin its own opening to the keyboard. Filling the container
            // centres it.
            Group {
                if chat.isLoading {
                    EmptyView()
                } else {
                    ChatThreadOpening(trip: liveTrip, headcount: headcount)
                }
            }
            .containerRelativeFrame(.vertical, alignment: .center)
        } else {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(liveTrip.tint.opacity(0.14))
                        .frame(width: 48, height: 48)

                    Image(systemName: liveTrip.symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(liveTrip.tint)
                }

                Text(liveTrip.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("\(liveTrip.dateRange) · \(headcount)")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
    }

    /// Puts "@Name " at the end of the draft and hands over the keyboard.
    private func mention(_ person: Traveller) {
        let spacer = draft.isEmpty || draft.last?.isWhitespace == true ? "" : " "
        draft += "\(spacer)@\(person.name) "
        trayOpen = false
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            composerFocused = true
        }
    }

    /// "1 person", not "1 people".
    private var headcount: String {
        liveTrip.travellers.count.pluralised("person", "people")
    }

    // MARK: - Composer

    private var composer: some View {
        ChatComposer(
            draft: $draft,
            context: editTarget.map { (.edit, $0) } ?? replyTarget.map { (.reply, $0) },
            contextAuthorName: (editTarget ?? replyTarget).map(chat.authorName) ?? "",
            mentionable: liveTrip.travellers.filter { $0.id != Traveller.you.id && !liveTrip.invitedIDs.contains($0.id) },
            trayOpen: $trayOpen,
            focus: $composerFocused,
            onSend: sendDraft,
            onCancelContext: cancelContext,
            onTyping: { chat.noteTyping() },
            onTool: use
        )
    }

    // MARK: - Grouping

    /// Consecutive messages from one person in a short window are drawn as a
    /// run — only the last keeps a tail and an avatar, only the first keeps a
    /// name. This is most of what makes a thread read like a conversation
    /// rather than a table.
    private func grouping(at index: Int) -> (run: BubbleRun, showsDayBreak: Bool) {
        let message = chat.messages[index]
        let previous = index > 0 ? chat.messages[index - 1] : nil
        let next = index + 1 < chat.messages.count ? chat.messages[index + 1] : nil

        // A reply always starts its own run: it carries a quote block above the
        // text, and tucking that into the middle of a run reads as a caption on
        // the message before it. A card does too, for the same reason — it's a
        // thing in its own right, not the next line of a sentence.
        func standsAlone(_ message: ChatMessage) -> Bool {
            message.replyToID != nil || message.attachment != nil
        }

        func continues(_ earlier: ChatMessage, _ later: ChatMessage) -> Bool {
            !standsAlone(later)
                && later.authorID == earlier.authorID
                && later.sentAt.timeIntervalSince(earlier.sentAt) < 120
                && Calendar.current.isDate(earlier.sentAt, inSameDayAs: later.sentAt)
        }

        let continuesFrom = previous.map { continues($0, message) } ?? false
        let continuesInto = next.map { continues(message, $0) } ?? false

        let dayBreak = previous.map {
            !Calendar.current.isDate($0.sentAt, inSameDayAs: message.sentAt)
        } ?? true

        return (BubbleRun(isFirst: !continuesFrom, isLast: !continuesInto), dayBreak)
    }
}
