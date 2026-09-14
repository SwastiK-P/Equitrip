//
//  SettleHaptics.swift
//  Equitrip
//

import CoreHaptics
import UIKit

/// What organising the pile feels like.
///
/// Three beats, matching what's on screen: a hum that tightens as the receipts
/// sweep in, one firm knock on the frame the card lands, then a light tick per
/// payment as the rows arrive. Built as a single Core Haptics pattern for the
/// same reason `BurstHaptics` is — four `Task.sleep`s raced against the
/// animation clock drift by tens of milliseconds, and over a beat this short
/// the drift is felt as a stumble rather than heard as a delay.
///
/// Timings come from `SettleTiming`, so the feel and the animation can't be
/// tuned apart from each other.
@MainActor
enum SettleHaptics {
    private static var engine: CHHapticEngine?

    private static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Beats

    /// The collapse. `payments` is how many rows land, so the ticks run out
    /// when the card does.
    static func gather(payments: Int) {
        guard isSupported, let engine = try? running() else {
            gatherFallback(payments: payments)
            return
        }

        var events: [CHHapticEvent] = [
            // The sweep: quiet and blunt at first, then tightening as the
            // receipts converge. Two overlapping continuous events rather than
            // one with a curve — the second is what makes it read as being
            // drawn together instead of a flat buzz.
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.2),
                    .init(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: SettleTiming.cardDelay
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.4),
                    .init(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: SettleTiming.cardDelay * 0.55,
                duration: SettleTiming.cardDelay * 0.45
            ),

            // The card arriving. The one event on the whole screen that gets
            // to be loud.
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.95),
                    .init(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: SettleTiming.cardDelay
            )
        ]

        // One tick per payment, softening as they go — the rows are a
        // consequence of the knock, not three more events of their own.
        for row in 0..<Swift.max(0, payments) {
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: Float(0.34 - Double(row) * 0.06)),
                        .init(parameterID: .hapticSharpness, value: 0.45)
                    ],
                    relativeTime: SettleTiming.rowDelay + Double(row + 1) * SettleTiming.rowStep
                )
            )
        }

        play(events, on: engine) { gatherFallback(payments: payments) }
    }

    /// The deal: one light tick per receipt as it lands.
    ///
    /// Sent as a single pattern rather than a tap per loop iteration, because
    /// the loop dealing the receipts sleeps its way through nine steps and the
    /// few milliseconds each `Task.sleep` overshoots by accumulate — by the
    /// last receipt the taps are audibly behind the cards. A pattern is
    /// scheduled once against the haptic clock and stays under them.
    ///
    /// Uniform, and softer than anything else on the page: nine identical
    /// events are nine identical facts, and a rising sequence would imply the
    /// last receipt mattered most.
    static func deal(count: Int, step: Double) {
        guard count > 0 else { return }

        guard isSupported, let engine = try? running() else {
            dealFallback(count: count, step: step)
            return
        }

        let events = (0..<count).map { index in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.42),
                    .init(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: Double(index) * step
            )
        }

        play(events, on: engine) { dealFallback(count: count, step: step) }
    }

    /// Warms the engine up, so the first tap of a session feels like the rest.
    /// Starting one costs tens of milliseconds — most of the sweep.
    static func prepare() {
        guard isSupported else { return }
        _ = try? running()
    }

    // MARK: - Engine

    private static func play(
        _ events: [CHHapticEvent],
        on engine: CHHapticEngine,
        else fallback: () -> Void
    ) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            // A haptic that won't play is no reason to skip the animation, and
            // this covers the engine simply being unavailable right now — a
            // call in progress, or Low Power Mode.
            fallback()
        }
    }

    /// One engine, started lazily and kept.
    private static func running() throws -> CHHapticEngine {
        if let engine { return engine }

        let created = try CHHapticEngine()
        created.isAutoShutdownEnabled = true
        created.resetHandler = { try? created.start() }
        created.stoppedHandler = { _ in }
        try created.start()

        engine = created
        return created
    }

    // MARK: - Fallback

    /// Whatever a device without Core Haptics can manage: the knock and the
    /// ticks, minus the hum. Scheduled rather than patterned, which is exactly
    /// the drift the real path exists to avoid — but a slightly late tap beats
    /// a silent one on hardware that can only vibrate.
    private static func dealFallback(count: Int, step: Double) {
        let tick = UIImpactFeedbackGenerator(style: .light)
        tick.prepare()

        Task { @MainActor in
            for _ in 0..<count {
                tick.impactOccurred(intensity: 0.42)
                try? await Task.sleep(for: .seconds(step))
            }
        }
    }

    private static func gatherFallback(payments: Int) {
        let soft = UIImpactFeedbackGenerator(style: .soft)
        soft.prepare()

        Task { @MainActor in
            soft.impactOccurred(intensity: 0.35)

            try? await Task.sleep(for: .seconds(SettleTiming.cardDelay))
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)

            try? await Task.sleep(for: .seconds(SettleTiming.rowDelay - SettleTiming.cardDelay))
            for row in 0..<Swift.max(0, payments) {
                try? await Task.sleep(for: .seconds(SettleTiming.rowStep))
                soft.impactOccurred(intensity: 0.34 - Double(row) * 0.06)
            }
        }
    }
}
