//
//  ScenarioStrengthCard.swift
//  Equitrip
//

import SwiftUI

/// How bad the what-if weather is: four dials in a grid — rain, gusts, heat,
/// flooding — and lightning as a switch under them.
///
/// Every dial only ever *adds* to the forecast — the simulator takes the
/// worse of the two — so each one's floor is "as forecast", not zero, and
/// there are no on/off switches beside them saying the same thing. The heat
/// dial starts at the trip's own forecast high, so every notch on it is
/// genuinely hotter.
struct ScenarioStrengthCard: View {
    @Binding var scenario: TwinScenario
    /// The hottest afternoon already forecast for the trip, °C.
    var forecastHigh: Double?

    private var heatFloor: Double {
        min(45, max(25, (forecastHigh ?? 30).rounded(.up)))
    }

    var body: some View {
        VStack(spacing: 0) {
            Grid(horizontalSpacing: 12, verticalSpacing: 22) {
                GridRow {
                    ScenarioDial(
                        title: "Rain", symbol: "cloud.heavyrain.fill", tint: AppTheme.accent,
                        fraction: optional(\.rainIntensity, floor: 0, ceiling: 100),
                        steps: 50,
                        value: scenario.rainIntensity.map { "\(Int($0))" }, unit: "mm/h",
                        caption: scenario.rainIntensity.map { TwinFormat.rainWord($0) }
                    )
                    ScenarioDial(
                        title: "Wind gusts", symbol: "wind", tint: AppTheme.accent,
                        fraction: optional(\.gusts, floor: 0, ceiling: 160),
                        steps: 32,
                        value: scenario.gusts.map { "\(Int($0))" }, unit: "km/h",
                        caption: scenario.gusts.map(gustWord)
                    )
                }
                GridRow {
                    ScenarioDial(
                        title: "Heat", symbol: "thermometer.sun.fill", tint: AppTheme.accent,
                        fraction: optional(\.temperature, floor: heatFloor, ceiling: 50),
                        steps: max(1, Int(50 - heatFloor)),
                        value: scenario.temperature.map { "\(Int($0))°" }, unit: "°C high",
                        caption: scenario.temperature.map(heatWord)
                    )
                    ScenarioDial(
                        title: "Flooding", symbol: "water.waves", tint: AppTheme.accent,
                        fraction: Binding(
                            get: { scenario.flooding },
                            set: { scenario.flooding = $0; scenario.preset = nil }
                        ),
                        steps: 20,
                        value: scenario.flooding >= 0.05 ? "\(Int((scenario.flooding * 100).rounded()))" : nil, unit: "% over",
                        caption: floodWord
                    )
                }
            }
            .padding(.vertical, 18)

            Hairline()

            Toggle(isOn: Binding(
                get: { scenario.thunder },
                set: { scenario.thunder = $0; scenario.preset = nil }
            )) {
                HStack(spacing: 12) {
                    WeatherGlyph(condition: .thunderstorm, size: 16)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lightning")
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        Text("Grounds flights, clears beaches and boats")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }
            }
            .tint(AppTheme.accent)
            .padding(.vertical, 13)
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
    }

    /// A dial over `floor...ceiling` whose floor means "leave it to the forecast".
    private func optional(_ path: WritableKeyPath<TwinScenario, Double?>, floor: Double, ceiling: Double) -> Binding<Double> {
        Binding(
            get: {
                guard let value = scenario[keyPath: path] else { return 0 }
                return min(1, max(0, (value - floor) / (ceiling - floor)))
            },
            set: { fraction in
                let value = (floor + fraction * (ceiling - floor)).rounded()
                scenario[keyPath: path] = value <= floor ? nil : value
                scenario.preset = nil
            }
        )
    }

    private func gustWord(_ kmh: Double) -> String {
        switch kmh {
        case ..<40: "Breezy"
        case ..<62: "Strong"
        case ..<89: "Gale"
        case ..<118: "Storm force"
        default: "Hurricane force"
        }
    }

    private func heatWord(_ celsius: Double) -> String {
        switch celsius {
        case ..<35: "Hot"
        case ..<40: "Very hot"
        case ..<45: "Heatwave"
        default: "Severe heatwave"
        }
    }

    private var floodWord: String? {
        switch scenario.flooding {
        case ..<0.05: nil
        case ..<0.35: "Drains overflowing"
        case ..<0.7: "Streets flooded"
        default: "Rivers over banks"
        }
    }
}
