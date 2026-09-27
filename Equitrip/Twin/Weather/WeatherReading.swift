//
//  WeatherReading.swift
//  Equitrip
//

import Foundation

/// The weather at one place right now, with each figure's source kept.
///
/// Built by `WeatherFusion` from a Weather Union station where there is one
/// and Open-Meteo everywhere else — field by field, because a station often
/// measures rain and temperature but not wind, and a gap in one figure is no
/// reason to throw away the others.
struct WeatherReading: Hashable, Codable {
    enum Field: String, Codable, Hashable, CaseIterable {
        case temperature, humidity, wind, rain, air
    }

    var temperature: Double?
    var apparentTemperature: Double?
    /// Percent.
    var humidity: Double?
    /// km/h.
    var windSpeed: Double?
    /// Degrees, meteorological (where it blows *from*).
    var windDirection: Double?
    var gusts: Double?
    /// mm/h right now.
    var rainIntensity: Double?
    /// mm since local midnight.
    var rainAccumulation: Double?
    var pm25: Double?
    var pm10: Double?
    var weatherCode: Int?
    var isDay: Bool
    var observedAt: Date
    /// Which fields a Weather Union station supplied. Empty means the whole
    /// reading is modelled.
    var stationFields: Set<Field>

    var condition: WeatherCondition {
        WeatherCondition(code: weatherCode, rainRate: rainIntensity ?? 0, temperature: temperature)
    }

    var isStationBacked: Bool { !stationFields.isEmpty }

    /// The source a headline badge credits: the station if it measured the
    /// temperature, otherwise the model.
    var headlineSource: WeatherSource {
        stationFields.contains(.temperature) ? .weatherUnion : .openMeteo
    }

    func source(of field: Field) -> WeatherSource {
        if stationFields.contains(field) { return .weatherUnion }
        return field == .air ? .airQuality : .openMeteo
    }

    /// US-EPA style band for PM2.5, the number people actually feel.
    var airBand: (label: String, severity: Int)? {
        guard let pm25 else { return nil }
        switch pm25 {
        case ..<12: return ("Good", 0)
        case ..<35.5: return ("Moderate", 1)
        case ..<55.5: return ("Unhealthy for some", 2)
        case ..<150.5: return ("Unhealthy", 3)
        default: return ("Hazardous", 4)
        }
    }
}
