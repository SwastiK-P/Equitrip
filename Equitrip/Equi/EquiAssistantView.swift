//
//  EquiAssistantView.swift
//  Equitrip
//

import SwiftUI

/// One turn in the Equi conversation.
///
/// `text` and `card` are `var`: a streaming reply lands in the same message in
/// place, token by token, rather than replacing it with a new one each time.
/// `card` is what makes Equi more than a text box — see `EquiCard`.
struct EquiMessage: Identifiable, Equatable {
    let id: UUID
    var text: String
    let isUser: Bool
    var card: EquiCard?
    let sentAt: Date

    /// `id` and `sentAt` are arguments rather than initialised in place so a
    /// turn read back out of `equi_messages` keeps the identity and the time
    /// it was written — a reloaded transcript that renumbers itself sorts by
    /// "now" and arrives in the wrong order.
    init(id: UUID = UUID(), text: String, isUser: Bool, card: EquiCard? = nil, sentAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.card = card
        self.sentAt = sentAt
    }
}

/// One row of the transcript: a turn, and whether it opens or closes a run of
/// turns from the same side. See `EquiAssistantView.rows`.
private struct EquiRow: Identifiable, Equatable {
    let message: EquiMessage
    let isFirstInGroup: Bool
    let isLastInGroup: Bool

    var id: UUID { message.id }
}

/// A short question the empty state offers so the first message isn't a
/// blank page staring back — the same problem a search bar has, solved the
/// same way.
struct EquiPrompt: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let text: String

    static func == (lhs: EquiPrompt, rhs: EquiPrompt) -> Bool { lhs.id == rhs.id }
}

/// Equi's own tab: a standalone AI chat, distinct from the per-trip group
/// thread in `TripChatView`. That one is people talking to each other about
/// a trip; this is one person talking to an assistant — different enough in
/// shape (no authors, no replies, no read receipts) that folding it into the
/// same view would have meant an `if isAI` running through every row. The
/// visual language leans into that difference too: a living, drifting aurora
/// instead of the flat peach canvas, and iMessage-style grouped bubbles
/// instead of the app's usual flat cards.
///
/// Answers stream in from Apple Intelligence's on-device model, briefed on
/// every trip the user is on — plan, people and money — rebuilt fresh on
/// each question so the answer never lags behind something just logged in
/// the app. See `EquiIntelligence` and `EquiContext`.
struct EquiAssistantView: View {
    /// Bumped by `RootTabView` every time this tab is selected.
    ///
    /// Driven from the tab bar rather than from `onAppear` because a `TabView`
    /// makes no promise about tearing a tab's view down when you leave it —
    /// depending on what else is on screen it may stay alive, and then
    /// `onAppear` never fires again and the second visit is silent. The
    /// selection is the one signal that is always right.
    var arrival: Int = 0
    /// Lets a card's own "open" action hand off to the real screen it's
    /// summarising, instead of a card being the end of the road — the same
    /// figures, but nowhere to go from them.
    var onOpenTrip: (Trip) -> Void = { _ in }

    @Environment(\.tripStore) private var tripStore
    @Environment(\.pane) private var pane

    /// The transcript, and every conversation before it. Owned here rather
    /// than injected: Equi's history is one person's own and is read by
    /// nothing else in the app — unlike `TripStore`, which half the screens
    /// need. See `EquiHistoryStore`.
    @State private var history = EquiHistoryStore()
    @State private var showingHistory = false
    @State private var draft = ""
    @State private var isThinking = false
    @State private var hasAppeared = false
    @State private var replyTask: Task<Void, Never>?
    @FocusState private var composerFocused: Bool
    /// The thread column's own width — the whole pane on a phone, what the
    /// sidebar leaves on a wide iPad. The hero is sized against it.
    @State private var threadWidth: CGFloat = 0
    /// Its height between the top bar and the composer.
    @State private var threadHeight: CGFloat = 0
    /// The window's status-bar inset, for lining the wide sidebar up with the
    /// tab bar. Stored, not read in `body` — see `splitLayout`.
    @State private var windowTopInset: CGFloat = 24

    // The arrival beat. See `playEntrance` — one sequencer drives all four so
    // the light, the bloom, the orb and the feel land together.
    @State private var sweepTravel: Double = 0
    @State private var sweepGlow: Double = 0
    @State private var bloom: Double = 0
    @State private var orbPop = false
    @State private var lastPlayedArrival: Int?

    private static let bottomAnchor = "equi-bottom"

    /// The conversation on screen. Reading through the store rather than
    /// holding a second copy: a thread opened from the history has to replace
    /// this wholesale, and two sources of truth for "what is on screen" is
    /// exactly how a reopened conversation ends up appended to the last one.
    private var messages: [EquiMessage] { history.messages }

    /// The three lanes of the drifting prompt wall.
    ///
    /// Three rather than the eight fixed tiles the design started from: a grid
    /// of cards under the illustration turned the page into a menu, where a
    /// lane answers "what can I ask?" continuously and takes a third of the
    /// room doing it.
    ///
    /// Split by subject rather than shuffled, so a lane reads as a coherent
    /// set: the days themselves, then the money, then the odds and ends.
    ///
    /// `static` because `EquiPrompt`'s identity is its `UUID`: as an instance
    /// property these would be rebuilt with fresh ids on every body pass,
    /// which is exactly the equality the marquee relies on to avoid
    /// re-rendering its tiles sixty times a second.
    private static let promptRows: [[EquiPrompt]] = [
        [
            EquiPrompt(symbol: "bed.double", text: "Where am I staying?"),
            EquiPrompt(symbol: "suitcase", text: "What should I pack?"),
            EquiPrompt(symbol: "airplane.arrival", text: "When do I land?"),
            EquiPrompt(symbol: "clock.badge.exclamationmark", text: "Any gaps in the plan?"),
            EquiPrompt(symbol: "calendar", text: "What's up next?")
        ],
        [
            EquiPrompt(symbol: "creditcard", text: "Am I over budget?"),
            EquiPrompt(symbol: "arrow.left.arrow.right", text: "Settle everyone up"),
            EquiPrompt(symbol: "chart.pie", text: "Where's the money going?"),
            EquiPrompt(symbol: "person.2", text: "Who still owes me?"),
            EquiPrompt(symbol: "fork.knife", text: "How much on food so far?")
        ],
        [
            EquiPrompt(symbol: "map", text: "How's it going so far?"),
            EquiPrompt(symbol: "sparkles", text: "Anything I've forgotten?"),
            EquiPrompt(symbol: "cloud.sun", text: "What's the weather doing?"),
            EquiPrompt(symbol: "figure.walk", text: "What's worth seeing nearby?"),
            EquiPrompt(symbol: "checklist", text: "What's still unbooked?")
        ]
    ]

    var body: some View {
        ZStack {
            EquiAuroraBackground(isThinking: isThinking, isAppeared: hasAppeared, bloom: bloom, showsPattern: !messages.isEmpty)

            if pane.isWide {
                splitLayout
            } else {
                thread
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .modifier(EquiHeaderBar(onTabLine: pane.isRegular && !pane.isWide) { header })
        // Above the bars as well as the thread, so the light passes over the
        // whole screen rather than stopping at the composer.
        .overlay { EquiShine(travel: sweepTravel, glow: sweepGlow) }
        // Keyed on the count, not the messages themselves — a bubble arriving
        // or leaving springs into place, but a stream of tokens landing in an
        // existing one shouldn't re-trigger that spring on every word.
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: messages.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isThinking)
        .sheet(isPresented: $showingHistory) {
            EquiHistorySheet(history: history) { summary in
                showingHistory = false
                openConversation(summary)
            }
        }
        // The sidebar replaces the sheet; one left open across a rotation into
        // the wide layout would be the same list twice.
        .onChange(of: pane.isWide) { _, wide in
            if wide { showingHistory = false }
        }
        .task { EquiArrivalHaptics.prepare() }
        // The list, not the transcripts: it decides whether the history button
        // has anything behind it, and it is one small query per launch.
        .task { await history.loadConversations() }
        .onAppear { playEntrance() }
        .onChange(of: arrival) { _, _ in playEntrance() }
    }

    // MARK: - Layouts

    /// The wide iPad: the conversations standing beside the thread.
    ///
    /// The composer belongs to the thread column rather than the screen, so it
    /// sits under what it writes into instead of running beneath the sidebar
    /// too. See `EquiSidebar` for why the list is out of its sheet here.
    private var splitLayout: some View {
        ZStack(alignment: .topLeading) {
            // The thread keeps the tab bar's safe area above it, and makes
            // room for the panel beside it. Down to the window's bottom edge
            // past the home indicator's inset, so the composer finishes level
            // with the panel; the keyboard is a separate region and still
            // lifts it.
            thread
                .padding(.leading, pane.railWidth + EquiSidebar.inset * 2 + 6)
                .ignoresSafeArea(.container, edges: .bottom)

            // A layer of its own, sized off the window rather than the safe
            // area: top edge level with the tab bar's, side and bottom the
            // same small inset, so the panel floats evenly in its corner.
            EquiSidebar(
                history: history,
                isThinking: isThinking,
                hasConversation: !messages.isEmpty,
                onNewConversation: startOver,
                onOpen: openConversation
            )
            .frame(width: pane.railWidth)
            .frame(maxHeight: .infinity)
            .padding(.top, windowTopInset + Self.tabBarGap)
            .padding([.leading, .bottom], EquiSidebar.inset)
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
            .offset(x: hasAppeared ? 0 : -18)
            .opacity(hasAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.04), value: hasAppeared)
        }
        // The status bar's height, read from the window after layout rather
        // than in `body`: asking UIKit for a window's insets while SwiftUI is
        // mid-update stalled this tab's graph — it drew once, invisibly, and
        // never took another state change.
        .onGeometryChange(for: CGSize.self) { $0.size } action: { _ in
            windowTopInset = UIApplication.keyWindowTopInset ?? windowTopInset
        }
    }

    /// How far below the status bar the floating iPad tab bar's top edge
    /// sits, measured off the simulator: the bar hangs directly under it.
    private static let tabBarGap: CGFloat = 1

    /// The transcript and its composer. The whole screen on a phone and a
    /// narrower iPad; the trailing column on a wide one.
    private var thread: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(rows) { row in
                            EquiBubbleRow(
                                message: row.message,
                                isLastInGroup: row.isLastInGroup,
                                onOpenTrip: onOpenTrip
                            )
                            .id(row.id)
                            .padding(.top, row.isFirstInGroup ? 14 : 2)
                            .transition(
                                .asymmetric(
                                    insertion: .modifier(
                                        active: BubblePop(offset: row.message.isUser ? 18 : -18, scale: 0.82, opacity: 0),
                                        identity: BubblePop(offset: 0, scale: 1, opacity: 1)
                                    ),
                                    removal: .opacity
                                )
                            )
                        }
                    }

                    if isThinking {
                        EquiThinkingBubble()
                            .padding(.top, 14)
                            .transition(.asymmetric(
                                insertion: .modifier(
                                    active: BubblePop(offset: -18, scale: 0.82, opacity: 0),
                                    identity: BubblePop(offset: 0, scale: 1, opacity: 1)
                                ),
                                removal: .opacity.combined(with: .scale(scale: 0.85))
                            ))
                    }

                    Color.clear.frame(height: 10).id(Self.bottomAnchor)
                }
                .padding(.horizontal, 16)
                // A transcript is prose and wants a measure; the empty
                // state is a horizon and a drifting wall of prompts, both
                // of which are meant to run off the edges of the window.
                .readableWidth(unless: messages.isEmpty)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            // The empty state is sized to the container and meant to sit
            // still: with scrolling live it rubber-banded under the
            // headline, which made a fixed page feel like a short list.
            //
            // Unconditional, unlike the first attempt, which had to leave
            // scrolling on under the keyboard so the cropped ends stayed
            // reachable. Focus now drops the headline and the lanes, and
            // the valley alone fits the space that's left.
            .scrollDisabled(messages.isEmpty)
            .onChange(of: messages.count) { _, _ in scrollToBottom(proxy) }
            .onChange(of: isThinking) { _, _ in scrollToBottom(proxy) }
            .onChange(of: composerFocused) { _, focused in
                if focused { scrollToBottom(proxy) }
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .scaleEffect(hasAppeared ? 1 : 0.97)
        .blur(radius: hasAppeared ? 0 : 6)
        .onGeometryChange(for: CGSize.self) { $0.size } action: {
            threadWidth = $0.width
            threadHeight = $0.height
        }
        // Tap anywhere above the composer to put the keyboard away.
        //
        // `scrollDismissesKeyboard` covers this in a thread you can scroll,
        // but the empty state deliberately can't be scrolled, so that gesture
        // has nothing to ride on and the keyboard had no way out at all. The
        // catcher only exists while the field is focused, so it never sits
        // between a finger and a prompt tile.
        //
        // Applied *before* the composer: an overlay here covers the thread
        // and nothing else, which is what keeps it off the field and the send
        // button underneath it.
        .overlay {
            if composerFocused {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { composerFocused = false }
                    .accessibilityHidden(true)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { composerBar }
    }

    // MARK: - Arrival

    /// The beat that plays every time the tab is opened.
    ///
    /// A gleam crosses the screen, the aurora blooms behind it, the orb takes
    /// a breath, and the haptics tick as the light passes the middle — one
    /// gesture, about six tenths of a second, gone before it can become
    /// something to wait through.
    ///
    /// The reset is written outside the animation and the play is written on
    /// the next runloop turn, so SwiftUI commits "back to the start" before it
    /// is asked to animate away from it. Setting both in one pass just moves
    /// the value with no frames in between, which is the classic way a replay
    /// silently does nothing on the second run.
    private func playEntrance() {
        // Both `onAppear` and `onChange(of: arrival)` call this, because which
        // of the two fires depends on whether the `TabView` kept this view
        // alive while you were elsewhere — and exactly one of them does, for
        // any given visit. Except when both do: a tab that stayed alive *and*
        // re-appears fires the pair in the same frame, which is inaudible in
        // the animation and very audible in the haptics. One play per visit.
        guard lastPlayedArrival != arrival else { return }
        lastPlayedArrival = arrival

        EquiArrivalHaptics.arrive()

        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            sweepTravel = 0
            sweepGlow = 0
            bloom = 0
            orbPop = false
        }

        Task { @MainActor in
            let sweep = EquiArrivalTiming.sweep

            withAnimation(.easeInOut(duration: sweep)) { sweepTravel = 1 }
            withAnimation(.easeOut(duration: sweep * 0.3)) { sweepGlow = 1 }
            withAnimation(.easeIn(duration: sweep * 0.5).delay(sweep * 0.45)) { sweepGlow = 0 }

            withAnimation(.easeOut(duration: sweep * 0.45)) { bloom = 1 }
            withAnimation(.easeInOut(duration: sweep * 0.7).delay(sweep * 0.4)) { bloom = 0 }

            withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) { orbPop = true }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(sweep * 0.4)) { orbPop = false }

            // First visit only: the staggered settle-in of the empty state.
            // Every visit after that gets the light, not a rebuild.
            if !hasAppeared {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { hasAppeared = true }
            }
        }
    }

    // MARK: - Grouping

    /// The transcript with its grouping already worked out.
    ///
    /// The neighbours are resolved here, once, instead of the row closure
    /// looking them up by index while it draws. `ForEach` re-runs that closure
    /// with indices from the layout it is replacing, so an index that was
    /// valid when the list was handed over is not necessarily valid by the
    /// time the closure runs — clearing the thread for a new conversation ran
    /// the old indices against an empty array and trapped. Carrying the answer
    /// on the row makes that impossible rather than merely unlikely.
    private var rows: [EquiRow] {
        let messages = messages
        return messages.indices.map { index in
            EquiRow(
                message: messages[index],
                isFirstInGroup: index == 0 || messages[index].isUser != messages[index - 1].isUser,
                isLastInGroup: index == messages.count - 1 || messages[index].isUser != messages[index + 1].isUser
            )
        }
    }

    // MARK: - Header

    /// Borrowed from Messages' own conversation header: the name centred on a
    /// floating card, with who you're talking to written under it.
    ///
    /// No avatar up here any more. Equi's face is down in the valley now, and
    /// two of them on one screen made the header badge read as a second,
    /// smaller Equi rather than as the same one. Messages puts a picture here
    /// because you have hundreds of threads and need to tell them apart; this
    /// tab is one conversation with one correspondent, so the name is enough.
    ///
    /// The card is centred by the `ZStack` rather than by an `HStack` with a
    /// balancing spacer, so it stays on the screen's centre line whether or
    /// not the new-conversation button is showing.
    ///
    /// On iPad the tab bar floats in the middle of this same line, so the card
    /// moves to the leading edge — centred, it sat underneath the tabs. On a
    /// wide iPad the whole header moves into the sidebar's title row.
    @ViewBuilder
    private var header: some View {
        if pane.isWide {
            // The sidebar's title row is the header here — see `EquiSidebar`.
            EmptyView()
        } else if pane.isRegular {
            HStack(spacing: 12) {
                titleCard

                Spacer(minLength: 0)

                headerButtons(spread: false)
            }
            .padding(.horizontal, pane.gutter)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .headerEntrance(appeared: hasAppeared, isEmpty: messages.isEmpty)
        } else {
            ZStack {
                titleCard

                headerButtons(spread: true)
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 8)
            .headerEntrance(appeared: hasAppeared, isEmpty: messages.isEmpty)
        }
    }

    private var titleCard: some View {
        VStack(alignment: pane.isRegular ? .leading : .center, spacing: 1) {
            Text("Equi")
                .font(.system(size: pane.isRegular ? 18 : 16.5, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(isThinking ? "Thinking…" : "Your trip assistant")
                .font(.system(size: pane.isRegular ? 12 : 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.06)), in: .rect(cornerRadius: 19))
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .strokeBorder(.white.opacity(0.2), lineWidth: 0.75)
        }
        .scaleEffect(orbPop ? 1.04 : 1)
        .shadow(color: AppTheme.accent.opacity(orbPop ? 0.28 : 0), radius: 12)
    }

    /// `spread` pushes the two to opposite ends of the line, either side of a
    /// centred title; unspread they sit together at the trailing edge.
    private func headerButtons(spread: Bool) -> some View {
        HStack(spacing: 10) {
            CircleGlyphButton(symbol: "clock.arrow.circlepath", size: 44) { openHistory() }
                .accessibilityLabel("Past conversations")

            if spread { Spacer() }

            if !messages.isEmpty {
                CircleGlyphButton(symbol: "plus.bubble", size: 44) { startOver() }
                    .accessibilityLabel("New conversation")
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
    }

    // MARK: - Empty state

    /// The opening screen: a line of type, a valley, and three lanes of things
    /// to ask.
    ///
    /// Everything here is stacked in one column and deliberately stops short
    /// of the composer — the illustration only reads as a place if there's sky
    /// left around it, which is what a grid of cards under the headline took
    /// away.
    ///
    /// Raising the keyboard leaves only the valley. The headline and the lanes
    /// are both invitations to start, and once you have started typing they
    /// are answered — while the keyboard also takes about a third of the
    /// height they were laid out against, so keeping them meant cropping them.
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 0) {
            if !composerFocused {
                VStack(spacing: 6) {
                    // Concatenated rather than two `Text`s in an `HStack`, so
                    // the accent word stays on the same baseline and wraps
                    // with the rest of the line instead of being its own box.
                    // The colour is on the name: it's the one word here that's
                    // a proper noun, and it's what the tab is called.
                    (Text("Ask ").foregroundStyle(AppTheme.ink)
                        + Text("Equi").foregroundStyle(AppTheme.accent)
                        + Text(" anything").foregroundStyle(AppTheme.ink))
                        .font(.system(size: pane.isRegular ? 42 : 33, weight: .semibold))
                        .tracking(-0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("About the plan, the money, or what's next.")
                        .font(.system(size: pane.isRegular ? 16 : 14))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 18)
                .equiStagger(0, appeared: hasAppeared)
                .transition(.opacity.combined(with: .offset(y: -12)))
            }

            EquiHeroScene(appeared: hasAppeared, width: heroWidth)
                // Out past the thread's own 16pt gutter: the valley is a
                // horizon, and a horizon with margins is a picture of one.
                .padding(.horizontal, -16)
                // Was pulled up under the headline to lift the horizon; the
                // speech bubble lives in the top of this box, so a negative
                // inset here closed the gap between it and the subtitle.
                .padding(.top, 4)

            if !composerFocused {
                EquiPromptWall(rows: Self.promptRows, appeared: hasAppeared) { send($0) }
                    // Same reason, plus the tiles then slide off the screen
                    // edges rather than stopping short of them.
                    .padding(.horizontal, -16)
                    .modifier(EquiLaneFade(isOn: pane.isWide))
                    .padding(.top, pane.isRegular ? 44 : 36)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical, alignment: .center)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: composerFocused)
    }

    /// How wide the valley is drawn on iPad; nil keeps the phone's full-bleed
    /// 240pt strip.
    ///
    /// The strip can't simply stretch: the artwork scales with width, so at
    /// iPad widths it grew taller than its 240pt box and rose up through the
    /// headline. Scaled as a whole instead — same proportions, so every note
    /// and arrow stays aimed where it was — to the largest size the column
    /// holds: its full width, unless the height left between the bars once
    /// the headline and the lanes have theirs runs out first.
    private var heroWidth: CGFloat? {
        guard pane.isRegular, threadWidth > 0, threadHeight > 0 else { return nil }
        let heightBudget = max(240, threadHeight - Self.emptyStateChrome)
        return max(393, min(threadWidth, heightBudget * EquiHeroScene.phoneAspect))
    }

    /// The empty state's height besides the valley on iPad: the headline and
    /// subtitle, the three lanes and the gap above them, and some air at the
    /// top and bottom so the page doesn't touch either bar.
    private static let emptyStateChrome: CGFloat = 330

    // MARK: - Composer

    /// The field and the send button share one `GlassEffectContainer` so they
    /// sample the same backdrop and read as two pieces of a single material —
    /// which is also what lets the button grow out of the capsule rather than
    /// appear beside it.
    private var composerBar: some View {
        GlassEffectContainer(spacing: 9) {
            HStack(alignment: .bottom, spacing: 9) {
                TextField("Message Equi", text: $draft, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1...5)
                    .focused($composerFocused)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    // Plain `.regular`, untinted and unstroked, because the
                    // tab bar sitting directly beneath it is plain `.regular`
                    // too — two pieces of glass a few points apart have to be
                    // the same glass, and a violet wash plus a white rim on
                    // one of them read as a mismatch rather than as emphasis.
                    // Focus is the exception: it earns a tint, and only then.
                    .glassEffect(
                        .regular
                            .tint(AppTheme.accent.opacity(composerFocused ? 0.14 : 0))
                            .interactive(),
                        in: .capsule
                    )
                    .overlay {
                        if composerFocused {
                            Capsule()
                                .strokeBorder(AppTheme.accent.opacity(0.4), lineWidth: 1.2)
                        }
                    }

                if canSend {
                    Button(action: submit) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accentDeep],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                in: .circle
                            )
                            .shadow(color: AppTheme.accent.opacity(0.35), radius: 8, y: 3)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
        }
        // Matches the tab bar's own inset, so the two capsules share a left
        // and right edge instead of the composer overhanging it by a few
        // points — which is exactly the sort of near-miss the eye picks up.
        // That pairing only holds where the tab bar is underneath it; on iPad
        // the bar floats at the top instead, and the field takes the same
        // measure and inset as the transcript it's writing into.
        .padding(.horizontal, pane.isRegular ? 16 : 22)
        .readableWidth()
        .padding(.top, 10)
        // A little higher on a wide iPad, where the field floats over the
        // window's edge rather than resting on a tab bar.
        .padding(.bottom, pane.isWide ? 22 : 10)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: canSend)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: composerFocused)
        // A wash of the canvas rather than a material. Glass laid over
        // `.ultraThinMaterial` samples an already-blurred surface and comes
        // back flat — the lensing has nothing left to bend. Fading the canvas
        // up instead gives the capsule real background to sit in while still
        // covering the thread as it scrolls under.
        .background {
            LinearGradient(
                colors: [
                    AppTheme.canvasBottom.opacity(0),
                    AppTheme.canvasBottom.opacity(0.86),
                    AppTheme.canvasBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
            // Carried on under the sidebar on a wide iPad, or the column's
            // edge shows as a seam down the bottom of the screen.
            .padding(.leading, pane.isWide ? -(pane.railWidth + EquiSidebar.inset * 2 + 6) : 0)
            .allowsHitTesting(false)
        }
        .offset(y: hasAppeared ? 0 : 24)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: hasAppeared)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func submit() {
        let text = draft
        draft = ""
        send(text)
    }

    /// Appends the user's turn, then streams Equi's reply into a bubble of
    /// its own — briefed on every trip via `EquiContext`, with the last few
    /// turns folded back in so a follow-up like "and the other one?" still
    /// resolves. See `EquiIntelligence.streamReply`.
    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let recent = messages.map { EquiIntelligence.Turn(isUser: $0.isUser, text: $0.text) }
        history.append(EquiMessage(text: trimmed, isUser: true))
        composerFocused = false
        isThinking = true

        replyTask?.cancel()
        replyTask = Task { @MainActor in
            switch EquiIntelligence.availability {
            case .unavailable(let reason):
                try? await Task.sleep(for: .milliseconds(400))
                isThinking = false
                history.append(EquiMessage(text: reason, isUser: false))
                return
            case .ready:
                break
            }

            var replyID: UUID?
            do {
                let stream = EquiIntelligence.streamReply(to: trimmed, recent: recent, store: tripStore)
                for try await chunk in stream {
                    // A cancelled reply is one the user walked away from, not
                    // one that failed — but what it managed to say is still
                    // part of the conversation, so it is saved before we go.
                    guard !Task.isCancelled else {
                        if let replyID { history.finishReply(replyID) }
                        return
                    }

                    if let replyID {
                        history.stream(replyID, text: chunk.text, card: chunk.card)
                    } else {
                        // Hold the thinking dots until there's something to
                        // show — the structured answer's first tokens can be
                        // an empty string while the model opens the field.
                        guard !chunk.text.isEmpty || chunk.card != nil else { continue }

                        isThinking = false
                        let message = EquiMessage(text: chunk.text, isUser: false, card: chunk.card)
                        replyID = message.id
                        history.beginReply(message)
                    }
                }
                // Saved once, here, rather than on every token: a reply is a
                // hundred chunks and one row.
                if let replyID { history.finishReply(replyID) }
            } catch {
                guard !Task.isCancelled else { return }
                isThinking = false
                let apology = "Something went wrong answering that — try again?"
                if let replyID {
                    history.stream(replyID, text: apology, card: nil)
                    history.finishReply(replyID)
                } else {
                    history.append(EquiMessage(text: apology, isUser: false))
                }
            }
        }
    }

    /// Puts the conversation away and starts an empty one. Nothing is lost —
    /// what was on screen is already behind the clock in the header.
    private func startOver() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        replyTask?.cancel()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            history.startNewConversation()
            isThinking = false
        }
    }

    private func openHistory() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        composerFocused = false
        showingHistory = true
        // Refreshed on every open rather than trusted from launch: the list is
        // the one thing on this screen that another device can change.
        Task { await history.loadConversations() }
    }

    /// Loads a past conversation into the thread, replacing what's there.
    private func openConversation(_ summary: EquiConversationSummary) {
        replyTask?.cancel()
        isThinking = false
        Task { await history.open(summary) }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }
}

#Preview {
    EquiAssistantView()
}

private extension View {
    /// The header's drop-in on first arrival, shared by the phone and iPad
    /// arrangements so the two can't drift onto different beats.
    func headerEntrance(appeared: Bool, isEmpty: Bool) -> some View {
        self
            .offset(y: appeared ? 0 : -14)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.02), value: appeared)
            .animation(.spring(response: 0.32, dampingFraction: 0.75), value: isEmpty)
    }
}

/// Where the header goes: the iPad's tab-bar line, or an ordinary top bar.
///
/// The phone keeps the plain `safeAreaBar` it was designed on rather than
/// `tabAlignedHeader`, whose own fallback left this screen with no header at
/// all. A wide iPad has no header here — the sidebar carries it.
private struct EquiHeaderBar<Header: View>: ViewModifier {
    var onTabLine: Bool
    @ViewBuilder var header: Header

    func body(content: Content) -> some View {
        if onTabLine {
            content.tabAlignedHeader { header }
        } else {
            content.safeAreaBar(edge: .top, spacing: 0) { header }
        }
    }
}

/// Fades the prompt lanes out at both ends of the wide iPad's thread column.
///
/// Beside the sidebar the column's edge would otherwise be a hard vertical
/// line the tiles vanish into, and the window's own edge gets the same fade so
/// the lanes read as one strip easing in and out. Only on a wide iPad: a mask
/// renders the lanes offscreen, and on the phone — where they simply run off
/// the screen — that once left their glass as grey plates. In the column the
/// glass held up, checked in the simulator.
private struct EquiLaneFade: ViewModifier {
    var isOn: Bool

    private static let fade: CGFloat = 90

    func body(content: Content) -> some View {
        if isOn {
            content.mask {
                HStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                        .frame(width: Self.fade)
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: Self.fade)
                }
                // Past the tiles' shadows above and below.
                .padding(.vertical, -20)
            }
        } else {
            content
        }
    }
}
