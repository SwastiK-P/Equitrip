//
//  TimelineWidget.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

/// What happens next on the trip you're on.
///
/// The balance widget answers "where do I stand"; this one answers "what am I
/// doing", which is the question a trip actually gets opened for while it's
/// running. It borrows the timeline's own furniture — the clock gutter, the
/// rail, the tinted glyph — so the widget and the screen it links to read as
/// the same object rather than two summaries of one.
struct TimelineWidget: Widget {
    static let kind = "EquitripTimeline"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind, intent: SelectTripIntent.self, provider: TripTimelineProvider()) { entry in
            TimelineWidgetView(trip: entry.trip, events: entry.events, hasTrips: entry.hasTrips)
        }
        .configurationDisplayName("Up next")
        .description("The next few things on your trip, with what each one costs you.")
        .supportedFamilies([.systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct TimelineWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let trip: EquitripSnapshot.TripSummary?
    let allEvents: [EquitripSnapshot.Event]
    var hasTrips: Bool = true

    init(trip: EquitripSnapshot.TripSummary?, events: [EquitripSnapshot.Event], hasTrips: Bool = true) {
        self.trip = trip
        self.allEvents = events
        self.hasTrips = hasTrips
    }

    /// How many rows each family has room for without the last one being cut
    /// in half. Fewer than it looks: every row carries a title, a vendor and
    /// a figure, and squeezing a fifth into the medium family costs the
    /// vendor line on all four.
    private var rowLimit: Int { family == .systemLarge ? 5 : 2 }

    private var events: [EquitripSnapshot.Event] {
        Array(allEvents.prefix(rowLimit))
    }

    private var destination: URL? {
        guard let id = trip?.id else { return URL(string: "equitrip://trips") }
        return URL(string: "equitrip://trip/\(id.uuidString)")
    }

    var body: some View {
        content.widgetCanvas()
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: rectangular
        default: system
        }
    }

    // MARK: - Home screen

    private var system: some View {
        Group {
            if let trip, !events.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    header(trip)

                    // The rail runs behind the rows rather than being drawn
                    // per row: a segment per row leaves a visible seam at
                    // every join, and the whole point of the line is that it
                    // is continuous.
                    ZStack(alignment: .topLeading) {
                        rail
                        rows
                    }
                    .padding(.top, 10)

                    if family == .systemLarge {
                        Spacer(minLength: 0)
                        footer(trip)
                    }
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    private func header(_ trip: EquitripSnapshot.TripSummary) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(trip.title)
                    .font(Brand.display(family == .systemLarge ? 19 : 16))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)

                Text(trip.progressLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Brand.inkTertiary)
            }

            Spacer(minLength: 6)

            Text("Up next")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(Brand.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Brand.accent.opacity(0.12), in: .capsule)
        }
    }

    /// Where the rail sits: hard against the right edge of the clock gutter,
    /// centred under the glyph column.
    private static let railX: CGFloat = 38 + 11

    private var rail: some View {
        Rectangle()
            .fill(Brand.cardStroke.opacity(0.13))
            .frame(width: 1.5)
            .padding(.top, 14)
            .padding(.bottom, 14)
            .offset(x: Self.railX)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rows: some View {
        VStack(spacing: family == .systemLarge ? 10 : 9) {
            ForEach(events) { event in
                EventRow(event: event, showsVendor: true)
            }
        }
    }

    /// The large family has the room to close on the money, which is the
    /// other half of what a booking means here.
    private func footer(_ trip: EquitripSnapshot.TripSummary) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(MoneyTone.of(trip.net))
                .frame(width: 6, height: 6)

            Text(trip.netLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(MoneyTone.of(trip.net))

            Text(trip.netCaption)
                .font(.system(size: 11.5))
                .foregroundStyle(Brand.inkSecondary)

            Spacer(minLength: 6)

            Text(trip.dateRange)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Brand.inkTertiary)
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Brand.cardStroke.opacity(0.08))
                .frame(height: 1)
        }
    }

    // MARK: - Lock screen

    /// One booking, because that is what the slot is: the next thing, when it
    /// is, and where. The cost is dropped — a lock screen is read at a
    /// glance, and the figure is the part that can wait for the app.
    private var rectangular: some View {
        Group {
            if let event = allEvents.first {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: event.symbol)
                            .font(.system(size: 10, weight: .bold))
                        Text(clockLabel(event) ?? "All day")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .widgetAccentable()

                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)

                    Text(event.vendor ?? trip?.title ?? "")
                        .font(.system(size: 11.5))
                        .opacity(0.7)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Nothing booked")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add something in Equitrip")
                        .font(.system(size: 11.5))
                        .opacity(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    private func clockLabel(_ event: EquitripSnapshot.Event) -> String? {
        guard let value = event.clockValue else { return nil }
        return "\(value) \(event.clockMeridiem ?? "")".trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Empty

    private var emptyState: some View {
        WidgetEmptyState(
            symbol: "calendar",
            title: hasTrips ? "Nothing booked" : "No trips yet",
            detail: hasTrips
                ? "Add a flight, a stay or a dinner and it'll show up here."
                : "Start a trip in Equitrip to see what's coming up."
        )
    }
}

// MARK: - Row

/// One booking on the rail: clock, dot, glyph, name, and what it costs you.
private struct EventRow: View {
    let event: EquitripSnapshot.Event
    var showsVendor: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ClockGutter(value: event.clockValue, meridiem: event.clockMeridiem)

            // The dot sits *on* the rail, ringed in the canvas colour so the
            // line reads as passing behind it rather than stopping at it.
            Circle()
                .fill(event.tint)
                .frame(width: 8, height: 8)
                .overlay { Circle().strokeBorder(Brand.canvasTop, lineWidth: 2) }
                .frame(width: 22)

            WidgetSymbolBadge(symbol: event.symbol, tint: event.tint, size: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)

                if showsVendor, let vendor = event.vendor {
                    Text(vendor)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 8)

            Spacer(minLength: 4)

            // Your share, not the total. The total is the group's problem;
            // the widget is on your phone.
            if let share = event.shareLabel {
                Text(share)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.inkSecondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview("Medium", as: .systemMedium) {
    TimelineWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    TimelineWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    TimelineWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
