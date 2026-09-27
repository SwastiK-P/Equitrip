//
//  OpenMeteoService.swift
//  Equitrip
//

import Foundation
import Supabase

/// The free, keyless half of the twin's weather: forecasts, the ensemble,
/// history, floods and air — everywhere on Earth.
///
/// Weather Union measures the present at a few hundred Indian street corners;
/// it has no forecast and no coverage abroad. Open-Meteo is the model that
/// fills both gaps, and its ensemble is what turns "it will rain" into "60%
/// of plausible futures have it raining hard enough to cancel a ferry". Every
/// request asks for Unix timestamps so no local-time string is ever parsed.
enum OpenMeteoService {

    enum Failure: LocalizedError {
        case unreadable(String)
        /// HTTP 429: the free tier's daily limit for this IP is spent.
        case rateLimited

        var errorDescription: String? {
            switch self {
            case .unreadable(let what): "Open-Meteo's \(what) couldn't be read."
            case .rateLimited: "Open-Meteo's free daily limit is used up on this network."
            }
        }
    }

    /// When a request last came back 429 with nothing cached to fall back on,
    /// so the twin can say *why* there's no forecast instead of blaming the
    /// connection.
    private(set) static var lastRateLimitedAt: Date?

    static var isRateLimited: Bool {
        lastRateLimitedAt.map { Date().timeIntervalSince($0) < 3600 } ?? false
    }

    struct Forecast {
        var current: WeatherReading?
        var hours: [WeatherHour]
        var days: [WeatherDay]
    }

    /// How far ahead Open-Meteo forecasts, in days. Hours past this are seasonal.
    static let horizonDays = 16
    /// How far back the forecast endpoint reaches. Anything older is archive.
    static let pastDays = 2

    // MARK: - Forecast

    static func forecast(at point: GeoPoint) async throws -> Forecast {
        let url = endpoint("https://api.open-meteo.com/v1/forecast", point, [
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m",
            "hourly": "temperature_2m,apparent_temperature,precipitation,precipitation_probability,weather_code,wind_speed_10m,wind_gusts_10m",
            "daily": "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,uv_index_max",
            "past_days": "\(pastDays)",
            "forecast_days": "\(horizonDays)",
            "timezone": "auto"
        ])
        let json = try await load(url, what: "forecast")

        let hours = parseHours(json["hourly"] as? [String: Any], basis: .forecast)
        let days = parseDays(json["daily"] as? [String: Any])

        var current: WeatherReading?
        if let now = json["current"] as? [String: Any] {
            // `precipitation` here is what fell over the last `interval`
            // seconds (15 minutes), not a rate — scaled up to mm/h.
            let interval = number(now["interval"]) ?? 900
            let fallen = number(now["precipitation"]) ?? 0
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let today = hours.filter { $0.time >= startOfDay && $0.time <= Date() }.reduce(0) { $0 + $1.precipitation }

            current = WeatherReading(
                temperature: number(now["temperature_2m"]),
                apparentTemperature: number(now["apparent_temperature"]),
                humidity: number(now["relative_humidity_2m"]),
                windSpeed: number(now["wind_speed_10m"]),
                windDirection: number(now["wind_direction_10m"]),
                gusts: number(now["wind_gusts_10m"]),
                rainIntensity: fallen * 3600 / max(interval, 60),
                rainAccumulation: today,
                pm25: nil,
                pm10: nil,
                weatherCode: number(now["weather_code"]).map { Int($0) },
                isDay: (number(now["is_day"]) ?? 1) > 0,
                observedAt: number(now["time"]).map { Date(timeIntervalSince1970: $0) } ?? Date(),
                stationFields: []
            )
        }
        return Forecast(current: current, hours: hours, days: days)
    }

    // MARK: - Ensemble

    /// Every member's rain and temperature, by hour. The GFS ensemble has 31
    /// members; the unperturbed control run counts as one more.
    static func ensemble(at point: GeoPoint) async throws -> [Date: (precipitation: [Double], temperature: [Double])] {
        let url = endpoint("https://ensemble-api.open-meteo.com/v1/ensemble", point, [
            "hourly": "precipitation,temperature_2m",
            "models": "gfs_seamless",
            "forecast_days": "\(horizonDays)"
        ])
        let json = try await load(url, what: "ensemble")
        guard let hourly = json["hourly"] as? [String: Any] else { throw Failure.unreadable("ensemble") }

        let times = column(hourly, "time").map { $0.map { Date(timeIntervalSince1970: $0) } }
        let rainKeys = hourly.keys.filter { $0.hasPrefix("precipitation") }.sorted()
        let tempKeys = hourly.keys.filter { $0.hasPrefix("temperature_2m") }.sorted()
        let rain = rainKeys.map { column(hourly, $0) }
        let temp = tempKeys.map { column(hourly, $0) }

        var result: [Date: (precipitation: [Double], temperature: [Double])] = [:]
        for (index, time) in times.enumerated() {
            guard let time else { continue }
            let p = rain.compactMap { index < $0.count ? $0[index] : nil }
            let t = temp.compactMap { index < $0.count ? $0[index] : nil }
            if !p.isEmpty { result[time] = (p, t) }
        }
        return result
    }

    // MARK: - History

    /// Hourly weather for past (or year-ago) dates, from ERA5.
    static func history(at point: GeoPoint, from start: Date, to end: Date, basis: WeatherHour.Basis) async throws -> [WeatherHour] {
        let url = endpoint("https://archive-api.open-meteo.com/v1/archive", point, [
            "hourly": "temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_gusts_10m",
            "start_date": dayString(start),
            "end_date": dayString(end),
            "timezone": "auto"
        ])
        let json = try await load(url, what: "history")
        return parseHours(json["hourly"] as? [String: Any], basis: basis)
    }

    // MARK: - Floods

    /// 0–1 per day: today's river discharge against the last two months'
    /// median. The river cell is the nearest one GloFAS models, which for a
    /// coastal town is often a stream — so this is weighed alongside local
    /// rain, never alone.
    static func floodIndex(at point: GeoPoint) async throws -> [Date: Double] {
        let url = endpoint("https://flood-api.open-meteo.com/v1/flood", point, [
            "daily": "river_discharge",
            "past_days": "60",
            "forecast_days": "\(horizonDays)"
        ])
        let json = try await load(url, what: "flood outlook")
        guard let daily = json["daily"] as? [String: Any] else { return [:] }

        let times = column(daily, "time")
        let flows = column(daily, "river_discharge")
        let known = flows.compactMap { $0 }.sorted()
        guard !known.isEmpty else { return [:] }
        let median = max(known.percentile(0.5), 0.05)

        var result: [Date: Double] = [:]
        for (time, flow) in zip(times, flows) {
            guard let time, let flow else { continue }
            let ratio = flow / median
            let index = min(1, max(0, (ratio - 1.3) / 2.5))
            result[Calendar.current.startOfDay(for: Date(timeIntervalSince1970: time))] = index
        }
        return result
    }

    // MARK: - Air

    static func air(at point: GeoPoint) async throws -> (pm25: Double?, pm10: Double?) {
        let url = endpoint("https://air-quality-api.open-meteo.com/v1/air-quality", point, [
            "current": "pm2_5,pm10"
        ])
        let json = try await load(url, what: "air quality")
        let now = json["current"] as? [String: Any]
        return (number(now?["pm2_5"]), number(now?["pm10"]))
    }

    // MARK: - Parsing

    private static func parseHours(_ hourly: [String: Any]?, basis: WeatherHour.Basis) -> [WeatherHour] {
        guard let hourly else { return [] }
        let times = column(hourly, "time")
        let temp = column(hourly, "temperature_2m")
        let apparent = column(hourly, "apparent_temperature")
        let rain = column(hourly, "precipitation")
        let chance = column(hourly, "precipitation_probability")
        let code = column(hourly, "weather_code")
        let wind = column(hourly, "wind_speed_10m")
        let gust = column(hourly, "wind_gusts_10m")

        return times.indices.compactMap { i in
            guard let time = times[i], let t = temp[safe: i] ?? nil else { return nil }
            return WeatherHour(
                time: Date(timeIntervalSince1970: time),
                temperature: t,
                apparentTemperature: apparent[safe: i] ?? nil,
                precipitation: (rain[safe: i] ?? nil) ?? 0,
                probability: chance[safe: i] ?? nil,
                windSpeed: (wind[safe: i] ?? nil) ?? 0,
                gusts: gust[safe: i] ?? nil,
                code: Int(((code[safe: i] ?? nil) ?? 0)),
                basis: basis
            )
        }
    }

    private static func parseDays(_ daily: [String: Any]?) -> [WeatherDay] {
        guard let daily else { return [] }
        let times = column(daily, "time")
        let high = column(daily, "temperature_2m_max")
        let low = column(daily, "temperature_2m_min")
        let rain = column(daily, "precipitation_sum")
        let chance = column(daily, "precipitation_probability_max")
        let code = column(daily, "weather_code")
        let uv = column(daily, "uv_index_max")

        return times.indices.compactMap { i in
            guard let time = times[i], let h = high[safe: i] ?? nil, let l = low[safe: i] ?? nil else { return nil }
            return WeatherDay(
                date: Calendar.current.startOfDay(for: Date(timeIntervalSince1970: time)),
                high: h,
                low: l,
                precipitation: (rain[safe: i] ?? nil) ?? 0,
                probability: chance[safe: i] ?? nil,
                code: Int(((code[safe: i] ?? nil) ?? 0)),
                uvMax: uv[safe: i] ?? nil
            )
        }
    }

    /// Days summarised from hours, for stretches only the archive covers.
    static func days(from hours: [WeatherHour]) -> [WeatherDay] {
        let grouped = Dictionary(grouping: hours) { Calendar.current.startOfDay(for: $0.time) }
        return grouped.keys.sorted().compactMap { day in
            guard let list = grouped[day], !list.isEmpty else { return nil }
            let temps = list.map(\.temperature)
            let worst = list.max { severity($0.code) < severity($1.code) }?.code ?? 0
            return WeatherDay(
                date: day,
                high: temps.max() ?? 0,
                low: temps.min() ?? 0,
                precipitation: list.reduce(0) { $0 + $1.precipitation },
                probability: nil,
                code: worst,
                uvMax: nil
            )
        }
    }

    /// Rough ordering of WMO codes by how much they matter, for "the day's weather".
    private static func severity(_ code: Int) -> Int {
        switch code {
        case 95...99: 9
        case 65, 67, 82: 8
        case 71...86: 7
        case 61...64, 66, 80, 81: 6
        case 51...57: 4
        case 45, 48: 3
        case 3: 2
        case 1, 2: 1
        default: 0
        }
    }

    // MARK: - Plumbing

    private static func endpoint(_ base: String, _ point: GeoPoint, _ query: [String: String]) -> URL {
        var components = URLComponents(string: base)!
        // A paid key lives on the same paths under `customer-` hosts.
        if WeatherConfig.hasOpenMeteoKey, let host = components.host {
            components.host = "customer-" + host
        }
        var items = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", point.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", point.longitude)),
            URLQueryItem(name: "timeformat", value: "unixtime")
        ]
        items += query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        if WeatherConfig.hasOpenMeteoKey {
            items.append(URLQueryItem(name: "apikey", value: WeatherConfig.openMeteoKey))
        }
        components.queryItems = items
        return components.url!
    }

    /// Cache first, then the network; a failed request falls back to the
    /// last good answer of any age — yesterday's forecast beats a blank twin.
    private static func load(_ url: URL, what: String) async throws -> [String: Any] {
        if let fresh = OpenMeteoCache.read(url, maxAge: OpenMeteoCache.lifetime(for: what)),
           let json = parse(fresh) {
            return json
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("Equitrip (iOS)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode
            // This IP is spent for the day: try again from the relay's.
            let body = status == 429 ? try await relay(url) : data
            guard status == 200 || status == 429, let json = parse(body) else { throw Failure.unreadable(what) }
            OpenMeteoCache.write(body, for: url)
            return json
        } catch {
            if let stale = OpenMeteoCache.read(url, maxAge: .infinity), let json = parse(stale) {
                return json
            }
            if case Failure.rateLimited = error { lastRateLimitedAt = Date() }
            throw error
        }
    }

    private struct RelayRequest: Encodable { let url: String }

    /// The same request, sent from the `open-meteo` Supabase function's IP.
    /// Only reached after a 429, and only when signed in.
    private static func relay(_ url: URL) async throws -> Data {
        do {
            return try await AuthService.shared.client.functions.invoke(
                "open-meteo",
                options: FunctionInvokeOptions(body: RelayRequest(url: url.absoluteString))
            ) { data, _ in data }
        } catch {
            throw Failure.rateLimited
        }
    }

    private static func parse(_ data: Data) -> [String: Any]? {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              json["error"] as? Bool != true
        else { return nil }
        return json
    }

    private static func column(_ block: [String: Any], _ key: String) -> [Double?] {
        (block[key] as? [Any])?.map { number($0) } ?? []
    }

    private static func number(_ value: Any?) -> Double? {
        (value as? NSNumber)?.doubleValue
    }

    private static func dayString(_ date: Date) -> String {
        DateFormatter.cached("yyyy-MM-dd").string(from: date)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
