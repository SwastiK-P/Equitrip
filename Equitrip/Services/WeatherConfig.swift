//
//  WeatherConfig.swift
//  Equitrip
//

import Foundation

/// Where the twin's forecasts come from.
///
/// Open-Meteo's free tier is keyless and limited per IP address — about 10,000
/// calls a day, with ensemble requests counting as dozens — so a few days of
/// testing on one network can hit "Daily API request limit exceeded". A paid
/// Open-Meteo key (https://open-meteo.com/en/pricing) lifts that: set it below
/// and every request goes to the `customer-` hosts with `apikey`. Left empty,
/// the free API is used, and `OpenMeteoCache` keeps repeat opens off it.
enum WeatherConfig {
    static let openMeteoKey = ""

    static var hasOpenMeteoKey: Bool { !openMeteoKey.isEmpty }
}
