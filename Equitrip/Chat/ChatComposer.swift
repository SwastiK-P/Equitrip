//
//  ChatComposer.swift
//  Equitrip
//

import SwiftUI

/// A component the composer's tray can start.
enum ChatComposeTool: String, CaseIterable, Identifiable {
    case photo, place, booking, poll, meetup, checklist, balances

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photo: "Photo"
        case .place: "Place"
        case .booking: "Booking"
        case .poll: "Poll"
        case .meetup: "Meetup"
        case .checklist: "Bring list"
        case .balances: "Balances"
        }
    }

    /// Outline glyphs in one colour, the way Home's quick actions draw theirs.
    /// A rainbow of filled tiles made the tray look like a launcher of seven
    /// unrelated apps rather than seven things you can put in one message.
    var symbol: String {
        switch self {
        case .photo: "photo"
        case .place: "mappin.and.ellipse"
        case .booking: "ticket"
        case .poll: "chart.bar"
        case .meetup: "calendar"
        case .checklist: "checklist"
        case .balances: "arrow.left.arrow.right"
        }
    }
}

/// The bottom of the thread: what you're answering or editing, who you might
/// be @-naming, the tray of things you can send, and the field itself.
///
/// The tray opens in place of the keyboard rather than as a sheet. A sheet
/// that then opens a second sheet (the poll editor, the place search) is two
/// dismissals to get back to the conversation; the tray is one tap.
struct ChatComposer: View {
    @Binding var draft: String
    let context: (mode: ComposerContextBar.Mode, message: ChatMessage)?
    let contextAuthorName: String
    /// Everyone who can be @-named — the trip minus you.
    let mentionable: [Traveller]
    @Binding var trayOpen: Bool
    var focus: FocusState<Bool>.Binding
    var onSend: () -> Void
    var onCancelContext: () -> Void
    var onTyping: () -> Void
    var onTool: (ChatComposeTool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let context {
                ComposerContextBar(
                    mode: context.mode,
                    authorName: contextAuthorName,
                    text: context.message.preview,
                    isMine: context.message.isMine,
                    onCancel: onCancelContext
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !suggestions.isEmpty {
                mentionStrip
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            field

            if trayOpen, context?.mode != .edit {
                tray
                    .transition(.offset(y: 24).combined(with: .opacity))
            }
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) { Hairline() }
                .ignoresSafeArea(edges: .bottom)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: suggestions.map(\.id))
    }

    // MARK: Field

    private var field: some View {
        HStack(alignment: .bottom, spacing: 9) {
            if context?.mode != .edit {
                Button(action: toggleTray) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(trayOpen ? AppTheme.card : AppTheme.ink)
                        .rotationEffect(.degrees(trayOpen ? 45 : 0))
                        .frame(width: 38, height: 38)
                        .background(trayOpen ? AnyShapeStyle(AppTheme.ink) : AnyShapeStyle(AppTheme.card), in: .circle)
                        .overlay { Circle().strokeBorder(AppTheme.cardStroke.opacity(trayOpen ? 0 : 0.08)) }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(trayOpen ? "Close attachments" : "Send a photo, place, poll and more")
            }

            TextField(placeholder, text: $draft, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1...6)
                .focused(focus)
                .onChange(of: draft) { _, new in
                    if !new.isEmpty { onTyping() }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(minHeight: 40)
                .background { Capsule().fill(AppTheme.card) }
                .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.08)) }

            if canSend {
                Button(action: onSend) {
                    Image(systemName: context?.mode == .edit ? "checkmark" : "arrow.up")
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
                .accessibilityLabel(context?.mode == .edit ? "Save edit" : "Send")
            }
        }
        .padding(.horizontal, 14)
        .readableWidth()
        .padding(.top, 8)
        .padding(.bottom, 8)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: canSend)
    }

    private var placeholder: String {
        switch context?.mode {
        case .edit: "Edit message"
        case .reply: "Reply"
        case nil: "Message"
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: Tray

    private var tray: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 16) {
            ForEach(ChatComposeTool.allCases) { tool in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onTool(tool)
                } label: {
                    VStack(spacing: 7) {
                        Image(systemName: tool.symbol)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: 52, height: 52)
                            .background(AppTheme.card, in: .circle)
                            .overlay { Circle().strokeBorder(AppTheme.cardStroke.opacity(0.07)) }

                        Text(tool.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .readableWidth()
    }

    /// Opens straight away, in the same transaction as the tap.
    ///
    /// The tray used to hold a live `PhotosPicker`, which reaches for the
    /// photo library the moment it's built — so every open waited on that
    /// before anything moved, and the `+` turned a beat after the finger left
    /// it. The picker is presented from the thread now, only when asked for.
    private func toggleTray() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let opening = !trayOpen
        if opening { focus.wrappedValue = false }

        withAnimation(.snappy(duration: 0.26)) {
            trayOpen = opening
        }
        // Closing leaves the keyboard down. Tapping ✕ means "not now", and a
        // keyboard springing up in its place reads as the opposite.
    }

    // MARK: Mentions

    /// The partial name after a trailing `@`, if the draft ends in one.
    private var mentionQuery: String? {
        guard let at = draft.lastIndex(of: "@") else { return nil }
        // Must start a word: "me@mail" isn't somebody being named.
        if at != draft.startIndex {
            let before = draft[draft.index(before: at)]
            guard before.isWhitespace else { return nil }
        }
        let query = draft[draft.index(after: at)...]
        guard !query.contains(where: \.isWhitespace), query.count <= 20 else { return nil }
        return String(query)
    }

    private var suggestions: [Traveller] {
        guard let query = mentionQuery else { return [] }
        let everyone = Traveller(id: Self.everyoneID, name: "everyone", asset: "Avatar01")
        let people = mentionable + (mentionable.count > 1 ? [everyone] : [])
        guard !query.isEmpty else { return people }
        return people.filter { $0.name.lowercased().hasPrefix(query.lowercased()) }
    }

    private static let everyoneID = UUID(uuidString: "00000000-0000-0000-0000-00000000E0E0")!

    private var mentionStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(suggestions) { person in
                    Button { insertMention(person.name) } label: {
                        HStack(spacing: 6) {
                            if person.id == Self.everyoneID {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                                    .frame(width: 22, height: 22)
                                    .background(AppTheme.accent.opacity(0.12), in: .circle)
                            } else {
                                TravellerAvatar(traveller: person, size: 22)
                            }
                            Text("@\(person.name)")
                                .font(.system(size: 13.5, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                        }
                        .padding(.leading, 4)
                        .padding(.trailing, 11)
                        .padding(.vertical, 4)
                        .background(AppTheme.card, in: .capsule)
                        .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.08)) }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private func insertMention(_ name: String) {
        guard let at = draft.lastIndex(of: "@") else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        draft.replaceSubrange(at..., with: "@\(name) ")
    }
}
