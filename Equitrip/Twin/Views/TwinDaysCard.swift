//
//  TwinDaysCard.swift
//  Equitrip
//

import SwiftUI

/// The trip's days as rows: each one's sky, its chance of rain, and where its
/// range sits among the trip's — the layout the Weather app taught everyone.
///
/// Rows rather than the scrolling strip of chips it replaced, so a week-long
/// trip is readable top to bottom without swiping. A day with a booking the
/// twin is worried about carries the risk's symbol, not an unexplained dot.
struct TwinDaysCard: View {
    let days: [WeatherDay]
    var riskByDay: [Date: RiskLevel] = [:]

    @State private var showsAll = false
    private let collapsedCount = 6

    private var visible: [WeatherDay] {
        showsAll ? days : Array(days.prefix(collapsedCount))
    }

    private var bounds: ClosedRange<Double> {
        let low = days.map(\.low).min() ?? 0
        let high = days.map(\.high).max() ?? 1
        return low...max(high, low + 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(visible.enumerated()), id: \.element.date) { index, day in
                row(day)
                if index < visible.count - 1 { Hairline() }
            }

            if days.count > collapsedCount {
                Hairline()
                Button {
                    withAnimation(.snappy) { showsAll.toggle() }
                } label: {
                    Text(showsAll ? "Show fewer" : "Show all \(days.count) days")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
    }

    private func row(_ day: WeatherDay) -> some View {
        let risk = riskByDay.first { Calendar.current.isDate($0.key, inSameDayAs: day.date) }?.value
        let chance = day.probability ?? 0

        return HStack(spacing: 10) {
            Text(label(for: day.date))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 62, alignment: .leading)
                .lineLimit(1)

            WeatherGlyph(condition: day.condition)
                .frame(width: 26)

            Text(chance >= 20 ? "\(Int(chance))%" : "")
                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.blue)
                .frame(width: 32, alignment: .leading)

            Text(TwinFormat.temperature(day.low))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.inkTertiary)
                .frame(width: 30, alignment: .trailing)

            RangeTrack(value: day.low...day.high, bounds: bounds)
                .frame(height: 5)

            Text(TwinFormat.temperature(day.high))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 30, alignment: .leading)

            Image(systemName: risk?.symbol ?? "circle")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(risk?.tint ?? .clear)
                .frame(width: 14)
                .accessibilityLabel(risk.map { $0.isNotable ? $0.label : "" } ?? "")
                .opacity(risk?.isNotable == true ? 1 : 0)
        }
        .monospacedDigit()
        .padding(.vertical, 11)
        .accessibilityElement(children: .combine)
    }

    private func label(for date: Date) -> String {
        Calendar.current.isDateInToday(date) ? "Today" : DateFormatter.cached("EEE d").string(from: date)
    }
}

/// One day's low-to-high, placed on the trip's whole range and coloured by
/// how warm it is — so a hot afternoon is visible before the number is read.
private struct RangeTrack: View {
    let value: ClosedRange<Double>
    let bounds: ClosedRange<Double>

    var body: some View {
        GeometryReader { proxy in
            let span = bounds.upperBound - bounds.lowerBound
            let start = (value.lowerBound - bounds.lowerBound) / span
            let end = (value.upperBound - bounds.lowerBound) / span
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.cardStroke.opacity(0.07))
                Capsule()
                    .fill(LinearGradient(
                        colors: [warmth(value.lowerBound), warmth(value.upperBound)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(6, proxy.size.width * (end - start)))
                    .offset(x: proxy.size.width * start)
            }
        }
    }

    private func warmth(_ celsius: Double) -> Color {
        switch celsius {
        case ..<15: Palette.teal
        case ..<25: Palette.green
        case ..<32: Palette.amber
        default: Palette.amberDeep
        }
    }
}
