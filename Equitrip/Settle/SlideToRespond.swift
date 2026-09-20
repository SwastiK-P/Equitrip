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
/// one dark track with the knob resting in the middle and an answer on each
/// side: drag right and let go past the line to confirm, left to say it
/// didn't arrive. Let go short of the line and it springs back to centre.
///
/// The light does the explaining. Touching the knob lifts it and throws a
/// glow out of both sides — green one way, red the other — so the two
/// answers are visible before either is chosen. Once the drag picks a side
/// the other glow goes out, the track fills behind the knob in that colour,
/// and the words the knob has passed over take the colour too. Minute haptic
/// clicks mark the travel and a firm detent marks the commit line.
struct SlideToRespond: View {
    var onConfirm: () -> Void
    var onDecline: () -> Void
    /// What the two ends actually mean here.
    ///
    /// A word or two each: they sit inside the track either side of the knob,
    /// and a phrase long enough to need shrinking ends up a different size
    /// from its partner and pressed against the rounded end. The question
    /// itself belongs above the control. The words are still the caller's to
    /// set, because the control also answers a request to leave — where an
    /// answer about money received would describe the wrong act.
    var confirmTitle: String = "Confirm"
    var declineTitle: String = "Decline"
    /// What the track says once the answer is in. The knob parks at the end
    /// over most of its side's label, so the landing gets a word of its own
    /// rather than the stub of the one it covered.
    var confirmedTitle: String = "Confirmed"
    var declinedTitle: String = "Declined"
    /// Read out in place of the payment-specific default.
    var accessibilityTitle: String = "Respond to this payment"
    var accessibilityDetail: String = "Confirm you received it, or say it hasn't arrived"

    private enum Answer { case confirm, decline }

    /// The knob's centre, measured from the track's centre.
    @State private var dragX: CGFloat = 0
    @State private var trackWidth: CGFloat = 0
    @State private var isTouching = false
    @State private var settled: Answer?
    @State private var pastThreshold: Answer?
    @State private var lastHapticStep: Int = 0

    private let height: CGFloat = 62
    /// A pill rather than a disc — wide enough to read as something you push
    /// sideways, and to hold an arrow that says which way.
    private let knobWidth: CGFloat = 90
    /// At rest the knob sits a few points inside the track and grows to fill
    /// it on touch — the "picked up" moment.
    private let restInset: CGFloat = 5
    /// How far (as a fraction of the half-track) counts as a commit. Short of
    /// the classic "slide all the way across" — this is a flick you can do in
    /// one thumb's-width of travel, not a deliberate haul from edge to edge.
    private static let threshold: CGFloat = 0.6
    /// Points of drag travel per minute haptic click.
    private static let hapticStepDistance: CGFloat = 14

    /// How long a sheet answered through this stays up after the answer is
    /// in, before it goes. The landed track — "Confirmed" in the answer's
    /// colour — is the receipt for the drag; gone in a blink, it read as the
    /// sheet vanishing on its own. The answer is saved at once; only the exit
    /// waits, so closing early never loses it.
    static let landingHold: Duration = .milliseconds(1700)

    private var maxDrag: CGFloat {
        max(1, (trackWidth - knobWidth) / 2)
    }

    /// -1 (fully decline) … 0 (rest) … 1 (fully confirm).
    private var progress: CGFloat {
        max(-1, min(1, dragX / maxDrag))
    }

    private var magnitude: CGFloat { abs(progress) }

    private var isLifted: Bool { isTouching || settled != nil }

    /// +1 toward confirm, -1 toward decline. An answer, once given, wins over
    /// wherever the knob happens to be mid-spring.
    private var direction: CGFloat {
        switch settled {
        case .confirm: 1
        case .decline: -1
        case nil: dragX >= 0 ? 1 : -1
        }
    }

    private var tint: Color { direction > 0 ? Palette.glowGreen : Palette.glowRed }

    /// The glow colour lifted toward white, so words drawn in it stay legible
    /// on a track that's already washed in the same hue.
    private var textTint: Color { tint.mix(with: AppTheme.ctaLabel, by: 0.4) }

    var body: some View {
        ZStack {
            Capsule()
                .fill(AppTheme.cta)

            // Starts from nothing: any colour at all on the first stop draws
            // a hard vertical seam where the fill begins.
            sweep(
                LinearGradient(
                    stops: [
                        .init(color: tint.opacity(0), location: 0),
                        .init(color: tint.opacity(0.1), location: 0.4),
                        .init(color: tint.opacity(0.34), location: 1)
                    ],
                    startPoint: direction > 0 ? .leading : .trailing,
                    endPoint: direction > 0 ? .trailing : .leading
                )
            )
            .opacity(sweepStrength)

            halo(.decline)
            halo(.confirm)

            Capsule()
                .strokeBorder(AppTheme.ctaLabel.opacity(0.1), lineWidth: 1)

            Capsule()
                .strokeBorder(tint.opacity(0.5), lineWidth: 1)
                .mask { sweep(LinearGradient(colors: [.clear, .black], startPoint: direction > 0 ? .leading : .trailing, endPoint: direction > 0 ? .trailing : .leading)) }
                .opacity(sweepStrength)

            labels(AppTheme.ctaLabel)

            // The same words again in the glow colour, cut to the part of the
            // track the knob has already crossed.
            labels(textTint)
                .mask { sweep(Color.black) }

            landing

            knob
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(.capsule)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { trackWidth = $0 }
        .contentShape(.capsule)
        .gesture(drag)
        .disabled(settled != nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint(accessibilityDetail)
        .accessibilityAction(named: confirmTitle) { commit(.confirm) }
        .accessibilityAction(named: declineTitle) { commit(.decline) }
    }

    // MARK: - Sweep

    /// The stretch of track the knob has crossed, from where it rested to its
    /// centre — or, once answered, the whole track.
    ///
    /// Measured from the resting knob's far edge rather than the centre, so
    /// the fade-in begins exactly where the track is first uncovered.
    private func sweep<S: ShapeStyle>(_ style: S) -> some View {
        let start = settled != nil ? -direction * trackWidth / 2 : -direction * knobWidth / 2
        let low = min(start, dragX)
        let high = max(start, dragX)

        return Rectangle()
            .fill(style)
            .frame(width: max(0, high - low))
            .offset(x: (low + high) / 2)
    }

    /// Fades the fill in over the first few points, so it arrives with the
    /// drag rather than appearing as a sliver the moment a finger lands.
    private var sweepStrength: Double {
        settled != nil ? 1 : Double(min(1, magnitude * 5))
    }

    // MARK: - Glow

    /// A blurred comet of one answer's colour, its bright head at the knob.
    ///
    /// Held still, it's barely longer than the knob and peeks out ahead of it
    /// — that's what shows both answers at once. As the drag commits to a
    /// side its tail stretches back down the track, fading as it goes, and
    /// past the commit line (or once answered) it reaches most of the way to
    /// where the knob started: the light is how far you've come.
    private func halo(_ answer: Answer) -> some View {
        let side: CGFloat = answer == .confirm ? 1 : -1
        let toward = max(0, progress * side)
        let away = max(0, -progress * side)

        let armed = settled == answer || pastThreshold == answer
        let tail = 180 * toward + (armed ? 80 : 0)
        let length = knobWidth + 6 + tail
        // How far the head sits past the knob's leading edge: a clear peek
        // while held still, tucked in once it's moving.
        let lead = 14 - 10 * toward
        let head = dragX + side * (knobWidth / 2 + lead)

        let opacity: Double = {
            if let settled { return settled == answer ? 0.9 : 0 }
            guard isTouching else { return 0 }
            let boost = pastThreshold == answer ? 0.15 : 0
            return min(1, 0.6 + 0.3 * Double(toward) + boost) * Double(1 - min(1, away * 3))
        }()

        let tint = answer == .confirm ? Palette.glowGreen : Palette.glowRed
        // The head keeps the knob-length's worth of full colour whatever the
        // length, so stretching the tail never dims the light at the knob.
        let solid = (knobWidth + 6) / length * 0.5
        let mid = solid + (1 - solid) * 0.45

        return Capsule()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: tint, location: 0),
                        .init(color: tint, location: solid),
                        .init(color: tint.opacity(0.5), location: mid),
                        .init(color: tint.opacity(0), location: 1)
                    ],
                    startPoint: side > 0 ? .trailing : .leading,
                    endPoint: side > 0 ? .leading : .trailing
                )
            )
            .frame(width: length, height: height * 0.9)
            .blur(radius: 18)
            .offset(x: head - side * length / 2)
            .opacity(opacity)
    }

    // MARK: - Labels

    private func labels(_ color: Color) -> some View {
        ZStack {
            sideLabel(declineTitle, side: -1, color: color)
            sideLabel(confirmTitle, side: 1, color: color)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Centred in the space between the resting knob and its end of the
    /// track, and held back at rest so the knob is what the eye lands on.
    /// The side being dragged toward comes up to full strength; the one being
    /// dragged away from goes out quickly, so there's no doubt which answer
    /// is loading.
    private func sideLabel(_ title: String, side: CGFloat, color: Color) -> some View {
        let toward = Double(max(0, progress * side))
        let away = Double(max(0, -progress * side))
        let opacity = settled != nil ? 0 : (0.62 + 0.38 * min(1, toward * 2.5)) * (1 - min(1, away * 2.5))

        return Text(title)
            .font(.system(size: 15, weight: .medium))
            .tracking(0.2)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .frame(width: maxDrag)
            .offset(x: side * (knobWidth / 2 + maxDrag / 2))
            .opacity(opacity)
    }

    /// The answer, spelled out in the space the knob left behind.
    private var landing: some View {
        Text(settled == .decline ? declinedTitle : confirmedTitle)
            .font(.system(size: 15, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(textTint)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(width: max(0, trackWidth - knobWidth))
            .offset(x: -direction * knobWidth / 2)
            .opacity(settled != nil ? 1 : 0)
    }

    // MARK: - Knob

    /// Grey and a little sunk at rest; lifted to a bright pill the moment
    /// it's touched, and kept that way once an answer lands.
    private var knob: some View {
        let inset = isLifted ? 0 : restInset

        return ZStack {
            Capsule()
                .fill(AppTheme.cta)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.ctaLabel.opacity(0.46), AppTheme.ctaLabel.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isLifted ? 0 : 1)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.ctaLabel, AppTheme.ctaLabel.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isLifted ? 1 : 0)

            Capsule()
                .strokeBorder(AppTheme.ctaLabel.opacity(isLifted ? 0.6 : 0.18), lineWidth: 1)

            // Swapped by identity rather than `.contentTransition(.symbolEffect)`:
            // the symbol effect renders its glyph in a layer that stops
            // following the knob's offset mid-drag, leaving the arrow painted
            // on the track where the knob used to be.
            Image(systemName: knobSymbol)
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(AppTheme.cta.opacity(isLifted ? 1 : 0.55))
                .id(knobSymbol)
                .transition(.scale(scale: 0.5).combined(with: .opacity))
        }
        .animation(.snappy(duration: 0.2), value: knobSymbol)
        .frame(width: knobWidth - inset * 2, height: height - inset * 2)
        .offset(x: dragX)
    }

    /// Both ways at rest; the way it's going once it moves; the answer once
    /// letting go would give it.
    private var knobSymbol: String {
        switch pastThreshold {
        case .confirm: "checkmark"
        case .decline: "xmark"
        case nil:
            if dragX > 8 { "arrow.right" }
            else if dragX < -8 { "arrow.left" }
            else { "arrow.left.and.right" }
        }
    }

    // MARK: - Gesture

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard settled == nil else { return }

                if !isTouching {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) { isTouching = true }
                }

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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        dragX = 0
                        isTouching = false
                    }
                }
            }
    }

    private func commit(_ answer: Answer) {
        let edge = answer == .confirm ? maxDrag : -maxDrag
        withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
            settled = answer
            pastThreshold = answer
            dragX = edge
            isTouching = false
        }

        UINotificationFeedbackGenerator().notificationOccurred(answer == .confirm ? .success : .warning)

        // A beat to see the knob land before the answer is sent; the caller
        // then holds for `landingHold` before leaving.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
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
