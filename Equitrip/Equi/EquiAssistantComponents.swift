//
//  EquiAssistantComponents.swift
//  Equitrip
//

import SwiftUI

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
struct EquiAuroraBackground: View {
    let isThinking: Bool
    let isAppeared: Bool
    /// 0 normally; driven to 1 and back on arrival, which brightens and
    /// spreads the whole field so the screen looks like it's waking up under
    /// the gleam rather than sitting still behind it.
    var bloom: Double = 0
    /// Only once a conversation is under way. The empty state has its own
    /// illustration and prompts to carry the screen, and glyphs behind a
    /// landscape made both of them noisier.
    var showsPattern = false

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

            // Over the mesh rather than under it, or the blur would smear the
            // glyphs into grey dust; low enough that a bubble never has to
            // compete with it.
            EquiSymbolPattern()
                .opacity(showsPattern ? 0.13 : 0)
                .animation(.easeInOut(duration: 0.5), value: showsPattern)

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
struct EquiOrb: View {
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
struct EquiPromptWall: View {
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
struct EquiMarqueeRow: View {
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
struct EquiPromptStrip: View, Equatable {
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

struct EquiPromptTile: View {
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

struct EquiBubbleRow: View {
    @Environment(\.tripStore) private var tripStore
    @Environment(\.pane) private var pane

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
                        // On a phone the 40pt spacer is the cap. In a 660pt
                        // column it let a long answer run the full measure,
                        // which stops reading as a bubble from one side and
                        // becomes a paragraph laid across both.
                        .frame(maxWidth: pane.isRegular ? 500 : .infinity, alignment: message.isUser ? .trailing : .leading)
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
                // Held to the same width as the bubble above it on iPad; a
                // card's figures are laid out for a phone's width and spread
                // apart past it.
                .frame(maxWidth: pane.isRegular ? 460 : .infinity, alignment: .leading)
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

struct EquiThinkingBubble: View {
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
struct BubblePop: ViewModifier {
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
