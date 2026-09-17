//
//  BurstHaptics.swift
//  Equitrip
//

import CoreHaptics
import UIKit

/// What the QR burst feels like.
///
/// Built as one Core Haptics pattern rather than a series of
/// `UIImpactFeedbackGenerator` taps, because the two halves of the animation
/// need different textures and the impact generator only has one: the code
/// gathering is a rising hum, the release is a single sharp knock, and the
/// particles are a scatter of light taps thinning out as they disperse. Played
/// as one pattern, those land on the exact frames they belong to — scheduling
/// eight `Task.sleep`s against the same clock does not, and the drift is
/// audible as a stutter against an animation this short.
///
/// Falls back to plain impacts wherever Core Haptics isn't available (older
/// hardware, iPad, the simulator), so the burst is never silent on a device
/// that can vibrate at all.
@MainActor
enum BurstHaptics {
    private static var engine: CHHapticEngine?

    private static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    /// Plays the whole burst. Durations come from the animation, so the two
    /// can't drift apart when the timing is tuned.
    static func play(form: Double, travel: Double, hold: Double, fly: Double) {
        guard isSupported else {
            fallback(form: form, travel: travel, hold: hold, fly: fly)
            return
        }

        do {
            let engine = try running()
            let pattern = try CHHapticPattern(
                events: events(form: form, travel: travel, hold: hold, fly: fly),
                parameters: []
            )
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            // A haptic that won't play is not a reason to skip the animation,
            // and the fallback covers the case where the engine is simply
            // unavailable right now (a call, Low Power Mode).
            fallback(form: form, travel: travel, hold: hold, fly: fly)
        }
    }

    // MARK: - Pattern

    private static func events(form: Double, travel: Double, hold: Double, fly: Double) -> [CHHapticEvent] {
        var events: [CHHapticEvent] = []
        let release = form + travel + hold

        // Landing: a soft tick as the code paints itself onto the thing you're
        // pointing at. Light and blunt — it's a recognition, not an event.
        events.append(
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.35),
                    .init(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0
            )
        )

        // Gathering: a continuous hum that tightens as the code lifts and
        // straightens. Sharpness climbs with it, so it reads as something
        // being drawn together rather than a flat buzz.
        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.22),
                    .init(parameterID: .hapticSharpness, value: 0.25)
                ],
                relativeTime: form,
                duration: travel
            )
        )

        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.45),
                    .init(parameterID: .hapticSharpness, value: 0.55)
                ],
                relativeTime: form + travel * 0.55,
                duration: travel * 0.45 + hold
            )
        )

        // The release: one sharp knock on the frame the code lets go.
        events.append(
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.9),
                    .init(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: release
            )
        )

        // The particles. Front-loaded and thinning, matching the way the
        // squares thin out as they spread — the taps are the modules going
        // past, so they have to run out when the modules do.
        let taps = 7
        for index in 0..<taps {
            let fraction = Double(index) / Double(taps - 1)
            events.append(
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        .init(parameterID: .hapticIntensity, value: Float(0.55 * (1 - fraction * 0.75))),
                        .init(parameterID: .hapticSharpness, value: Float(0.4 + fraction * 0.3))
                    ],
                    // Squared, so they're dense at the release and sparse by
                    // the end rather than evenly spaced.
                    relativeTime: release + fly * pow(fraction, 1.7) * 0.85
                )
            )
        }

        // The whiteout: the screen filling, felt.
        events.append(
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 1),
                    .init(parameterID: .hapticSharpness, value: 0.45)
                ],
                relativeTime: release + fly * 0.94
            )
        )

        return events
    }

    // MARK: - Engine

    /// One engine, started lazily and kept. Starting it costs tens of
    /// milliseconds, which is most of the gather beat — long enough for the
    /// first hum to be missed entirely if it were built per scan.
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

    /// Warms the engine up so the first scan of a session feels like the rest.
    /// Called when the scanner opens.
    static func prepare() {
        guard isSupported else { return }
        _ = try? running()
    }

    // MARK: - Fallback

    private static func fallback(form: Double, travel: Double, hold: Double, fly: Double) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()

        Task { @MainActor in
            generator.impactOccurred(intensity: 0.4)

            try? await Task.sleep(for: .seconds(form + travel + hold))
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)

            for index in 0..<4 {
                try? await Task.sleep(for: .seconds(fly * 0.18))
                generator.impactOccurred(intensity: 0.5 - Double(index) * 0.1)
            }
        }
    }
}
