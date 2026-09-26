//
//  ChatComposer.swift
//  Equitrip
//

import SwiftUI

/// A component the composer's `+` menu can start.
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

    /// Filled glyphs, each in its own colour, so the menu can be scanned by
    /// colour before it's read — the way a share sheet's app icons are.
    var symbol: String {
        switch self {
        case .photo: "photo.fill"
        case .place: "mappin"
        case .booking: "ticket.fill"
        case .poll: "chart.bar.fill"
        case .meetup: "calendar"
        case .checklist: "checklist"
        case .balances: "arrow.left.arrow.right"
        }
    }

    var tint: Color {
        switch self {
        case .photo: Palette.blue
        case .place: Palette.glowRed
        case .booking: Palette.indigo
        case .poll: Palette.amberDeep
        case .meetup: Palette.violet
        case .checklist: Palette.teal
        case .balances: Palette.greenDeep
        }
    }
}

/// The bottom of the thread: what you're answering or editing, who you might
/// be @-naming, the `+` for things you can send, and the field itself.
///
/// The `+` opens a menu over the thread (`ChatComposeMenu`) rather than a
/// sheet. A sheet that then opens a second sheet (the poll editor, the place
/// search) is two dismissals to get back to the conversation; the menu is one
/// tap.
struct ChatComposer: View {
    @Environment(\.pane) private var pane
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
                // A glass card sitting just above the field, the same material
                // as the field itself, rather than a frosted strip across the
                // screen that reads as a toolbar.
                .padding(.bottom, 7)
                .glassEffect(.regular, in: .rect(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .readableWidth()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !suggestions.isEmpty {
                mentionStrip
                    .readableWidth()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            field
        }
        // Bare when it's only the field, so the glass floats over the thread
        // (the thread's soft bottom edge effect does the fading) — glass on a
        // frosted bar is glass on glass and just reads as grey. A reply
        // preview or the mention strip gets the bar back so it doesn't sit
        // on top of messages.
        .background {
            if hasChrome {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(alignment: .top) { Hairline() }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.opacity)
            }
        }
        .animation(.snappy(duration: 0.26), value: hasChrome)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: suggestions.map(\.id))
    }

    /// Only the phone's mention strip still needs the frosted bar — its chips
    /// would otherwise sit on top of messages. The reply preview carries its
    /// own glass, and on iPad a band edge-to-edge under a centred column
    /// reads as a stretched phone layout.
    private var hasChrome: Bool {
        !pane.isRegular && !suggestions.isEmpty
    }

    // MARK: Field

    private var field: some View {
        GlassEffectContainer(spacing: 9) { fieldRow }
    }

    private var fieldRow: some View {
        HStack(alignment: .bottom, spacing: 9) {
            if context?.mode != .edit {
                // Glass rather than a white disc, and it stays glass when the
                // tray opens: the old solid-black ✕ was the heaviest thing on
                // screen for a control that only means "put this away".
                Button(action: toggleTray) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .rotationEffect(.degrees(trayOpen ? 45 : 0))
                        .frame(width: 40, height: 40)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
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
                .padding(.vertical, 10)
                .frame(minHeight: 40)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20, style: .continuous))

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

    // MARK: Menu

    /// Opens straight away, in the same transaction as the tap.
    ///
    /// The old tray held a live `PhotosPicker`, which reaches for the
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
