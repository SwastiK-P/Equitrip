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
private struct EquiMessage: Identifiable, Equatable {
    let id = UUID()
    var text: String
    let isUser: Bool
    var card: EquiCard?
    let sentAt = Date()

    init(text: String, isUser: Bool, card: EquiCard? = nil) {
        self.text = text
        self.isUser = isUser
        self.card = card
    }
}

/// A short question the empty state offers so the first message isn't a
/// blank page staring back — the same problem a search bar has, solved the
/// same way.
private struct EquiPrompt: Identifiable, Equatable {
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

    @State private var messages: [EquiMessage] = []
    @State private var draft = ""
    @State private var isThinking = false
    @State private var hasAppeared = false
    @State private var replyTask: Task<Void, Never>?
    @FocusState private var composerFocused: Bool

    // The arrival beat. See `playEntrance` — one sequencer drives all four so
    // the light, the bloom, the orb and the feel land together.
    @State private var sweepTravel: Double = 0
    @State private var sweepGlow: Double = 0
    @State private var bloom: Double = 0
    @State private var orbPop = false
    @State private var lastPlayedArrival: Int?

    private static let bottomAnchor = "equi-bottom"

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
            EquiAuroraBackground(isThinking: isThinking, isAppeared: hasAppeared, bloom: bloom)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                EquiBubbleRow(
                                    message: message,
                                    isLastInGroup: isLastInGroup(at: index),
                                    onOpenTrip: onOpenTrip
                                )
                                .id(message.id)
                                .padding(.top, isFirstInGroup(at: index) ? 14 : 2)
                                .transition(
                                    .asymmetric(
                                        insertion: .modifier(
                                            active: BubblePop(offset: message.isUser ? 18 : -18, scale: 0.82, opacity: 0),
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
        }
        // Tap anywhere above the composer to put the keyboard away.
        //
        // `scrollDismissesKeyboard` covers this in a thread you can scroll,
        // but the empty state deliberately can't be scrolled, so that gesture
        // has nothing to ride on and the keyboard had no way out at all. The
        // catcher only exists while the field is focused, so it never sits
        // between a finger and a prompt tile.
        //
        // Applied *before* the bars: an overlay here covers the thread and
        // nothing else, which is what keeps it off the composer and the send
        // button underneath it.
        .overlay {
            if composerFocused {
                Color.clear
                    .contentShape(.rect)
                    .onTapGesture { composerFocused = false }
                    .accessibilityHidden(true)
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .safeAreaInset(edge: .bottom, spacing: 0) { composerBar }
        // Above the bars as well as the thread, so the light passes over the
        // whole screen rather than stopping at the composer.
        .overlay { EquiShine(travel: sweepTravel, glow: sweepGlow) }
        // Keyed on the count, not the messages themselves — a bubble arriving
        // or leaving springs into place, but a stream of tokens landing in an
        // existing one shouldn't re-trigger that spring on every word.
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: messages.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isThinking)
        .task { EquiArrivalHaptics.prepare() }
        .onAppear { playEntrance() }
        .onChange(of: arrival) { _, _ in playEntrance() }
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

    private func isFirstInGroup(at index: Int) -> Bool {
        guard index > 0 else { return true }
        return messages[index].isUser != messages[index - 1].isUser
    }

    private func isLastInGroup(at index: Int) -> Bool {
        guard index < messages.count - 1 else { return true }
        return messages[index].isUser != messages[index + 1].isUser
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
    private var header: some View {
        ZStack {
            VStack(spacing: 1) {
                Text("Equi")
                    .font(.system(size: 16.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(isThinking ? "Thinking…" : "Your trip assistant")
                    .font(.system(size: 11.5, weight: .medium))
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

            HStack {
                Spacer()

                if !messages.isEmpty {
                    CircleGlyphButton(symbol: "plus.bubble", size: 44) { startOver() }
                        .accessibilityLabel("New conversation")
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .offset(y: hasAppeared ? 0 : -14)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.02), value: hasAppeared)
        .animation(.spring(response: 0.32, dampingFraction: 0.75), value: messages.isEmpty)
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
                        .font(.system(size: 33, weight: .semibold))
                        .tracking(-0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("About the plan, the money, or what's next.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 18)
                .equiStagger(0, appeared: hasAppeared)
                .transition(.opacity.combined(with: .offset(y: -12)))
            }

            EquiHeroScene(appeared: hasAppeared)
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
                    .padding(.top, 36)
                    .transition(.opacity.combined(with: .offset(y: 12)))
            }
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical, alignment: .center)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: composerFocused)
    }

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
        // measure as the transcript it's writing into.
        .padding(.horizontal, 22)
        .readableWidth()
        .padding(.top, 10)
        .padding(.bottom, 10)
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

        let history = messages.map { EquiIntelligence.Turn(isUser: $0.isUser, text: $0.text) }
        messages.append(EquiMessage(text: trimmed, isUser: true))
        composerFocused = false
        isThinking = true

        replyTask?.cancel()
        replyTask = Task { @MainActor in
            switch EquiIntelligence.availability {
            case .unavailable(let reason):
                try? await Task.sleep(for: .milliseconds(400))
                isThinking = false
                messages.append(EquiMessage(text: reason, isUser: false))
                return
            case .ready:
                break
            }

            var replyID: UUID?
            do {
                let stream = EquiIntelligence.streamReply(to: trimmed, recent: history, store: tripStore)
                for try await chunk in stream {
                    guard !Task.isCancelled else { return }

                    if let replyID, let index = messages.firstIndex(where: { $0.id == replyID }) {
                        messages[index].text = chunk.text
                        messages[index].card = chunk.card
                    } else {
                        // Hold the thinking dots until there's something to
                        // show — the structured answer's first tokens can be
                        // an empty string while the model opens the field.
                        guard !chunk.text.isEmpty || chunk.card != nil else { continue }

                        isThinking = false
                        let message = EquiMessage(text: chunk.text, isUser: false, card: chunk.card)
                        replyID = message.id
                        messages.append(message)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                isThinking = false
                if let replyID, let index = messages.firstIndex(where: { $0.id == replyID }) {
                    messages[index].text = "Something went wrong answering that — try again?"
                } else {
                    messages.append(EquiMessage(text: "Something went wrong answering that — try again?", isUser: false))
                }
            }
        }
    }

    private func startOver() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        replyTask?.cancel()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            messages.removeAll()
            isThinking = false
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            proxy.scrollTo(Self.bottomAnchor, anchor: .bottom)
        }
    }
}

// MARK: - Aurora background

/// Equi's own backdrop, and the one screen in the app that isn't a flat
/// canvas.
///
/// One layer now, not four. It used to carry a lattice of dots, a set of
/// spreading rings and the mountain horizon as well — which was defensible
/// when the screen was a face on a gradient, and stopped being defensible the
/// moment the valley moved into the page itself as an illustration. Texture
/// behind a drawing doesn't add depth to it, it competes with it. What's left
/// is a `MeshGradient` whose control points drift so beige bleeds into violet
/// and back without ever repeating: sky for the illustration to sit in, and
/// nothing else asking to be looked at.
private struct EquiAuroraBackground: View {
    let isThinking: Bool
    let isAppeared: Bool
    /// 0 normally; driven to 1 and back on arrival, which brightens and
    /// spreads the whole field so the screen looks like it's waking up under
    /// the gleam rather than sitting still behind it.
    var bloom: Double = 0

    @State private var drift = false

    // The mesh's own palette: the app's beige at the corners, violet pooled
    // through the middle. Held here rather than inline so the two point sets
    // below stay readable.
    private static let beige = AppTheme.canvasTop
    private static let beigeDeep = AppTheme.dynamic(light: 0xF7E9DC, dark: 0x181210)
    private static let lilac = AppTheme.dynamic(light: 0xEDE6FF, dark: 0x231C3A)
    private static let lilacDeep = AppTheme.dynamic(light: 0xDCD0FB, dark: 0x2E2551)
    private static let blush = AppTheme.dynamic(light: 0xFBE4D6, dark: 0x241713)

    var body: some View {
        ZStack {
            AppTheme.canvasTop

            mesh
                .blur(radius: 26)
                .opacity(0.92)

            // The bottom of the screen still has to be the app's canvas, or
            // the composer sitting on it stops looking like it belongs here.
            LinearGradient(
                stops: [
                    .init(color: AppTheme.canvasBottom.opacity(0), location: 0),
                    .init(color: AppTheme.canvasBottom.opacity(0), location: 0.7),
                    .init(color: AppTheme.canvasBottom, location: 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.7)
        }
        .ignoresSafeArea()
        .scaleEffect(isAppeared ? 1 + bloom * 0.03 : 1.06)
        .opacity(isAppeared ? 1 : 0)
        .animation(.easeOut(duration: 0.7), value: isAppeared)
        .onAppear { startDrifting() }
        .onChange(of: isThinking) { _, _ in startDrifting() }
    }

    /// A 3×3 mesh with the four corners pinned and the edge and centre points
    /// wandering. Pinning the corners is what keeps the beige reading as the
    /// page it is: only the violet in the middle moves.
    private var mesh: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0],
                [drift ? 0.42 : 0.60, drift ? 0.00 : 0.06],
                [1.0, 0.0],

                [0.0, drift ? 0.44 : 0.34],
                [drift ? 0.36 : 0.64, drift ? 0.52 : 0.40],
                [1.0, drift ? 0.32 : 0.46],

                [0.0, 1.0],
                [drift ? 0.58 : 0.40, drift ? 1.00 : 0.94],
                [1.0, 1.0]
            ],
            colors: [
                Self.beige, Self.lilac, Self.beige,
                Self.lilac, Self.lilacDeep, Self.blush,
                Self.beigeDeep, Self.lilac, Self.beigeDeep
            ],
            smoothsColors: true
        )
    }

    /// Restarting the drift when `isThinking` flips is what makes the screen
    /// quicken while a reply is being composed.
    private func startDrifting() {
        let duration = isThinking ? 6.0 : 12.0
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            drift.toggle()
        }
    }
}

// MARK: - Equi orb

/// The small gradient sphere that stands in for Equi throughout the thread —
/// header, empty state, gutter, thinking bubble. Centralised so its "alive"
/// pulse (a slow breathing ring while thinking) is defined once.
private struct EquiOrb: View {
    var size: CGFloat
    var isThinking: Bool
    var glyphSize: CGFloat? = nil

    @State private var pulse = false

    var body: some View {
        ZStack {
            if isThinking {
                Circle()
                    .stroke(AppTheme.accent.opacity(0.35), lineWidth: 2)
                    .frame(width: size, height: size)
                    .scaleEffect(pulse ? 1.45 : 1)
                    .opacity(pulse ? 0 : 0.8)
                    .animation(.easeOut(duration: 1.1).repeatForever(autoreverses: false), value: pulse)
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentDeep],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)

            Image("Equi")
                .font(.system(size: glyphSize ?? size * 0.41, weight: .semibold))
                .foregroundStyle(.white)
        }
        .onAppear { if isThinking { pulse = true } }
        .onChange(of: isThinking) { _, thinking in pulse = thinking }
    }
}

// MARK: - Prompt wall

/// Three lanes of starter questions, drifting past each other.
///
/// A static row of four suggestions answers "what can I ask?" once; a lane
/// that keeps moving answers it continuously, and reads as somewhere with
/// more in it than fits. Each runs at its own speed, and the middle one runs
/// the other way — matched motion would let the eye lock onto the wall as a
/// single block sliding sideways.
private struct EquiPromptWall: View {
    let rows: [[EquiPrompt]]
    var appeared: Bool
    let onTap: (String) -> Void

    /// Points per second; the sign is the direction. Deliberately slow — this
    /// sits under an illustration, and anything brisk enough to notice pulls
    /// the eye straight off it.
    private static let speeds: [Double] = [14, -19, 11]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                EquiMarqueeRow(
                    prompts: row,
                    speed: Self.speeds[index % Self.speeds.count],
                    phase: Double(index) * 0.37,
                    onTap: onTap
                )
                .equiStagger(4 + index, appeared: appeared)
            }
        }
        // Deliberately unmasked. A softening gradient at each end was the
        // obvious finish, but a `mask` composites its subtree offscreen, and
        // Liquid Glass rendered offscreen has no live backdrop left to
        // sample — it falls back to an opaque plate, which showed up as a
        // grey band running the width of every lane. The screen edge is the
        // cut instead.
    }
}

/// One lane of the wall.
///
/// The offset is computed from the clock inside a `TimelineView` rather than
/// handed to `withAnimation(.repeatForever)`, for one reason: SwiftUI hit-tests
/// against the model geometry, not the presentation layer, so a tile animated
/// the usual way would be tappable where it *will be* rather than where it is.
/// Driving the offset per frame keeps the two in step, and the tiles stay
/// tappable while they move.
///
/// The cost of that is a body pass per frame, which is why the strip is
/// `Equatable` — the tiles themselves are then never rebuilt, and each frame
/// only moves a transform.
private struct EquiMarqueeRow: View {
    let prompts: [EquiPrompt]
    let speed: Double
    /// Fraction of a cycle to start at, so the lanes don't march in step.
    let phase: Double
    let onTap: (String) -> Void

    @State private var stripWidth: CGFloat = 0

    private static let rowHeight: CGFloat = 40
    private static let gap: CGFloat = 8

    var body: some View {
        Color.clear
            .frame(height: Self.rowHeight)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                TimelineView(.animation) { context in
                    HStack(spacing: Self.gap) {
                        // Three copies: the lane only ever slides by one
                        // strip's width, so two are enough to cover any phone
                        // and the third is insurance for a wide device or a
                        // short row.
                        ForEach(0..<3, id: \.self) { copy in
                            strip
                                .equatable()
                                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
                                    if copy == 0 { stripWidth = width }
                                }
                        }
                    }
                    .fixedSize()
                    .offset(x: offset(at: context.date))
                }
            }
    }

    /// Walks from `-cycle` to `0` and jumps back — at `-cycle` the second copy
    /// sits exactly where the first one does at `0`, so the reset is invisible
    /// and the lane reads as one endless strip.
    ///
    /// The wrap is written out rather than left to `truncatingRemainder`,
    /// which keeps the sign of its dividend: a leftward lane would otherwise
    /// land in `-2 * cycle ..< -cycle` and sit a full strip off the leading
    /// edge, showing an empty row.
    private func offset(at date: Date) -> CGFloat {
        let cycle = stripWidth + Self.gap
        guard cycle > 1 else { return 0 }

        let travelled = date.timeIntervalSinceReferenceDate * speed + phase * cycle
        var wrapped = travelled.truncatingRemainder(dividingBy: cycle)
        if wrapped < 0 { wrapped += cycle }
        return CGFloat(wrapped) - cycle
    }

    private var strip: EquiPromptStrip {
        EquiPromptStrip(prompts: prompts, gap: Self.gap, onTap: onTap)
    }
}

/// The repeating run of tiles.
///
/// `Equatable` on the prompts alone: the closure is captured fresh on every
/// pass and would defeat the synthesised conformance, and the whole point is
/// to let SwiftUI skip this subtree on the frames where only the offset moved.
private struct EquiPromptStrip: View, Equatable {
    let prompts: [EquiPrompt]
    let gap: CGFloat
    let onTap: (String) -> Void

    static func == (lhs: EquiPromptStrip, rhs: EquiPromptStrip) -> Bool {
        lhs.prompts == rhs.prompts && lhs.gap == rhs.gap
    }

    var body: some View {
        // No `GlassEffectContainer` around these. A container is for glass
        // that merges or morphs, which these never do, and it gives the
        // renderer one more reason to flatten the lane into a single plate
        // instead of letting each capsule sample the mesh behind it.
        HStack(spacing: gap) {
            ForEach(prompts) { prompt in
                EquiPromptTile(prompt: prompt) { onTap(prompt.text) }
            }
        }
    }
}

private struct EquiPromptTile: View {
    let prompt: EquiPrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: prompt.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)

                Text(prompt.text)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassEffect(.regular.tint(AppTheme.accent.opacity(0.06)).interactive(), in: .capsule)
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.75)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Bubble row

private struct EquiBubbleRow: View {
    @Environment(\.tripStore) private var tripStore

    let message: EquiMessage
    let isLastInGroup: Bool
    var onOpenTrip: (Trip) -> Void = { _ in }

    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 7) {
                if message.isUser {
                    Spacer(minLength: 40)
                } else {
                    gutter
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 16))
                        .foregroundStyle(message.isUser ? .white : AppTheme.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background {
                            bubbleShape
                                .fill(message.isUser ? AnyShapeStyle(mineGradient) : AnyShapeStyle(.ultraThinMaterial))
                                .overlay {
                                    if !message.isUser {
                                        bubbleShape.strokeBorder(AppTheme.cardStroke.opacity(0.08))
                                    }
                                }
                                .shadow(
                                    color: message.isUser ? AppTheme.accent.opacity(0.22) : .black.opacity(0.05),
                                    radius: 8,
                                    y: 3
                                )
                        }
                }

                if message.isUser { gutter }
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)

            // Inset to the bubble's own column, so a card lines up under the
            // text rather than under the avatar beside it.
            if let card = message.card {
                Button {
                    guard let trip = tripStore.trip(card.tripID) else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenTrip(trip)
                } label: {
                    EquiCardView(card: card)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.leading, message.isUser ? 0 : 31)
                .transition(.scale(scale: 0.94, anchor: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: message.card)
    }

    /// iMessage-style grouping: bubbles stay fully rounded while more from the
    /// same speaker follow, and only the last one in a run gets the tucked-in
    /// corner that reads as "end of thought."
    private var bubbleShape: UnevenRoundedRectangle {
        let tail: CGFloat = isLastInGroup ? 5 : 18
        return UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: message.isUser ? 18 : tail,
            bottomTrailingRadius: message.isUser ? tail : 18,
            topTrailingRadius: 18,
            style: .continuous
        )
    }

    /// The assistant gets its orb on the leading edge; the user gets their
    /// own avatar on the trailing edge — "my side should look like mine,"
    /// same as it does everywhere else in the app a person's face shows up.
    /// Either way it only appears on the last bubble of a run, so a burst of
    /// consecutive messages doesn't repeat the same face down the column.
    @ViewBuilder
    private var gutter: some View {
        if isLastInGroup {
            Group {
                if message.isUser {
                    TravellerAvatar(traveller: .you, size: 24)
                } else {
                    EquiOrb(size: 24, isThinking: false, glyphSize: 10)
                }
            }
            // `TravellerAvatar`'s own ring is drawn in `AppTheme.card`, which
            // matches the flat surfaces it normally sits on — but here it's
            // floating over the aurora background, a near-identical hue in
            // light mode, so that ring all but disappears. A true white
            // stroke on top reads as a border against any of it.
            .overlay { Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.75) }
        } else {
            Color.clear.frame(width: 24, height: 24)
        }
    }

    private var mineGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Thinking indicator

private struct EquiThinkingBubble: View {
    @State private var pulsing = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 7) {
            EquiOrb(size: 24, isThinking: true, glyphSize: 10)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.inkTertiary)
                        .frame(width: 7, height: 7)
                        .scaleEffect(pulsing ? 1 : 0.55)
                        .opacity(pulsing ? 1 : 0.4)
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
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 5,
                    bottomTrailingRadius: 18,
                    topTrailingRadius: 18,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                .overlay {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 18,
                        bottomLeadingRadius: 5,
                        bottomTrailingRadius: 18,
                        topTrailingRadius: 18,
                        style: .continuous
                    )
                    .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                }
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement()
        .accessibilityLabel("Equi is thinking")
        .onAppear { pulsing = true }
    }
}

// MARK: - Entrance helpers

/// A pop-in transition for message bubbles: a small lateral offset, scale and
/// fade combined, driven through SwiftUI's transition system rather than a
/// hand-rolled `.onAppear` animation so it composes correctly with list
/// insertion/removal.
private struct BubblePop: ViewModifier {
    var offset: CGFloat
    var scale: CGFloat
    var opacity: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .scaleEffect(scale, anchor: .bottom)
            .opacity(opacity)
    }
}

extension View {
    /// Staggers an empty-state element's entrance behind `hasAppeared` so the
    /// first open of the tab reads as things settling into place one after
    /// another, not a single flat fade.
    ///
    /// Internal rather than private: the hero scene staggers its own notes and
    /// arrows on the same beat, and two copies of this would be two beats.
    func equiStagger(_ index: Int, appeared: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.8)
                    .delay(0.12 + Double(index) * 0.06),
                value: appeared
            )
    }
}

#Preview {
    EquiAssistantView()
}
