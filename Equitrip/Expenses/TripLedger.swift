//
//  TripLedger.swift
//  Equitrip
//

import SwiftUI

/// The money side of one trip.
///
/// It used to be a tab of its own, sitting outside every trip and opening on a
/// trip picker — which meant the first thing the screen asked you was a
/// question you had already answered by opening a trip. A trip is the
/// container: its plan, its people and its money are three views of one thing,
/// not three destinations. So this is a section of the trip screen rather than
/// a place you navigate to, and everything on it is already scoped.
///
/// Three blocks, in the order the questions get asked: what has this cost,
/// where do I stand in it, and is anything wrong with the record.
struct TripLedger: View {
    let trip: Trip
    var onOpen: (ItineraryItem) -> Void
    /// Opens a proposal that's waiting on an answer.
    var onReviewDeparture: ((TripDeparture) -> Void)?
    /// Opens a closed exit's frozen statement.
    var onOpenStatement: ((TripDeparture) -> Void)?

    @State private var filter: Filter = .all
    @State private var searchText = ""
    @State private var showAllExpenses = false
    @State private var showAudit = false
    @State private var appeared = false

    enum Filter: Hashable, CaseIterable {
        case all, youPaid, yours, unpaid, disputed

        var label: String {
            switch self {
            case .all: "All"
            case .youPaid: "You paid"
            case .yours: "Costs you"
            case .unpaid: "No payer"
            case .disputed: "Disputed"
            }
        }
    }

    /// How many rows the ledger shows inline before handing off to the full
    /// list. Five is a glance's worth — enough to answer "what's recent"
    /// without the card outgrowing the rest of the trip screen, which is what
    /// happened once a trip passed a dozen priced bookings.
    private static let inlineCap = 5

    private var currency: String { trip.currencyCode }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            money
                .staggered(0, appeared)

            // Between the totals and the expense list on purpose. Somebody
            // leaving is a fact about the money — it's why a share moved —
            // so it belongs with the figures rather than filed away under
            // people, and it sits above the expenses because it changes how
            // they're read.
            if !trip.departures.isEmpty {
                people
                    .staggered(1, appeared)
            }

            expenses
                .staggered(2, appeared)

            // Under the expenses, deliberately last. It answers the question
            // the figures provoke rather than one of the figures themselves:
            // you read what something costs, you disagree with it, and only
            // then do you want to know who made it that.
            AuditTrailButton(trip: trip) { showAudit = true }
                .staggered(3, appeared)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .onAppear { withAnimation { appeared = true } }
        .sheet(isPresented: $showAllExpenses) {
            ExpensesListView(trip: trip, filter: filter, searchText: searchText, onOpen: onOpen)
        }
        .sheet(isPresented: $showAudit) {
            AuditTrailSheet(trip: trip)
        }
    }

    /// Shared between the inline card and the full list, so "You paid, 3" on
    /// one means the same thing as "You paid, 3" on the other — both are the
    /// same filter applied to the same search, just with a different cap.
    fileprivate static func apply(_ filter: Filter, search: String, to priced: [ItineraryItem], trip: Trip) -> [ItineraryItem] {
        let filtered: [ItineraryItem]
        switch filter {
        case .all:
            filtered = priced
        case .youPaid:
            filtered = priced.filter { $0.paidByID == Traveller.you.id }
        case .yours:
            filtered = priced.filter { trip.share(of: $0, for: Traveller.you.id) > 0 }
        case .unpaid:
            filtered = priced.filter { $0.paidByID == nil }
        case .disputed:
            filtered = priced.filter { $0.isDisputed }
        }

        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched: [ItineraryItem]
        if query.isEmpty {
            searched = filtered
        } else {
            searched = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(query)
                    || item.vendor.localizedCaseInsensitiveContains(query)
                    || item.kind.label.localizedCaseInsensitiveContains(query)
            }
        }

        return searched.sorted(by: Trip.chronological)
    }

    // MARK: - Figures

    private var priced: [ItineraryItem] { trip.items.filter { $0.cost > 0 } }

    private var totalSpend: Double { trip.projectedCost }
    private var yourShare: Double { trip.cost(for: Traveller.you.id) }
    private var youPaid: Double { trip.paid(by: Traveller.you.id) }
    private var owedToYou: Double { trip.owedTo(Traveller.you.id) }
    private var youOwe: Double { trip.owing(Traveller.you.id) }

    private var byCategory: [(kind: ItineraryKind, amount: Double)] {
        Dictionary(grouping: priced, by: \.kind)
            .map { (kind: $0.key, amount: $0.value.reduce(0) { $0 + $1.cost }) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Money

    /// What the trip costs, drawn rather than listed, and then the four
    /// figures that place you inside it.
    ///
    /// The four are deliberately two pairs. "Your share" and "You paid" are
    /// facts about the plan — what it costs you, what left your account — and
    /// the difference between them is the whole of the second pair: what comes
    /// back and what goes out. Laid out as one flat row of four they read as
    /// four unrelated totals, which is how people end up thinking they owe the
    /// sum of all of them.
    private var money: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TRIP SPEND")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(Money.format(totalSpend.rounded(), code: currency))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: totalSpend)
                .padding(.top, 2)

            Text("across \(priced.count.pluralised("booking"))")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)

            SpendBreakdown(slices: byCategory, total: totalSpend, currency: currency)
                .padding(.top, 16)

            Hairline()
                .padding(.vertical, 16)

            VStack(spacing: 9) {
                HStack(spacing: 9) {
                    figure(label: "Your share", value: yourShare, symbol: "person.fill")
                    figure(label: "You paid", value: youPaid, symbol: "creditcard.fill")
                }

                HStack(spacing: 9) {
                    figure(
                        label: "You're owed",
                        value: owedToYou,
                        symbol: "arrow.uturn.left",
                        tint: AppTheme.moneyIn
                    )
                    figure(
                        label: "You owe",
                        value: youOwe,
                        symbol: "arrow.uturn.right",
                        tint: AppTheme.moneyOut
                    )
                }
            }
        }
        .padding(18)
        .cardSurface(corner: 28, shadow: 16)
    }

    private func figure(
        label: String,
        value: Double,
        symbol: String,
        tint: Color = AppTheme.inkSecondary
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.13), in: .circle)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                Text(Money.format(value.rounded(), code: currency))
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .foregroundStyle(value > 0 ? AppTheme.ink : AppTheme.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.canvasBottom.opacity(0.45), in: .rect(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Departures

    /// Who has left, and who has asked to.
    ///
    /// The whole of the departure UI's depth lives here, collapsed to one row
    /// per person. Everything on the timeline is a marker — a greyed face, a
    /// line on the day it happened — and this is where the arithmetic behind
    /// those markers is available to anybody who wants to interrogate it,
    /// without putting it in front of the people who don't.
    private var people: some View {
        let pending = trip.pendingDepartures
        let closed = trip.confirmedDepartures

        return VStack(alignment: .leading, spacing: 11) {
            SectionHeader(
                title: "Who's on this",
                caption: "\(trip.activeTravellers.count) of \(trip.travellers.count)"
            )

            VStack(spacing: 0) {
                ForEach(Array(pending.enumerated()), id: \.element.id) { index, departure in
                    DepartureLedgerRow(
                        trip: trip,
                        departure: departure,
                        action: onReviewDeparture.map { handler in { handler(departure) } }
                    )

                    if index < pending.count - 1 || !closed.isEmpty { Hairline(inset: 16) }
                }

                ForEach(Array(closed.enumerated()), id: \.element.id) { index, departure in
                    DepartureLedgerRow(
                        trip: trip,
                        departure: departure,
                        action: onOpenStatement.map { handler in { handler(departure) } }
                    )

                    if index < closed.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 24)
        }
    }

    // MARK: - Expenses

    private var visible: [ItineraryItem] {
        Self.apply(filter, search: searchText, to: priced, trip: trip)
    }

    private var inlineVisible: [ItineraryItem] { Array(visible.prefix(Self.inlineCap)) }

    private var expenses: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(
                title: "Expenses",
                caption: Money.format(visible.reduce(0) { $0 + $1.cost }.rounded(), code: currency),
                actionTitle: visible.count > Self.inlineCap ? "View all" : nil
            ) {
                showAllExpenses = true
            }

            LedgerSearchField(text: $searchText, placeholder: "Search expenses")

            filters

            if visible.isEmpty {
                Text(emptyLine)
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface(corner: 22)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(inlineVisible.enumerated()), id: \.element.id) { index, item in
                        Button { onOpen(item) } label: {
                            LedgerRow(item: item, trip: trip)
                        }
                        .buttonStyle(PressableButtonStyle())

                        if index < inlineVisible.count - 1 { Hairline(inset: 16) }
                    }
                }
                .cardSurface(corner: 24)

                if visible.count > Self.inlineCap {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAllExpenses = true
                    } label: {
                        Text("View all \(visible.count) expenses")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var emptyLine: String {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "No expenses match “\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))”."
        }
        switch filter {
        case .all: return "Put a price on a booking and it lands here."
        case .youPaid: return "You haven't paid for anything on this trip."
        case .yours: return "None of these bookings land on you."
        case .unpaid: return "Every expense has somebody's name against it."
        case .disputed: return "No disputed payments — everything checks out."
        }
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Self.filterOptions(for: priced), id: \.self) { option in
                    LedgerFilterChip(
                        label: option.label,
                        count: Self.apply(option, search: searchText, to: priced, trip: trip).count,
                        isOn: filter == option
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { filter = option }
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    /// The filter chips to show. The disputed chip is hidden when there are
    /// no disputed payments — showing a zero-count disputed chip on a clean
    /// ledger would just make it look like something is wrong.
    fileprivate static func filterOptions(for priced: [ItineraryItem]) -> [Filter] {
        if priced.contains(where: { $0.isDisputed }) {
            return Filter.allCases
        }
        return Filter.allCases.filter { $0 != .disputed }
    }
}

// MARK: - Departure row

/// One person's exit, collapsed to a line.
///
/// A pending one leads with what it's waiting for, because that's an action
/// somebody owes; a closed one leads with the dates and the final figure,
/// because that's a fact somebody might want to check.
struct DepartureLedgerRow: View {
    let trip: Trip
    let departure: TripDeparture
    var action: (() -> Void)?

    private var traveller: Traveller? { trip.traveller(departure.travellerID) }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                if let traveller {
                    TravellerAvatar(traveller: traveller, size: 36, isDimmed: departure.isConfirmed)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(subtitleName)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: departure.isPending ? "clock.fill" : "arrow.right.to.line")
                            .font(.system(size: 8, weight: .bold))
                        Text(detail)
                            .font(.system(size: 11.5, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(departure.isPending ? Palette.amber : AppTheme.inkTertiary)
                }

                Spacer(minLength: 6)

                if departure.isConfirmed, abs(departure.agreedBalance) > SettlementEngine.epsilon {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(Money.format(abs(departure.agreedBalance).rounded(), code: trip.currencyCode))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(departure.agreedBalance > 0 ? AppTheme.moneyIn : AppTheme.moneyOut)
                        Text(departure.agreedBalance > 0 ? "owed to them" : "they owe")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .fixedSize()
                }

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .padding(14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(action == nil)
    }

    private var subtitleName: String {
        guard let traveller else { return "Someone" }
        return traveller.id == Traveller.you.id ? "You" : traveller.name
    }

    private var detail: String {
        if departure.isPending {
            return departure.isYours ? "Waiting to be confirmed" : "Asked to leave · needs your answer"
        }
        return trip.presenceLabel(departure.travellerID) ?? "Left the trip"
    }
}

// MARK: - All expenses

/// The full ledger, handed off to from the trip card's five-row preview.
///
/// Same filters, same search, same rows — it's the rest of the list rather
/// than a different way of looking at it, so nothing here has to be relearnt.
private struct ExpensesListView: View {
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    @State var filter: TripLedger.Filter
    @State var searchText: String
    var onOpen: (ItineraryItem) -> Void

    private var priced: [ItineraryItem] { trip.items.filter { $0.cost > 0 } }
    private var visible: [ItineraryItem] { TripLedger.apply(filter, search: searchText, to: priced, trip: trip) }

    var body: some View {
        VStack(spacing: 0) {
            header
            LedgerSearchField(text: $searchText, placeholder: "Search expenses")
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            filters
                .padding(.bottom, 4)
            list
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Expenses")
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

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(TripLedger.filterOptions(for: priced), id: \.self) { option in
                    LedgerFilterChip(
                        label: option.label,
                        count: TripLedger.apply(option, search: searchText, to: priced, trip: trip).count,
                        isOn: filter == option
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { filter = option }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var list: some View {
        ScrollView {
            if visible.isEmpty {
                Text(emptyLine)
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface(corner: 22)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                        Button {
                            dismiss()
                            onOpen(item)
                        } label: {
                            LedgerRow(item: item, trip: trip)
                        }
                        .buttonStyle(PressableButtonStyle())

                        if index < visible.count - 1 { Hairline(inset: 16) }
                    }
                }
                .cardSurface(corner: 24)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            Color.clear.frame(height: 24)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyLine: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty else { return "No expenses match “\(query)”." }
        switch filter {
        case .all: return "Put a price on a booking and it lands here."
        case .youPaid: return "You haven't paid for anything on this trip."
        case .yours: return "None of these bookings land on you."
        case .unpaid: return "Every expense has somebody's name against it."
        case .disputed: return "No disputed payments — everything checks out."
        }
    }
}

// MARK: - Search field

/// Shared with the audit trail sheet, which searches the same way over a
/// different list — one field, one behaviour, one clear button.
struct LedgerSearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            TextField(placeholder, text: $text)
                .font(.system(size: 14.5))
                .foregroundStyle(AppTheme.ink)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .frame(height: 42)
        .panelSurface(corner: 14)
    }
}

// MARK: - Filter chip

struct LedgerFilterChip: View {
    let label: String
    let count: Int
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))

                Text("\(count)")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(isOn ? AppTheme.ctaLabel : AppTheme.inkSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(isOn ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(isOn ? 0 : 0.07)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row

private struct LedgerRow: View {
    let item: ItineraryItem
    let trip: Trip

    private var yourShare: Double { trip.share(of: item, for: Traveller.you.id) }
    private var payer: Traveller? { item.paidByID.flatMap(trip.traveller) }

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

                if item.isDisputed {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Disputed")
                            .font(.system(size: 10.5, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.danger)
                } else {
                    Text(
                        yourShare > 0.01
                            ? "yours \(Money.format(yourShare.rounded(), code: trip.currencyCode))"
                            : "not yours"
                    )
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
            DateFormatter.cached("d MMM").string(from: item.date),
            item.vendor.isEmpty ? item.split.shortLabel : item.vendor
        ]
        .joined(separator: " · ")
    }

    /// Whose money it was, or the fact that nobody has said — which is the one
    /// state on this screen that's actually a problem.
    @ViewBuilder
    private var payerLine: some View {
        if item.isDisputed {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: 9, weight: .bold))
                Text("Payment disputed")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppTheme.danger)
            .padding(.top, 2)
        } else if let payer {
            HStack(spacing: 5) {
                TravellerAvatar(traveller: payer, size: 16)

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

// MARK: - Breakdown

/// Where the money went, as rows that are their own bars.
///
/// Third attempt, and the two it replaces failed the same way. A donut is what
/// every app reaches for the moment it has a total and some categories, so it
/// reads as a widget dropped in rather than as this trip — and comparing arcs
/// means comparing angles, which people are poor at, with no room inside a
/// wedge for a label. A treemap fixes the comparison but brings its own
/// problem: it's an unfamiliar shape doing a familiar job, so it asks to be
/// decoded before it can be read.
///
/// This asks nothing. Each category is a row, and the row's own fill is how
/// much of the trip it was — the bar isn't a graphic next to the data, it's the
/// surface the data sits on. Length is the comparison, which is the one visual
/// judgement people make accurately, and every row has full width for a name
/// and an amount at a readable size. It also degrades properly: one category or
/// seven, it's the same component, where a donut with one slice is a circle and
/// a treemap with one is a rectangle.
private struct SpendBreakdown: View {
    let slices: [(kind: ItineraryKind, amount: Double)]
    let total: Double
    let currency: String

    @State private var drawn = false

    var body: some View {
        VStack(spacing: 7) {
            ForEach(Array(slices.enumerated()), id: \.element.kind) { index, slice in
                row(slice, delay: Double(index) * 0.06)
            }

            if slices.isEmpty {
                Text("Nothing priced up yet")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            }
        }
        .onAppear { drawn = true }
    }

    private func row(_ slice: (kind: ItineraryKind, amount: Double), delay: Double) -> some View {
        let fraction = total > 0 ? slice.amount / total : 0

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardStroke.opacity(0.045))

            GeometryReader { proxy in
                // A wash rather than a solid fill: the row's text runs across
                // the whole width and has to stay one colour, so the bar can't
                // be dark enough to need white type over part of it and ink
                // over the rest.
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [slice.kind.tint.opacity(0.26), slice.kind.tint.opacity(0.13)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(alignment: .leading) {
                        // The saturated edge. It's what stops a pale wash from
                        // reading as a rounded rectangle that happens to be
                        // tinted, and it's where the eye measures from.
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 14,
                            style: .continuous
                        )
                        .fill(slice.kind.tint)
                        .frame(width: 4)
                    }
                    .frame(width: max(4, proxy.size.width * (drawn ? fraction : 0)))
                    .animation(
                        .spring(response: 0.72, dampingFraction: 0.85).delay(delay),
                        value: drawn
                    )
            }

            HStack(spacing: 10) {
                Image(systemName: slice.kind.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(slice.kind.tint)
                    .frame(width: 22)

                Text(slice.kind.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 8)

                Text(percent(fraction))
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .monospacedDigit()

                Text(Money.format(slice.amount.rounded(), code: currency))
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.leading, 14)
            .padding(.trailing, 14)
        }
        .frame(height: 46)
        .clipShape(.rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel(
            "\(slice.kind.label), \(Money.format(slice.amount.rounded(), code: currency)), \(percent(fraction))"
        )
    }

    /// Rounded to whole points, and never to zero — a category that cost real
    /// money reading "0%" is worse than a rounding error.
    private func percent(_ fraction: Double) -> String {
        let value = fraction * 100
        return value < 1 && value > 0 ? "<1%" : "\(Int(value.rounded()))%"
    }
}
