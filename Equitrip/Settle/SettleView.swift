//
//  SettleView.swift
//  Equitrip
//

import SwiftUI

/// Who pays whom, minimised — and the record of what's already moved.
///
/// Three questions, in order: where do you stand overall, is anything waiting
/// on you right now, and — trip by trip — what's the fewest transfers that
/// would clear it. `SettlementEngine` does the actual optimising; this is
/// entirely about presenting its answer and collecting the two acts that
/// change it: marking something paid, and agreeing that it was.
struct SettleView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.pane) private var pane

    @State private var appeared = false
    /// One slot for both flows, not two `.sheet` modifiers on this view.
    /// SwiftUI only honours the first `sheet(item:)` stacked on a view — the
    /// same lesson `HomeView.Sheet` already learned the hard way — so
    /// settling up and reviewing a claim share this binding.
    @State private var sheet: SettleSheet?

    @State private var showHistory = false

    private enum SettleSheet: Identifiable {
        case settle(trip: Trip, toID: UUID, amount: Double)
        case review(Settlement)

        var id: String {
            switch self {
            case .settle(let trip, let toID, _): "settle-\(trip.id)-\(toID)"
            case .review(let settlement): "review-\(settlement.id)"
            }
        }
    }

    /// Trips worth showing here: money has actually moved on them, or there's
    /// a direct settlement in flight — the same bar `Trip.showsBalance` sets
    /// for the ledger, plus settlements, since a trip can be fully paid up
    /// through direct transfers with nothing left in the booking ledger at all.
    private var relevantTrips: [Trip] {
        store.trips.filter { $0.travellers.count > 1 && ($0.showsBalance || !$0.settlements.isEmpty) }
    }

    /// Still something to square up — the "By trip" list.
    private var activeTrips: [Trip] { relevantTrips.filter { !$0.isFullySettled } }

    /// Nothing left to move: filed away in History rather than left cluttering
    /// the live list once there's nothing left to act on.
    private var settledTrips: [Trip] { relevantTrips.filter { $0.isFullySettled } }

    private var awaitingYou: [(trip: Trip, settlement: Settlement)] { store.settlementsAwaitingYou }

    private var owedToYou: Double {
        relevantTrips.reduce(0) { $0 + max(0, $1.remainingBalance(for: Traveller.you.id)) }
    }

    private var youOwe: Double {
        relevantTrips.reduce(0) { $0 + max(0, -$1.remainingBalance(for: Traveller.you.id)) }
    }

    private var currency: String { relevantTrips.first?.currencyCode ?? store.primaryCurrency }

    var body: some View {
        ZStack {
            CanvasBackground()

            if pane.isWide {
                splitLayout
            } else {
                stackedLayout
            }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .settle(let trip, let toID, let amount):
                SettleUpSheet(trip: trip, toID: toID, suggestedAmount: amount)

            case .review(let settlement):
                if let trip = store.trip(settlement.tripID) {
                    SettlementReviewSheet(trip: trip, settlement: settlement)
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            SettleHistorySheet(trips: settledTrips)
        }
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Layouts

    /// The phone layout: one column, read top to bottom.
    private var stackedLayout: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: pane.spacing(24)) {
                header
                    .staggered(0, appeared)

                failureBanner

                summary
                    .staggered(1, appeared)

                if !awaitingYou.isEmpty {
                    waitingOnYouSection
                        .staggered(2, appeared)
                }

                plan
                    .staggered(3, appeared)
            }
            .gutter()
            .pageWidth()
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .refreshable { await store.sync() }
    }

    /// The iPad layout: where you stand, pinned beside what to do about it.
    ///
    /// The two halves of this screen answer different questions and are read
    /// at different speeds. The summary is a standing figure you glance at
    /// once and then keep in the corner of your eye; the per-trip plan is a
    /// list you work down, settling as you go — and every row of it changes
    /// the summary. Scrolling them together meant the number the whole screen
    /// is about slid off the top the moment you started acting on it.
    ///
    /// So the summary column doesn't scroll with the plan. It carries the
    /// claims waiting on your word too, which belong with the figures rather
    /// than at the head of a list they aren't part of, and History, which on a
    /// phone has to hide behind a glyph in the header for want of anywhere
    /// better to put it.
    private var splitLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .gutter()
                .pageWidth()
                .padding(.top, 4)
                .staggered(0, appeared)

            HStack(alignment: .top, spacing: pane.columnSpacing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: pane.spacing(24)) {
                        failureBanner

                        summary
                            .staggered(1, appeared)

                        if !awaitingYou.isEmpty {
                            waitingOnYouSection
                                .staggered(2, appeared)
                        }

                        historyCard
                            .staggered(3, appeared)
                    }
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
                .frame(width: pane.figureRailWidth)

                ScrollView {
                    plan
                        .staggered(3, appeared)
                        .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
                .refreshable { await store.sync() }
                .frame(width: pane.detailWidth(beside: pane.figureRailWidth))
            }
            .gutter()
            .pageWidth()
            .padding(.top, pane.spacing(24) - 6)
        }
    }

    @ViewBuilder
    private var failureBanner: some View {
        if let failure = store.writeFailure {
            ConnectionBanner(message: failure) {
                store.clearWriteFailure()
                Task { await store.reload() }
            }
        }
    }

    /// What's left to move, whichever of the three states the trips are in.
    @ViewBuilder
    private var plan: some View {
        if relevantTrips.isEmpty {
            emptyState
        } else if activeTrips.isEmpty {
            allClearBanner
        } else {
            tripsSection
        }
    }

    /// History as a row rather than a glyph.
    ///
    /// On a phone it's a disc in the header because there is nowhere else for
    /// it; given a column of its own it can say what it holds and how much,
    /// which is the difference between a control people find and one they
    /// don't. Hidden entirely when there's nothing in it — a disabled row
    /// explaining an empty archive is worse than no row.
    @ViewBuilder
    private var historyCard: some View {
        if !settledTrips.isEmpty {
            Button { showHistory = true } label: {
                HStack(spacing: 12) {
                    IconTile(symbol: "clock.arrow.circlepath", tint: AppTheme.accent, size: 38, corner: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("History")
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)

                        Text("\(settledTrips.count.pluralised("trip")) squared away")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .padding(14)
                .cardSurface(corner: 22)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            headerText

            Spacer(minLength: 6)

            // Only where there's nowhere better for it — see `historyCard`.
            if !pane.isWide {
                CircleGlyphButton(symbol: "clock.arrow.circlepath", size: 40) {
                    showHistory = true
                }
                .disabled(settledTrips.isEmpty)
                .opacity(settledTrips.isEmpty ? 0.35 : 1)
            }
        }
    }

    private var headerText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Settle up")
                .font(.system(size: pane.isRegular ? 38 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("Minimised to the fewest transfers, every time something changes.")
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                summaryFigure(label: "You're owed", value: owedToYou, dot: AppTheme.moneyIn)
                Rectangle().fill(AppTheme.cardStroke.opacity(0.10)).frame(width: 1, height: 34)
                summaryFigure(label: "You owe", value: youOwe, dot: AppTheme.moneyOut)
                    .padding(.leading, 16)
            }

            if !relevantTrips.isEmpty {
                Hairline().padding(.vertical, 14)

                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)

                    // "below" was true when there was only ever one column.
                    // The trips sit beside this card on iPad, so the sentence
                    // stops pointing and just says what the number covers.
                    Text("\(totalTransferCount.pluralised("transfer")) closes out every trip here")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkSecondary)
                }
            }
        }
        .padding(pane.isRegular ? 22 : 18)
        .cardSurface(corner: pane.corner(26), shadow: 14)
    }

    private var totalTransferCount: Int {
        relevantTrips.reduce(0) { $0 + $1.suggestedTransfers.count }
    }

    private func summaryFigure(label: String, value: Double, dot: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Circle().fill(dot).frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Text(Money.format(value, code: currency))
                .font(.system(size: pane.isRegular ? 27 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Waiting on you

    private var waitingOnYouSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Waiting on you", caption: "\(awaitingYou.count)")

            VStack(spacing: 10) {
                ForEach(awaitingYou, id: \.settlement.id) { entry in
                    Button { sheet = .review(entry.settlement) } label: {
                        WaitingOnYouRow(trip: entry.trip, settlement: entry.settlement)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    // MARK: - Trips

    private var tripsSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(title: "By trip")

            VStack(spacing: 14) {
                ForEach(activeTrips) { trip in
                    TripSettleCard(
                        trip: trip,
                        onSettle: { toID, amount in sheet = .settle(trip: trip, toID: toID, amount: amount) },
                        onReview: { settlement in sheet = .review(settlement) },
                        onWithdraw: { settlement in store.withdrawSettlement(settlement, in: trip.id) }
                    )
                }
            }
        }
    }

    // MARK: - All clear

    /// Every trip that had a balance has settled — nothing left to act on
    /// here, so the settled trips move to History rather than sitting in
    /// this list re-announcing "all settled up" over and over.
    private var allClearBanner: some View {
        Button { showHistory = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppTheme.positive)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("All settled up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(settledTrips.count.pluralised("trip")) squared away — view in History")
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                }

                Spacer(minLength: 6)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(16)
            .cardSurface(corner: 24)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.positive)
                .frame(width: 52, height: 52)
                .background(AppTheme.positive.opacity(0.12), in: .circle)

            VStack(spacing: 5) {
                Text("All square")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("When someone pays for a booking, who owes whom will show up here.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 260)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .cardSurface(corner: 24)
    }
}

// MARK: - Waiting-on-you row

private struct WaitingOnYouRow: View {
    let trip: Trip
    let settlement: Settlement

    private var payer: Traveller? { trip.traveller(settlement.fromID) }

    var body: some View {
        HStack(spacing: 12) {
            if let payer {
                TravellerAvatar(traveller: payer, size: 40)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(payer?.name ?? "Someone") paid you \(Money.format(settlement.amount, code: settlement.currencyCode))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(trip.title) · \(settlement.method.label) · tap to review")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(13)
        .background(AppTheme.accent.opacity(0.06), in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.accent.opacity(0.16))
        }
    }
}

// MARK: - Per-trip card

private struct TripSettleCard: View {
    let trip: Trip
    var onSettle: (UUID, Double) -> Void
    var onReview: (Settlement) -> Void
    var onWithdraw: (Settlement) -> Void

    private var transfers: [SettlementEngine.Transfer] { trip.suggestedTransfers }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tripHeader

            Hairline(inset: 16)

            if trip.isFullySettled {
                settledRow
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(transfers.enumerated()), id: \.element.id) { index, transfer in
                        TransferRow(
                            trip: trip,
                            transfer: transfer,
                            pending: trip.pendingSettlement(from: transfer.from, to: transfer.to),
                            onSettle: { onSettle(transfer.to, transfer.amount) },
                            onReview: onReview,
                            onWithdraw: onWithdraw
                        )

                        if index < transfers.count - 1 { Hairline(inset: 16) }
                    }
                }
            }
        }
        .cardSurface(corner: 24)
    }

    private var tripHeader: some View {
        HStack(spacing: 10) {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(width: 34, height: 34)
            .clipShape(.rect(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(trip.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(trip.dateRange)
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            AvatarStack(travellers: trip.travellers, size: 22, max: 4, departedIDs: trip.departedIDs)
        }
        .padding(14)
    }

    private var settledRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.positive)

            Text("All settled up")
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Transfer row

/// One line of the minimised plan: who pays whom, and the one thing to do
/// about it — which depends entirely on which of the two people you are.
private struct TransferRow: View {
    let trip: Trip
    let transfer: SettlementEngine.Transfer
    /// A claim already in flight for this exact pair, if there is one — so
    /// the row shows "waiting" instead of offering to ask twice.
    let pending: Settlement?
    var onSettle: () -> Void
    var onReview: (Settlement) -> Void
    var onWithdraw: (Settlement) -> Void

    @State private var confirmingWithdraw = false

    private var from: Traveller? { trip.traveller(transfer.from) }
    private var to: Traveller? { trip.traveller(transfer.to) }
    private var youArePayer: Bool { transfer.from == Traveller.you.id }
    private var youAreRecipient: Bool { transfer.to == Traveller.you.id }

    var body: some View {
        HStack(spacing: 10) {
            people

            VStack(alignment: .leading, spacing: 2) {
                Text(line)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Money.format(transfer.amount, code: trip.currencyCode))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer(minLength: 6)

            action
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var people: some View {
        HStack(spacing: -8) {
            if let from { TravellerAvatar(traveller: from, size: 30).zIndex(1) }
            if let to { TravellerAvatar(traveller: to, size: 30) }
        }
    }

    private var line: String {
        let fromName = youArePayer ? "You" : (from?.name ?? "Someone")
        let toName = youAreRecipient ? "you" : (to?.name ?? "someone")
        return "\(fromName) → \(toName)"
    }

    @ViewBuilder
    private var action: some View {
        if let pending {
            if youAreRecipient {
                Button { onReview(pending) } label: {
                    TagChip(title: "Review", tint: AppTheme.accent, symbol: "bell.fill")
                }
                .buttonStyle(PressableButtonStyle())
            } else if youArePayer {
                Button { confirmingWithdraw = true } label: {
                    TagChip(title: "Waiting", tint: Palette.amber, symbol: "clock.fill")
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint("Tap to withdraw this request")
                .confirmationDialog(
                    "Withdraw this request?",
                    isPresented: $confirmingWithdraw,
                    titleVisibility: .visible
                ) {
                    Button("Withdraw", role: .destructive) { onWithdraw(pending) }
                    Button("Keep waiting", role: .cancel) {}
                } message: {
                    Text("\(to?.name ?? "They") hasn't answered \(Money.format(pending.amount, code: trip.currencyCode)) yet.")
                }
            } else {
                TagChip(title: "Pending", tint: Palette.amber, symbol: "clock.fill")
            }
        } else if youArePayer {
            Button(action: onSettle) {
                Text("Settle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ctaLabel)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.cta, in: .capsule)
            }
            .buttonStyle(PressableButtonStyle())
        } else if youAreRecipient {
            TagChip(title: "Owed to you", tint: AppTheme.moneyIn, symbol: "arrow.down.left")
        }
    }
}

#Preview {
    SettleView()
        .environment(\.tripStore, TripStore())
}
