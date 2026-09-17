//
//  EventDetailView.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// One booking: what it is, when, what it costs you — and for a flight, the
/// route, terminal and gate laid out like the pass, which is what a wrist is
/// for at an airport.
struct EventDetailView: View {
    let event: EquitripSnapshot.Event

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                header

                if event.routeLabel != nil || event.flightNumber != nil {
                    flightCard
                }

                facts
            }
        }
        .watchPageTint(event.tint)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            SymbolBadge(symbol: event.symbol, tint: event.tint)

            Text(event.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)

            if let vendor = event.vendor {
                Text(vendor)
                    .font(.footnote)
                    .foregroundStyle(Brand.inkSecondary)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: Flight

    private var flightCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Eyebrow(text: event.flightNumber ?? "Flight", tint: event.tint)
                Spacer()
                Image(systemName: "airplane")
                    .font(.caption)
                    .foregroundStyle(event.tint)
            }

            if let route = event.routeLabel {
                Text(route)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            if event.terminal != nil || event.gate != nil {
                HStack(spacing: 6) {
                    if let terminal = event.terminal { chip("Terminal", terminal) }
                    if let gate = event.gate { chip("Gate", gate) }
                }
            }
        }
        .watchCard(padding: 11)
    }

    private func chip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.inkTertiary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(Brand.ink)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Facts

    private var facts: some View {
        VStack(alignment: .leading, spacing: 0) {
            fact("When", when)

            if let share = event.shareAmountLabel {
                Divider()
                fact("Your share", share, emphasis: true)
            }

            if let cost = event.costLabel {
                Divider()
                fact("Total", cost)
            }

            if let detail = event.detail, detail != event.vendor, detail != event.routeLabel {
                Divider()
                fact("Sharing", detail)
            }
        }
        .watchCard(padding: 11)
    }

    /// Label opposite value, until the text is large enough that the two
    /// would meet in the middle — then the value goes under its label.
    private func fact(_ label: String, _ value: String, emphasis: Bool = false) -> some View {
        let name = Text(label)
            .font(.caption2)
            .foregroundStyle(Brand.inkTertiary)
        let figure = Text(value)
            .font(emphasis
                  ? .system(.body, design: .rounded, weight: .bold)
                  : .footnote.weight(.semibold))
            .foregroundStyle(emphasis ? Brand.accent : Brand.ink)

        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 1) {
                    name
                    figure
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline) {
                    name
                    Spacer(minLength: 6)
                    figure.multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var when: String {
        let day = event.date.tripDayLabel
        guard let time = event.timeLabel else { return "\(day)\nAll day" }
        return "\(day)\n\(time)"
    }
}

#Preview {
    NavigationStack { EventDetailView(event: EquitripSnapshot.placeholder.upNext[1]) }
}
