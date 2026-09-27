//
//  PlaceWeather.swift
//  Equitrip
//

import Foundation

/// One hour of weather at one place, and how sure anyone is about it.
struct WeatherHour: Hashable, Codable {
    /// How an hour's figures were arrived at, which decides how much the
    /// simulator lets them wander.
    enum Basis: String, Codable, Hashable {
        /// Inside the forecast window: the ensemble's members carry the spread.
        case forecast
        /// Already happened: reanalysis, close to what was measured.
        case observed
        /// Beyond the forecast: the same hour a year earlier, standing in for
        /// the season. Wide uncertainty, honestly labelled.
        case seasonal
    }

    let time: Date
    var temperature: Double
    var apparentTemperature: Double?
    /// mm fallen in the hour.
    var precipitation: Double
    /// 0–100, forecast hours only.
    var probability: Double?
    /// km/h.
    var windSpeed: Double
    var gusts: Double?
    var code: Int
    var basis: Basis
    /// The ensemble's members for this hour, when it reached this far.
    var memberPrecipitation: [Double] = []
    var memberTemperature: [Double] = []

    var condition: WeatherCondition {
        WeatherCondition(code: code, rainRate: precipitation, temperature: temperature)
    }

    /// The 10th and 90th percentile of rain across the members, or nil.
    var precipitationRange: ClosedRange<Double>? {
        guard memberPrecipitation.count >= 5 else { return nil }
        let sorted = memberPrecipitation.sorted()
        return sorted.percentile(0.1)...sorted.percentile(0.9)
    }
}

/// One day's summary at one place.
struct WeatherDay: Hashable, Codable {
    let date: Date
    var high: Double
    var low: Double
    var precipitation: Double
    var probability: Double?
    var code: Int
    var uvMax: Double?

    var condition: WeatherCondition {
        WeatherCondition(code: code, rainRate: precipitation / 6, temperature: high)
    }
}

/// Everything the twin knows about the weather at one place.
///
/// A trip is usually two or three places — the hotel's neighbourhood, the
/// airport, a day trip — and bookings near each other share one of these, so
/// a six-booking day costs one set of requests rather than six.
struct PlaceWeather: Hashable, Codable, Identifiable {
    let id: String
    var name: String
    var point: GeoPoint
    var current: WeatherReading?
    var hours: [WeatherHour]
    var days: [WeatherDay]
    /// 0–1 per local day: river discharge against its recent normal.
    var floodIndex: [Date: Double]
    var sources: Set<WeatherSource>
    var fetchedAt: Date
    /// How far the Weather Union station disagreed with the model, in °C,
    /// when both answered. Surfaced so a station that looks misplaced can be
    /// seen being ignored, rather than silently winning.
    var stationDisagreement: Double?

    func hours(in interval: DateInterval) -> [WeatherHour] {
        hours.filter { interval.contains($0.time) }
    }

    /// The hour nearest `date`, within three hours.
    func hour(at date: Date) -> WeatherHour? {
        let nearest = hours.min { abs($0.time.timeIntervalSince(date)) < abs($1.time.timeIntervalSince(date)) }
        guard let nearest, abs(nearest.time.timeIntervalSince(date)) <= 3 * 3600 else { return nil }
        return nearest
    }

    func day(for date: Date) -> WeatherDay? {
        let start = Calendar.current.startOfDay(for: date)
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: start) }
    }

    func flood(on date: Date) -> Double {
        let start = Calendar.current.startOfDay(for: date)
        return floodIndex.first { Calendar.current.isDate($0.key, inSameDayAs: start) }?.value ?? 0
    }

    /// Hours from now on, for the strip at the top of the twin.
    func upcomingHours(_ count: Int, from now: Date = Date()) -> [WeatherHour] {
        let start = now.addingTimeInterval(-1800)
        return Array(hours.filter { $0.time >= start }.prefix(count))
    }
}

extension Array where Element == Double {
    /// Linear-interpolated percentile of an already-sorted array.
    func percentile(_ p: Double) -> Double {
        guard !isEmpty else { return 0 }
        guard count > 1 else { return self[0] }
        let rank = p * Double(count - 1)
        let lower = Int(rank.rounded(.down))
        let upper = Swift.min(lower + 1, count - 1)
        let weight = rank - Double(lower)
        return self[lower] * (1 - weight) + self[upper] * weight
    }
}
