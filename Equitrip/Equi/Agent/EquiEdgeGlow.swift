//
//  EquiEdgeGlow.swift
//  Equitrip
//

import SwiftUI

/// Light running round the edge of the screen while Equi has the controls —
/// the signal, readable at a glance and from across a table, that the phone is
/// being driven and not frozen.
///
/// It comes out of the Dynamic Island and wraps both ways down the sides to
/// meet at the bottom (`reach`), and draws back in the same way when the job
/// is done, so the one place Equi lives outside the app is where the light
/// starts and ends. Half of each stroke sits past the screen's edge, which is
/// what makes it read as light spilling in from the bezel rather than a
/// border drawn on top.
///
/// Purple throughout — Equi's colour, the tab bar's accent — with the mood in
/// the shade and the pace: indigo-violet and brisk while working, orchid and
/// slowly breathing while it waits on you, lavender and bright as it
/// finishes. Only a failure leaves the family. Changes cross-fade over a fixed time
/// computed per frame — the gradient lives inside a `TimelineView`, where an
/// ordinary animation would never get to interpolate it.
struct EquiEdgeGlow: View {
    var reach: Double
    var mood: EquiAgent.Mood
    /// Bumped on every press; each bump flares the light.
    var pressCount: Int
    var cornerRadius: CGFloat

    @State private var from = Tint.working
    @State private var to = Tint.working
    @State private var changedAt = Date.distantPast
    @State private var pressedAt = Date.distantPast

    private static let fade: Double = 0.7

    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date
            let t = now.timeIntervalSinceReferenceDate
            let blend = min(1, max(0, now.timeIntervalSince(changedAt) / Self.fade))
            let tint = from.mixed(with: to, by: blend)
            let flare = max(0, 1 - now.timeIntervalSince(pressedAt) / 0.55)
            let breath = 0.5 + 0.5 * sin(t * tint.breathRate)
            let spin = Angle.degrees((t * tint.spin).truncatingRemainder(dividingBy: 360))
            let gradient = AngularGradient(colors: tint.colors + [tint.colors[0]], center: .center, angle: spin)
            let edge = EdgeTrace(reach: reach, cornerRadius: cornerRadius)

            ZStack {
                edge
                    .stroke(gradient, style: StrokeStyle(lineWidth: 46, lineCap: .round))
                    .blur(radius: 38)
                    .opacity(0.34 + 0.22 * breath + 0.3 * flare)

                edge
                    .stroke(gradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .blur(radius: 11)
                    .opacity(0.72 + 0.28 * flare)

                edge
                    .stroke(gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .blur(radius: 1.6)

                // A comet each way round, only once the ring is closed.
                if reach > 0.98 {
                    let lap = (t * 0.22).truncatingRemainder(dividingBy: 1)
                    Comet(position: lap, cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .blur(radius: 2.5)
                    Comet(position: 1 - lap, cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .blur(radius: 2.5)
                }
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: mood) { _, mood in
            let now = Date()
            let blend = min(1, max(0, now.timeIntervalSince(changedAt) / Self.fade))
            from = from.mixed(with: to, by: blend)
            to = Tint.for(mood)
            changedAt = now
        }
        .onChange(of: pressCount) { _, _ in pressedAt = Date() }
    }

    // MARK: - Tints

    /// The colours for one mood, and how fast they move.
    struct Tint {
        var colors: [Color]
        /// Degrees a second the gradient turns.
        var spin: Double
        /// How quickly the outer bloom breathes, in radians a second.
        var breathRate: Double

        /// The accent's indigo through violet to lavender.
        static let working = Tint(
            colors: [hex(0x4B45C6), hex(0x7C4DE0), hex(0xB06EF5), hex(0x9A93FF), hex(0x6A3FD9)],
            spin: 46, breathRate: 1.4
        )
        static let asking = Tint(
            colors: [hex(0xA24BE0), hex(0xD36EE8), hex(0x8B5CF6), hex(0xE08AF0), hex(0x7C4DE0)],
            spin: 16, breathRate: 2.6
        )
        static let done = Tint(
            colors: [hex(0x9A93FF), hex(0xC4B5FD), hex(0x7C4DE0), hex(0xE9D5FF), hex(0xA98BF5)],
            spin: 60, breathRate: 1.4
        )
        static let failed = Tint(
            colors: [hex(0xFF5A4F), hex(0xF59E6B), hex(0xE3609E), hex(0xFF5A4F), hex(0xF08A72)],
            spin: 20, breathRate: 1.2
        )
        static let stopped = Tint(
            colors: [hex(0x9C8B7F), hex(0x6B5B50), hex(0x9A93FF), hex(0x9C8B7F), hex(0xB0A49B)],
            spin: 20, breathRate: 1.0
        )

        static func `for`(_ mood: EquiAgent.Mood) -> Tint {
            switch mood {
            case .working: .working
            case .asking: .asking
            case .done: .done
            case .failed: .failed
            case .stopped: .stopped
            }
        }

        func mixed(with other: Tint, by amount: Double) -> Tint {
            guard amount > 0 else { return self }
            guard amount < 1 else { return other }
            return Tint(
                colors: zip(colors, other.colors).map { $0.mix(with: $1, by: amount) },
                spin: spin + (other.spin - spin) * amount,
                breathRate: breathRate + (other.breathRate - breathRate) * amount
            )
        }

        private static func hex(_ rgb: UInt32) -> Color {
            Color(
                red: Double((rgb >> 16) & 0xFF) / 255,
                green: Double((rgb >> 8) & 0xFF) / 255,
                blue: Double(rgb & 0xFF) / 255
            )
        }
    }
}

// MARK: - Shapes

/// The screen's outline, starting at the top centre — under the island — and
/// drawn as two arms that grow from there down both sides.
private struct EdgeTrace: Shape {
    var reach: Double
    var cornerRadius: CGFloat

    var animatableData: Double {
        get { reach }
        set { reach = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard reach > 0.001 else { return Path() }
        let outline = Self.outline(in: rect, radius: cornerRadius)
        guard reach < 0.999 else { return outline }
        var path = outline.trimmedPath(from: 0, to: reach / 2)
        path.addPath(outline.trimmedPath(from: 1 - reach / 2, to: 1))
        return path
    }

    static func outline(in rect: CGRect, radius r: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - r, y: rect.maxY), radius: r)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - r), radius: r)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
        path.closeSubpath()
        return path
    }
}

/// A short bright stretch of the outline, for the light travelling round it.
private struct Comet: Shape {
    var position: Double
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let outline = EdgeTrace.outline(in: rect, radius: cornerRadius)
        let length = 0.07
        let start = position
        let end = position + length
        if end <= 1 { return outline.trimmedPath(from: start, to: end) }
        var path = outline.trimmedPath(from: start, to: 1)
        path.addPath(outline.trimmedPath(from: 0, to: end - 1))
        return path
    }
}
