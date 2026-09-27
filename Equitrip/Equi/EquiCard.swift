//
//  EquiCard.swift
//  Equitrip
//

import SwiftUI
import FoundationModels

// MARK: - What gets drawn

/// The shapes Equi can answer *in*, beyond a paragraph of prose.
///
/// Chosen by Swift from the question (`EquiFacts`), not by the model: the
/// first Equi let the model pick, and it picked the same handful of cards
/// whatever was asked. The card's contents are still drawn live from
/// `TripStore` at render time, so a figure on a card is never one the model
/// restated — and never a stale one on a card scrolled back to next week.
enum EquiCardKind: Hashable {
    /// The trip itself: cover, dates, who's on it, where you stand.
    case trip
    /// A finished trip, told as its totals.
    case recap
    /// Money: your net position and the transfers that would clear it.
    case balance
    /// What's on the plan — next up, or one day of it.
    case itinerary
    /// Every booking of one kind: the stays, the flights.
    case bookings
    /// Where the money is going, broken down by category.
    case spending
    /// Everyone on the trip and what each of them is carrying.
    case people
    /// Several trips side by side.
    case trips
    /// What's missing from the plan.
    case gaps
}

/// A card under one of Equi's replies, and what it's narrowed to.
///
/// The narrowing is what makes a card answer the question that was asked:
/// "how much on food?" draws the spending card with food picked out, "what's
/// on tomorrow?" the plan for tomorrow, "what does Ed owe?" the balance with
/// Ed's transfers first.
struct EquiCard: Equatable {
    /// Which figure a row of `.trips` leads with.
    enum Metric: String, Equatable {
        case cost, balance
    }

    /// Which trips a `.trips` card lists, read live — a new trip shows up on
    /// an old "my trips" card.
    enum TripSet: String, Equatable {
        case all, past, upcoming
    }

    var kind: EquiCardKind
    /// The trip the card is about. Nil only for `.trips`.
    var tripID: UUID?
    var category: ItineraryKind?
    var personID: UUID?
    var day: Date?
    var tripSet: TripSet?
    /// Named trips being compared, when the question picked them out.
    var tripIDs: [UUID] = []
    var metric: Metric?
}

extension EquiCardKind {
    /// The name this kind is stored under in `equi_messages.card_kind`.
    ///
    /// Spelled out rather than derived from the case name: a stored transcript
    /// must not change meaning because a case was renamed to read better.
    var storageKey: String {
        switch self {
        case .trip: "trip"
        case .recap: "recap"
        case .balance: "balance"
        case .itinerary: "itinerary"
        case .bookings: "bookings"
        case .spending: "spending"
        case .people: "people"
        case .trips: "trips"
        case .gaps: "gaps"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "trip": self = .trip
        case "recap": self = .recap
        case "balance": self = .balance
        case "itinerary": self = .itinerary
        case "bookings": self = .bookings
        case "spending": self = .spending
        case "people": self = .people
        case "trips": self = .trips
        case "gaps": self = .gaps
        // "text", or a card written by a newer build than this one. The reply
        // still reads fine as prose, which is the point of keeping the text.
        default: return nil
        }
    }
}

extension EquiCard {
    /// The card as one string for `equi_messages.card_kind`: the kind, then
    /// its narrowing as `;key=value` pairs — `spending;category=meal`.
    ///
    /// Packed into the existing column rather than new ones, so no migration:
    /// a build from before the narrowing reads `spending;category=meal` as a
    /// kind it doesn't know and shows the reply as prose.
    var storageKey: String {
        var parts = [kind.storageKey]
        if let category { parts.append("category=\(category.rawValue)") }
        if let personID { parts.append("person=\(personID.uuidString)") }
        if let day { parts.append("day=\(Self.dayFormat.string(from: day))") }
        if let tripSet { parts.append("set=\(tripSet.rawValue)") }
        if !tripIDs.isEmpty { parts.append("trips=\(tripIDs.map(\.uuidString).joined(separator: ","))") }
        if let metric { parts.append("metric=\(metric.rawValue)") }
        return parts.joined(separator: ";")
    }

    /// Rebuilds a card from a saved transcript, or nothing when the row was
    /// plain prose or named a card this build doesn't know.
    init?(storageKey: String?, tripID: UUID?) {
        guard let storageKey else { return nil }
        let parts = storageKey.split(separator: ";").map(String.init)
        guard let head = parts.first, let kind = EquiCardKind(storageKey: head) else { return nil }
        guard tripID != nil || kind == .trips else { return nil }

        self.init(kind: kind, tripID: kind == .trips ? nil : tripID)
        for part in parts.dropFirst() {
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else { continue }
            switch pair[0] {
            case "category": category = ItineraryKind(rawValue: pair[1])
            case "person": personID = UUID(uuidString: pair[1])
            case "day": day = Self.dayFormat.date(from: pair[1])
            case "set": tripSet = TripSet(rawValue: pair[1])
            case "trips": tripIDs = pair[1].split(separator: ",").compactMap { UUID(uuidString: String($0)) }
            case "metric": metric = Metric(rawValue: pair[1])
            default: break
            }
        }
    }

    private static let dayFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}

// MARK: - Renderer

/// Draws whichever card the answer called for, reading the trip live out of
/// the store — so a card that's been sitting in the thread for ten minutes
/// still shows the right number after somebody logs an expense.
struct EquiCardView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.colorScheme) private var scheme

    let card: EquiCard
    /// For cards whose rows are trips of their own (`.trips`), where the card
    /// as a whole has nowhere to go.
    var onOpenTrip: (Trip) -> Void = { _ in }

    var body: some View {
        if let content = content {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card, in: .rect(cornerRadius: 20, style: .continuous))
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.09 : 0.045))
                }
                .shadow(color: AppTheme.softShadow(scheme), radius: 10, y: 4)
        }
    }

    private var content: AnyView? {
        if card.kind == .trips {
            return AnyView(EquiTripsCard(card: card, onOpenTrip: onOpenTrip))
        }
        guard let trip = store.trip(card.tripID) else { return nil }
        switch card.kind {
        case .trip: return AnyView(EquiTripCard(trip: trip))
        case .recap: return AnyView(EquiRecapCard(trip: trip))
        case .balance: return AnyView(EquiBalanceCard(trip: trip, personID: card.personID))
        case .itinerary: return AnyView(EquiItineraryCard(trip: trip, day: card.day))
        case .bookings: return AnyView(EquiBookingsCard(trip: trip, category: card.category))
        case .spending: return AnyView(EquiSpendingCard(trip: trip, focus: card.category))
        case .people: return AnyView(EquiPeopleCard(trip: trip, focus: card.personID))
        case .gaps: return AnyView(EquiGapsCard(trip: trip))
        case .trips: return nil
        }
    }
}

// MARK: - Shared chrome

/// Every card says what it is on the left and which trip it's about on the
/// right, so a card scrolled back to a week later still explains itself.
struct EquiCardHeader: View {
    let symbol: String
    let title: String
    /// Nil on a card about several trips, where there's no one name to give.
    let trip: Trip?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(trip?.tint ?? AppTheme.accent)

            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 6)

            if let trip {
                Text(trip.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - 1. The trip

/// The trip at a glance — the same card Home leads with, shrunk to fit a
/// conversation. Answers "what's my next trip?" without making anyone leave
/// the thread to go and look.
private struct EquiTripCard: View {
    @Environment(\.tripStore) private var store
    let trip: Trip

    var body: some View {
        VStack(spacing: 0) {
            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint,
                onResolve: { store.setCover($0, for: trip.id) }
            )
            .frame(height: 112)
            .frame(maxWidth: .infinity)
            .overlay { ProgressiveBlur(edge: .bottom, begins: 0.48, scrim: 0.32) }
            .overlay(alignment: .topLeading) { phaseChip }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(trip.title)
                        .tripTitle(trip.titleStyle, size: 19)
                        .foregroundStyle(.white)

                    Text("\(trip.destination) · \(trip.dateRange)")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .lineLimit(1)
                .shadow(color: .black.opacity(0.3), radius: 5, y: 1)
                .padding(12)
            }

            HStack(alignment: .center, spacing: 10) {
                AvatarStack(travellers: trip.travellers, size: 24, max: 4, departedIDs: trip.departedIDs)

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(trip.showsBalance ? trip.netLabel : Money.format(trip.yourShare, code: trip.currencyCode))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.showsBalance ? trip.netTone : AppTheme.ink)

                    Text(trip.showsBalance ? trip.netCaption : "your share")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .padding(.horizontal, 13)
            .padding(.top, 11)

            HStack(spacing: 6) {
                Text(trip.progressLabel)
                Text("·")
                Text(trip.projectedLabel)
                Spacer(minLength: 4)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppTheme.inkTertiary)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .padding(.top, 7)
            .padding(.bottom, 13)
        }
    }

    private var phaseChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(trip.phase.tint)
                .frame(width: 5, height: 5)

            Text(trip.phase.label)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(.black.opacity(0.3), in: .capsule)
        .background(.ultraThinMaterial, in: .capsule)
        .padding(10)
    }
}

// MARK: - 2. The balance

/// Where you stand, and the fewest transfers that would clear it — the Settle
/// tab's answer, given inline.
private struct EquiBalanceCard: View {
    let trip: Trip
    /// Someone the question named — their transfers go first.
    var personID: UUID?

    /// The transfers that concern the person asked about (or you) first,
    /// then everyone else's: "what does Ed owe?" shouldn't open on Kim.
    private var transfers: [SettlementEngine.Transfer] {
        let focus = personID ?? Traveller.you.id
        let all = trip.suggestedTransfers
        let mine = all.filter { $0.from == focus || $0.to == focus }
        let rest = all.filter { $0.from != focus && $0.to != focus }
        return Array((mine + rest).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "indianrupeesign.circle.fill", title: "Where you stand", trip: trip)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(trip.showsBalance ? trip.netLabel : Money.format(trip.yourShare, code: trip.currencyCode))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(trip.showsBalance ? trip.netTone : AppTheme.ink)

                Text(trip.showsBalance ? trip.netCaption : "your share of the plan")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            if transfers.isEmpty {
                TagChip(
                    title: trip.showsBalance ? "All square" : "Nothing paid yet",
                    tint: trip.showsBalance ? AppTheme.positive : AppTheme.inkTertiary,
                    symbol: trip.showsBalance ? "checkmark.seal.fill" : "clock.fill"
                )
            } else {
                Hairline()

                VStack(spacing: 9) {
                    ForEach(transfers) { transfer in
                        row(for: transfer)
                    }
                }
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private func row(for transfer: SettlementEngine.Transfer) -> some View {
        HStack(spacing: 7) {
            if let from = trip.traveller(transfer.from) {
                TravellerAvatar(traveller: from, size: 22)
                Text(name(from))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)

            if let to = trip.traveller(transfer.to) {
                TravellerAvatar(traveller: to, size: 22)
                Text(name(to))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }

            Spacer(minLength: 4)

            Text(Money.format(transfer.amount, code: trip.currencyCode))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .lineLimit(1)
    }

    private func name(_ traveller: Traveller) -> String {
        traveller.id == Traveller.you.id ? "You" : traveller.name
    }
}

// MARK: - 3. What's next

/// The next few things on the plan, in the timeline's own row language.
@MainActor
private struct EquiItineraryCard: View {
    let trip: Trip
    /// One day of the plan, when the question asked about one.
    var day: Date?

    private var upcoming: [ItineraryItem] {
        guard let day else { return trip.upcoming(limit: 3) }
        return Array(trip.items.filter { $0.day == day }.sorted(by: Trip.chronological).prefix(5))
    }

    private var title: String {
        guard let day else { return "Up next" }
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInTomorrow(day) { return "Tomorrow" }
        return DateFormatter.cached("EEEE d MMM").string(from: day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "calendar", title: title, trip: trip)

            if upcoming.isEmpty {
                Text(day == nil ? "Nothing booked yet." : "Nothing on the plan that day.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                VStack(spacing: 11) {
                    ForEach(upcoming) { item in
                        row(for: item)
                    }
                }
            }
        }
        .padding(14)
    }

    private func row(for item: ItineraryItem) -> some View {
        HStack(spacing: 10) {
            IconTile(symbol: item.symbol, tint: item.kind.tint, size: 32, corner: 10)

            VStack(alignment: .leading, spacing: 1.5) {
                Text(item.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text(subtitle(for: item))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if item.cost > 0 {
                Text(Money.format(item.cost, code: trip.currencyCode))
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }
        }
    }

    private func subtitle(for item: ItineraryItem) -> String {
        var pieces = [DateFormatter.cached("EEE d MMM").string(from: item.day)]
        if let time = item.timeLabel { pieces.append(time) }
        if let vendor = item.vendorName { pieces.append(vendor) }
        return pieces.joined(separator: " · ")
    }
}

// MARK: - 4. Where the money goes

/// The trip's cost split by category, largest first — the answer to "what's
/// eating the budget?" that a sentence can't give.
private struct EquiSpendingCard: View {
    let trip: Trip
    /// The category the question asked about: its total leads, its bar stays
    /// lit and the rest step back.
    var focus: ItineraryKind?

    private var totals: [(kind: ItineraryKind, amount: Double)] {
        Dictionary(grouping: trip.items, by: \.kind)
            .mapValues { $0.reduce(0) { $0 + $1.cost } }
            .filter { $0.value > 0 }
            .map { (kind: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "chart.pie.fill", title: "Where it's going", trip: trip)

            let rows = focusedRows
            let largest = totals.first?.amount ?? 1

            headline

            if rows.isEmpty {
                Text("Nothing has a price on it yet.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(rows, id: \.kind) { row in
                        bar(kind: row.kind, amount: row.amount, fraction: row.amount / largest)
                            .opacity(focus == nil || focus == row.kind ? 1 : 0.4)
                    }
                }
            }
        }
        .padding(14)
    }

    /// The top four, with the asked-about category always among them.
    private var focusedRows: [(kind: ItineraryKind, amount: Double)] {
        var rows = Array(totals.prefix(4))
        if let focus, !rows.contains(where: { $0.kind == focus }), let row = totals.first(where: { $0.kind == focus }) {
            rows[rows.count - 1] = row
        }
        return rows
    }

    @ViewBuilder
    private var headline: some View {
        if let focus {
            let amount = totals.first { $0.kind == focus }?.amount ?? 0
            let share = trip.projectedCost > 0 ? Int((amount / trip.projectedCost * 100).rounded()) : 0
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Money.format(amount, code: trip.currencyCode))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("on \(focus.label.lowercased()) · \(share)% of \(trip.projectedLabel)")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }
        } else {
            Text(trip.projectedLabel)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private func bar(kind: ItineraryKind, amount: Double, fraction: Double) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(kind.tint)
                    .frame(width: 14)

                Text(kind.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Spacer(minLength: 4)

                Text(Money.format(amount, code: trip.currencyCode))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Capsule()
                .fill(kind.tint.opacity(0.14))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(kind.tint)
                            .frame(width: max(4, geo.size.width * fraction))
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview("Equi cards") {
    let you = Traveller.you
    let day = Calendar.current.startOfDay(for: Date())
    let trip = Trip(
        title: "Backwaters",
        destination: "Kerala",
        startDate: Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day,
        endDate: Calendar.current.date(byAdding: .day, value: 4, to: day) ?? day,
        travellers: [you, .ed, .krishna, .kim],
        items: [
            ItineraryItem(
                title: "Kochi → Alleppey", vendor: "IndiGo", kind: .flight,
                date: day, time: day.addingTimeInterval(9 * 3600), cost: 18_400,
                participantIDs: [you.id], paidByID: you.id
            ),
            ItineraryItem(
                title: "Houseboat", vendor: "Spice Coast", kind: .stay,
                date: day, cost: 24_000,
                participantIDs: [you.id, Traveller.ed.id], paidByID: Traveller.ed.id
            ),
            ItineraryItem(
                title: "Toddy shop lunch", kind: .meal,
                date: day, time: day.addingTimeInterval(13 * 3600), cost: 3_200,
                paidByID: Traveller.krishna.id
            ),
            ItineraryItem(
                title: "Kathakali show", kind: .activity,
                date: day.addingTimeInterval(86_400), time: day.addingTimeInterval(86_400 + 18 * 3600),
                cost: 4_800, paidByID: you.id
            )
        ]
    )

    let store = TripStore(trips: [trip])

    return ScrollView {
        VStack(spacing: 14) {
            ForEach([EquiCardKind.trip, .recap, .balance, .itinerary, .bookings, .spending, .people, .gaps], id: \.self) { kind in
                EquiCardView(card: EquiCard(kind: kind, tripID: trip.id, category: kind == .spending ? .meal : nil))
            }
            EquiCardView(card: EquiCard(kind: .trips, tripSet: .all))
        }
        .padding(16)
    }
    .background { CanvasBackground() }
    .environment(\.tripStore, store)
}

// MARK: - 5. Who's on it

/// Everyone on the trip and what each of them is carrying — the question
/// "who's actually paid for things?" answered per person.
private struct EquiPeopleCard: View {
    let trip: Trip
    /// Someone the question named: first on the list, the rest stepped back.
    var focus: UUID?

    /// The named person first, then whoever has paid most.
    private var people: [Traveller] {
        let sorted = trip.travellers
            .filter { !trip.invitedIDs.contains($0.id) }
            .sorted { trip.paid(by: $0.id) > trip.paid(by: $1.id) }
        guard let focus, let index = sorted.firstIndex(where: { $0.id == focus }) else { return Array(sorted.prefix(5)) }
        var ordered = sorted
        ordered.insert(ordered.remove(at: index), at: 0)
        return Array(ordered.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "person.2.fill", title: "Who's on it", trip: trip)

            VStack(spacing: 10) {
                ForEach(people) { traveller in
                    row(for: traveller)
                        .opacity(focus == nil || focus == traveller.id ? 1 : 0.45)
                }
            }
        }
        .padding(14)
    }

    private func row(for traveller: Traveller) -> some View {
        let balance = trip.balance(for: traveller.id)

        return HStack(spacing: 9) {
            TravellerAvatar(traveller: traveller, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(traveller.id == Traveller.you.id ? "You" : traveller.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text("paid \(Money.format(trip.paid(by: traveller.id), code: trip.currencyCode))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 4)

            Text(abs(balance) < SettlementEngine.epsilon
                 ? "square"
                 : Money.format(balance, code: trip.currencyCode, signed: true))
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(
                    abs(balance) < SettlementEngine.epsilon
                        ? AppTheme.moneyFlat
                        : (balance > 0 ? AppTheme.moneyIn : AppTheme.moneyOut)
                )
        }
    }
}
