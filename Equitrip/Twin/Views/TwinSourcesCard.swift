//
//  TwinSourcesCard.swift
//  Equitrip
//

import SwiftUI

/// Where every number on the twin came from, and how much the model has
/// learned — folded to one line until someone asks.
///
/// The station footnote that used to sit on the weather card ("No Weather
/// Union station nearby · model 5 min ago") lives here now: it's the answer
/// to "how do you know?", and the people asking that open this.
struct TwinSourcesCard: View {
    let weather: [PlaceWeather]
    var destination: PlaceWeather?
    let calibrationCount: Int
    let updatedAt: Date?

    @State private var isExpanded = false
    @Environment(\.openURL) private var openURL

    private var sources: [WeatherSource] {
        Set(weather.flatMap(\.sources)).sorted { $0.trustRank < $1.trustRank }
    }

    private var stationPlaces: [PlaceWeather] {
        weather.filter { $0.current?.isStationBacked == true }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .frame(width: 20)
                    Text("Where these numbers come from")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 14)
                .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())

            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    note(stationNote)
                        .padding(.bottom, 8)

                    ForEach(sources, id: \.self) { source in
                        Hairline(inset: 30)
                        Button { openURL(source.url) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: source.symbol)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(source.tint)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(source.label)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text(detail(for: source))
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.inkTertiary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 4)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                            .padding(.vertical, 10)
                            .contentShape(.rect)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    Hairline()
                    VStack(alignment: .leading, spacing: 8) {
                        note("Ground reports come from Bluesky, Mastodon, GDELT news, NDMA Sachet and GDACS, and are sorted on this device.")
                        note(calibrationCount == 0
                             ? "The model runs on its starting weights until real outcomes arrive — flight statuses, booking-change emails and your answers teach it."
                             : "Calibrated on \(calibrationCount.pluralised("real outcome")) from flight statuses, booking changes and travellers' answers.")
                        note("Updated \(TwinFormat.ago(updatedAt)).")
                    }
                    .padding(.vertical, 12)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(AppTheme.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var stationNote: String {
        guard let destination else { return "Forecasts are blended per place on the trip." }
        let age = TwinFormat.ago(destination.current?.observedAt ?? destination.fetchedAt)
        if destination.current?.isStationBacked == true {
            return "A Weather Union station reading from \(age) is blended into the forecast for \(destination.name)."
        }
        if let gap = destination.stationDisagreement, abs(gap) > 8 {
            return "The nearest station was set aside — it was \(Int(abs(gap)))° off the model. Model run \(age)."
        }
        return destination.point.isInWeatherUnionCoverage
            ? "No Weather Union station near \(destination.name), so this is the model, run \(age)."
            : "\(destination.name) is outside Weather Union's coverage, so this is the model, run \(age)."
    }

    private func detail(for source: WeatherSource) -> String {
        guard source == .weatherUnion else { return source.detail }
        let names = stationPlaces.map(\.name)
        return names.isEmpty ? source.detail : "Live station at \(names.joined(separator: ", "))"
    }
}
