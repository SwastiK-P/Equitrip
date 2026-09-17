//
//  ChatBubbleRow.swift
//  Equitrip
//

import SwiftUI

/// One message, with everything you can do to it.
///
/// Swipe right to reply — the same gesture every group chat has trained people
/// to expect, and much less friction than a long-press menu for the thing
/// they'll do most often. The long-press menu holds the rest: copy, pin,
/// edit, delete and who's seen it.
struct ChatBubbleRow: View {
    let message: ChatMessage
    let trip: Trip
    let chat: ChatService
    let run: BubbleRun
    let isHighlighted: Bool
    /// Other people whose read position ends at this message.
    let seenBy: [Traveller]
    var actions: ChatRowActions

    @State private var dragX: CGFloat = 0
    @State private var armed = false

    /// Far enough that a lazy horizontal wobble during a scroll can't fire it.
    private static let trigger: CGFloat = 54

    /// Avatar (26) + its spacing (7) + the bubble's own text inset (12), so a
    /// name or timestamp lines up with the words rather than the bubble edge.
    private static let textInset: CGFloat = 45

    var body: some View {
        ZStack(alignment: .leading) {
            replyAffordance

            content
                .offset(x: dragX)
        }
        .gesture(swipeToReply)
    }

    private var author: Traveller? { chat.author(of: message) }
    private var quoted: ChatMessage? { chat.message(message.replyToID) }
    private var mentionNames: [String] { trip.travellers.map(\.name) + ["all", "everyone"] }
    private var mentionsYou: Bool { !message.isMine && ChatRichText.mentionsYou(in: message.body) }

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
                if armed, !message.isDeleted { actions.reply(message) }
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
                Text(chat.authorName(of: message))
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
                messageBody
                    .contextMenu { menu }
                if message.isMine { gutter } else { Spacer(minLength: 40) }
            }

            footer
                .padding(message.isMine ? .trailing : .leading, Self.textInset)
        }
        .padding(.bottom, run.isLast ? 8 : 1)
    }

    @ViewBuilder
    private var footer: some View {
        if message.delivery == .failed {
            HStack(spacing: 10) {
                Button { actions.retry(message) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Not sent · Tap to retry")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(AppTheme.danger)
                }
                Button("Discard") { actions.discard(message) }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 1)
        } else if run.isLast || !seenBy.isEmpty {
            HStack(spacing: 6) {
                if message.isMine, !seenBy.isEmpty { SeenByAvatars(people: seenBy) }

                if run.isLast {
                    HStack(spacing: 3) {
                        if message.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8, weight: .bold))
                        }
                        Text(timeLabel)
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                }

                if !message.isMine, !seenBy.isEmpty { SeenByAvatars(people: seenBy) }
            }
            .padding(.top, 1)
        }
    }

    private var timeLabel: String {
        let time = DateFormatter.cached("h:mm a").string(from: message.sentAt)
        if message.delivery == .sending { return "Sending…" }
        return message.editedAt != nil && !message.isDeleted ? "\(time) · Edited" : time
    }

    /// Whoever sent it, on their own side. Both sides get a face: in a group
    /// where you're one voice among several, your own messages are as much
    /// "who said this" as anyone else's.
    ///
    /// The gutter is held even when no avatar is drawn, so a run of messages
    /// stays in one column instead of stepping sideways under the last one.
    private var gutter: some View {
        Group {
            if run.isLast, let face = author {
                TravellerAvatar(traveller: face, size: 26, isDimmed: trip.hasLeft(face.id))
            } else {
                Color.clear
            }
        }
        .frame(width: 26, height: 26)
    }

    // MARK: Body

    @ViewBuilder
    private var messageBody: some View {
        if message.isDeleted {
            tombstone
        } else if message.isEmojiOnly {
            Text(message.body)
                .font(.system(size: 44))
                .padding(.vertical, 2)
                .opacity(message.delivery == .sending ? 0.55 : 1)
        } else if let attachment = message.attachment {
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                if message.replyToID != nil {
                    quote(onDark: false)
                        .frame(maxWidth: ChatAttachmentCard.width, alignment: .leading)
                }

                ChatAttachmentCard(
                    message: message,
                    attachment: attachment,
                    trip: trip,
                    chat: chat,
                    onOpenBooking: actions.openBooking,
                    onOpenPhoto: { url in actions.openPhoto(url, message) }
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.accent.opacity(isHighlighted ? 0.18 : 0))
                        .allowsHitTesting(false)
                }

                if !message.body.isEmpty {
                    textBubble(run: BubbleRun(isFirst: false, isLast: run.isLast))
                }
            }
            .opacity(message.delivery == .failed ? 0.7 : 1)
        } else {
            textBubble(run: run)
        }
    }

    /// Everything inside a bubble is leading-aligned, whoever sent it.
    ///
    /// The bubble is trailing-aligned in the row; its *contents* are not. When
    /// they were, a reply left a wedge of empty bubble to the left of the text
    /// — the quote block is wider than a short reply, so the text slid right
    /// to the far edge and the bubble looked broken.
    private func textBubble(run: BubbleRun) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if message.replyToID != nil, message.attachment == nil {
                quote(onDark: message.isMine)
            }

            Text(ChatRichText.attributed(message.body, names: mentionNames, onDark: message.isMine))
                .font(.system(size: 16))
                .tint(message.isMine ? .white : AppTheme.accent)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background { BubbleBackground(isMine: message.isMine, run: run, mentionsYou: mentionsYou) }
        .overlay {
            // The jump highlight. A wash rather than a border, so it reads on
            // both the accent bubble and the card one.
            BubbleShape(isMine: message.isMine, run: run)
                .fill(AppTheme.accent.opacity(isHighlighted ? 0.28 : 0))
                .allowsHitTesting(false)
        }
        .contentShape(BubbleShape(isMine: message.isMine, run: run))
        .opacity(message.delivery == .sending ? 0.55 : 1)
        .animation(.easeOut(duration: 0.3), value: isHighlighted)
    }

    @ViewBuilder
    private func quote(onDark: Bool) -> some View {
        if let quoted {
            Button {
                actions.jump(quoted.id)
            } label: {
                QuoteBlock(authorName: chat.authorName(of: quoted), text: quoted.preview, onDark: onDark)
            }
            .buttonStyle(.plain)
        } else {
            // The original is older than the window we hold. Saying so beats
            // a reply that answers nothing visible.
            QuoteBlock(authorName: "Original message", text: "No longer available", onDark: onDark)
        }
    }

    private var tombstone: some View {
        HStack(spacing: 6) {
            Image(systemName: "nosign")
                .font(.system(size: 12, weight: .medium))
            Text(message.isMine ? "You deleted this message" : "This message was deleted")
                .font(.system(size: 14).italic())
        }
        .foregroundStyle(AppTheme.inkTertiary)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background {
            BubbleShape(isMine: message.isMine, run: run)
                .stroke(AppTheme.cardStroke.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    // MARK: Menu

    @ViewBuilder
    private var menu: some View {
        if !message.isDeleted, message.delivery == .sent {
            Button("Reply", systemImage: "arrowshape.turn.up.left") { actions.reply(message) }

            if !message.body.isEmpty {
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = message.body
                }
            }

            Button(message.isPinned ? "Unpin" : "Pin", systemImage: message.isPinned ? "pin.slash" : "pin") {
                actions.pin(message, !message.isPinned)
            }

            if message.isEditable {
                Button("Edit", systemImage: "pencil") { actions.edit(message) }
            }

            Button("Info", systemImage: "info.circle") { actions.info(message) }

            if message.isMine {
                Divider()
                Button(role: .destructive) { actions.delete(message) } label: {
                    Label("Delete for everyone", systemImage: "trash")
                }
                .tint(.red)
            }
        } else if message.delivery == .failed {
            Button("Retry", systemImage: "arrow.clockwise") { actions.retry(message) }
            Button(role: .destructive) { actions.discard(message) } label: {
                Label("Discard", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}

/// What a row can ask the thread to do. Gathered into one value so adding an
/// action doesn't mean threading another closure through every initialiser.
struct ChatRowActions {
    var reply: (ChatMessage) -> Void
    var jump: (UUID) -> Void
    var retry: (ChatMessage) -> Void
    var discard: (ChatMessage) -> Void
    var pin: (ChatMessage, Bool) -> Void
    var edit: (ChatMessage) -> Void
    var delete: (ChatMessage) -> Void
    var info: (ChatMessage) -> Void
    var openBooking: (ItineraryItem) -> Void
    var openPhoto: (URL, ChatMessage) -> Void
}
