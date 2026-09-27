//
//  WeatherWatchCard.swift
//  Equitrip
//

import SwiftUI

/// Home's line into the Weather Twin, for the trip that's on.
///
/// Quiet when there's nothing to say — one row: the sky, the temperature and
/// "weather looks kind to the plan" — and louder only when the twin has
/// something: a risk-coloured spine, the headline, and the two bookings most
/// at risk with their odds. It never shows a gradient or a badge for its own
/// sake; the colour arrives with the risk and leaves with it.
struct WeatherWatchCard: View {
    let trip: Trip
    var onOpen: () -> Void

    @Environment(\.weatherTwin) private var twinStore

    private var state: WeatherTwinStore.TripState? { twinStore.state(for: trip.id) }
    private var result: TwinResult? { state?.live }
    private var place: PlaceWeather? { state?.weather["dest"] }

    var body: some View {
        Button(action: onOpen) {
            Group {
                if let result, result.risk.isNotable, let twin = state?.twin {
                    alert(result, twin: twin)
                } else if place != nil {
                    calm
                } else {
                    loading
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(corner: 22)
        }
        .buttonStyle(PressableButtonStyle())
        .task(id: trip.id) { await twinStore.refresh(trip) }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: result?.risk)
    }

    // MARK: - States

    private var calm: some View {
        let reading = place?.current
        let condition = reading?.condition ?? .partlyCloudy

        return HStack(spacing: 12) {
            skyTile(condition, isDay: reading?.isDay ?? true, rain: reading?.rainIntensity ?? 0)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("\(TwinFormat.temperature(reading?.temperature)) · \(condition.label)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    if reading?.isStationBacked == true {
                        LiveDot(tint: Palette.red)
                    }
                }
                Text(result?.headline ?? "Checking the weather against the plan")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(14)
    }

    private func alert(_ result: TwinResult, twin: TripTwin) -> some View {
        let reading = place?.current

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                skyTile(reading?.condition ?? .rain, isDay: reading?.isDay ?? true, rain: reading?.rainIntensity ?? 0)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: result.risk.symbol).font(.system(size: 10, weight: .bold))
                        Text("Weather Twin · \(result.risk.label)")
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(0.4)
                    }
                    .foregroundStyle(result.risk.tint)
                    Text(result.headline)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 8) {
                ForEach(result.notable.prefix(2)) { outcome in
                    if let node = twin.node(outcome.id) {
                        HStack(spacing: 9) {
                            Image(systemName: node.item.symbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(node.item.kind.tint)
                                .frame(width: 18)
                            Text(node.item.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                            if outcome.order > 1 {
                                Text("knock-on")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Palette.amberDeep)
                            }
                            Spacer(minLength: 6)
                            RiskPill(risk: outcome.risk, probability: outcome.pAffected)
                        }
                    }
                }
            }

            HStack {
                Text("Open the twin")
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                Spacer()
                if let reading {
                    SourceBadge(source: reading.headlineSource, isLive: reading.isStationBacked)
                }
            }
            .foregroundStyle(AppTheme.accent)
        }
        .padding(14)
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 22, bottomLeadingRadius: 22, style: .continuous)
                .fill(result.risk.tint)
                .frame(width: 4)
        }
    }

    private var loading: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardStroke.opacity(0.06))
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 6) {
                Capsule().fill(AppTheme.cardStroke.opacity(0.07)).frame(width: 140, height: 12)
                Capsule().fill(AppTheme.cardStroke.opacity(0.05)).frame(width: 200, height: 10)
            }
            Spacer()
            ProgressView().controlSize(.small)
        }
        .padding(14)
    }

    private func skyTile(_ condition: WeatherCondition, isDay: Bool, rain: Double) -> some View {
        let symbol = condition.symbol(isDay: isDay)
        // The symbol is the only sun: the sky's own was a second one beside it.
        // Its colours are the sky's — a white cloud and the pale sun the sky
        // draws — rather than SF Symbols' saturated multicolour yellow.
        return WeatherSky(condition: condition, isDay: isDay, rainRate: rain, drawsSun: false)
            .frame(width: 48, height: 48)
            .clipShape(.rect(cornerRadius: 14, style: .continuous))
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .white,
                        symbol.contains("sun") ? Color(red: 1, green: 0.88, blue: 0.5)
                            : symbol.contains("bolt") ? Color(red: 1, green: 0.84, blue: 0.3)
                            : symbol.contains("moon") ? Color.white.opacity(0.85)
                            : Color(red: 0.72, green: 0.87, blue: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            }
    }
}
