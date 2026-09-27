//
//  WeatherCondition.swift
//  Equitrip
//

import SwiftUI

/// What the sky is doing, in the handful of families the screens draw.
///
/// WMO codes come in dozens of shades ("slight rain showers", "moderate
/// drizzle"); the twin cares about a few distinctions that change what
/// happens to a booking, and the sky animation needs one scene per family —
/// so the code is folded once, here, and everything else reads the family.
enum WeatherCondition: String, Codable, Hashable, CaseIterable {
    case clear, partlyCloudy, cloudy, fog, drizzle, rain, heavyRain, thunderstorm, snow, heat

    /// From a WMO weather code, lifted by what was actually measured — a
    /// station reporting 20 mm/h is heavy rain whatever the model's code says.
    init(code: Int?, rainRate: Double = 0, temperature: Double? = nil) {
        let base: WeatherCondition = switch code ?? 0 {
        case 0: .clear
        case 1, 2: .partlyCloudy
        case 3: .cloudy
        case 45, 48: .fog
        case 51, 53, 55, 56, 57: .drizzle
        case 61, 63, 80, 81, 66: .rain
        case 65, 67, 82: .heavyRain
        case 71, 73, 75, 77, 85, 86: .snow
        case 95, 96, 99: .thunderstorm
        default: .cloudy
        }

        if rainRate >= 7.6, base != .thunderstorm {
            self = .heavyRain
        } else if rainRate >= 0.5, [.clear, .partlyCloudy, .cloudy, .fog, .drizzle].contains(base) {
            self = rainRate >= 2.5 ? .rain : .drizzle
        } else if let temperature, temperature >= 38, [.clear, .partlyCloudy].contains(base) {
            self = .heat
        } else {
            self = base
        }
    }

    var label: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly cloudy"
        case .cloudy: "Overcast"
        case .fog: "Fog"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy rain"
        case .thunderstorm: "Thunderstorm"
        case .snow: "Snow"
        case .heat: "Extreme heat"
        }
    }

    func symbol(isDay: Bool = true) -> String {
        switch self {
        case .clear: isDay ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .snow: "cloud.snow.fill"
        case .heat: "sun.max.trianglebadge.exclamationmark.fill"
        }
    }

    /// Whether anything is falling — what the sky animation draws streaks for.
    var isWet: Bool { [.drizzle, .rain, .heavyRain, .thunderstorm].contains(self) }

    /// The two ends of the sky gradient behind the conditions hero.
    ///
    /// Light, like the rest of the app: a storm is a slate sky rather than a
    /// black one, so dark ink stays legible on every scene without a scrim.
    func sky(isDay: Bool) -> (top: Color, bottom: Color) {
        guard isDay else {
            return (Color(red: 0.36, green: 0.40, blue: 0.62), Color(red: 0.62, green: 0.63, blue: 0.80))
        }
        switch self {
        case .clear: return (Color(red: 0.49, green: 0.74, blue: 0.98), Color(red: 0.86, green: 0.93, blue: 1.0))
        case .partlyCloudy: return (Color(red: 0.58, green: 0.77, blue: 0.95), Color(red: 0.90, green: 0.94, blue: 0.99))
        case .cloudy, .fog: return (Color(red: 0.72, green: 0.77, blue: 0.84), Color(red: 0.92, green: 0.93, blue: 0.95))
        case .drizzle, .rain: return (Color(red: 0.55, green: 0.64, blue: 0.76), Color(red: 0.84, green: 0.88, blue: 0.93))
        case .heavyRain: return (Color(red: 0.44, green: 0.52, blue: 0.65), Color(red: 0.77, green: 0.82, blue: 0.89))
        case .thunderstorm: return (Color(red: 0.39, green: 0.42, blue: 0.58), Color(red: 0.74, green: 0.76, blue: 0.87))
        case .snow: return (Color(red: 0.80, green: 0.86, blue: 0.93), Color(red: 0.96, green: 0.97, blue: 0.99))
        case .heat: return (Color(red: 0.99, green: 0.67, blue: 0.40), Color(red: 1.0, green: 0.90, blue: 0.76))
        }
    }

    /// Ink that reads on `sky`: white on the darker scenes, app ink on the pale ones.
    func ink(isDay: Bool) -> Color {
        guard isDay else { return .white }
        switch self {
        case .heavyRain, .thunderstorm, .rain, .drizzle: return .white
        default: return AppTheme.ink
        }
    }
}
