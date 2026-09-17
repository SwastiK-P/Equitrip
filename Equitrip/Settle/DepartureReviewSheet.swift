//
//  DepartureReviewSheet.swift
//  Equitrip
//

import SwiftUI

/// The other side of leaving: somebody has asked to go, and this is where the
/// group answers.
///
/// It shows exactly the lines that were proposed rather than a freshly
/// computed set, because the point of a two-sided flow is that both sides are
/// looking at the same thing. Confirming freezes it; declining hands it back
/// so the two of you can talk about the booking you disagree on and try again.
struct DepartureReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tripStore) private var store

    let trip: Trip
    let departure: TripDeparture

    private var traveller: Traveller? { trip.traveller(departure.travellerID) }
    private var plan: DeparturePlan? { DeparturePlan.review(departure, in: trip) }
    private var currency: String { trip.currencyCode }
    /// You're the one who asked. You can withdraw it, but you can't wave it
    /// through — the whole feature is that leaving isn't self-certifying.
    private var isMine: Bool { departure.travellerID == Traveller.you.id }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let traveller, let plan {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summary(traveller, plan)

                        if plan.affectsOthers { impact(plan) }

                        lines(plan)

                        if !departure.note.isEmpty { note }

                        Color.clear.frame(height: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)

                if departure.isPending { footer(traveller) }
            } else {
                Spacer()
                Text("This departure is no longer on the trip.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                Spacer()
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents([.large])
        .presentationBackground { CanvasBackground() }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isMine ? "Your request to leave" : "Request to leave")
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

    private func summary(_ traveller: Traveller, _ plan: DeparturePlan) -> some View {
        let balance = plan.finalBalance
        // Read off the preview rather than the live trip: the departure isn't
        // confirmed yet, so the trip itself doesn't know they've gone. Same
        // wording as everywhere else it appears, rather than a second copy of
        // the format that can drift from it.
        let presence = plan.previewTrip.presenceLabel(traveller.id)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                TravellerAvatar(traveller: traveller, size: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isMine ? "You" : traveller.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(presence ?? "Leaving \(DateFormatter.cached("d MMM").string(from: departure.leftAt))")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                }

                Spacer(minLength: 0)
            }

            Hairline().padding(.vertical, 14)

            Text(abs(balance) < SettlementEngine.epsilon
                 ? "NOTHING OUTSTANDING"
                 : (balance > 0 ? "THE GROUP WOULD OWE THEM" : "THEY WOULD STILL OWE"))
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(Money.format(abs(balance).rounded(), code: currency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(balance > 0 ? AppTheme.moneyIn : (balance < 0 ? AppTheme.moneyOut : AppTheme.ink))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 2)

            Text("Their share of everything up to that day is unchanged. Nothing after it lands on them unless it's already paid for.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(18)
        .cardSurface(corner: 26, shadow: 14)
    }

    // MARK: - Impact

    /// What confirming would cost the people still here. The single most
    /// important thing on this screen for anyone who isn't the one leaving.
    private func impact(_ plan: DeparturePlan) -> some View {
        let each = plan.groupImpactEach

        return HStack(alignment: .top, spacing: 12) {
            SymbolBadge(
                symbol: each > 0 ? "exclamationmark.triangle.fill" : "arrow.down.circle.fill",
                tint: each > 0 ? Palette.amber : AppTheme.positive,
                size: 32
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(each > 0
                     ? "Confirming adds \(Money.format(abs(each).rounded(), code: currency)) to your share"
                     : "Confirming takes \(Money.format(abs(each).rounded(), code: currency)) off your share")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(each > 0
                     ? "A booking that costs the same whoever turns up now splits across fewer people. Decline if they should keep paying their part of it."
                     : "Bookings that cost less without them have come down in price.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (each > 0 ? Palette.amber : AppTheme.positive).opacity(0.1),
            in: .rect(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Lines

    private func lines(_ plan: DeparturePlan) -> some View {
        let all = plan.lines
        let carried = all.filter(\.isBorne)
        let dropped = all.filter { !$0.isBorne }

        return VStack(alignment: .leading, spacing: 14) {
            if !carried.isEmpty {
                group("Still charged to them", Money.format(plan.carriedTotal.rounded(), code: currency), carried)
            }
            if !dropped.isEmpty {
                group("Coming off their bill", Money.format(plan.droppedTotal.rounded(), code: currency), dropped)
            }
        }
    }

    private func group(_ title: String, _ caption: String, _ lines: [DeparturePlan.Line]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: title, caption: caption)

            VStack(spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                    DepartureSummaryRow(line: line, currency: currency)
                    if index < lines.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 24)
        }
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("THEIR NOTE")
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

    // MARK: - Answer

    @ViewBuilder
    private func footer(_ traveller: Traveller) -> some View {
        if isMine {
            // You proposed it. Withdrawing is the only move you have — see
            // `departures_respond`, which is enforced server-side too.
            VStack(spacing: 8) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    store.withdrawDeparture(departure, in: trip.id)
                    dismiss()
                } label: {
                    Text("Withdraw request")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.danger.opacity(0.12), in: .rect(cornerRadius: 18))
                }
                .buttonStyle(PressableButtonStyle())

                Text("Waiting on someone else to confirm it.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(.ultraThinMaterial)
        } else {
            VStack(spacing: 9) {
                SlideToRespond(
                    onConfirm: { respond(.confirmed) },
                    onDecline: { respond(.declined) },
                    // Nothing is being received here. Confirming an exit
                    // changes who bears what; it moves no money on its own,
                    // and the settling that follows happens in the Settle tab
                    // like any other balance.
                    confirmTitle: "Confirm exit",
                    declineTitle: "Decline",
                    accessibilityTitle: "Answer this request to leave",
                    accessibilityDetail: "Confirm the exit, or decline it and leave them on the trip"
                )

                Text("Confirming closes \(traveller.name)'s side for good.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(.ultraThinMaterial)
        }
    }

    private func respond(_ status: TripDeparture.Status) {
        store.respondToDeparture(departure, with: status, in: trip.id)
        dismiss()
    }
}

// MARK: - Read-only line

/// The same booking row as the leave sheet's, without the switch. Reviewing is
/// a yes-or-no on the whole proposal, not a chance to quietly edit somebody
/// else's terms — if a line is wrong, the answer is decline and talk.
struct DepartureSummaryRow: View {
    let line: DeparturePlan.Line
    let currency: String

    private var item: ItineraryItem { line.item }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)
                .opacity(line.isBorne ? 1 : 0.45)
                .saturation(line.isBorne ? 1 : 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title.isEmpty ? item.kind.label : item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Image(systemName: line.disposition.symbol)
                        .font(.system(size: 9, weight: .bold))
                    Text(line.reason)
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(line.disposition.tint)

                Text(DateFormatter.cached("EEE d MMM").string(from: item.date))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.inkTertiary)

                if !line.isBorne, line.othersDelta > 0 {
                    Text("+\(Money.format(line.othersDelta.rounded(), code: currency)) each for everyone else")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.amber)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 6)

            Text(Money.format(line.amount.rounded(), code: currency))
                .font(.system(size: 14.5, weight: .bold, design: .rounded))
                .foregroundStyle(line.isBorne ? AppTheme.ink : AppTheme.inkTertiary)
                .strikethrough(!line.isBorne, color: AppTheme.inkTertiary)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(14)
    }
}
