//
//  ScenarioSkyCard.swift
//  Equitrip
//

import SwiftUI

/// The what-if weather, drawn: the sky it describes, falling as hard as the
/// rain dial says, with the event's figures on it.
///
/// A sentence under the preset grid said "35 mm/h for 6 hours" and left the
/// reader to picture it. The same animated sky the live card uses shows it
/// instead — the drops thicken as rain goes up, lightning flashes when it's
/// on, a heatwave shimmers — and the sky is a night one when the event
/// starts after dark, so the card also says *when* without being read.
struct ScenarioSkyCard: View {
    let scenario: TwinScenario

    private var condition: WeatherCondition {
        if scenario.thunder { return .thunderstorm }
        if let rain = scenario.rainIntensity {
            if rain >= 20 { return .heavyRain }
            if rain >= 2.5 { return .rain }
            if rain > 0 { return .drizzle }
        }
        if scenario.temperature != nil { return .heat }
        if scenario.flooding >= 0.3 { return .heavyRain }
        if scenario.gusts != nil { return .cloudy }
        return .partlyCloudy
    }

    private var isDay: Bool { (6..<19).contains(scenario.startHour) }
    private var ink: Color { condition.ink(isDay: isDay) }

    private var title: String {
        if scenario.isLive { return "The forecast as it is" }
        return scenario.preset?.label ?? "Your own weather"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Text(when)
                    .font(.system(size: 13, weight: .medium))
                    .opacity(0.8)
            }

            if scenario.isLive {
                Text("Raise any dial below to add weather to it.")
                    .font(.system(size: 13))
                    .opacity(0.8)
            } else {
                FlowLayout(spacing: 6, rowSpacing: 6) {
                    ForEach(figures, id: \.label) { figure in
                        HStack(spacing: 4) {
                            Image(systemName: figure.symbol)
                                .font(.system(size: 10, weight: .bold))
                            Text(figure.label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.22), in: .capsule)
                    }
                }
            }
        }
        .foregroundStyle(ink)
        .shadow(color: .black.opacity(ink == AppTheme.ink ? 0 : 0.25), radius: 4, y: 1)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .bottomLeading)
        .background {
            WeatherSky(condition: condition, isDay: isDay, rainRate: scenario.rainIntensity ?? 0)
                .overlay {
                    // Dense rain streaks ran through white type; a soft floor
                    // of shade under the words keeps them readable.
                    if ink != AppTheme.ink {
                        LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .top, endPoint: .bottom)
                    }
                }
        }
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .shadow(color: condition.sky(isDay: isDay).top.opacity(0.25), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    private var when: String {
        let formatter = DateFormatter.cached("h a")
        let start = Calendar.current.startOfDay(for: Date()).addingTimeInterval(Double(scenario.startHour) * 3600)
        let hours = Int(scenario.durationHours) == 1 ? "1 hour" : "\(Int(scenario.durationHours)) hours"
        let day = scenario.targetDay.map { DateFormatter.cached("EEE d MMM").string(from: $0) } ?? "every day"
        return "\(hours) from \(formatter.string(from: start)), \(day)"
    }

    private var figures: [(symbol: String, label: String)] {
        var list: [(String, String)] = []
        if let rain = scenario.rainIntensity { list.append(("cloud.rain.fill", "\(Int(rain)) mm/h")) }
        if let gusts = scenario.gusts { list.append(("wind", "\(Int(gusts)) km/h")) }
        if let heat = scenario.temperature { list.append(("thermometer.sun.fill", "\(Int(heat))°")) }
        if scenario.flooding >= 0.05 { list.append(("water.waves", "\(Int((scenario.flooding * 100).rounded()))% flood")) }
        if scenario.thunder { list.append(("bolt.fill", "Lightning")) }
        return list
    }
}
