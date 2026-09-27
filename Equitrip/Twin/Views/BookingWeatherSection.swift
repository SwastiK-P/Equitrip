//
//  BookingWeatherSection.swift
//  Equitrip
//

import SwiftUI

/// One booking's weather, on its detail sheet: the conditions it'll be in,
/// what the twin makes of them, what could be done — and, once it's
/// happened, the one question that teaches the twin most.
///
/// "Did the weather get this?" is asked only after the booking, and only
/// when the twin had an opinion. The answer is pooled anonymously
/// (`TwinLearning`) and re-scores the trip at once.
struct BookingWeatherSection: View {
    let item: ItineraryItem
    let trip: Trip

    @Environment(\.weatherTwin) private var twinStore
    @State private var answered = false

    private var outcome: NodeOutcome? { twinStore.outcome(for: item.id, in: trip.id) }
    private var hour: WeatherHour? { twinStore.hour(for: item, in: trip.id) }
    private var node: TwinNode? { twinStore.state(for: trip.id)?.twin?.node(item.id) }

    private var hasHappened: Bool {
        (item.time ?? item.date.endOfDay) < Date()
    }

    var body: some View {
        if let hour, let node {
            VStack(alignment: .leading, spacing: 10) {
                Text("WEATHER")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.leading, 2)

                VStack(alignment: .leading, spacing: 12) {
                    conditions(hour, node: node)

                    if let outcome {
                        Hairline()
                        assessment(outcome, node: node)
                    }

                    let actions = twinStore.actions.actions(for: item.id, in: trip.id)
                    if !actions.isEmpty, !hasHappened {
                        ScrollView(.horizontal) {
                            HStack(spacing: 7) {
                                ForEach(actions) { action in
                                    TwinActionChip(
                                        action: action,
                                        canRun: false,
                                        onToggle: { twinStore.actions.toggleQueued(action) },
                                        onRun: {}
                                    )
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .scrollClipDisabled()
                    }

                    if hasHappened, outcome != nil, !twinStore.learning.hasRecorded(item.id, source: .traveller) {
                        Hairline()
                        feedback
                    }
                }
                .padding(14)
                .cardSurface(corner: 20)
            }
            .task { await twinStore.refresh(trip) }
        } else {
            Color.clear.frame(height: 0)
                .task { await twinStore.refresh(trip) }
        }
    }

    private func conditions(_ hour: WeatherHour, node: TwinNode) -> some View {
        let isDay = (6...18).contains(Calendar.current.component(.hour, from: hour.time))
        return HStack(spacing: 14) {
            Image(systemName: hour.condition.symbol(isDay: isDay))
                .font(.system(size: 28))
                .symbolRenderingMode(.multicolor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(TwinFormat.temperature(hour.temperature)) · \(hour.condition.label)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(caption(hour))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Label(node.exposure.label, systemImage: node.exposure.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                Text(hour.basis == .forecast ? "Forecast" : hour.basis == .observed ? "Observed" : "Typical for the season")
                    .font(.system(size: 10.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
    }

    private func caption(_ hour: WeatherHour) -> String {
        var parts = ["\(TwinFormat.rain(hour.precipitation)) mm rain"]
        if let probability = hour.probability { parts.append("\(Int(probability))% chance") }
        parts.append("\(Int((hour.gusts ?? hour.windSpeed).rounded())) km/h gusts")
        return parts.joined(separator: " · ")
    }

    private func assessment(_ outcome: NodeOutcome, node: TwinNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(outcome.risk.label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(outcome.risk.tint)
                Spacer()
                RiskPill(risk: outcome.risk, probability: outcome.pAffected)
            }
            UncertaintyBar(
                probability: outcome.pAffected,
                spread: min(outcome.spread.lowerBound, outcome.pAffected)...max(outcome.spread.upperBound, outcome.pAffected),
                tint: outcome.risk.tint
            )
            if outcome.order > 1, let cause = outcome.causedBy.flatMap({ twinStore.state(for: trip.id)?.twin?.node($0) }) {
                Text("At risk because of \(cause.item.title), not its own weather.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
            } else if let driver = outcome.drivers.first {
                Text("Mostly \(driver.label.lowercased()): \(driver.value).")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
        }
    }

    private var feedback: some View {
        HStack(spacing: 10) {
            Text(answered ? "Thanks — the twin has learned from this." : "Did the weather affect this?")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            if !answered {
                answer("Yes", disrupted: true)
                answer("No", disrupted: false)
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(AppTheme.positive)
            }
        }
        .animation(.snappy, value: answered)
    }

    private func answer(_ title: String, disrupted: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            twinStore.recordAnswer(disrupted, for: item, in: trip)
            answered = true
        } label: {
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.accent.opacity(0.1), in: .capsule)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
