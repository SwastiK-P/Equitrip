//
//  TripChatView.swift
//  Equitrip
//

import SwiftUI

/// Group chat for the trip that's happening now.
///
/// Scoped to the ongoing trip on purpose: a chat per trip, forever, becomes
/// three dead threads and one live one. The conversation that matters is the
/// one about the thing you're currently doing.
///
/// The thread is built around replies. A group planning a trip talks about six
/// things at once — the flight, the villa deposit, who's diving — and a flat
/// wall of messages loses which answer belongs to which question. Quoting the
/// message you're answering is the cheapest way to keep that legible without
/// forking the conversation into threads nobody reads.
struct TripChatView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip

    @State private var chat: ChatService
    @State private var draft = ""
    @State private var replyTarget: ChatMessage?
    /// Briefly lit after jumping to a quoted message, so the eye can find it.
    @State private var highlighted: UUID?
    @FocusState private var composerFocused: Bool

    init(trip: Trip) {
        self.trip = trip
        _chat = State(initialValue: ChatService(trip: trip))
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        threadOpening

                        ForEach(Array(chat.messages.enumerated()), id: \.element.id) { index, message in
                            let group = grouping(at: index)

                            if group.showsDayBreak {
                                DayDivider(date: message.sentAt)
                            }

                            ChatBubbleRow(
                                message: message,
                                author: chat.author(of: message),
                                authorName: chat.authorName(of: message),
                                quoted: chat.message(message.replyToID),
                                quotedAuthorName: chat.message(message.replyToID).map(chat.authorName),
                                run: group.run,
                                isHighlighted: highlighted == message.id,
                                onReply: { begin(replyTo: message) },
                                onJump: { jump(to: $0, using: proxy) },
                                onRetry: { Task { await chat.retry(message) } }
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

                        Color.clear.frame(height: 6).id(Self.bottomAnchor)
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
                .onChange(of: chat.messages.count) { _, _ in scrollToBottom(proxy) }
                .onChange(of: chat.typingNames) { _, _ in scrollToBottom(proxy) }
                .onChange(of: composerFocused) { _, focused in
                    if focused { scrollToBottom(proxy) }
                }
            }

            if chat.isLoading, chat.messages.isEmpty {
                LoadingState(message: "Loading the conversation…")
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) { composerBar }
        .task { await chat.start() }
        .onDisappear { chat.stop() }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: chat.messages.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: chat.typingNames)
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: replyTarget?.id)
    }

    private static let bottomAnchor = "chat-bottom"

    // MARK: - Actions

    private func begin(replyTo message: ChatMessage) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        replyTarget = message
        composerFocused = true
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

    private func send() {
        let text = draft
        let parent = replyTarget
        draft = ""
        replyTarget = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await chat.send(text, replyingTo: parent) }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            CircleGlyphButton(symbol: "chevron.down", size: 36) { dismiss() }
                .accessibilityLabel("Close chat")

            VStack(alignment: .leading, spacing: 1) {
                Text(trip.title)
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

            Spacer(minLength: 6)

            AvatarStack(travellers: trip.travellers, size: 28, max: 3, departedIDs: trip.departedIDs)
        }
        .padding(.horizontal, 18)
        .readableWidth()
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var statusTint: Color {
        if chat.failure != nil { return AppTheme.danger }
        return chat.isConnected ? AppTheme.positive : AppTheme.inkTertiary
    }

    private var subtitle: String {
        if let failure = chat.failure { return failure }
        if !chat.isConnected { return "Connecting…" }
        if !chat.typingNames.isEmpty { return typingSummary }
        return trip.travellers.count == 1 ? "Just you" : headcount
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
    /// scrolling to the beginning lands somewhere deliberate. Doubles as the
    /// empty state — on a thread with no messages this is the whole screen,
    /// and it already says what the conversation is for.
    @ViewBuilder
    private var threadOpening: some View {
        let card = VStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(trip.tint.opacity(0.14))
                    .frame(width: 54, height: 54)

                Image(systemName: trip.symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(trip.tint)
            }

            Text(trip.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(chat.messages.isEmpty
                 ? "Say something to \(headcount) on this trip."
                 : "\(trip.dateRange) · \(headcount)")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)

        // The thread is bottom-anchored, which is right once there are
        // messages and wrong when there are none — an empty thread would pin
        // its own opening to the keyboard. Filling the container centres it.
        if chat.messages.isEmpty {
            card.containerRelativeFrame(.vertical, alignment: .center)
        } else {
            card.padding(.top, 18).padding(.bottom, 22)
        }
    }

    /// "1 person", not "1 people".
    private var headcount: String {
        let count = trip.travellers.count
        return "\(count) \(count == 1 ? "person" : "people")"
    }

    // MARK: - Composer

    private var composerBar: some View {
        VStack(spacing: 0) {
            if let replyTarget {
                ReplyPreview(
                    authorName: chat.authorName(of: replyTarget),
                    text: replyTarget.body,
                    isMine: replyTarget.isMine,
                    onCancel: { self.replyTarget = nil }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            composer
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) { Hairline() }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 9) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField(replyTarget == nil ? "Message" : "Reply", text: $draft, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1...5)
                    .focused($composerFocused)
                    .onChange(of: draft) { _, new in
                        if !new.isEmpty { chat.noteTyping() }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(minHeight: 40)
            .background { Capsule().fill(AppTheme.card) }
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.08)) }

            if canSend {
                Button(action: send) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentDeep],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: .circle
                        )
                }
                .buttonStyle(PressableButtonStyle())
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .readableWidth()
        .padding(.top, 8)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: canSend)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        // the message before it.
        let continuesFrom = message.replyToID == nil && (previous.map {
            $0.authorID == message.authorID
                && message.sentAt.timeIntervalSince($0.sentAt) < 120
                && Calendar.current.isDate($0.sentAt, inSameDayAs: message.sentAt)
        } ?? false)

        let continuesInto = next.map {
            $0.replyToID == nil
                && $0.authorID == message.authorID
                && $0.sentAt.timeIntervalSince(message.sentAt) < 120
                && Calendar.current.isDate($0.sentAt, inSameDayAs: message.sentAt)
        } ?? false

        let dayBreak = previous.map {
            !Calendar.current.isDate($0.sentAt, inSameDayAs: message.sentAt)
        } ?? true

        return (BubbleRun(isFirst: !continuesFrom, isLast: !continuesInto), dayBreak)
    }
}

// MARK: - Bubble geometry

struct BubbleRun {
    let isFirst: Bool
    let isLast: Bool
}

// MARK: - Day divider

private struct DayDivider: View {
    let date: Date

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.inkSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(AppTheme.card.opacity(0.75), in: .capsule)
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.06)) }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }

    private var label: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return DateFormatter.cached("EEEE d MMMM").string(from: date)
    }
}

// MARK: - Row

/// One message, with everything you can do to it.
///
/// Swipe right to reply — the same gesture every group chat has trained people
/// to expect, and much less friction than a long-press menu for the thing
/// they'll do most often. The menu is still there for the rest.
private struct ChatBubbleRow: View {
    let message: ChatMessage
    let author: Traveller?
    let authorName: String
    let quoted: ChatMessage?
    let quotedAuthorName: String?
    let run: BubbleRun
    let isHighlighted: Bool
    var onReply: () -> Void
    var onJump: (UUID) -> Void
    var onRetry: () -> Void

    @State private var dragX: CGFloat = 0
    @State private var armed = false

    /// Far enough that a lazy horizontal wobble during a scroll can't fire it.
    private static let trigger: CGFloat = 54

    var body: some View {
        ZStack(alignment: .leading) {
            replyAffordance

            content
                .offset(x: dragX)
        }
        .gesture(swipeToReply)
        .contextMenu {
            Button("Reply", systemImage: "arrowshape.turn.up.left", action: onReply)
            Button("Copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.body
            }
        }
    }

    // MARK: Gesture

    private var swipeToReply: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { value in
                // Vertical intent belongs to the scroll view, always.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                let raw = max(0, value.translation.width)
                // Rubber-banding past the trigger point: the row keeps
                // responding to the finger without sliding off the screen.
                dragX = raw > Self.trigger
                    ? Self.trigger + (raw - Self.trigger) * 0.25
                    : raw

                if dragX >= Self.trigger, !armed {
                    armed = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else if dragX < Self.trigger, armed {
                    armed = false
                }
            }
            .onEnded { _ in
                if armed { onReply() }
                armed = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragX = 0 }
            }
    }

    /// The arrow revealed under the bubble as it slides. Tracks the drag
    /// rather than appearing at the end, so the gesture explains itself the
    /// first time someone tries it by accident.
    private var replyAffordance: some View {
        let progress = min(1, dragX / Self.trigger)

        return Image(systemName: "arrowshape.turn.up.left.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(armed ? AppTheme.accent : AppTheme.inkTertiary)
            .frame(width: 30, height: 30)
            .background(AppTheme.card.opacity(0.9), in: .circle)
            .overlay { Circle().strokeBorder(AppTheme.cardStroke.opacity(0.07)) }
            .scaleEffect(0.6 + 0.4 * progress)
            .opacity(progress)
            .padding(.leading, 2)
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: message.isMine ? .trailing : .leading, spacing: 2) {
            if run.isFirst, !message.isMine {
                Text(authorName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, Self.textInset)
            }

            // Only the bubble and the avatar share this row. The name and the
            // timestamp used to sit in it too, which dragged the avatar down
            // to the timestamp's baseline instead of the bubble's — a face
            // floating below the message it belongs to.
            HStack(alignment: .bottom, spacing: 7) {
                if message.isMine { Spacer(minLength: 40) } else { gutter }
                bubble
                if message.isMine { gutter } else { Spacer(minLength: 40) }
            }

            footer
                .padding(message.isMine ? .trailing : .leading, Self.textInset)
        }
        .padding(.bottom, run.isLast ? 8 : 1)
    }

    /// Avatar (26) + its spacing (7) + the bubble's own text inset (12), so a
    /// name or timestamp lines up with the words rather than the bubble edge.
    private static let textInset: CGFloat = 45

    @ViewBuilder
    private var footer: some View {
        if message.delivery == .failed {
            Button(action: onRetry) {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Not sent · Tap to retry")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundStyle(AppTheme.danger)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)
        } else if run.isLast {
            Text(DateFormatter.cached("h:mm a").string(from: message.sentAt))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.top, 1)
        }
    }

    /// Whoever sent it, on their own side. Both sides get a face: in a group
    /// where you're one voice among several, your own messages are as much
    /// "who said this" as anyone else's.
    ///
    /// The gutter is held even when no avatar is drawn, so a run of messages
    /// stays in one column instead of stepping sideways under the last one.
    private var gutter: some View {
        Group {
            if run.isLast, let face = message.isMine ? Traveller.you : author {
                TravellerAvatar(traveller: face, size: 26)
            } else {
                Color.clear
            }
        }
        .frame(width: 26, height: 26)
    }

    /// Everything inside a bubble is leading-aligned, whoever sent it.
    ///
    /// The bubble is trailing-aligned in the row; its *contents* are not. When
    /// they were, a reply left a wedge of empty bubble to the left of the text
    /// — the quote block is wider than a short reply, so the text slid right
    /// to the far edge and the bubble looked broken.
    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let quoted, let quotedAuthorName {
                Button {
                    onJump(quoted.id)
                } label: {
                    QuoteBlock(
                        authorName: quotedAuthorName,
                        text: quoted.body,
                        onDark: message.isMine
                    )
                }
                .buttonStyle(.plain)
            } else if message.replyToID != nil {
                // The original is gone — deleted, or older than the window we
                // hold. Saying so beats a reply that answers nothing visible.
                QuoteBlock(
                    authorName: "Original message",
                    text: "No longer available",
                    onDark: message.isMine
                )
            }

            Text(message.body)
                .font(.system(size: 16))
                .foregroundStyle(message.isMine ? .white : AppTheme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background { BubbleBackground(isMine: message.isMine, run: run) }
        .overlay {
            // The jump highlight. A wash rather than a border, so it reads on
            // both the accent bubble and the card one.
            BubbleShape(isMine: message.isMine, run: run)
                .fill(AppTheme.accent.opacity(isHighlighted ? 0.28 : 0))
                .allowsHitTesting(false)
        }
        .opacity(message.delivery == .sending ? 0.55 : 1)
        .animation(.easeOut(duration: 0.3), value: isHighlighted)
    }
}

// MARK: - Quote

/// The message being answered, drawn inside the reply that answers it.
///
/// Two lines maximum. A quote that reproduces the whole original doubles the
/// length of the thread and buries the reply, which is the opposite of what
/// quoting is for.
private struct QuoteBlock: View {
    let authorName: String
    let text: String
    /// Quotes inside your own bubble sit on the accent gradient, so they need
    /// white-on-translucent rather than ink-on-card.
    let onDark: Bool

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(onDark ? Color.white.opacity(0.65) : AppTheme.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(authorName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(onDark ? Color.white.opacity(0.9) : AppTheme.accent)

                Text(text)
                    .font(.system(size: 12.5))
                    .foregroundStyle(onDark ? Color.white.opacity(0.75) : AppTheme.inkSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

        }
        .padding(.leading, 7)
        .padding(.trailing, 9)
        .padding(.vertical, 6)
        .background(
            (onDark ? Color.white.opacity(0.16) : AppTheme.accent.opacity(0.08)),
            in: .rect(cornerRadius: 10, style: .continuous)
        )
    }
}

/// The same quote, above the composer, while you're writing the reply.
private struct ReplyPreview: View {
    let authorName: String
    let text: String
    let isMine: Bool
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(AppTheme.accent)
                .frame(width: 3, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(isMine ? "Replying to yourself" : "Replying to \(authorName)")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)

                Text(text)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.card.opacity(0.8), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel reply")
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 2)
    }
}

// MARK: - Bubble background

/// A rounded rect whose corners tighten where a run continues, so a group of
/// messages reads as one block with a single tail.
private struct BubbleShape: Shape {
    let isMine: Bool
    let run: BubbleRun

    func path(in rect: CGRect) -> Path {
        let tight: CGFloat = 6
        let round: CGFloat = 19

        let radii = RectangleCornerRadii(
            topLeading: isMine ? round : (run.isFirst ? round : tight),
            bottomLeading: isMine ? round : (run.isLast ? round : tight),
            bottomTrailing: isMine ? (run.isLast ? round : tight) : round,
            topTrailing: isMine ? (run.isFirst ? round : tight) : round
        )

        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: rect)
    }
}

private struct BubbleBackground: View {
    let isMine: Bool
    let run: BubbleRun

    var body: some View {
        BubbleShape(isMine: isMine, run: run)
            .fill(isMine ? AnyShapeStyle(mineGradient) : AnyShapeStyle(AppTheme.card))
            .overlay {
                if !isMine {
                    BubbleShape(isMine: isMine, run: run)
                        .stroke(AppTheme.cardStroke.opacity(0.07), lineWidth: 1)
                }
            }
    }

    /// A slight vertical gradient rather than a flat fill — it's what stops a
    /// long bubble looking like a printed block.
    private var mineGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Typing

/// Three dots that breathe out of phase, which is what reads as "someone is
/// mid-sentence" rather than "something is loading".
private struct TypingBubble: View {
    let names: [String]
    /// Whoever we can put a face to. May be shorter than `names`.
    let people: [Traveller]

    @State private var pulsing = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            // The gutter carries the same face the sender's messages will,
            // so an indicator reads as "Ed is typing" at a glance instead of
            // an anonymous bubble floating in the avatar column.
            Group {
                if let first = people.first {
                    TravellerAvatar(traveller: first, size: 26)
                } else {
                    Color.clear
                }
            }
            .frame(width: 26, height: 26)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.inkTertiary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulsing ? 1 : 0.55)
                        .opacity(pulsing ? 1 : 0.4)
                        // Each dot drives its own repeating animation, offset
                        // by a delay. The previous version fed a single
                        // animated `phase` through `sin()` and handed the
                        // *result* to `scaleEffect` — but SwiftUI interpolates
                        // the value it is given, not the input to the function
                        // that produced it. Both ends of that sine came out at
                        // 0.7, so it animated 0.7 to 0.7: nothing moved.
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.16),
                            value: pulsing
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background {
                Capsule()
                    .fill(AppTheme.card)
                    .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.07)) }
            }

            Spacer(minLength: 40)
        }
        .padding(.bottom, 8)
        .accessibilityElement()
        .accessibilityLabel(label)
        .onAppear { pulsing = true }
    }

    private var label: String {
        switch names.count {
        case 0: "Someone is typing"
        case 1: "\(names[0]) is typing"
        case 2: "\(names[0]) and \(names[1]) are typing"
        default: "\(names.count) people are typing"
        }
    }
}
