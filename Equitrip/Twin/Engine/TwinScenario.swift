//
//  TwinScenario.swift
//  Equitrip
//

import Foundation

/// A what-if: weather that isn't forecast, laid over weather that is.
///
/// Every field is an override, and an empty scenario is the live twin — the
/// simulator runs the same code either way, which is what makes "live" and
/// "what-if" comparable figure for figure. Nothing here ever reaches the
/// trip itself: a scenario only changes what the simulator is told the sky
/// is doing.
struct TwinScenario: Hashable {

    /// Starting points people reach for. Each one only fills the sliders —
    /// every value stays adjustable afterwards.
    enum Preset: String, CaseIterable, Identifiable, Hashable {
        case live, monsoonBurst, thunderstorm, cyclone, flashFlood, heatwave

        var id: String { rawValue }

        var label: String {
            switch self {
            case .live: "Live forecast"
            case .monsoonBurst: "Monsoon burst"
            case .thunderstorm: "Thunderstorm"
            case .cyclone: "Cyclone"
            case .flashFlood: "Flash flood"
            case .heatwave: "Heatwave"
            }
        }

        var symbol: String {
            switch self {
            case .live: "dot.radiowaves.left.and.right"
            case .monsoonBurst: "cloud.heavyrain.fill"
            case .thunderstorm: "cloud.bolt.rain.fill"
            case .cyclone: "hurricane"
            case .flashFlood: "water.waves"
            case .heatwave: "thermometer.sun.fill"
            }
        }

        var blurb: String {
            switch self {
            case .live: "What the forecast and the ground say now"
            case .monsoonBurst: "35 mm/h for six hours, streets filling"
            case .thunderstorm: "Two hours of lightning and 75 km/h gusts"
            case .cyclone: "A landfalling system: 110 km/h, a day of rain"
            case .flashFlood: "A cloudburst: 80 mm/h, rivers over their banks"
            case .heatwave: "45 °C through the afternoon"
            }
        }

        var scenario: TwinScenario {
            var s = TwinScenario()
            s.preset = self
            switch self {
            case .live:
                return TwinScenario()
            case .monsoonBurst:
                s.rainIntensity = 35; s.durationHours = 6; s.gusts = 45; s.flooding = 0.35; s.startHour = 14
            case .thunderstorm:
                s.rainIntensity = 25; s.durationHours = 2; s.gusts = 75; s.thunder = true; s.startHour = 16
            case .cyclone:
                s.rainIntensity = 55; s.durationHours = 18; s.gusts = 110; s.flooding = 0.8; s.thunder = true; s.startHour = 6
            case .flashFlood:
                s.rainIntensity = 80; s.durationHours = 3; s.flooding = 1; s.startHour = 15
            case .heatwave:
                s.temperature = 45; s.durationHours = 8; s.startHour = 11
            }
            return s
        }
    }

    var preset: Preset?
    /// Peak rain, mm/h.
    var rainIntensity: Double?
    /// How long the event lasts, from `startHour` on `targetDay`.
    var durationHours: Double = 6
    /// Local hour the event begins.
    var startHour: Int = 14
    /// Afternoon high, °C.
    var temperature: Double?
    /// km/h.
    var gusts: Double?
    /// 0–1: how far rivers and drains are over capacity.
    var flooding: Double = 0
    /// Lightning in the area — grounds flights and clears beaches.
    var thunder: Bool = false
    /// The day it happens. Nil means every day of the trip.
    var targetDay: Date?
    /// Where it's centred. Nil means everywhere on the trip at once.
    var center: GeoPoint?
    var radiusKm: Double = 25

    var isLive: Bool {
        rainIntensity == nil && temperature == nil && gusts == nil && flooding == 0 && !thunder
    }

    /// The scenario in one sentence, from its values — a preset's blurb stops
    /// being true the moment a dial moves.
    var summary: String {
        guard !isLive else { return "The forecast as it is. Raise any dial below to add weather to it." }
        let formatter = DateFormatter.cached("h a")
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(Double(startHour) * 3600)
        var parts: [String] = []
        if let rainIntensity { parts.append("\(Int(rainIntensity)) mm/h rain") }
        if let temperature { parts.append("\(Int(temperature))°C heat") }
        if let gusts { parts.append("gusts to \(Int(gusts)) km/h") }
        if thunder { parts.append("lightning") }
        if flooding >= 0.05 { parts.append(flooding >= 0.7 ? "rivers over their banks" : flooding >= 0.35 ? "streets flooded" : "drains overflowing") }
        let hours = Int(durationHours) == 1 ? "1 hour" : "\(Int(durationHours)) hours"
        return "\(hours) from \(formatter.string(from: start)): \(parts.joined(separator: ", "))."
    }

    /// When the event is happening on a given day.
    func eventWindow(on day: Date) -> DateInterval? {
        let calendar = Calendar.current
        if let targetDay, !calendar.isDate(targetDay, inSameDayAs: day) { return nil }
        let start = calendar.startOfDay(for: day).addingTimeInterval(Double(startHour) * 3600)
        return DateInterval(start: start, duration: max(1, durationHours) * 3600)
    }

    /// 0–1: how much of the event reaches `point`. Full strength inside 60%
    /// of the radius, gone by 160%.
    func reach(at point: GeoPoint) -> Double {
        guard let center else { return 1 }
        let d = center.distance(to: point) / max(radiusKm, 1)
        if d <= 0.6 { return 1 }
        if d >= 1.6 { return 0 }
        let t = (d - 0.6) / 1.0
        return 1 - t * t * (3 - 2 * t)
    }

    /// What the event does to one booking, worked out once: how strongly
    /// it reaches the place and how its hours line up with the booking's.
    /// Everything here is calendar arithmetic that doesn't change between
    /// simulation runs, so the simulator asks once per booking rather than
    /// once per booking per run.
    struct Overlay {
        let strength: Double
        let overlapSeconds: Double
        let soakedBeforeHours: Double
    }

    func overlay(window: DateInterval, at point: GeoPoint) -> Overlay? {
        guard !isLive else { return nil }
        let strength = reach(at: point)
        guard strength > 0 else { return nil }

        // The event can start the day before a morning booking and still be
        // going; check both days.
        let calendar = Calendar.current
        let days = [calendar.date(byAdding: .day, value: -1, to: window.start)!, window.start]
        let events = days.compactMap(eventWindow(on:))
        guard let event = events.first(where: { $0.intersects(window) || ($0.end <= window.start && window.start.timeIntervalSince($0.end) < 12 * 3600) })
        else { return nil }

        // Rain that fell before the booking still floods the road to it.
        let before = min(event.end, window.start).timeIntervalSince(event.start)
        return Overlay(
            strength: strength,
            overlapSeconds: event.intersection(with: window)?.duration ?? 0,
            soakedBeforeHours: max(0, before / 3600)
        )
    }

    /// Lays the event over one booking's weather.
    func apply(_ overlay: Overlay?, to features: WeatherFeatures) -> WeatherFeatures {
        guard let overlay else { return features }
        let strength = overlay.strength
        let overlapHours = overlay.overlapSeconds
        let soakedBefore = overlay.soakedBeforeHours
        let during = overlapHours > 0
        var f = features

        if let rain = rainIntensity {
            if during { f.rainRate = max(f.rainRate, rain * strength) }
            f.rainTotal += rain * strength * 0.75 * (overlapHours / 3600 + soakedBefore)
        }
        if let gusts, during {
            f.gusts = max(f.gusts, gusts * strength)
        }
        if let temperature, during {
            let apparent = temperature + 3
            f.apparentTemperature = f.apparentTemperature + (max(apparent, f.apparentTemperature) - f.apparentTemperature) * strength
            f.temperature = f.temperature + (max(temperature, f.temperature) - f.temperature) * strength
        }
        if flooding > 0 {
            f.flood = max(f.flood, flooding * strength)
        }
        if thunder, during, strength > 0.5 {
            f.thunder = true
        }
        return f
    }
}
