//
//  BalanceWidget.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

/// Where you stand, on the home screen and the lock screen.
///
/// The app's whole reason to exist is one number and its two halves, so the
/// widget leads with the number and lets the halves explain it — the same
/// hierarchy as Home's balance card, minus the trip picker and the settle
/// button, neither of which a widget can honestly offer.
struct BalanceWidget: Widget {
    static let kind = "EquitripBalance"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            BalanceWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Balance")
        .description("What you're owed and what you owe, across your trips.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryRectangular, .accessoryCircular, .accessoryInline
        ])
    }
}

struct BalanceWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let snapshot: EquitripSnapshot

    var body: some View {
        content.widgetCanvas()
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    private var tone: Color { MoneyTone.of(snapshot.net) }

    /// Tapping the balance lands on Settle — the balance is a question, and
    /// that tab is the only screen that answers it.
    private var destination: URL? { URL(string: "equitrip://settle") }

    // MARK: - Small

    /// Header, figure, caption, bar, halves. Nothing else fits at 158pt
    /// without one of them becoming unreadable, and the bar is what makes the
    /// two halves legible at a glance rather than something to be compared
    /// digit by digit.
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            if snapshot.hasTrips {
                ScopeLine(title: snapshot.scopeTitle ?? "All trips")

                Spacer(minLength: 6)

                Text(snapshot.netLabel)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(tone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())

                Text(snapshot.netCaption)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Brand.inkSecondary)
                    .padding(.top, 1)

                Spacer(minLength: 8)

                SplitBar(fraction: snapshot.owedFraction, cells: 14, height: 8)

                HStack(spacing: 8) {
                    DottedFigure(
                        label: "Owed",
                        value: snapshot.owedToYouLabel,
                        dot: Brand.accent,
                        compact: true
                    )
                    DottedFigure(
                        label: "You owe",
                        value: snapshot.youOweLabel,
                        dot: Brand.danger,
                        compact: true
                    )
                }
                .padding(.top, 9)
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    // MARK: - Medium

    /// The figure keeps the left half to itself and the breakdown takes the
    /// right, split by a hairline. Side by side rather than stacked because
    /// the medium family is twice as wide as it is anything else, and a
    /// stacked layout here just leaves a long empty corridor beside the
    /// number.
    private var medium: some View {
        Group {
            if snapshot.hasTrips {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ScopeLine(title: snapshot.scopeTitle ?? "All trips")

                        Spacer(minLength: 6)

                        Text(snapshot.netLabel)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(tone)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text(snapshot.scopeCaption)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Brand.inkSecondary)
                            .lineLimit(2)
                            .padding(.top, 2)

                        Spacer(minLength: 8)

                        SplitBar(fraction: snapshot.owedFraction, cells: 18, height: 9)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Rectangle()
                        .fill(Brand.cardStroke.opacity(0.10))
                        .frame(width: 1)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 14) {
                        DottedFigure(
                            label: "You're owed",
                            value: snapshot.owedToYouLabel,
                            dot: Brand.accent
                        )
                        DottedFigure(
                            label: "You owe",
                            value: snapshot.youOweLabel,
                            dot: Brand.danger
                        )

                        if let trip = snapshot.currentTrip {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.title)
                                    .font(Brand.display(13))
                                    .foregroundStyle(Brand.ink)
                                    .lineLimit(1)
                                Text(trip.progressLabel)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(Brand.inkTertiary)
                            }
                        }
                    }
                    .frame(width: 118, alignment: .leading)
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    // MARK: - Lock screen

    /// Two lines and a bar. The accessory families render monochrome, so the
    /// owed/owe distinction that colour carries everywhere else has to be
    /// carried by weight and opacity instead — hence the labelled halves
    /// rather than two bare figures either side of a slash.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .bold))
                Text(snapshot.scopeTitle ?? "Equitrip")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .widgetAccentable()

            Text(snapshot.netLabel)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(snapshot.owedToYouLabel) in · \(snapshot.youOweLabel) out")
                .font(.system(size: 11, weight: .medium))
                .opacity(0.7)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    /// A ring filled by the share of the outstanding money that is owed *to*
    /// you, with the net in the middle. The ring is the honest use of a
    /// circular slot: it is a ratio, which is the one thing a circle reads
    /// better than a rectangle does.
    private var circular: some View {
        Gauge(value: snapshot.owedFraction) {
            Image(systemName: "arrow.left.arrow.right")
        } currentValueLabel: {
            Text(snapshot.netCompactLabel)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .gaugeStyle(.accessoryCircular)
        .widgetURL(destination)
    }

    private var inline: some View {
        Label(
            snapshot.hasTrips ? "\(snapshot.netLabel) \(snapshot.netCaption)" : "No trips yet",
            systemImage: "arrow.left.arrow.right"
        )
        .widgetURL(destination)
    }

    // MARK: - Empty

    private var emptyState: some View {
        WidgetEmptyState(
            symbol: "suitcase.fill",
            title: "No trips yet",
            detail: "Start a trip in Equitrip and your balance shows up here."
        )
    }
}

#Preview("Small", as: .systemSmall) {
    BalanceWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview("Medium", as: .systemMedium) {
    BalanceWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    BalanceWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

#Preview("Circular", as: .accessoryCircular) {
    BalanceWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
