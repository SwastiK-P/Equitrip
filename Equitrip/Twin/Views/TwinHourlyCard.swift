//
//  TwinHourlyCard.swift
//  Equitrip
//

import SwiftUI

/// The next day of weather in eight three-hour steps, with the trip's
/// bookings under the steps they start in.
///
/// Eight columns because eight fit a phone's width: the hourly strip it
/// replaced scrolled sideways through 24 columns, so most of the day — and
/// most of the bookings on it — sat off the edge where nobody looked.
struct TwinHourlyCard: View {
    let hours: [WeatherHour]
    var bookings: [TwinNode] = []

    private static let step = 3

    private var slots: [WeatherHour] {
        stride(from: 0, to: min(hours.count, 24), by: Self.step).map { hours[$0] }
    }

    var body: some View {
        let marks = hasBookings
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.element.time) { index, hour in
                column(hour, isNow: index == 0, marks: marks)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .cardSurface(corner: 22)
    }

    /// Whether any booking starts in the next day at all; the marker row
    /// only takes space when it has something to show.
    private var hasBookings: Bool {
        guard let first = slots.first?.time else { return false }
        let window = DateInterval(start: first, duration: Double(slots.count * Self.step) * 3600)
        return bookings.contains { $0.item.time.map(window.contains) ?? false }
    }

    private func column(_ hour: WeatherHour, isNow: Bool, marks: Bool) -> some View {
        let isDay = (6...18).contains(Calendar.current.component(.hour, from: hour.time))
        let window = DateInterval(start: hour.time, duration: Double(Self.step) * 3600)
        let booking = bookings.first { node in
            node.item.time.map { window.contains($0) } ?? false
        }
        let chance = hour.probability ?? 0

        return VStack(spacing: 8) {
            Text(isNow ? "Now" : DateFormatter.cached("h a").string(from: hour.time))
                .font(.system(size: 11.5, weight: isNow ? .bold : .medium))
                .foregroundStyle(isNow ? AppTheme.ink : AppTheme.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            WeatherGlyph(condition: hour.condition, isDay: isDay, size: 18)
                .frame(height: 22)

            Text(TwinFormat.temperature(hour.temperature))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .monospacedDigit()

            Text(chance >= 20 ? "\(Int(chance))%" : " ")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.blue)

            if marks {
                ZStack {
                    if let booking {
                    Image(systemName: booking.item.symbol)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(booking.item.kind.tint, in: .circle)
                        .accessibilityLabel(booking.item.title)
                    }
                }
                .frame(height: 18)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
