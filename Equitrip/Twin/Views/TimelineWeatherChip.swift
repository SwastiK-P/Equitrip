//
//  TimelineWeatherChip.swift
//  Equitrip
//

import SwiftUI

/// The weather a booking will be in, on its timeline card: the sky, the
/// temperature, and — only when the twin is worried — its odds.
///
/// Draws nothing until the twin has an answer, so a timeline opened offline
/// or for a trip months away looks exactly as it did before.
struct TimelineWeatherChip: View {
    let item: ItineraryItem
    let tripID: UUID

    @Environment(\.weatherTwin) private var twinStore

    var body: some View {
        if let hour = twinStore.hour(for: item, in: tripID) {
            let outcome = twinStore.outcome(for: item.id, in: tripID)
            let isDay = (6...18).contains(Calendar.current.component(.hour, from: hour.time))

            HStack(spacing: 5) {
                Image(systemName: hour.condition.symbol(isDay: isDay))
                    .font(.system(size: 11))
                    .symbolRenderingMode(.multicolor)
                Text(TwinFormat.temperature(hour.temperature))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
                if hour.precipitation >= 0.5 {
                    Text("\(TwinFormat.rain(hour.precipitation)) mm")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.blue)
                }
                if let outcome, outcome.risk.isNotable {
                    Text("·")
                        .foregroundStyle(AppTheme.inkTertiary)
                    Image(systemName: outcome.order > 1 ? "arrow.turn.down.right" : outcome.risk.symbol)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(outcome.risk.tint)
                    Text(TwinFormat.percent(outcome.pAffected))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(outcome.risk.tint)
                }
                if hour.basis == .seasonal {
                    Text("typical")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill((outcome?.risk.isNotable ?? false) ? outcome!.risk.tint.opacity(0.1) : AppTheme.cardStroke.opacity(0.05))
            }
            .accessibilityElement(children: .combine)
            .padding(.top, 4)
            .transition(.opacity)
        }
    }
}

/// A day's high and sky, beside its name on the timeline.
struct DayWeatherBadge: View {
    let date: Date
    let tripID: UUID

    @Environment(\.weatherTwin) private var twinStore

    var body: some View {
        if let day = twinStore.day(date, in: tripID) {
            HStack(spacing: 4) {
                Image(systemName: day.condition.symbol())
                    .font(.system(size: 11))
                    .symbolRenderingMode(.multicolor)
                Text(TwinFormat.temperature(day.high))
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .transition(.opacity)
        }
    }
}

/// The itinerary's door into the twin, above the days it's about.
///
/// A single line when all is well; when the twin is worried, the line takes
/// the risk's colour and names what's at stake.
struct TwinEntryCard: View {
    let trip: Trip
    var onOpen: () -> Void

    @Environment(\.weatherTwin) private var twinStore

    var body: some View {
        let state = twinStore.state(for: trip.id)
        let result = state?.live
        let reading = state?.weather["dest"]?.current
        let risk = result?.risk ?? .calm

        Button(action: onOpen) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(risk.isNotable ? risk.tint.opacity(0.14) : Palette.blue.opacity(0.1))
                    Image(systemName: risk.isNotable ? risk.symbol : (reading?.condition.symbol(isDay: reading?.isDay ?? true) ?? "cloud.sun.fill"))
                        .font(.system(size: 15, weight: .semibold))
                        .symbolRenderingMode(risk.isNotable ? .monochrome : .multicolor)
                        .foregroundStyle(risk.tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Weather Twin")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                        if let reading {
                            Text("\(TwinFormat.temperature(reading.temperature)) now")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.inkSecondary)
                        }
                        if reading?.isStationBacked == true { LiveDot(tint: Palette.red) }
                    }
                    Text(subtitle(state: state, result: result))
                        .font(.system(size: 12))
                        .foregroundStyle(risk.isNotable ? risk.tint : AppTheme.inkSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if state?.phase.isWorking == true {
                    ProgressView().controlSize(.small)
                } else {
                    Text("What-if")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(AppTheme.accent.opacity(0.1), in: .capsule)
                }
            }
            .padding(12)
            .cardSurface(corner: 18)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(risk.isNotable ? risk.tint.opacity(0.35) : .clear, lineWidth: 1.2)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: risk)
    }

    private func subtitle(state: WeatherTwinStore.TripState?, result: TwinResult?) -> String {
        if let phase = state?.phase, phase.isWorking { return phase.label }
        if case .failed(let message) = state?.phase { return message }
        guard let result else { return "Live weather, ground reports and what-ifs" }
        if result.risk.isNotable { return "\(result.notable.count.pluralised("booking")) at risk · tap to see why" }
        return "Every booking on track"
    }
}
