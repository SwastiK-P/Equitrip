//
//  WeatherSource.swift
//  Equitrip
//

import SwiftUI

/// Where a number on the weather screens came from.
///
/// Every figure the twin shows is attributed, because the twin mixes a
/// station a few hundred metres from the hotel with a global model on a 10 km
/// grid, and those deserve different amounts of trust. The label is what a
/// badge says; `url` is where "Sources" sends people who want to check.
enum WeatherSource: String, Codable, Hashable, CaseIterable, Identifiable {
    /// Zomato's ground stations: measured, hyperlocal, India only.
    case weatherUnion
    /// Open-Meteo's forecast blend: modelled, global.
    case openMeteo
    /// The 31-member GFS ensemble: the spread of plausible futures.
    case ensemble
    /// ERA5 reanalysis: what the weather actually did, for past days.
    case archive
    /// GloFAS river discharge: the flood signal.
    case flood
    /// CAMS air quality.
    case airQuality

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weatherUnion: "Weather Union"
        case .openMeteo: "Open-Meteo"
        case .ensemble: "GFS ensemble"
        case .archive: "ERA5 reanalysis"
        case .flood: "GloFAS floods"
        case .airQuality: "CAMS air quality"
        }
    }

    var detail: String {
        switch self {
        case .weatherUnion: "Zomato ground station, measured live"
        case .openMeteo: "Forecast model blend, hourly"
        case .ensemble: "31 model runs — the spread is the uncertainty"
        case .archive: "Observed history, for days already past"
        case .flood: "River discharge against its recent normal"
        case .airQuality: "PM2.5 and PM10"
        }
    }

    var symbol: String {
        switch self {
        case .weatherUnion: "sensor.fill"
        case .openMeteo: "globe.asia.australia.fill"
        case .ensemble: "chart.line.uptrend.xyaxis"
        case .archive: "clock.arrow.circlepath"
        case .flood: "water.waves"
        case .airQuality: "aqi.medium"
        }
    }

    var tint: Color {
        switch self {
        case .weatherUnion: Palette.red
        case .openMeteo: Palette.blue
        case .ensemble: Palette.violet
        case .archive: Palette.stone
        case .flood: Palette.teal
        case .airQuality: Palette.amber
        }
    }

    var url: URL {
        switch self {
        case .weatherUnion: URL(string: "https://www.weatherunion.com")!
        case .openMeteo, .ensemble: URL(string: "https://open-meteo.com")!
        case .archive: URL(string: "https://open-meteo.com/en/docs/historical-weather-api")!
        case .flood: URL(string: "https://open-meteo.com/en/docs/flood-api")!
        case .airQuality: URL(string: "https://open-meteo.com/en/docs/air-quality-api")!
        }
    }

    /// Measured beats modelled: the order a badge picks its headline source in.
    var trustRank: Int {
        switch self {
        case .weatherUnion: 0
        case .archive: 1
        case .openMeteo: 2
        case .ensemble: 3
        case .flood: 4
        case .airQuality: 5
        }
    }
}

extension Palette {
    /// Zomato's own red, for the one badge that credits Weather Union.
    static let red = AppTheme.dynamic(light: 0xE23744, dark: 0xF0555F)
}
