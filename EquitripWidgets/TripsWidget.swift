//
//  TripsWidget.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

/// The one trip that matters right now — the one under way, or else the next
/// to start — drawn the way Home's trip card is: its cover photo filling the
/// tile, the name in the display face over it, and where you stand on a
/// frosted bar along the bottom.
///
/// It used to be a list: a suitcase glyph per trip on the peach canvas, which
/// read as a settings row, not a trip. A home-screen widget is glanced at, and
/// the glance is "what am I on next and what's it costing me" — one trip
/// answers that; a queue doesn't.
struct TripsWidget: Widget {
    static let kind = "EquitripTrips"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            TripsWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Trip")
        .description("Your trip under way, or the next one, with your share.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct TripsWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let snapshot: EquitripSnapshot

    /// Live first; otherwise whichever upcoming trip starts soonest. Past
    /// trips never lead — a finished trip isn't what a glance is for.
    private var trip: EquitripSnapshot.TripSummary? {
        snapshot.allTrips
            .filter { $0.phase != .past }
            .sorted { lhs, rhs in
                if lhs.phase != rhs.phase { return lhs.phase == .live }
                return (lhs.startDate ?? .distantFuture) < (rhs.startDate ?? .distantFuture)
            }
            .first
    }

    var body: some View {
        if let trip {
            TripHeroCard(trip: trip, isLarge: family == .systemLarge)
                .widgetURL(trip.link)
                .containerBackground(for: .widget) { TripHeroBackground(trip: trip) }
        } else {
            WidgetEmptyState(
                symbol: "suitcase.fill",
                title: "No trip coming up",
                detail: "Start a trip in Equitrip and it'll show up here."
            )
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetURL(URL(string: "equitrip://trips"))
            .widgetCanvas()
        }
    }
}

// MARK: - Background

/// The cover photo, darkened towards the bottom so white type stays legible
/// on any picture. Without a cover, a deep gradient in the trip's colour.
private struct TripHeroBackground: View {
    let trip: EquitripSnapshot.TripSummary

    var body: some View {
        ZStack {
            if let image = sharedImage(SharedImages.wideCoverKey(trip.id)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [trip.tint.mix(with: .black, by: 0.35), trip.tint.mix(with: .black, by: 0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: trip.badgeSymbol)
                    .font(.system(size: 120, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.07))
                    .offset(x: 90, y: -20)
            }
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.25), location: 0),
                    .init(color: .clear, location: 0.3),
                    .init(color: .black.opacity(0.35), location: 0.6),
                    .init(color: .black.opacity(0.75), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Card

private struct TripHeroCard: View {
    let trip: EquitripSnapshot.TripSummary
    let isLarge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                PhasePill(trip: trip)
                Spacer(minLength: 6)
                FaceStack(ids: trip.travellerIDs ?? [], total: trip.travellerCount ?? 0)
            }

            Spacer(minLength: 6)

            if isLarge {
                titleBlock
                statusBar.padding(.top, 12)
            } else {
                HStack(alignment: .bottom, spacing: 10) {
                    titleBlock
                    Spacer(minLength: 6)
                    figure(size: 19)
                }
            }
        }
        .padding(isLarge ? 16 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(trip.title)
                .font(Brand.display(isLarge ? 32 : 24))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: isLarge ? 13 : 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
        }
        .shadow(color: .black.opacity(0.3), radius: 6, y: 1)
    }

    /// "28 Sep–1 Oct · 22 bookings · ₹1,45,520" on large, dates and
    /// bookings on medium where the figure sits beside it.
    private var subtitle: String {
        var parts = [trip.dateRange]
        if let bookings = trip.bookingLabel { parts.append(bookings) }
        if isLarge, let projected = trip.projectedLabel { parts.append(projected) }
        return parts.joined(separator: " · ")
    }

    private func figure(size: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(trip.figure.value)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(trip.figure.caption)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .lineLimit(1)
        .fixedSize()
        .shadow(color: .black.opacity(0.3), radius: 6, y: 1)
    }

    /// Frosted strip: how far in (or when it starts) as the day track, and
    /// the figure. Widgets can't blur what's behind them, so the frost is a
    /// translucent white over the already-darkened photo.
    private var statusBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.phase == .live ? trip.progressLabel : "Starts \(trip.progressLabel.lowercased())")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                DayTrack(
                    progress: trip.phase == .live ? trip.progress : 0,
                    days: trip.dayCount ?? 1,
                    tint: .white,
                    height: 5,
                    track: .white.opacity(0.22)
                )
            }

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 34)

            figure(size: 22)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.white.opacity(0.16), in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

/// "● Live" / "● Upcoming" on a dark translucent capsule, readable on any photo.
private struct PhasePill: View {
    let trip: EquitripSnapshot.TripSummary

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(trip.phase == .live ? Brand.green : Brand.accent)
                .frame(width: 6, height: 6)
            Text(trip.phase == .live ? "Live" : "Upcoming")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.black.opacity(0.28), in: .capsule)
        .overlay { Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1) }
    }
}

/// The first three people on the trip, overlapping, with a white ring.
private struct FaceStack: View {
    let ids: [UUID]
    let total: Int
    private let size: CGFloat = 26

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(ids.prefix(3), id: \.self) { id in
                Group {
                    if let image = sharedImage(SharedImages.faceKey(id)) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Circle().fill(.white.opacity(0.3))
                    }
                }
                .frame(width: size, height: size)
                .clipShape(.circle)
                .overlay { Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5) }
            }
            if total > 3 {
                Text("+\(total - 3)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(.black.opacity(0.4), in: .circle)
                    .overlay { Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1.5) }
            }
        }
    }
}

// MARK: - Phase styling

private extension EquitripSnapshot.TripSummary {
    var tint: Color { phase == .live ? Brand.accent : Brand.teal }

    var badgeSymbol: String { symbol ?? "airplane.departure" }

    var link: URL {
        URL(string: "equitrip://trip/\(id.uuidString)") ?? URL(string: "equitrip://trips")!
    }

    /// Before anyone has paid for anything, "Settled" is a claim the trip
    /// hasn't earned, so the figure is what the trip will cost you instead.
    var figure: (value: String, caption: String) {
        showsBalance ?? true
            ? (netLabel, netCaption)
            : (yourShareLabel ?? netLabel, "your share")
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
