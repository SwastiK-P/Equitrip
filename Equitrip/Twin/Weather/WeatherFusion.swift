//
//  WeatherFusion.swift
//  Equitrip
//

import Foundation

/// Builds one `PlaceWeather` from every source that can speak for a place,
/// and makes them agree.
///
/// The order is the point. Weather Union is asked first wherever it has
/// coverage, because a station a few hundred metres from the hotel measuring
/// rain *now* is better evidence than any model. Open-Meteo fills everything a
/// station can't: the forecast, the ensemble spread, days already past, the
/// season beyond the forecast, floods and air.
///
/// Then the twin *syncs with reality*: a live station reading nudges the next
/// few forecast hours towards what's actually being measured (the model's
/// bias fades out over six hours), and rain a station sees that the model
/// missed is carried into the next two hours as a nowcast. A station that
/// disagrees with the model by more than 8 °C is assumed to be answering for
/// somewhere else and is set aside — visibly, via `stationDisagreement`.
enum WeatherFusion {

    struct Place {
        let id: String
        let name: String
        let point: GeoPoint
    }

    /// Weather for every place, covering `window` (the trip, give or take a day).
    static func weather(for places: [Place], window: DateInterval) async -> [String: PlaceWeather] {
        let stations = await WeatherUnionService.readings(for: places.map { ($0.id, $0.point) })

        // All places at once: each is six requests of its own, and a trip
        // with an airport and a day trip used to fetch them in a queue.
        var result: [String: PlaceWeather] = [:]
        await withTaskGroup(of: (String, PlaceWeather?).self) { group in
            for place in places {
                let station = stations[place.id] ?? .unavailable
                group.addTask { (place.id, await build(place, window: window, station: station)) }
            }
            for await (id, weather) in group {
                if let weather { result[id] = weather }
            }
        }
        return result
    }

    private static func build(_ place: Place, window: DateInterval, station: WeatherUnionService.Answer) async -> PlaceWeather? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let forecastStart = calendar.date(byAdding: .day, value: -OpenMeteoService.pastDays, to: today)!
        let forecastEnd = calendar.date(byAdding: .day, value: OpenMeteoService.horizonDays, to: today)!

        let needsForecast = window.end >= forecastStart && window.start <= forecastEnd
        let pastEnd = min(window.end, forecastStart.addingTimeInterval(-1))
        let needsPast = window.start < forecastStart
        let seasonalStart = max(window.start, forecastEnd)
        let needsSeasonal = window.end > forecastEnd

        // A forecast is always fetched: it carries today's "current" even for
        // a trip months away, which is what the Home card and hero show.
        async let forecast = try? OpenMeteoService.forecast(at: place.point)
        async let ensemble = needsForecast ? (try? OpenMeteoService.ensemble(at: place.point)) : nil
        async let flood = try? OpenMeteoService.floodIndex(at: place.point)
        async let air = try? OpenMeteoService.air(at: place.point)
        async let past = needsPast
            ? (try? OpenMeteoService.history(at: place.point, from: window.start, to: pastEnd, basis: .observed))
            : nil
        async let seasonal = needsSeasonal
            ? (try? OpenMeteoService.history(
                at: place.point,
                from: calendar.date(byAdding: .year, value: -1, to: seasonalStart)!,
                to: calendar.date(byAdding: .year, value: -1, to: window.end)!,
                basis: .seasonal
            ))
            : nil

        let (forecastValue, ensembleValue, floodValue, airValue, pastValue, seasonalValue) =
            await (forecast, ensemble, flood, air, past, seasonal)

        guard forecastValue != nil || pastValue != nil || seasonalValue != nil else { return nil }

        var sources: Set<WeatherSource> = []
        var hours: [WeatherHour] = []
        var days: [WeatherDay] = []

        if let pastValue, !pastValue.isEmpty {
            hours += pastValue
            days += OpenMeteoService.days(from: pastValue)
            sources.insert(.archive)
        }

        if let forecastValue {
            var forecastHours = forecastValue.hours
            if let ensembleValue, !ensembleValue.isEmpty {
                for index in forecastHours.indices {
                    if let members = ensembleValue[forecastHours[index].time] {
                        forecastHours[index].memberPrecipitation = members.precipitation
                        forecastHours[index].memberTemperature = members.temperature
                    }
                }
                sources.insert(.ensemble)
            }
            hours += forecastHours
            days += forecastValue.days
            sources.insert(.openMeteo)
        }

        if let seasonalValue, !seasonalValue.isEmpty {
            // Shifted forward a year so they sit on the trip's own dates.
            let shifted = seasonalValue.compactMap { hour -> WeatherHour? in
                guard let date = calendar.date(byAdding: .year, value: 1, to: hour.time) else { return nil }
                var copy = WeatherHour(
                    time: date,
                    temperature: hour.temperature,
                    apparentTemperature: hour.apparentTemperature,
                    precipitation: hour.precipitation,
                    probability: nil,
                    windSpeed: hour.windSpeed,
                    gusts: hour.gusts,
                    code: hour.code,
                    basis: .seasonal
                )
                copy.memberPrecipitation = []
                return copy
            }
            let known = Set(hours.map(\.time))
            hours += shifted.filter { !known.contains($0.time) }
            let knownDays = Set(days.map(\.date))
            days += OpenMeteoService.days(from: shifted).filter { !knownDays.contains($0.date) }
            sources.insert(.archive)
        }

        hours.sort { $0.time < $1.time }
        days.sort { $0.date < $1.date }
        // The forecast endpoint's past days overlap the archive; keep one per hour.
        hours = hours.reduce(into: [WeatherHour]()) { list, hour in
            if list.last?.time != hour.time { list.append(hour) }
        }

        var current = forecastValue?.current
        if let airValue {
            current?.pm25 = airValue.pm25
            current?.pm10 = airValue.pm10
            if airValue.pm25 != nil { sources.insert(.airQuality) }
        }
        if let floodValue, !floodValue.isEmpty { sources.insert(.flood) }

        var weather = PlaceWeather(
            id: place.id,
            name: place.name,
            point: place.point,
            current: current,
            hours: hours,
            days: days,
            floodIndex: floodValue ?? [:],
            sources: sources,
            fetchedAt: Date(),
            stationDisagreement: nil
        )

        if case .reading(let reading, let fetchedAt) = station {
            assimilate(reading, at: fetchedAt, into: &weather)
        }
        return weather
    }

    // MARK: - Syncing with the station

    /// Lays a Weather Union reading over the model, field by field, then
    /// corrects the near forecast towards it.
    static func assimilate(_ station: WeatherUnionService.Station, at fetchedAt: Date, into weather: inout PlaceWeather) {
        var reading = weather.current ?? WeatherReading(
            isDay: true,
            observedAt: fetchedAt,
            stationFields: []
        )

        let modelTemperature = reading.temperature
        if let measured = station.temperature, let modelTemperature {
            let gap = measured - modelTemperature
            weather.stationDisagreement = gap
            // Too far off to be the same place — keep the model, say so.
            guard abs(gap) <= 8 else { return }
        }

        var fields: Set<WeatherReading.Field> = []

        if let t = station.temperature {
            reading.temperature = t
            fields.insert(.temperature)
        }
        if let h = station.humidity {
            reading.humidity = h
            fields.insert(.humidity)
        }
        if let raw = station.wind_speed {
            // Unlabelled in the API: whichever reading of the number sits
            // closer to the model's km/h is the one taken.
            let model = reading.windSpeed ?? raw * 3.6
            reading.windSpeed = abs(raw * 3.6 - model) < abs(raw - model) ? raw * 3.6 : raw
            if let direction = station.wind_direction { reading.windDirection = direction }
            fields.insert(.wind)
        }
        if station.rain_intensity != nil || station.rain_accumulation != nil {
            if let rate = station.rain_intensity { reading.rainIntensity = rate }
            if let total = station.rain_accumulation { reading.rainAccumulation = total }
            fields.insert(.rain)
        }
        if let pm = station.aqi_pm_2_point_5 {
            reading.pm25 = pm
            reading.pm10 = station.aqi_pm_10 ?? reading.pm10
            fields.insert(.air)
        }

        reading.stationFields = fields
        reading.observedAt = fetchedAt
        weather.current = reading
        weather.sources.insert(.weatherUnion)

        correctNearForecast(&weather, station: reading, modelTemperature: modelTemperature, at: fetchedAt)
    }

    /// The model's bias, measured against the station, faded out across the
    /// next six hours — and measured rain the model missed, carried two hours.
    private static func correctNearForecast(
        _ weather: inout PlaceWeather,
        station: WeatherReading,
        modelTemperature: Double?,
        at time: Date
    ) {
        let bias = (station.temperature ?? 0) - (modelTemperature ?? station.temperature ?? 0)
        let rain = station.rainIntensity ?? 0

        for index in weather.hours.indices {
            let lead = weather.hours[index].time.timeIntervalSince(time) / 3600
            guard lead >= -0.5, lead <= 6 else { continue }

            let weight = max(0, 1 - max(lead, 0) / 6)
            weather.hours[index].temperature += bias * weight
            weather.hours[index].memberTemperature = weather.hours[index].memberTemperature.map { $0 + bias * weight }

            if rain > weather.hours[index].precipitation, lead <= 2 {
                let carried = rain * max(0.35, 1 - max(lead, 0) / 2)
                weather.hours[index].precipitation = max(weather.hours[index].precipitation, carried)
                weather.hours[index].memberPrecipitation = weather.hours[index].memberPrecipitation.map { max($0, carried * 0.8) }
            }
        }
    }
}
