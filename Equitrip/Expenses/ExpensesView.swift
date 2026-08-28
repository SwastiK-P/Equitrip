//
//  ExpensesView.swift
//  Equitrip
//

import SwiftUI

/// The ledger: what the group has spent, on what, and whose money it was.
///
/// The Itinerary answers "what are we doing?" in the order it happens. This
/// answers "where did the money go?", which is a different sort, a different
/// grouping and a different set of questions — most of them variations on
/// "what do I still owe, and to whom?". They're the same bookings underneath;
/// nothing here is a second record, and that's deliberate. A group ledger with
/// two sources of truth is a group ledger that will eventually disagree with
/// itself.
struct ExpensesView: View {
    @Environment(\.tripStore) private var store

    /// Which trips the figures cover. Nil is everything.
    @State private var scopeID: UUID?
    @State private var filter: Filter = .all
    @State private var viewing: Expense?
    @State private var appeared = false

    enum Filter: String, CaseIterable, Hashable {
        case all, yours, unpaid, youPaid

        var label: String {
            switch self {
            case .all: "All"
            case .yours: "Yours"
            case .unpaid: "Unpaid"
            case .youPaid: "You paid"
            }
        }
    }

    /// One booking with the trip it belongs to. Costs are meaningless without
    /// the currency, the split and the roster, and all three live on the trip.
    struct Expense: Identifiable {
        let item: ItineraryItem
        let trip: Trip

        var id: UUID { item.id }
        var yourShare: Double { trip.share(of: item, for: Traveller.you.id) }
        var isYours: Bool { yourShare > 0 }
        var payer: Traveller? { item.paidByID.flatMap(trip.traveller) }
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            if store.trips.isEmpty, store.state.isLoading {
                LoadingState(message: "Loading your ledger…")
            } else if all.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaBar(edge: .top, spacing: 0) { header }
        .onAppear { withAnimation { appeared = true } }
        .sheet(item: $viewing) { expense in
            ItineraryItemDetailView(
                item: expense.item,
                trip: expense.trip,
                onRecordPayment: { payer, method, receipt in
                    var updated = expense.item
                    updated.paidByID = payer
                    updated.paymentMethod = method
                    updated.receiptURL = receipt
                    store.updateItem(updated, in: expense.trip.id)
                    // Re-presented against the updated booking, so the sheet
                    // shows what was just recorded rather than what it opened
                    // with.
                    viewing = Expense(item: updated, trip: store.trip(expense.trip.id) ?? expense.trip)
                }
            )
        }
    }

    // MARK: - Data

    private var scopedTrips: [Trip] {
        guard let scopeID else { return store.trips }
        return store.trips.filter { $0.id == scopeID }
    }

    private var scopedTrip: Trip? {
        scopeID.flatMap { id in store.trips.first { $0.id == id } }
    }

    /// Every booking that costs something, newest first. A booking with no
    /// price isn't an expense yet — it's a plan, and it belongs on the
    /// timeline until somebody puts a number on it.
    private var all: [Expense] {
        scopedTrips
            .flatMap { trip in trip.items.filter { $0.cost > 0 }.map { Expense(item: $0, trip: trip) } }
            .sorted { ($0.item.time ?? $0.item.date) > ($1.item.time ?? $1.item.date) }
    }

    private var visible: [Expense] {
        switch filter {
        case .all: all
        case .yours: all.filter(\.isYours)
        case .unpaid: all.filter { $0.item.paidByID == nil }
        case .youPaid: all.filter { $0.item.paidByID == Traveller.you.id }
        }
    }

    private var currency: String { scopedTrip?.currencyCode ?? store.primaryCurrency }

    private var total: Double { all.reduce(0) { $0 + $1.item.cost } }
    private var yourShare: Double { all.reduce(0) { $0 + $1.yourShare } }
    private var youPaid: Double { all.filter { $0.item.paidByID == Traveller.you.id }.reduce(0) { $0 + $1.item.cost } }
    private var unpaid: Double { all.filter { $0.item.paidByID == nil }.reduce(0) { $0 + $1.item.cost } }

    /// Spend per category, biggest first. Only categories that actually cost
    /// something appear — a legend full of zeroes explains nothing.
    private var byCategory: [(kind: ItineraryKind, amount: Double)] {
        Dictionary(grouping: all, by: \.item.kind)
            .map { (kind: $0.key, amount: $0.value.reduce(0) { $0 + $1.item.cost }) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                summary
                    .padding(.horizontal, 20)
                    .staggered(0, appeared)

                if byCategory.count > 1 {
                    breakdown
                        .padding(.horizontal, 20)
                        .staggered(1, appeared)
                }

                filters
                    .padding(.horizontal, 20)
                    .staggered(2, appeared)

                list
                    .padding(.horizontal, 20)
                    .staggered(3, appeared)

                Color.clear.frame(height: 20)
            }
            .padding(.top, 2)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .refreshable { await store.reload() }
        .animation(.spring(response: 0.4, dampingFraction: 0.88), value: filter)
    }

    // MARK: - Summary

    /// What the group has spent, then what of it is yours. Two figures, not
    /// four, because the other two — what you laid out and what's still
    /// unrecorded — are answers to "why doesn't this match my bank?", which is
    /// a follow-up question and sits in the row underneath.
    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(scopedTrip?.title.uppercased() ?? "ALL TRIPS")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)

            Text(Money.format(total, code: currency))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: total)
                .padding(.top, 6)

            Text("across \(all.count.pluralised("booking"))")
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.top, 1)

            Hairline()
                .padding(.vertical, 16)

            HStack(spacing: 0) {
                figure(label: "Your share", value: yourShare, tint: AppTheme.ink)
                divider
                figure(label: "You laid out", value: youPaid, tint: AppTheme.moneyIn)
                divider
                figure(label: "Unrecorded", value: unpaid, tint: unpaid > 0 ? Palette.amber : AppTheme.inkTertiary)
            }
        }
        .padding(20)
        .cardSurface(corner: 28, shadow: 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.10))
            .frame(width: 1, height: 30)
    }

    private func figure(label: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineLimit(1)

            // Rounded to the whole unit. A three-way split leaves a third of
            // a rupee on almost every booking, and "₹7,07,233.33" in a
            // third-of-a-card column is two characters of real information
            // and six of noise. The exact figure is on the booking itself,
            // where somebody arguing about it will go anyway.
            Text(Money.format(value.rounded(), code: currency))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    // MARK: - Breakdown

    /// One bar, split by category. Where the money went is a proportion
    /// question — "half of it was the villa" — and a proportion is what a
    /// single divided bar shows and a list of amounts doesn't.
    private var breakdown: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Where it went")

            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(byCategory, id: \.kind) { slice in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(slice.kind.tint)
                                .frame(width: max(3, proxy.size.width * (slice.amount / max(total, 1))) - 2)
                        }
                    }
                }
                .frame(height: 12)

                FlowLayout(spacing: 12, rowSpacing: 8) {
                    ForEach(byCategory, id: \.kind) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(slice.kind.tint)
                                .frame(width: 7, height: 7)

                            Text(slice.kind.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.inkSecondary)

                            Text(Money.format(slice.amount, code: currency))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                        }
                    }
                }
            }
            .padding(16)
            .cardSurface(corner: 22)
        }
    }

    // MARK: - Filters

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { option in
                    let on = filter == option
                    let count = count(for: option)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            filter = option
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(option.label)
                                .font(.system(size: 13.5, weight: .semibold))

                            Text("\(count)")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .opacity(0.7)
                        }
                        .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background {
                            Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
                        }
                        .overlay {
                            Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07))
                        }
                        .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func count(for option: Filter) -> Int {
        switch option {
        case .all: all.count
        case .yours: all.filter(\.isYours).count
        case .unpaid: all.filter { $0.item.paidByID == nil }.count
        case .youPaid: all.filter { $0.item.paidByID == Traveller.you.id }.count
        }
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if visible.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(AppTheme.inkTertiary)

                Text(emptyFilterMessage)
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .cardSurface(corner: 22)
        } else {
            VStack(alignment: .leading, spacing: 13) {
                SectionHeader(
                    title: filter == .all ? "Every expense" : filter.label,
                    caption: Money.format(visible.reduce(0) { $0 + $1.item.cost }, code: currency)
                )

                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, expense in
                        Button { viewing = expense } label: {
                            ExpenseRow(expense: expense, showsTrip: scopeID == nil)
                        }
                        .buttonStyle(PressableButtonStyle())

                        if index < visible.count - 1 {
                            Hairline(inset: 16)
                        }
                    }
                }
                .cardSurface(corner: 24)
            }
        }
    }

    private var emptyFilterMessage: String {
        switch filter {
        case .all: "Nothing has been priced up yet."
        case .yours: "None of these bookings land on you."
        case .unpaid: "Every expense has somebody's name on it."
        case .youPaid: "You haven't paid for anything yet."
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Expenses")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            scopePicker
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    /// The same scoping the Home hero has, for the same reason: a portfolio
    /// total across trips in different currencies adds unlike things together,
    /// and one trip is the only honest figure when that happens.
    private var scopePicker: some View {
        Menu {
            Button {
                scopeID = nil
            } label: {
                Label("All trips", systemImage: scopeID == nil ? "checkmark" : "square.stack.3d.up")
            }

            if !store.trips.isEmpty { Divider() }

            ForEach(store.trips) { trip in
                Button {
                    scopeID = trip.id
                } label: {
                    Text(trip.title)
                    Text(trip.dateRange)
                    Image(systemName: scopeID == trip.id ? "checkmark" : trip.symbol)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(scopedTrip?.title ?? "All trips")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.accent.opacity(0.12), in: .capsule)
            .contentShape(.capsule)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Scope, \(scopedTrip?.title ?? "all trips")")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            IconTile(symbol: "creditcard", tint: Palette.amberDeep, size: 58, corner: 19)

            Text(store.trips.isEmpty ? "No trips yet" : "Nothing spent yet")
                .font(AppTheme.display(24))
                .foregroundStyle(AppTheme.ink)

            Text(
                store.trips.isEmpty
                    ? "Costs show up here as soon as there's a trip to put them on."
                    : "Put a price on a booking and it lands here, with whose cost it is."
            )
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.inkSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Row

private struct ExpenseRow: View {
    let expense: ExpensesView.Expense
    /// Off when the list is already scoped to one trip — repeating its name on
    /// every row is noise.
    var showsTrip: Bool

    private var item: ItineraryItem { expense.item }
    private var trip: Trip { expense.trip }

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                payerLine
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(item.cost, code: trip.currencyCode))
                    .font(.system(size: 15.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                if expense.yourShare > 0 {
                    Text("you \(Money.format(expense.yourShare, code: trip.currencyCode))")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else {
                    Text("not yours")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .lineLimit(1)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .contentShape(.rect)
    }

    private var subtitle: String {
        [
            showsTrip ? trip.title : nil,
            DateFormatter.cached("d MMM").string(from: item.date),
            item.vendor.isEmpty ? item.split.shortLabel : item.vendor
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }

    /// Whose money it was, or the fact that nobody has said. The unpaid state
    /// is the one worth pointing at — it's the reason a balance is wrong.
    @ViewBuilder
    private var payerLine: some View {
        if let payer = expense.payer {
            HStack(spacing: 5) {
                MemojiAvatar(traveller: payer, size: 16)

                Text(payer.id == Traveller.you.id ? "You paid" : "\(payer.name) paid")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
            .padding(.top, 2)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("Nobody's paid yet")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Palette.amber)
            .padding(.top, 2)
        }
    }
}

#Preview {
    RootTabView(userName: "Swastik Patil")
}
