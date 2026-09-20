//
//  ToastMotion.swift
//  Equitrip
//

import SwiftUI

/// Where every channel of a toast's entrance and exit stands at one instant.
///
/// The island drip is several animations layered with staggered starts: a
/// droplet falls out of the Dynamic Island, turns from island-black to glass,
/// swells into the card, and only then does the text sharpen in. The shape
/// is drawn in a `Canvas`, which SwiftUI's animation system can't
/// interpolate — so rather than `withAnimation`, each channel is a spring
/// evaluated against the clock inside a `TimelineView`. It also means an exit
/// that interrupts an entrance picks up from wherever each channel had got
/// to, instead of snapping.
struct ToastMotion {
    /// 0 = tucked inside the island, 1 = hanging at the card's position.
    var drop: Double
    /// 0 = a round droplet, 1 = the full-size card.
    var expand: Double
    /// 0 = content hidden and blurred, 1 = readable.
    var reveal: Double
    /// 0 = island black, 1 = glass.
    var tint: Double
    /// The plain slide-down used where there's no island to drip from.
    var slide: Double

    /// How much faster than the reference's timings everything plays. The
    /// springs and delays below keep their proportions, and this scales the
    /// clock, so the choreography stays the same, only quicker.
    static let speed = 1.4

    /// How long after a dismissal the last channel comes to rest — the
    /// droplet returning into the island. The center holds the toast on
    /// screen until then.
    static let exitDuration: Duration = .seconds(1.45 / speed)
    /// When the text is readable — auto-dismiss counts from here, so a toast
    /// gets its full reading time rather than losing time to the drip.
    static let revealDelay: TimeInterval = 0.56 / speed

    /// `elapsed` is the toast's own clock (see `Clock`), and `exitStart` is
    /// where that clock stood when the exit began.
    static func at(elapsed: TimeInterval, exitStart: TimeInterval?) -> ToastMotion {
        guard let exitStart else { return entering(elapsed) }

        let from = entering(exitStart)
        let t = elapsed - exitStart
        return ToastMotion(
            drop: settle(from.drop, to: 0, t - 0.28, Springs.returning),
            // Swells for a beat before it collapses — the anticipation that
            // makes the card read as being pulled back in, not shrinking.
            expand: settle(from.expand, to: 0, t - 0.10, Springs.collapse, velocity: 2),
            reveal: settle(from.reveal, to: 0, t, Springs.fade),
            tint: settle(from.tint, to: 0, t - 0.28, Springs.returning),
            slide: settle(from.slide, to: 0, t, Springs.slideOut)
        )
    }

    private static func entering(_ t: TimeInterval) -> ToastMotion {
        ToastMotion(
            drop: settle(0, to: 1, t, Springs.drop),
            expand: settle(0, to: 1, t - 0.34, Springs.expand),
            reveal: settle(0, to: 1, t - revealDelay, Springs.reveal),
            tint: settle(0, to: 1, t - 0.11, Springs.reveal),
            slide: settle(0, to: 1, t, Springs.slideIn)
        )
    }

    /// A spring from `from` to `to`, `t` seconds after it started. Negative
    /// `t` is a channel still waiting out its delay.
    static func settle(
        _ from: Double,
        to: Double,
        _ t: TimeInterval,
        _ spring: Spring,
        velocity: Double = 0
    ) -> Double {
        guard t > 0 else { return from }
        return from + spring.value(target: to - from, initialVelocity: velocity, time: t)
    }

    /// A toast's own clock, which can't jump.
    ///
    /// Toasts tend to fire exactly when the main thread is busy: right after
    /// launch, as a save lands. On the wall clock, a 600ms hitch skips 600ms
    /// of the drip, and the first thing on screen is the finished card. This
    /// clock advances by at most one short step per frame, so a hitch pauses
    /// the animation where it was instead.
    ///
    /// A reference type ticked from inside `TimelineView`'s body. It isn't
    /// observed, so ticking it doesn't invalidate anything.
    final class Clock {
        private var toastID: UUID?
        private var lastFrame: Date?
        private(set) var elapsed: TimeInterval = 0
        private(set) var exitStart: TimeInterval?

        func tick(_ date: Date, toast: UUID, isExiting: Bool) -> ToastMotion {
            if toastID != toast {
                toastID = toast
                lastFrame = nil
                elapsed = 0
                exitStart = nil
            }
            if let lastFrame {
                elapsed += min(max(date.timeIntervalSince(lastFrame), 0), 1.0 / 20) * ToastMotion.speed
            }
            lastFrame = date
            if isExiting, exitStart == nil { exitStart = elapsed }
            return ToastMotion.at(elapsed: elapsed, exitStart: isExiting ? exitStart : nil)
        }
    }

    /// A finger dragging the card. Tracked by hand for the same reason as
    /// the channels above: the offset feeds the `Canvas` geometry too.
    struct Drag {
        private(set) var translation: Double = 0
        private var releasedAt: Date?

        /// Follows the finger up freely, resists being pulled down.
        mutating func track(_ dy: Double) {
            releasedAt = nil
            translation = dy < 0 ? max(dy, -120) : 24 * (1 - exp(-dy / 60))
        }

        /// Springs back from wherever it was let go.
        mutating func release(at date: Date) {
            releasedAt = date
        }

        func offset(at now: Date) -> Double {
            guard let releasedAt else { return translation }
            return ToastMotion.settle(translation, to: 0, now.timeIntervalSince(releasedAt), Springs.drag)
        }
    }

    enum Springs {
        static let drop = Spring(settlingDuration: 1.15, dampingRatio: 0.82)
        static let expand = Spring(settlingDuration: 1.0, dampingRatio: 0.8)
        static let reveal = Spring(settlingDuration: 0.7, dampingRatio: 1)
        static let collapse = Spring(settlingDuration: 0.66, dampingRatio: 0.92)
        static let returning = Spring(settlingDuration: 1.15, dampingRatio: 0.9)
        static let fade = Spring(settlingDuration: 0.36, dampingRatio: 1)
        static let slideIn = Spring(settlingDuration: 0.6, dampingRatio: 0.82)
        static let slideOut = Spring(settlingDuration: 0.5, dampingRatio: 1)
        /// A card let go without being flicked away, settling back.
        static let drag = Spring(settlingDuration: 0.56, dampingRatio: 0.7)
    }
}
