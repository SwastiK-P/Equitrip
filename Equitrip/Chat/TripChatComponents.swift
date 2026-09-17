//
//  TripChatComponents.swift
//  Equitrip
//

import SwiftUI

// MARK: - Bubble geometry

struct BubbleRun {
    let isFirst: Bool
    let isLast: Bool
}

/// A rounded rect whose corners tighten where a run continues, so a group of
/// messages reads as one block with a single tail.
struct BubbleShape: Shape {
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

struct BubbleBackground: View {
    let isMine: Bool
    let run: BubbleRun
    /// Somebody @-named you. An accent edge rather than a fill, so it's
    /// findable while scrolling without shouting over the rest of the thread.
    var mentionsYou = false

    var body: some View {
        BubbleShape(isMine: isMine, run: run)
            .fill(isMine ? AnyShapeStyle(mineGradient) : AnyShapeStyle(AppTheme.card))
            .overlay {
                if !isMine {
                    BubbleShape(isMine: isMine, run: run)
                        .stroke(
                            mentionsYou ? AppTheme.accent.opacity(0.55) : AppTheme.cardStroke.opacity(0.07),
                            lineWidth: mentionsYou ? 1.5 : 1
                        )
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

// MARK: - Rich text

/// A message body with its links made tappable and its @-mentions set apart.
///
/// Mentions are matched against the trip's own travellers rather than any
/// `@word`, so an email address or a handle pasted from Instagram doesn't
/// light up as if it named somebody on the trip.
enum ChatRichText {
    static func attributed(_ text: String, names: [String], onDark: Bool) -> AttributedString {
        var result = AttributedString(text)
        let base: Color = onDark ? .white : AppTheme.ink
        result.foregroundColor = base

        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        if let detector = try? NSDataDetector(types: types.rawValue) {
            let whole = NSRange(text.startIndex..., in: text)
            for match in detector.matches(in: text, range: whole) {
                guard let range = Range(match.range, in: text),
                      let target = Range(range, in: result)
                else { continue }

                let url = match.url ?? match.phoneNumber.flatMap { URL(string: "tel:\($0.filter { !$0.isWhitespace })") }
                guard let url else { continue }

                result[target].link = url
                result[target].underlineStyle = .single
                result[target].foregroundColor = onDark ? .white : AppTheme.accent
            }
        }

        for name in names where !name.isEmpty {
            var searchStart = text.startIndex
            while let found = text.range(of: "@\(name)", options: .caseInsensitive, range: searchStart..<text.endIndex) {
                searchStart = found.upperBound
                guard let target = Range(found, in: result) else { continue }
                result[target].font = .system(size: 16, weight: .semibold)
                result[target].foregroundColor = onDark ? .white : AppTheme.accent
            }
        }

        return result
    }

    static func mentions(_ name: String, in text: String) -> Bool {
        !name.isEmpty && text.range(of: "@\(name)", options: .caseInsensitive) != nil
    }

    /// Everyone @-named, or everyone on the trip for `@all` / `@everyone`.
    static func mentionsYou(in text: String) -> Bool {
        let lowered = text.lowercased()
        if lowered.contains("@all") || lowered.contains("@everyone") { return true }
        return mentions(Traveller.you.name, in: text)
    }
}

// MARK: - Quote

/// The message being answered, drawn inside the reply that answers it.
///
/// Two lines maximum. A quote that reproduces the whole original doubles the
/// length of the thread and buries the reply, which is the opposite of what
/// quoting is for.
struct QuoteBlock: View {
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

/// What the composer is about to do to an existing message — answer it or
/// rewrite it — shown above the field while you type.
struct ComposerContextBar: View {
    enum Mode { case reply, edit }

    let mode: Mode
    let authorName: String
    let text: String
    let isMine: Bool
    var onCancel: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(mode == .edit ? Palette.amber : AppTheme.accent)
                .frame(width: 3, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(mode == .edit ? Palette.amber : AppTheme.accent)

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
            .accessibilityLabel(mode == .edit ? "Cancel edit" : "Cancel reply")
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 2)
    }

    private var title: String {
        switch mode {
        case .edit: "Editing message"
        case .reply: isMine ? "Replying to yourself" : "Replying to \(authorName)"
        }
    }
}

// MARK: - Day divider

struct ChatDayDivider: View {
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


// MARK: - Seen

/// The small faces under the last message each person has read.
struct SeenByAvatars: View {
    let people: [Traveller]

    var body: some View {
        HStack(spacing: -4) {
            ForEach(people.prefix(5)) { person in
                TravellerAvatar(traveller: person, size: 15)
                    .overlay { Circle().strokeBorder(AppTheme.canvasBottom, lineWidth: 1.5) }
            }
            if people.count > 5 {
                Text("+\(people.count - 5)")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, 7)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Seen by \(people.map(\.name).formatted(.list(type: .and)))")
    }
}

// MARK: - Typing

/// Three dots that breathe out of phase, which is what reads as "someone is
/// mid-sentence" rather than "something is loading".
struct TypingBubble: View {
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
                        // by a delay. Feeding one animated phase through
                        // `sin()` animates the function's output, not its
                        // input — both ends came out equal and nothing moved.
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

// MARK: - Pinned

/// One pinned message at a time, held under the header — where the villa
/// wifi password and the ferry time live once somebody pins them.
///
/// With more than one pinned, tapping doesn't just jump — it cycles to the
/// next pin, Telegram-style, so working through "what did we pin" is a row
/// of taps rather than a trip through the full list every time.
struct PinnedBanner: View {
    let message: ChatMessage
    let authorName: String
    /// Index of `message` within the pinned set, for the tick indicator.
    let index: Int
    let count: Int
    var onOpen: () -> Void
    var onShowAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onOpen) {
                HStack(spacing: 10) {
                    ZStack {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                            .rotationEffect(.degrees(35))
                    }
                    .frame(width: 26, height: 26)
                    .background(AppTheme.accent.opacity(0.12), in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Pinned")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                            if count > 1 { pinTicks }
                        }
                        Text("\(authorName): \(message.preview)")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())

            if count > 1 {
                Button("All", action: onShowAll)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // Tinted toward the card colour: the plain glass read as too see-through
        // with the thread scrolling underneath it.
        .glassEffect(.regular.tint(AppTheme.card.opacity(0.72)), in: .rect(cornerRadius: 16))
    }

    /// A tick per pin, the current one widened — the same shorthand Telegram
    /// uses so "which pin am I on" reads at a glance without spelling out
    /// "2 of 3" in words.
    private var pinTicks: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<count, id: \.self) { tick in
                Capsule()
                    .fill(tick == index ? AppTheme.accent : AppTheme.accent.opacity(0.25))
                    .frame(width: tick == index ? 9 : 3.5, height: 3)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: index)
    }
}

// MARK: - Jump to latest

/// Offered once you've scrolled up, with a count of what's arrived since.
struct JumpToLatestButton: View {
    let unseen: Int
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.interactive(), in: .circle)

                if unseen > 0 {
                    Text(unseen > 99 ? "99+" : "\(unseen)")
                        .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 19, minHeight: 19)
                        .background(AppTheme.accent, in: .capsule)
                        .offset(x: 5, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(unseen > 0 ? "Jump to latest, \(unseen) new" : "Jump to latest")
    }
}

// MARK: - Sheet chrome

/// Title and close button for the chat's own sheets, matching
/// `SettingsSheetScaffold`'s header.
struct ChatSheetHeader: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var caption: String?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                if let caption {
                    Text(caption)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}
