//
//  TripsWidget.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

/// Every trip that's live or still to come, in one glance.
///
/// Balance answers "where do I stand" and "Up next" narrates one trip's plan;
/// neither says "what am I even on right now" when there's more than one
/// trip going at once — a family holiday overlapping a friends' weekend, or
/// next month's trip already half-planned. This is Home's trip list, reduced
/// to what a widget can draw without a photo.
struct TripsWidget: Widget {
    static let kind = "EquitripTrips"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            TripsWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Trips")
        .description("Your live and upcoming trips, with where you stand on each.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TripsWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let snapshot: EquitripSnapshot

    /// Live first — the one somebody's most likely mid-way through — then
    /// whichever starts soonest, so the list reads as a queue rather than the
    /// order sync happened to return.
    private var trips: [EquitripSnapshot.TripSummary] {
        snapshot.allTrips.sorted { lhs, rhs in
            if lhs.phase != rhs.phase { return lhs.phase == .live }
            return (lhs.startDate ?? .distantFuture) < (rhs.startDate ?? .distantFuture)
        }
    }

    private var destination: URL? { URL(string: "equitrip://trips") }

    var body: some View {
        Group {
            if snapshot.hasTrips, let lead = trips.first {
                if family == .systemLarge { large(lead: lead) } else { medium }
            } else {
                WidgetEmptyState(
                    symbol: "suitcase.fill",
                    title: "No trips yet",
                    detail: "Start a trip in Equitrip and it'll show up here."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // The fallback tap target. Rows carry their own `Link`, so this only
        // catches the header and the gaps between them.
        .widgetURL(destination)
        .widgetCanvas()
    }

    private var header: some View {
        ScopeLine(
            title: "Trips",
            symbol: "suitcase.fill",
            trailing: trips.count == 1 ? "1 active" : "\(trips.count) active"
        )
    }

    // MARK: - Medium

    /// Two rows, separated by a hairline and spread to fill the tile — hung
    /// from the top they left a strip of empty gradient under the second.
    private var medium: some View {
        let shown = Array(trips.prefix(2))

        return VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 8)

            ForEach(Array(shown.enumerated()), id: \.element.id) { index, trip in
                TripRow(trip: trip)

                if index < shown.count - 1 {
                    WidgetHairline()
                        .padding(.leading, 48)
                        .padding(.vertical, 9)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Large

    /// The lead trip as a card with room for its progress and the balance at
    /// full size; the rest queue underneath. With nothing else planned, the
    /// space goes to what's next on the lead trip instead of standing empty.
    private func large(lead: EquitripSnapshot.TripSummary) -> some View {
        let others = Array(trips.dropFirst().prefix(2))
        let events = Array(leadEvents(lead).prefix(3))

        return VStack(alignment: .leading, spacing: 0) {
            header

            FeaturedTripCard(trip: lead)
                .padding(.top, 10)

            if !others.isEmpty {
                sectionLabel("Also coming up")

                VStack(spacing: 0) {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, trip in
                        TripRow(trip: trip)

                        if index < others.count - 1 {
                            WidgetHairline()
                                .padding(.leading, 48)
                                .padding(.vertical, 8)
                        }
                    }
                }
            } else if !events.isEmpty {
                sectionLabel("Next on \(lead.title)")

                VStack(spacing: 8) {
                    ForEach(events) { event in
                        HStack(spacing: 8) {
                            ClockGutter(value: event.clockValue, meridiem: event.clockMeridiem)
                            WidgetSymbolBadge(symbol: event.symbol, tint: event.tint, size: 26)
                            Text(event.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Brand.ink)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            if let share = event.shareAmountLabel {
                                Text(share)
                                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Brand.inkSecondary)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func leadEvents(_ trip: EquitripSnapshot.TripSummary) -> [EquitripSnapshot.Event] {
        if let events = snapshot.eventsByTrip[trip.id] { return events }
        return trip.id == snapshot.currentTrip?.id ? snapshot.upNext : []
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9.5, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(Brand.inkTertiary)
            .lineLimit(1)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }
}

// MARK: - Phase styling

private extension EquitripSnapshot.TripSummary {
    /// Indigo for under way, teal for still to come. Upcoming used to be
    /// stone, which on the peach canvas read as a disabled row.
    var tint: Color { phase == .live ? Brand.accent : Brand.teal }

    var badgeSymbol: String { symbol ?? "airplane.departure" }

    var link: URL {
        URL(string: "equitrip://trip/\(id.uuidString)") ?? URL(string: "equitrip://trips")!
    }

    /// The same swap `CurrentTripCard` makes: before anyone has paid for
    /// anything, "Settled" is a claim the trip hasn't earned, so the figure
    /// is what the trip will cost you instead.
    var figure: (value: String, caption: String, tone: Color) {
        showsBalance ?? true
            ? (netLabel, netCaption, MoneyTone.of(net))
            : (yourShareLabel ?? netLabel, "your share", Brand.ink)
    }
}

/// "Live" as a small tinted pill beside a trip's name.
private struct LiveChip: View {
    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .frame(width: 4.5, height: 4.5)
            Text("Live")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(Brand.accent)
        .padding(.horizontal, 6)
        .padding(.vertical, 2.5)
        .background(Brand.accent.opacity(0.13), in: .capsule)
    }
}

// MARK: - Row

/// One trip: its badge, name and stage, and where you stand on it.
///
/// Its own `Link`, so a tile with several trips opens the one that was
/// tapped rather than always the first.
private struct TripRow: View {
    let trip: EquitripSnapshot.TripSummary

    var body: some View {
        Link(destination: trip.link) {
            HStack(spacing: 11) {
                WidgetSymbolBadge(symbol: trip.badgeSymbol, tint: trip.tint, size: 37)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(trip.title)
                            .font(Brand.display(15))
                            .foregroundStyle(Brand.ink)
                            .lineLimit(1)

                        if trip.phase == .live { LiveChip() }
                    }

                    // A live trip shows how far in, drawn; an upcoming one
                    // has nothing to fill yet, so it gets its dates instead.
                    if trip.phase == .live {
                        HStack(spacing: 7) {
                            Text(trip.progressLabel)
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundStyle(Brand.inkSecondary)
                                .fixedSize()
                            DayTrack(progress: trip.progress, days: trip.dayCount ?? 1, height: 4)
                                .frame(maxWidth: 72)
                        }
                    } else {
                        Text("\(trip.dateRange) · \(trip.progressLabel)")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Brand.inkTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(trip.figure.value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.figure.tone)
                    Text(trip.figure.caption)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Brand.inkTertiary)
                }
                .lineLimit(1)
                .fixedSize()
            }
            .contentShape(.rect)
        }
    }
}

// MARK: - Featured card

/// The lead trip at the size Home gives it: name in the display face, the
/// day track across the full width, and the balance as the largest figure.
private struct FeaturedTripCard: View {
    let trip: EquitripSnapshot.TripSummary

    var body: some View {
        Link(destination: trip.link) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    WidgetSymbolBadge(symbol: trip.badgeSymbol, tint: trip.tint, size: 46)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(trip.title)
                                .font(Brand.display(21))
                                .foregroundStyle(Brand.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            if trip.phase == .live { LiveChip() }
                        }
                        Text("\(trip.destination) · \(trip.dateRange)")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Brand.inkSecondary)
                            .lineLimit(1)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(trip.phase == .live ? trip.progressLabel : "Starts \(trip.progressLabel.lowercased())")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                        Spacer(minLength: 6)
                        if let travellers = trip.travellerCount {
                            Label("\(travellers)", systemImage: "person.2.fill")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundStyle(Brand.inkTertiary)
                                .labelStyle(TightLabel())
                        }
                    }
                    DayTrack(
                        progress: trip.phase == .live ? trip.progress : 0,
                        days: trip.dayCount ?? 1,
                        tint: trip.tint,
                        height: 6
                    )
                }

                WidgetHairline()

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(trip.figure.value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.figure.tone)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(trip.figure.caption)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Brand.inkTertiary)
                }
            }
            .padding(14)
            .background(Brand.card.opacity(0.78), in: .rect(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Brand.cardStroke.opacity(0.06))
            }
        }
    }
}

private struct TightLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - Previews

private var singleTripSnapshot: EquitripSnapshot {
    var snapshot = EquitripSnapshot.placeholder
    snapshot.allTrips = Array(snapshot.allTrips.prefix(1))
    return snapshot
}

#Preview("Medium", as: .systemMedium) {
    TripsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview("Large", as: .systemLarge) {
    TripsWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: singleTripSnapshot)
}
