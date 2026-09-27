//
//  WeatherUnionService.swift
//  Equitrip
//

import Foundation
import Supabase

/// Live readings from Zomato's Weather Union stations, through the
/// `weather-union` Supabase function.
///
/// The app never holds the key: the function does, spends it only for a
/// signed-in user, caches each ~1 km cell for ten minutes and keeps the whole
/// user base under Weather Union's 1,000-calls-a-day allowance. Points outside
/// India aren't sent at all — there are no stations there to answer.
///
/// Units, as the stations report them: °C, % humidity, mm/h rain intensity and
/// mm accumulated. Wind speed arrives unlabelled; `WeatherFusion` settles m/s
/// against km/h by comparing it with the model rather than guessing.
enum WeatherUnionService {

    nonisolated struct Station: Decodable, Hashable {
        let temperature: Double?
        let humidity: Double?
        let wind_speed: Double?
        let wind_direction: Double?
        let rain_intensity: Double?
        let rain_accumulation: Double?
        let aqi_pm_2_point_5: Double?
        let aqi_pm_10: Double?
    }

    enum Answer: Hashable {
        case reading(Station, fetchedAt: Date)
        /// No station near enough — an answer, not an error.
        case noStation
        case unavailable
    }

    private nonisolated struct Point: Encodable {
        let id: String
        let lat: Double
        let lon: Double
    }

    private nonisolated struct Request: Encodable {
        let points: [Point]
    }

    private nonisolated struct Row: Decodable {
        let id: String
        let status: String
        let reading: Station?
        let fetched_at: String?
    }

    private nonisolated struct Response: Decodable {
        let readings: [Row]
    }

    private static let function = "weather-union"

    /// One reading per place id. Places outside coverage come back `.noStation`
    /// without a network call; a function that isn't deployed yet, or a
    /// signed-out session, comes back `.unavailable` for all of them.
    static func readings(for places: [(id: String, point: GeoPoint)]) async -> [String: Answer] {
        var answers: [String: Answer] = [:]
        let covered = places.filter { $0.point.isInWeatherUnionCoverage }
        for place in places where !place.point.isInWeatherUnionCoverage {
            answers[place.id] = .noStation
        }
        guard !covered.isEmpty else { return answers }

        do {
            let response: Response = try await AuthService.shared.client.functions.invoke(
                function,
                options: FunctionInvokeOptions(body: Request(points: covered.prefix(12).map {
                    Point(id: $0.id, lat: $0.point.latitude, lon: $0.point.longitude)
                }))
            )
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            for row in response.readings {
                switch row.status {
                case "ok":
                    if let reading = row.reading {
                        let at = row.fetched_at.flatMap { iso.date(from: $0) } ?? Date()
                        answers[row.id] = .reading(reading, fetchedAt: at)
                    } else {
                        answers[row.id] = .noStation
                    }
                case "no_station": answers[row.id] = .noStation
                default: answers[row.id] = .unavailable
                }
            }
        } catch {
            for place in covered where answers[place.id] == nil { answers[place.id] = .unavailable }
        }
        return answers
    }
}
