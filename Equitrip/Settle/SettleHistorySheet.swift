//
//  SettleHistorySheet.swift
//  Equitrip
//

import SwiftUI

/// Everywhere the group has already squared up — filed here once a trip has
/// nothing left to act on, so the live "By trip" list stays about what still
/// needs a decision rather than re-announcing old news.
struct SettleHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    let trips: [Trip]

    private var sortedTrips: [Trip] {
        trips.sorted { ($0.settlements.map(\.createdAt).max() ?? .distantPast)
            > ($1.settlements.map(\.createdAt).max() ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if trips.isEmpty {
                empty
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(sortedTrips) { trip in
                            HistoryRow(trip: trip)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background { CanvasBackground() }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("History")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("\(trips.count.pluralised("trip")) settled")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppTheme.positive)

            Text("Nothing settled yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Row

private struct HistoryRow: View {
    let trip: Trip

    private var lastMovement: Date? { trip.settlements.map(\.createdAt).max() }
    private var confirmedTotal: Double {
        trip.settlements.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        HStack(spacing: 12) {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(width: 38, height: 38)
            .clipShape(.rect(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text(trip.dateRange)
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.positive)
                    Text("Settled")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                }

                if confirmedTotal > 0 {
                    Text(Money.format(confirmedTotal, code: trip.currencyCode))
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else if let lastMovement {
                    Text(lastMovement, style: .date)
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .padding(14)
        .cardSurface(corner: 20)
    }
}

#Preview {
    SettleHistorySheet(trips: [])
        .environment(\.tripStore, TripStore())
}
