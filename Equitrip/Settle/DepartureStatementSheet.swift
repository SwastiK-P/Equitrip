//
//  DepartureStatementSheet.swift
//  Equitrip
//

import SwiftUI

/// What somebody's exit came to, as agreed, kept exactly as agreed.
///
/// This is the one screen in the app that deliberately does *not* recompute.
/// Everywhere else, figures are derived live so shares always add up to the
/// cost; here they're read straight out of `TripDeparture.agreedAmounts`,
/// because the question this screen answers is "what did we shake hands on",
/// and that has a fixed answer no later edit is entitled to change.
///
/// If the live ledger and this sheet ever disagree, that's information rather
/// than a bug — something moved after the exit was closed — and the difference
/// is shown rather than hidden.
struct DepartureStatementSheet: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let departure: TripDeparture

    private var traveller: Traveller? { trip.traveller(departure.travellerID) }
    private var currency: String { trip.currencyCode }

    /// The bookings on the statement, in the order they happened. Anything
    /// deleted from the trip since is skipped — its figure stays in the total,
    /// which is what `agreedBalance` is for.
    private var entries: [(item: ItineraryItem, amount: Double, disposition: TripDeparture.Disposition)] {
        departure.agreedAmounts
            .compactMap { id, amount in
                guard let item = trip.items.first(where: { $0.id == id }) else { return nil }
                return (item, amount, departure.dispositions[id] ?? .consumed)
            }
            .sorted { Trip.chronological($0.item, $1.item) }
    }

    /// What they'd owe if the whole thing were worked out from today's
    /// bookings instead of the frozen record. Equal to `agreedBalance` unless
    /// something moved after the exit closed.
    private var liveBalance: Double {
        trip.remainingBalance(for: departure.travellerID)
    }

    private var drift: Double { liveBalance - departure.agreedBalance }
    private var hasDrifted: Bool { abs(drift) > SettlementEngine.epsilon }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let traveller { summary(traveller) }

                    if hasDrifted { driftNote }

                    if !entries.isEmpty { breakdown }

                    if !departure.note.isEmpty { note }

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Exit statement")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(trip.title)
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

    // MARK: - Summary

    private func summary(_ traveller: Traveller) -> some View {
        let balance = departure.agreedBalance
        let isYou = traveller.id == Traveller.you.id

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                TravellerAvatar(traveller: traveller, size: 46)
                    .saturation(0.15)
                    .opacity(0.75)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isYou ? "You" : traveller.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(trip.presenceLabel(traveller.id) ?? "Left the trip")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                }

                Spacer(minLength: 0)
            }

            Hairline().padding(.vertical, 14)

            Text(abs(balance) < SettlementEngine.epsilon
                 ? "SETTLED"
                 : (balance > 0 ? "THE GROUP OWES THEM" : (isYou ? "YOU OWE" : "THEY OWE")))
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(Money.format(abs(balance).rounded(), code: currency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(balance > 0 ? AppTheme.moneyIn : (balance < 0 ? AppTheme.moneyOut : AppTheme.ink))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 2)

            Text(agreedLine)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(18)
        .cardSurface(corner: 26, shadow: 14)
    }

    private var agreedLine: String {
        let when = DateFormatter.cached("d MMM").string(from: departure.respondedAt ?? departure.proposedAt)
        let by = departure.respondedByID.flatMap(trip.traveller)?.name

        if let by { return "Agreed with \(by) on \(when). This figure is frozen." }
        return "Agreed on \(when). This figure is frozen."
    }

    /// The honest disclosure when the trip has moved on since.
    private var driftNote: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadge(symbol: "arrow.triangle.2.circlepath", tint: Palette.amber, size: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("Bookings changed after this was agreed")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("Worked out from today's itinerary it would be \(Money.format(abs(liveBalance).rounded(), code: currency)) — \(Money.format(abs(drift).rounded(), code: currency)) \(drift > 0 ? "more in their favour" : "less"). The agreed figure above is the one that stands.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.amber.opacity(0.1), in: .rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(
                title: "What they carried",
                caption: Money.format(entries.reduce(0) { $0 + $1.amount }.rounded(), code: currency)
            )

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.item.id) { index, entry in
                    row(entry)
                    if index < entries.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 24)
        }
    }

    private func row(_ entry: (item: ItineraryItem, amount: Double, disposition: TripDeparture.Disposition)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadge(symbol: entry.item.symbol, tint: entry.item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.item.title.isEmpty ? entry.item.kind.label : entry.item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: entry.disposition.symbol)
                        .font(.system(size: 9, weight: .bold))
                    Text(entry.disposition.label)
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(entry.disposition.tint)

                Text(DateFormatter.cached("EEE d MMM").string(from: entry.item.date))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            Text(Money.format(entry.amount.rounded(), code: currency))
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(14)
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("NOTE")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(departure.note)
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(corner: 22)
    }
}
