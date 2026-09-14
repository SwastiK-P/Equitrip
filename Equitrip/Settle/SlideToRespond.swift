//
//  SlideToRespond.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// Answering a settlement claim as one drag instead of two taps.
///
/// A pair of buttons makes "yes" and "no" weigh the same, and a claim about
/// real money moving shouldn't be that easy to answer by accident. This is
/// one track with the two answers living at its ends: drag right and let go
/// past the line to confirm, left to say it didn't arrive.
///
/// The proportions are the effort slider's: a thin track with the knob riding
/// *on* it rather than sunk into a rail, and the label pair sitting above
/// rather than crammed inside. The container itself glows green as the drag goes
/// right and red as it goes left — with no tail behind the knob — accompanied by
/// minute mechanical haptic clicks for each increment of travel and a firm detent
/// at the commit line. Let go short of the line and the whole thing springs back to center.
struct SlideToRespond: View {
    var onConfirm: () -> Void
    var onDecline: () -> Void
    /// What the two ends actually mean here.
    ///
    /// Defaulted to a settlement's wording because that's what this was built
    /// for, but the control is now also used to answer a request to leave —
    /// where "Confirm received" reads as though money is about to move, which
    /// it isn't. A slider whose labels describe the wrong act is worse than no
    /// slider, so the words are the caller's to set.
    var confirmTitle: String = "Confirm received"
    var declineTitle: String = "Didn't get this"
    /// Read out in place of the payment-specific default.
    var accessibilityTitle: String = "Respond to this payment"
    var accessibilityDetail: String = "Confirm you received it, or say it hasn't arrived"

    private enum Answer { case confirm, decline }

    @State private var dragX: CGFloat = 0
    @State private var trackWidth: CGFloat = 0
    @State private var settled: Answer?
    @State private var pastThreshold: Answer?
    @State private var lastHapticStep: Int = 0

    /// The pill is sized to just take the knob — a couple of points of
    /// margin around it and nothing more.
    private let thumbSize: CGFloat = 34
    private let trackHeight: CGFloat = 38
    /// How far (as a fraction of the half-track) counts as a commit. Short of
    /// the classic "slide all the way across" — this is a flick you can do in
    /// one thumb's-width of travel, not a deliberate haul from edge to edge.
    private static let threshold: CGFloat = 0.6
    /// Points of drag travel per minute haptic click.
    private static let hapticStepDistance: CGFloat = 14

    private var maxDrag: CGFloat {
        max(1, (trackWidth - thumbSize) / 2)
    }

    /// -1 (fully decline) … 0 (rest) … 1 (fully confirm).
    private var progress: CGFloat {
        max(-1, min(1, dragX / maxDrag))
    }

    private var magnitude: CGFloat { abs(progress) }

    private var tint: Color {
        progress >= 0 ? AppTheme.positive : AppTheme.danger
    }

    var body: some View {
        VStack(spacing: 9) {
            labels

            ZStack {
                track
                thumb
            }
            .frame(height: trackHeight)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { trackWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, width in trackWidth = width }
                }
            }
        }
        .gesture(drag)
        .disabled(settled != nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint(accessibilityDetail)
        .accessibilityAction(named: confirmTitle) { commit(.confirm) }
        .accessibilityAction(named: declineTitle) { commit(.decline) }
    }

    // MARK: - Labels

    private var labels: some View {
        HStack(spacing: 0) {
            label("xmark", declineTitle, tint: AppTheme.danger)
                .opacity(sideOpacity(for: -1))

            Spacer(minLength: 8)

            label("checkmark", confirmTitle, tint: AppTheme.positive)
                .opacity(sideOpacity(for: 1))
        }
    }

    private func label(_ symbol: String, _ text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10.5, weight: .bold))
            Text(text)
                .font(.system(size: 12.5, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
    }

    /// Dims at rest, brightens as that side is approached — read together
    /// with the opposite label the drag is pulling away from, which dims
    /// further still so there's no doubt which answer is loading.
    private func sideOpacity(for side: CGFloat) -> Double {
        let toward = max(0, progress * side)
        let away = max(0, -progress * side)
        return 0.45 + toward * 0.55 - away * 0.25
    }

    // MARK: - Track Container

    /// The track container: neutral at rest, glowing green as the drag moves
    /// right to confirm, and red as it moves left to decline — with no tail behind the knob.
    private var track: some View {
        ZStack {
            Capsule()
                .fill(AppTheme.cardStroke.opacity(0.07))

            Capsule()
                .fill(tint.opacity(containerFillOpacity))

            Capsule()
                .strokeBorder(tint.opacity(containerStrokeOpacity), lineWidth: 1.5)

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { index in
                    if index > 0 { Spacer(minLength: 0) }
                    Circle()
                        .fill(AppTheme.inkTertiary.opacity(0.35))
                        .frame(width: 2.5, height: 2.5)
                }
            }
            .padding(.horizontal, thumbSize / 2)
        }
        .frame(height: trackHeight)
        .shadow(
            color: tint.opacity(containerGlowOpacity),
            radius: pastThreshold != nil ? 10 : 6
        )
        .animation(.easeOut(duration: 0.25), value: pastThreshold)
    }

    /// Smooth non-linear curve so colour whispers in gently as you slide rather than popping.
    private var easeFactor: Double {
        let eased = pow(Double(magnitude), 1.6)
        let boost = pastThreshold != nil ? 0.12 : 0.0
        return min(1.0, eased + boost)
    }

    private var containerFillOpacity: Double {
        easeFactor * 0.18
    }

    private var containerStrokeOpacity: Double {
        easeFactor * 0.32
    }

    private var containerGlowOpacity: Double {
        easeFactor * 0.22
    }

    // MARK: - Thumb

    private var thumb: some View {
        Circle()
            .fill(.white)
            .frame(width: thumbSize, height: thumbSize)
            .overlay {
                Image(systemName: thumbSymbol)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(thumbIconTint)
                    .contentTransition(.symbolEffect(.replace))
            }
            // Elevation only — no coloured glow of its own. The knob throws
            // the light backward down the track; it doesn't wear any.
            .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
            .scaleEffect(pastThreshold == nil ? 1 : 1.1)
            .offset(x: dragX)
            .animation(.interpolatingSpring(stiffness: 520, damping: 30), value: dragX)
    }

    private var thumbIconTint: Color {
        switch pastThreshold {
        case .confirm: AppTheme.positive
        case .decline: AppTheme.danger
        case nil: AppTheme.inkTertiary
        }
    }

    private var thumbSymbol: String {
        switch pastThreshold {
        case .confirm: "checkmark"
        case .decline: "xmark"
        case nil: "arrow.left.and.right"
        }
    }

    // MARK: - Gesture

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard settled == nil else { return }
                dragX = max(-maxDrag, min(maxDrag, value.translation.width))

                let now: Answer? = magnitude >= Self.threshold
                    ? (progress > 0 ? .confirm : .decline)
                    : nil

                if now != pastThreshold {
                    // Firm mechanical cue right as drag enters or leaves committing territory
                    UIImpactFeedbackGenerator(style: now == nil ? .light : .medium).impactOccurred()
                    withAnimation(.easeOut(duration: 0.25)) { pastThreshold = now }
                    lastHapticStep = Int(dragX / Self.hapticStepDistance)
                } else {
                    // Minute haptic click for each fine increment of travel
                    let step = Int(dragX / Self.hapticStepDistance)
                    if step != lastHapticStep {
                        lastHapticStep = step
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            }
            .onEnded { _ in
                guard settled == nil else { return }
                lastHapticStep = 0
                if let answer = pastThreshold {
                    commit(answer)
                } else {
                    if magnitude > 0.15 {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { dragX = 0 }
                }
            }
    }

    private func commit(_ answer: Answer) {
        settled = answer
        pastThreshold = answer

        let edge = answer == .confirm ? maxDrag : -maxDrag
        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) { dragX = edge }

        UINotificationFeedbackGenerator().notificationOccurred(answer == .confirm ? .success : .warning)

        // A beat to see the thumb land before whatever's driving `onConfirm`
        // / `onDecline` dismisses this — committing invisibly reads as the
        // drag doing nothing.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            answer == .confirm ? onConfirm() : onDecline()
        }
    }
}

#Preview {
    ZStack {
        CanvasBackground()
        SlideToRespond(onConfirm: {}, onDecline: {})
            .padding(.horizontal, 20)
    }
}
