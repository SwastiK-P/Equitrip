//
//  SettleWidget.swift
//  EquitripWidgets
//

import SwiftUI
import WidgetKit

/// Who's paid you and is waiting on a confirmation.
///
/// Balance answers "where do I stand" in the abstract; this answers the more
/// urgent question — "is somebody sitting there wondering why I haven't
/// tapped Confirm". It's the same list Home's pending-settlements card shows,
/// reduced to a glance: the people, the money, and how many are waiting.
struct SettleWidget: Widget {
    static let kind = "EquitripSettle"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            SettleWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Settle")
        .description("Payments waiting on you to confirm.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct SettleWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let snapshot: EquitripSnapshot

    /// `nil` on a snapshot published before this field existed — treated the
    /// same as "none waiting", since the widget has nothing truer to say.
    private var requests: [EquitripSnapshot.SettleRequest] { snapshot.settleRequests ?? [] }

    private var destination: URL? { URL(string: "equitrip://settle") }

    var body: some View {
        content.widgetCanvas()
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    private var countLabel: String {
        requests.count == 1 ? "1 to confirm" : "\(requests.count) to confirm"
    }

    // MARK: - Small

    /// The faces waiting, then the money at the front of the queue. A bare
    /// count read as a notification badge with nothing behind it; the amount
    /// is what someone actually checks against their bank app.
    private var small: some View {
        Group {
            if !snapshot.hasTrips {
                emptyState
            } else if let first = requests.first {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        ScopeLine(title: "Settle", symbol: "bell.badge.fill")
                        Spacer(minLength: 4)
                        CountBadge(count: requests.count)
                    }

                    Spacer(minLength: 8)

                    AvatarStack(names: requests.map(\.fromName), size: 30)

                    Text(first.amountLabel)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Brand.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.top, 9)

                    Text("from \(first.fromName) · \(first.methodLabel)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    Text(requests.count > 1 ? "+\(requests.count - 1) more waiting" : first.tripTitle)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(requests.count > 1 ? Brand.accent : Brand.inkTertiary)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ScopeLine(title: "Settle", symbol: "bell.badge.fill")
                    Spacer(minLength: 6)
                    settledSeal(size: 40)
                    Text("All settled")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Brand.ink)
                        .padding(.top, 10)
                    Text("Nobody's waiting on you.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(2)
                        .padding(.top, 1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    // MARK: - Medium

    /// Count on the left, people on the right — the balance widget's split,
    /// so the two sit side by side on a home screen as one family. The list
    /// is centred against the count rather than hung from the top, which left
    /// the lower third of the tile empty whenever fewer than three were
    /// waiting.
    private var medium: some View {
        Group {
            if !snapshot.hasTrips {
                emptyState
            } else if requests.isEmpty {
                HStack(spacing: 14) {
                    settledSeal(size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        ScopeLine(title: "Settle", symbol: "bell.badge.fill")
                        Text("All settled")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                            .padding(.top, 4)
                        Text("Nobody's waiting on you to confirm a payment.")
                            .font(.system(size: 12))
                            .foregroundStyle(Brand.inkSecondary)
                            .lineLimit(2)
                    }
                }
            } else {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ScopeLine(title: "Settle", symbol: "bell.badge.fill")

                        Spacer(minLength: 4)

                        Text("\(requests.count)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Brand.accent)
                            .contentTransition(.numericText())

                        Text(requests.count == 1 ? "payment to confirm" : "payments to confirm")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Brand.inkSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Text("Review")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Brand.ctaLabel)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Brand.cta, in: .capsule)
                    }
                    .frame(width: 92, alignment: .leading)

                    Rectangle()
                        .fill(Brand.cardStroke.opacity(0.10))
                        .frame(width: 1)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 14)

                    requestList
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    private var requestList: some View {
        let shown = Array(requests.prefix(3))

        return VStack(spacing: 0) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, request in
                SettleRow(request: request)

                if index < shown.count - 1 {
                    WidgetHairline()
                        .padding(.leading, 38)
                        .padding(.vertical, 7)
                }
            }

            if requests.count > shown.count {
                Text("+\(requests.count - shown.count) more")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Brand.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 38)
                    .padding(.top, 5)
            }
        }
    }

    // MARK: - Lock screen

    private var rectangular: some View {
        Group {
            if let first = requests.first {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(countLabel)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .widgetAccentable()

                    Text("\(first.fromName) · \(first.amountLabel)")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)

                    Text(first.tripTitle)
                        .font(.system(size: 11))
                        .opacity(0.7)
                        .lineLimit(1)
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("All settled")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .widgetAccentable()

                    Text(snapshot.hasTrips ? "Nothing waiting on you" : "No trips yet")
                        .font(.system(size: 11.5))
                        .opacity(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(destination)
    }

    private var inline: some View {
        Label(
            requests.isEmpty ? "All settled" : countLabel,
            systemImage: requests.isEmpty ? "checkmark.seal.fill" : "bell.badge.fill"
        )
        .widgetURL(destination)
    }

    // MARK: - Settled / empty

    /// The good outcome gets its own mark in `Brand.positive`, not the muted
    /// glyph `WidgetEmptyState` draws for "nothing here yet".
    private func settledSeal(size: CGFloat) -> some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(Brand.positive)
            .frame(width: size, height: size)
            .background(Brand.positive.opacity(0.13), in: .circle)
    }

    private var emptyState: some View {
        WidgetEmptyState(
            symbol: "suitcase.fill",
            title: "No trips yet",
            detail: "Payments waiting on your confirmation will show up here."
        )
    }
}

// MARK: - Pieces

/// One settlement to confirm: who, where and how, and the figure to check.
private struct SettleRow: View {
    let request: EquitripSnapshot.SettleRequest

    var body: some View {
        HStack(spacing: 10) {
            InitialAvatar(name: request.fromName, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(request.fromName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(1)
                // The method as its glyph, the trip spelled out — both in
                // words ran past the column and ended every row in "Goa Re…".
                HStack(spacing: 3) {
                    Image(systemName: request.methodSymbol)
                        .font(.system(size: 8.5, weight: .semibold))
                    Text(request.tripTitle)
                        .lineLimit(1)
                }
                .font(.system(size: 10))
                .foregroundStyle(Brand.inkTertiary)
            }

            Spacer(minLength: 4)

            Text(request.amountLabel)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(Brand.accent)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

/// Up to three overlapping faces, then a "+n" disc for the rest.
private struct AvatarStack: View {
    let names: [String]
    var size: CGFloat = 28

    private static let visible = 3

    var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(Array(names.prefix(Self.visible).enumerated()), id: \.offset) { _, name in
                InitialAvatar(name: name, size: size, ringed: true)
            }

            if names.count > Self.visible {
                Text("+\(names.count - Self.visible)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(Brand.inkSecondary)
                    .frame(width: size, height: size)
                    .background(Brand.card, in: .circle)
                    .overlay { Circle().strokeBorder(Brand.canvasTop, lineWidth: 2) }
            }
        }
    }
}

/// How many are waiting, as a filled pill beside the header.
private struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            // `card` rather than white: in dark mode the accent lightens and
            // white on it loses its contrast.
            .foregroundStyle(Brand.card)
            .padding(.horizontal, count > 9 ? 5 : 0)
            .frame(minWidth: 18, minHeight: 18)
            .background(Brand.accent, in: .capsule)
    }
}

// MARK: - Previews

private var settledSnapshot: EquitripSnapshot {
    var snapshot = EquitripSnapshot.placeholder
    snapshot.settleRequests = []
    return snapshot
}

#Preview("Small", as: .systemSmall) {
    SettleWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: settledSnapshot)
    SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview("Medium", as: .systemMedium) {
    SettleWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: settledSnapshot)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    SettleWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}
