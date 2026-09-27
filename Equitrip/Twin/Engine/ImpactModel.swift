//
//  ImpactModel.swift
//  Equitrip
//

import Foundation

/// The weather one booking will actually be in, boiled down to what matters.
struct WeatherFeatures: Hashable {
    /// Peak mm/h across the booking's window.
    var rainRate: Double = 0
    /// mm across the window and the twelve hours before it — what floods roads.
    var rainTotal: Double = 0
    /// km/h.
    var gusts: Double = 0
    var temperature: Double = 25
    var apparentTemperature: Double = 25
    /// 0–1, river discharge against normal.
    var flood: Double = 0
    var thunder = false
    var fog = false
    /// 0–1 from public reports (`SignalDigest.evidence`); negative when the
    /// ground says "all clear".
    var evidence: Double = 0
    var code: Int = 0

    var condition: WeatherCondition {
        WeatherCondition(code: thunder ? 95 : code, rainRate: rainRate, temperature: temperature)
    }
}

/// Why the model thinks what it thinks about one booking — each driver a
/// figure a person can check against the forecast.
struct ImpactDriver: Hashable, Identifiable {
    let symbol: String
    let label: String
    let value: String
    /// Share of the model's score this driver is responsible for.
    let weight: Double
    var id: String { label }
}

/// The chance weather disrupts a booking, given the weather it's in.
///
/// Deliberately small and readable: a logistic model per exposure over eight
/// saturating terms — rain rate, rain total, gusts, heat, flooding,
/// lightning, fog and ground reports — with hand-set weights that encode
/// what's broadly true (wind grounds boats before it grounds planes, standing
/// water stops cars before it stops trains). Every term is capped, so no one
/// extreme figure can drive the answer to certainty alone.
///
/// The weights are priors, not the last word: `TwinCalibration` pulls each
/// answer towards what has actually happened to bookings like this one in
/// weather like this, as those outcomes are observed and pooled.
enum ImpactModel {

    private struct Weights {
        let bias, rain, soak, gust, heat, flood, thunder, fog, evidence: Double
    }

    private static func weights(_ exposure: WeatherExposure) -> Weights {
        switch exposure {
        case .outdoor: Weights(bias: -3.2, rain: 1.6, soak: 0.8, gust: 1.0, heat: 1.5, flood: 1.0, thunder: 1.4, fog: 0.2, evidence: 1.6)
        case .marine: Weights(bias: -3.0, rain: 1.2, soak: 0.5, gust: 2.4, heat: 0.3, flood: 0.8, thunder: 2.0, fog: 0.6, evidence: 1.8)
        case .road: Weights(bias: -3.6, rain: 0.9, soak: 1.4, gust: 0.4, heat: 0.0, flood: 2.2, thunder: 0.6, fog: 0.6, evidence: 1.8)
        case .rail: Weights(bias: -4.0, rain: 0.6, soak: 1.0, gust: 0.3, heat: 0.1, flood: 2.4, thunder: 0.4, fog: 0.4, evidence: 1.6)
        case .air: Weights(bias: -3.8, rain: 0.6, soak: 0.2, gust: 1.6, heat: 0.1, flood: 0.4, thunder: 1.8, fog: 1.4, evidence: 1.6)
        case .shelter: Weights(bias: -5.5, rain: 0.3, soak: 0.6, gust: 0.6, heat: 0.0, flood: 2.2, thunder: 0.6, fog: 0.0, evidence: 0.8)
        case .indoor: Weights(bias: -5.0, rain: 0.3, soak: 0.5, gust: 0.3, heat: 0.0, flood: 1.2, thunder: 0.4, fog: 0.0, evidence: 1.0)
        }
    }

    /// Each term, normalised and capped.
    private static func terms(_ f: WeatherFeatures) -> (rain: Double, soak: Double, gust: Double, heat: Double, flood: Double, thunder: Double, fog: Double, evidence: Double) {
        (
            rain: min(f.rainRate / 10, 2.5),
            soak: min(f.rainTotal / 60, 2),
            gust: min(max(0, f.gusts - 30) / 40, 2.5),
            heat: min(max(0, f.apparentTemperature - 35) / 6, 2.5),
            flood: min(max(f.flood, 0), 1),
            thunder: f.thunder ? 1 : 0,
            fog: f.fog ? 1 : 0,
            evidence: min(max(f.evidence, -0.3), 1)
        )
    }

    /// The prior probability, before calibration.
    static func prior(_ exposure: WeatherExposure, _ f: WeatherFeatures) -> Double {
        let w = weights(exposure)
        let t = terms(f)
        let z = w.bias + w.rain * t.rain + w.soak * t.soak + w.gust * t.gust + w.heat * t.heat
            + w.flood * t.flood + w.thunder * t.thunder + w.fog * t.fog + w.evidence * t.evidence
        return 1 / (1 + exp(-z))
    }

    static func probability(_ exposure: WeatherExposure, _ f: WeatherFeatures, calibration: TwinCalibration) -> Double {
        calibration.adjust(prior(exposure, f), exposure: exposure, band: band(f))
    }

    /// 0–4: how severe the weather is, regardless of what's booked. The key
    /// observations are pooled under, so "band 3" means the same weather to
    /// every trip.
    static func band(_ f: WeatherFeatures) -> Int {
        let t = terms(f)
        let score = max(t.rain / 2.5, t.soak / 2, t.gust / 2.5, t.heat / 2.5, t.flood, t.thunder * 0.6)
        switch score {
        case ..<0.12: return 0
        case ..<0.3: return 1
        case ..<0.55: return 2
        case ..<0.8: return 3
        default: return 4
        }
    }

    /// When a booking is disrupted, how often that means it doesn't happen
    /// at all rather than running late.
    static func cancellationShare(_ exposure: WeatherExposure, band: Int) -> Double {
        let base: Double = switch exposure {
        case .outdoor: 0.55
        case .marine: 0.75
        case .road: 0.12
        case .rail: 0.3
        case .air: 0.28
        case .shelter: 0.08
        case .indoor: 0.3
        }
        return min(0.95, base + Double(max(0, band - 2)) * 0.1)
    }

    /// Typical delay, in minutes, for a disrupted booking that still happens.
    static func delayRange(_ exposure: WeatherExposure, band: Int) -> ClosedRange<Double> {
        let scale = 1 + Double(band) * 0.35
        switch exposure {
        case .road: return (20 * scale)...(90 * scale)
        case .rail: return (30 * scale)...(150 * scale)
        case .air: return (40 * scale)...(210 * scale)
        case .marine: return (30 * scale)...(120 * scale)
        default: return (20 * scale)...(75 * scale)
        }
    }

    /// The figures behind a score, largest contribution first.
    static func drivers(_ exposure: WeatherExposure, _ f: WeatherFeatures) -> [ImpactDriver] {
        let w = weights(exposure)
        let t = terms(f)
        var list: [ImpactDriver] = []

        func add(_ contribution: Double, _ symbol: String, _ label: String, _ value: String) {
            guard contribution > 0.15 else { return }
            list.append(ImpactDriver(symbol: symbol, label: label, value: value, weight: contribution))
        }

        add(w.rain * t.rain, "cloud.rain.fill", "Peak rain", String(format: "%.0f mm/h", f.rainRate))
        add(w.soak * t.soak, "drop.fill", "Rain before & during", String(format: "%.0f mm", f.rainTotal))
        add(w.gust * t.gust, "wind", "Gusts", String(format: "%.0f km/h", f.gusts))
        add(w.heat * t.heat, "thermometer.sun.fill", "Feels like", String(format: "%.0f°", f.apparentTemperature))
        add(w.flood * t.flood, "water.waves", "Flood signal", t.flood >= 0.66 ? "High" : t.flood >= 0.33 ? "Raised" : "Slight")
        add(w.thunder * t.thunder, "cloud.bolt.fill", "Lightning", "Likely")
        add(w.fog * t.fog, "cloud.fog.fill", "Fog", "Low visibility")
        add(w.evidence * t.evidence, "person.2.wave.2.fill", "Ground reports", t.evidence >= 0.5 ? "Many" : "Some")

        let total = list.reduce(0) { $0 + $1.weight }
        return list
            .map { ImpactDriver(symbol: $0.symbol, label: $0.label, value: $0.value, weight: total > 0 ? $0.weight / total : 0) }
            .sorted { $0.weight > $1.weight }
    }
}
