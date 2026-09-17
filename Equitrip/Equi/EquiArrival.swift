//
//  EquiArrival.swift
//  Equitrip
//

import CoreHaptics
import SwiftUI
import UIKit

// MARK: - Timing

/// One clock for the arrival, so the light and the feel can't be tuned apart
/// from each other — the same reason `SettleTiming` exists.
///
/// Deliberately short. This plays every single time the tab is opened, not
/// once at launch, and anything that reads as a *sequence* rather than a
/// single gesture becomes something to sit through by the fifth visit.
enum EquiArrivalTiming {
    /// How long the gleam takes to cross the screen.
    static let sweep: Double = 0.62
    /// When it passes the middle — where the glint peaks and the tick lands.
    static var crest: Double { sweep * 0.5 }
}

// MARK: - Shine

/// A specular band that crosses the screen once when the tab opens.
///
/// Light moving over glass, rather than a flash: the band is soft-edged,
/// blurred and additive, so it brightens what's underneath instead of covering
/// it. Both parameters are driven from outside — the view has no animation of
/// its own — because the same beat also has to move the aurora, the orb and
/// the haptics, and one caller sequencing all of them keeps them in step.
struct EquiShine: View {
    @Environment(\.colorScheme) private var scheme

    /// 0 = off the leading edge, 1 = off the trailing edge.
    var travel: Double
    /// Fades the gleam in and back out across the sweep.
    var glow: Double

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.3), location: 0.4),
                            .init(color: .white.opacity(0.75), location: 0.5),
                            .init(color: .white.opacity(0.3), location: 0.6),
                            .init(color: .white.opacity(0), location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width * 0.45)
                // Tilted and over-tall so the band still covers the corners it
                // sweeps past, rather than clipping into a parallelogram.
                .scaleEffect(y: 1.9)
                .rotationEffect(.degrees(16))
                .blur(radius: 12)
                .offset(x: -width * 0.9 + travel * width * 1.8)
                .blendMode(.plusLighter)
                // Additive white blows out fast on the light canvas and needs
                // the help on the dark one.
                .opacity(glow * (scheme == .dark ? 0.85 : 0.5))
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Haptics

/// What opening Equi feels like: a soft swell as the light crosses, and one
/// light tick as it lands.
///
/// A single Core Haptics pattern rather than two scheduled taps, for the
/// reason `SettleHaptics` spells out — over a beat this short, the few
/// milliseconds a `Task.sleep` overshoots by are felt as a stumble. Kept
/// quieter than anything else in the app: this fires on every visit to the
/// tab, so it has to stay under the threshold where it would start asking for
/// attention.
@MainActor
enum EquiArrivalHaptics {
    private static var engine: CHHapticEngine?

    private static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    static func arrive() {
        guard isSupported, let engine = try? running() else {
            arriveFallback()
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.17),
                    .init(parameterID: .hapticSharpness, value: 0.25)
                ],
                relativeTime: 0,
                duration: EquiArrivalTiming.crest
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: 0.42),
                    .init(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: EquiArrivalTiming.crest
            )
        ]

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            try engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
        } catch {
            arriveFallback()
        }
    }

    /// Warms the engine, so the first visit of a session feels like the rest —
    /// starting one costs tens of milliseconds, which is most of the sweep.
    static func prepare() {
        guard isSupported else { return }
        _ = try? running()
    }

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

    /// Whatever a device without Core Haptics can manage.
    private static func arriveFallback() {
        let soft = UIImpactFeedbackGenerator(style: .soft)
        soft.prepare()
        soft.impactOccurred(intensity: 0.4)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(EquiArrivalTiming.crest))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.45)
        }
    }
}
