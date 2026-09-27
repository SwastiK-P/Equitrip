//
//  TwinNowCard.swift
//  Equitrip
//

import SwiftUI

/// The weather where the trip is, right now, in one compact card.
///
/// It replaced a 300-point sky with a 64-point temperature and four bordered
/// glass tiles, which pushed the thing the twin exists to answer — what the
/// weather does to the plan — below the fold. The sky stays as the card's
/// background; the four figures that move bookings sit on one line under the
/// condition, and the provenance footnote moved to `TwinSourcesCard`, where
/// the people who want it look for it.
struct TwinNowCard: View {
    let place: PlaceWeather

    private var reading: WeatherReading? { place.current }

    private var condition: WeatherCondition {
        reading?.condition ?? place.upcomingHours(1).first?.condition ?? .partlyCloudy
    }

    private var isDay: Bool { reading?.isDay ?? true }
    private var ink: Color { condition.ink(isDay: isDay) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // The temperature leads on the left: the sky draws its sun in
            // the top-right corner, and a numeral over it was unreadable.
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(place.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    if reading?.isStationBacked == true {
                        LiveDot(tint: ink)
                            .accessibilityLabel("Live station reading")
                    }
                }
                .foregroundStyle(ink.opacity(0.8))

                HStack(alignment: .center, spacing: 14) {
                    Text(TwinFormat.temperature(reading?.temperature))
                        .font(.system(size: 50, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    VStack(alignment: .leading, spacing: 3) {
                        Label(condition.label, systemImage: condition.symbol(isDay: isDay))
                            .font(.system(size: 16, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(ink)
                        if let feels = reading?.apparentTemperature {
                            Text("Feels like \(TwinFormat.temperature(feels))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ink.opacity(0.75))
                        }
                    }
                }
            }

            HStack(spacing: 0) {
                figure(
                    value: TwinFormat.rain(reading?.rainIntensity ?? 0), unit: "mm/h",
                    caption: TwinFormat.rainWord(reading?.rainIntensity ?? 0),
                    measured: reading?.stationFields.contains(.rain) ?? false
                )
                divider
                figure(
                    value: reading?.windSpeed.map { "\(Int($0.rounded()))" } ?? "–", unit: "km/h",
                    caption: TwinFormat.compass(reading?.windDirection).isEmpty ? "Wind" : "Wind from \(TwinFormat.compass(reading?.windDirection))",
                    measured: reading?.stationFields.contains(.wind) ?? false
                )
                divider
                figure(
                    value: reading?.humidity.map { "\(Int($0.rounded()))" } ?? "–", unit: "%",
                    caption: "Humidity",
                    measured: reading?.stationFields.contains(.humidity) ?? false
                )
                divider
                figure(
                    value: reading?.pm25.map { "\(Int($0.rounded()))" } ?? "–", unit: "PM2.5",
                    caption: reading?.airBand.map { "\($0.label) air" } ?? "Air",
                    measured: reading?.stationFields.contains(.air) ?? false
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            WeatherSky(condition: condition, isDay: isDay, rainRate: reading?.rainIntensity ?? 0)
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .shadow(color: condition.sky(isDay: isDay).top.opacity(0.25), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.6), value: condition)
    }

    private var divider: some View {
        Rectangle()
            .fill(ink.opacity(0.18))
            .frame(width: 1, height: 30)
            .padding(.horizontal, 10)
    }

    /// A station-measured figure carries a dot, so a reading that's half
    /// station and half model says which half is which.
    private func figure(value: String, unit: String, caption: String, measured: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(unit)
                    .font(.system(size: 9.5, weight: .semibold))
                    .opacity(0.7)
                if measured {
                    Circle()
                        .fill(Palette.red)
                        .frame(width: 5, height: 5)
                        .offset(y: -6)
                        .accessibilityLabel("Measured by a station")
                }
            }
            Text(caption)
                .font(.system(size: 11, weight: .medium))
                .opacity(0.75)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .foregroundStyle(ink)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
