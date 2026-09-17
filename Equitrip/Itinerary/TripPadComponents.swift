//
//  TripPadComponents.swift
//  Equitrip
//

import SwiftUI

// The pieces the full-width iPad trip screen is built from: the trip sheet's
// tiles and rows, the plan's pill tabs, and the cost bar floating over the
// timeline.

// MARK: - Fact tile

/// One figure about the trip, in a quiet filled tile — duration, people,
/// bookings, where you stand.
///
/// Filled rather than carded: these sit inside the trip sheet, which is
/// already a surface, and a card on a card reads as a second layer of
/// navigation rather than as a label and a number.
struct TripFactTile: View {
    let symbol: String
    let label: String
    let value: String
    var valueTint: Color = AppTheme.ink
    /// Trailing decoration beside the value — the avatar stack on the people
    /// tile, which says more than the count does.
    var accessory: AnyView?
    var action: (() -> Void)?

    var body: some View {
        Button {
            guard let action else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .semibold))
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }
                .foregroundStyle(AppTheme.inkSecondary)

                HStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(valueTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: 0)

                    accessory
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 18, style: .continuous))
            .contentShape(.rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Summary row

/// A label on the left, its answer on the right. The trip sheet's small print.
struct TripSummaryRow: View {
    let symbol: String
    let label: String
    let value: String
    var valueTint: Color = AppTheme.ink

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(valueTint)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Cost bar

/// The trip's money, floating at the foot of the plan with the one thing you'd
/// do about it.
///
/// Pinned rather than scrolled, because it's the figure every booking above it
/// is moving — reading a day's bookings with the total out of sight is reading
/// half the answer. Deliberately no blur or edge fade behind it: it's a card
/// sitting over the list, not a bar the list dissolves into — Liquid Glass, so
/// the timeline stays faintly visible as it passes underneath.
struct TripCostBar: View {
    let trip: Trip
    var actionTitle: String
    var actionSymbol: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            figure(trip.projectedLabel, caption: "Projected · \(trip.travellers.count.pluralised("traveller"))")

            Rectangle()
                .fill(AppTheme.cardStroke.opacity(0.1))
                .frame(width: 1, height: 32)

            if trip.showsBalance {
                figure(trip.netLabel, caption: trip.netCaption.capitalizedFirst, tint: trip.netTone)
            } else {
                figure(Money.format(trip.yourShare.rounded(), code: trip.currencyCode), caption: "Your share")
            }

            Spacer(minLength: 12)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                action()
            } label: {
                Label(actionTitle, systemImage: actionSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ctaLabel)
                    .padding(.horizontal, 20)
                    .frame(height: 46)
                    .background(AppTheme.cta, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(.leading, 22)
        .padding(.trailing, 10)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
    }

    private func figure(_ value: String, caption: String, tint: Color = AppTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(caption)
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineLimit(1)
        }
        .fixedSize()
    }
}

// MARK: - Support

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
