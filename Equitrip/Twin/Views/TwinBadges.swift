//
//  TwinBadges.swift
//  Equitrip
//

import SwiftUI

// MARK: - Source badge

/// Who measured or modelled a number: "Weather Union · live" in Zomato red
/// when a station is speaking, "Open-Meteo" when it's the model.
struct SourceBadge: View {
    let source: WeatherSource
    var isLive: Bool = false
    /// On a coloured sky rather than a white card.
    var onSky: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            if isLive {
                LiveDot(tint: onSky ? .white : source.tint)
            } else {
                Image(systemName: source.symbol)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(source.label)
                .font(.system(size: 11, weight: .semibold))
            if isLive {
                Text("LIVE")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(0.6)
                    .opacity(0.8)
            }
        }
        .foregroundStyle(onSky ? .white : source.tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            Capsule().fill(onSky ? AnyShapeStyle(.white.opacity(0.22)) : AnyShapeStyle(source.tint.opacity(0.12)))
        }
        .overlay {
            if onSky { Capsule().strokeBorder(.white.opacity(0.3)) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isLive ? "\(source.label), live station reading" : source.label)
    }
}

/// A dot that breathes, for things that are live.
struct LiveDot: View {
    var tint: Color = AppTheme.positive
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(tint)
            .frame(width: 6, height: 6)
            .background {
                Circle()
                    .fill(tint.opacity(0.35))
                    .scaleEffect(on ? 2.4 : 1)
                    .opacity(on ? 0 : 1)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { on = true }
            }
    }
}

// MARK: - Risk pill

/// "42% · Warning" in the risk's own colour.
struct RiskPill: View {
    let risk: RiskLevel
    var probability: Double?
    var large = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: risk.symbol)
                .font(.system(size: large ? 11 : 9, weight: .bold))
            if let probability {
                Text("\(Int((probability * 100).rounded()))%")
                    .font(.system(size: large ? 13 : 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: probability))
            }
            Text(risk.short)
                .font(.system(size: large ? 12 : 10.5, weight: .semibold))
        }
        .foregroundStyle(risk.tint)
        .padding(.horizontal, large ? 10 : 8)
        .padding(.vertical, large ? 6 : 4)
        .background(risk.tint.opacity(0.13), in: .capsule)
        .animation(.snappy, value: probability)
    }
}

// MARK: - Uncertainty bar

/// A probability with its spread: the band is P10–P90 across plausible
/// futures, the dot is the twin's answer. A wide band is the twin saying it
/// isn't sure, which is worth seeing.
struct UncertaintyBar: View {
    let probability: Double
    let spread: ClosedRange<Double>
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.cardStroke.opacity(0.07))

                // Threshold ticks at the risk bands.
                ForEach([0.15, 0.35, 0.6], id: \.self) { mark in
                    Rectangle()
                        .fill(AppTheme.cardStroke.opacity(0.12))
                        .frame(width: 1, height: 10)
                        .offset(x: w * mark)
                }

                Capsule()
                    .fill(tint.opacity(0.22))
                    .frame(width: max(8, w * (spread.upperBound - spread.lowerBound)))
                    .offset(x: w * spread.lowerBound)

                Capsule()
                    .fill(tint)
                    .frame(width: max(4, w * probability))

                Circle()
                    .fill(.white)
                    .frame(width: 10, height: 10)
                    .overlay { Circle().strokeBorder(tint, lineWidth: 2.5) }
                    .offset(x: max(0, min(w - 10, w * probability - 5)))
            }
        }
        .frame(height: 10)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: probability)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: spread)
        .accessibilityElement()
        .accessibilityLabel("\(Int(probability * 100)) percent, likely between \(Int(spread.lowerBound * 100)) and \(Int(spread.upperBound * 100))")
    }
}

// MARK: - Weather glyph

/// A condition's symbol coloured for a white card.
///
/// Multicolor symbols are drawn for dark skies: their clouds are white, so
/// on a card a rainy day showed three blue dashes and nothing else. Each
/// layer gets a colour that reads on white instead — grey cloud, amber sun,
/// blue rain.
struct WeatherGlyph: View {
    let condition: WeatherCondition
    var isDay = true
    var size: CGFloat = 17

    var body: some View {
        let cloud = AppTheme.inkTertiary.opacity(0.75)
        let sun = isDay ? Palette.amber : Palette.indigo
        let (primary, secondary, tertiary): (Color, Color, Color) = switch condition {
        case .clear: (sun, sun, sun)
        case .partlyCloudy: (cloud, sun, sun)
        case .cloudy, .fog: (cloud, cloud, cloud)
        case .drizzle, .rain, .heavyRain: (cloud, Palette.blue, Palette.blue)
        case .thunderstorm: (cloud, Palette.amber, Palette.blue)
        case .snow: (cloud, Palette.teal, Palette.teal)
        case .heat: (Palette.amberDeep, Palette.amberDeep, Palette.amberDeep)
        }
        Image(systemName: condition.symbol(isDay: isDay))
            .font(.system(size: size))
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary, tertiary)
            .accessibilityLabel(condition.label)
    }
}

// MARK: - Formatting

enum TwinFormat {
    static func percent(_ p: Double) -> String { "\(Int((p * 100).rounded()))%" }

    static func rain(_ mm: Double) -> String {
        mm < 0.1 ? "0" : mm < 10 ? String(format: "%.1f", mm) : String(format: "%.0f", mm)
    }

    static func temperature(_ c: Double?) -> String {
        c.map { "\(Int($0.rounded()))°" } ?? "–"
    }

    /// How rain feels at a rate, in the words weather services use.
    static func rainWord(_ mm: Double) -> String {
        switch mm {
        case ..<0.1: "Dry"
        case ..<2.5: "Light"
        case ..<7.6: "Moderate"
        case ..<25: "Heavy"
        case ..<50: "Very heavy"
        default: "Extreme"
        }
    }

    static func ago(_ date: Date?) -> String {
        guard let date else { return "not yet" }
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        return "\(minutes / 60) h ago"
    }

    static func compass(_ degrees: Double?) -> String {
        guard let degrees else { return "" }
        let points = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return points[Int((degrees / 45).rounded()) % 8]
    }
}
