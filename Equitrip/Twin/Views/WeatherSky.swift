//
//  WeatherSky.swift
//  Equitrip
//

import SwiftUI

/// The sky the weather is, drawn live behind the conditions: sun glow on a
/// clear day, drifting cloud, rain whose density follows the measured mm/h,
/// lightning that actually flashes, a heat shimmer.
///
/// It's the one decorative thing on the twin, and it earns its place by being
/// information — you can read "heavy rain" off it before you've read a
/// number. Everything is drawn in one `Canvas` from index-seeded positions,
/// so there's no particle state to keep and nothing allocates per frame.
/// Reduce Motion stops the clock and leaves a still of the same sky.
struct WeatherSky: View {
    let condition: WeatherCondition
    var isDay: Bool = true
    /// Rain rate in mm/h, which sets how many drops fall.
    var rainRate: Double = 0
    /// Off where a weather symbol sits on top and already has its own sun —
    /// a small tile showed two.
    var drawsSun: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let sky = condition.sky(isDay: isDay)

        ZStack {
            LinearGradient(colors: [sky.top, sky.bottom], startPoint: .top, endPoint: .bottom)

            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Canvas { gc, size in
                    if drawsSun { drawSun(&gc, size, t) }
                    drawClouds(&gc, size, t)
                    drawFog(&gc, size, t)
                    drawPrecipitation(&gc, size, t)
                    drawHeat(&gc, size, t)
                    drawLightning(&gc, size, t)
                }
            }
        }
        .animation(.easeInOut(duration: 0.9), value: condition)
        .accessibilityHidden(true)
    }

    // MARK: - Layers

    private func drawSun(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        guard [.clear, .partlyCloudy, .heat].contains(condition) else { return }
        let hot = condition == .heat
        // Right of centre and below the top row, where a hero card keeps its
        // badge — so the glow sits behind open sky rather than under text.
        let centre = CGPoint(x: size.width * 0.86, y: size.height * (isDay ? 0.4 : 0.36))
        let pulse = 1 + 0.04 * sin(t * 0.7)
        let radius = size.width * (isDay ? (hot ? 0.13 : 0.09) : 0.045) * pulse
        let core: Color = isDay ? (hot ? Color(red: 1, green: 0.62, blue: 0.25) : Color(red: 1, green: 0.93, blue: 0.62)) : .white

        let glow = Path(ellipseIn: CGRect(x: centre.x - radius * 3, y: centre.y - radius * 3, width: radius * 6, height: radius * 6))
        gc.fill(glow, with: .radialGradient(
            Gradient(colors: [core.opacity(isDay ? 0.55 : 0.3), core.opacity(0)]),
            center: centre, startRadius: radius * 0.6, endRadius: radius * 3
        ))
        gc.fill(Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)),
                with: .color(core.opacity(isDay ? 0.95 : 0.9)))
    }

    private func drawClouds(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let count: Int
        let shade: Color
        switch condition {
        case .clear, .heat: return
        case .partlyCloudy: count = 3; shade = .white
        case .cloudy, .fog, .snow: count = 6; shade = .white
        case .drizzle, .rain: count = 6; shade = Color(white: 0.93)
        case .heavyRain: count = 7; shade = Color(white: 0.82)
        case .thunderstorm: count = 8; shade = Color(red: 0.62, green: 0.64, blue: 0.74)
        }

        for i in 0..<count {
            let width = size.width * (0.36 + 0.26 * noise(i, 1))
            let speed = 6 + 10 * noise(i, 2)
            let travel = size.width + width
            let x = (noise(i, 3) * travel + t * speed).truncatingRemainder(dividingBy: travel) - width
            // Kept faint: the sky sits behind white type, and a bright cloud
            // passing under a figure would wash it out.
            let y = size.height * (0.02 + 0.5 * noise(i, 4))
            let opacity = (isDay ? 0.26 : 0.16) + 0.14 * noise(i, 5)
            cloud(&gc, at: CGPoint(x: x, y: y), width: width, color: shade.opacity(opacity))
        }
    }

    private func cloud(_ gc: inout GraphicsContext, at origin: CGPoint, width: CGFloat, color: Color) {
        let h = width * 0.34
        var path = Path()
        path.addEllipse(in: CGRect(x: origin.x, y: origin.y + h * 0.35, width: width, height: h * 0.65))
        path.addEllipse(in: CGRect(x: origin.x + width * 0.14, y: origin.y + h * 0.05, width: width * 0.42, height: h * 0.8))
        path.addEllipse(in: CGRect(x: origin.x + width * 0.4, y: origin.y - h * 0.12, width: width * 0.44, height: h * 0.95))
        gc.fill(path, with: .color(color))
    }

    private func drawFog(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        guard condition == .fog else { return }
        gc.drawLayer { layer in
            layer.addFilter(.blur(radius: 16))
            for i in 0..<4 {
                let y = size.height * (0.35 + 0.16 * Double(i))
                let drift = sin(t * 0.15 + Double(i)) * 30
                layer.fill(Path(CGRect(x: -40 + drift, y: y, width: size.width + 80, height: 26)),
                           with: .color(.white.opacity(0.45)))
            }
        }
    }

    private func drawPrecipitation(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        if condition == .snow {
            for i in 0..<70 {
                let speed = 22 + 18 * noise(i, 6)
                let y = (noise(i, 7) * (size.height + 20) + t * speed).truncatingRemainder(dividingBy: size.height + 20) - 10
                let x = noise(i, 8) * size.width + sin(t * 0.8 + Double(i)) * 8
                let r = 1.5 + 2 * noise(i, 9)
                gc.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(0.85)))
            }
            return
        }
        guard condition.isWet else { return }

        let base: Double = switch condition {
        case .drizzle: 45
        case .rain: 95
        case .heavyRain: 170
        default: 190
        }
        let density = min(1.6, max(0.6, 0.6 + rainRate / 30))
        let count = Int(base * density)
        let slant = condition == .thunderstorm ? 0.24 : 0.14
        let heavy = condition == .heavyRain || condition == .thunderstorm

        var streaks = Path()
        for i in 0..<count {
            let speed = 420 + 260 * noise(i, 10)
            let length = (condition == .drizzle ? 7 : heavy ? 20 : 14) * (0.7 + 0.6 * noise(i, 11))
            let span = size.height + 40
            let y = (noise(i, 12) * span + t * speed).truncatingRemainder(dividingBy: span) - 20
            var x = noise(i, 13) * (size.width + 60) - 30 + y * slant
            x = x.truncatingRemainder(dividingBy: size.width + 30)
            streaks.move(to: CGPoint(x: x, y: y))
            streaks.addLine(to: CGPoint(x: x + length * slant, y: y + length))
        }
        gc.stroke(streaks, with: .color(.white.opacity(heavy ? 0.55 : 0.45)), lineWidth: heavy ? 1.4 : 1.1)
    }

    private func drawHeat(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        guard condition == .heat else { return }
        for band in 0..<5 {
            var wave = Path()
            let baseY = size.height * (0.62 + 0.08 * Double(band))
            wave.move(to: CGPoint(x: 0, y: baseY))
            for x in stride(from: 0.0, through: size.width, by: 6) {
                let y = baseY + sin(x / 22 + t * 2.2 + Double(band)) * 3
                wave.addLine(to: CGPoint(x: x, y: y))
            }
            gc.stroke(wave, with: .color(.white.opacity(0.18)), lineWidth: 2)
        }
    }

    private func drawLightning(_ gc: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        guard condition == .thunderstorm else { return }
        let phase = t.truncatingRemainder(dividingBy: 6.5)
        let flash: Double
        if phase < 0.09 { flash = 0.5 }
        else if phase > 0.18, phase < 0.26 { flash = 0.32 }
        else { return }

        gc.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash)))

        // A bolt, placed differently each strike.
        let strike = Int(t / 6.5)
        var x = size.width * (0.25 + 0.5 * noise(strike, 20))
        var y = size.height * 0.12
        var bolt = Path()
        bolt.move(to: CGPoint(x: x, y: y))
        for step in 0..<6 {
            x += (noise(strike * 7 + step, 21) - 0.5) * 36
            y += size.height * 0.1
            bolt.addLine(to: CGPoint(x: x, y: y))
        }
        gc.stroke(bolt, with: .color(.white.opacity(flash + 0.4)), lineWidth: 2.2)
    }

    /// Stable pseudo-random 0–1 per (index, salt).
    private func noise(_ i: Int, _ salt: Int) -> Double {
        let v = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43758.5453
        return v - floor(v)
    }
}
