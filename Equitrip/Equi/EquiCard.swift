//
//  EquiCard.swift
//  Equitrip
//

import SwiftUI
import FoundationModels

// MARK: - What the model chooses

/// The shapes Equi can answer *in*, beyond a paragraph of prose.
///
/// The model picks one of these by name and nothing else — it never fills in
/// the contents. That separation is the whole design: a small on-device model
/// asked to restate a balance will eventually restate it wrong, so the card is
/// drawn live from `TripStore` at render time and the model's only job is
/// deciding which view of the trip answers the question. It cannot get a
/// number wrong that it never touches.
@Generable
enum EquiCardKind: Hashable {
    /// Talk, no card. Most questions land here.
    case text
    /// The trip itself: cover, dates, who's on it, where you stand.
    case trip
    /// Money: your net position and the transfers that would clear it.
    case balance
    /// What's coming up next on the plan.
    case itinerary
    /// Where the money is going, broken down by category.
    case spending
    /// Everyone on the trip and what each of them is carrying.
    case people
}

/// One answer from Equi: what to say, and what to draw underneath it.
///
/// Field order is load-bearing. The model generates properties in declaration
/// order, so `reply` first means the text starts streaming immediately, and
/// `card` last means the card only appears once `tripTitle` has already
/// resolved — otherwise a card would flash up against a fallback trip and
/// then swap out from under the reader.
@Generable
struct EquiAnswer {
    @Guide(description: "Your reply, in one or two friendly sentences. When a card is shown, do not repeat the figures it already displays — introduce it instead.")
    var reply: String

    @Guide(description: "The exact title of the trip the answer is about, copied from the briefing. Empty string when no card is shown.")
    var tripTitle: String

    @Guide(description: "Which card to draw under the reply. Use 'text' unless a card genuinely answers the question better than a sentence would.")
    var card: EquiCardKind
}

/// A card the model asked for, bound to a real trip.
struct EquiCard: Equatable {
    let kind: EquiCardKind
    let tripID: UUID
}

extension EquiCardKind {
    /// The name this choice is stored under in `equi_messages.card_kind`.
    ///
    /// Spelled out rather than taken from a `RawRepresentable` conformance:
    /// `@Generable` synthesises its own machinery over this enum, and a stored
    /// transcript must not change meaning because a case was renamed or
    /// reordered to read better in the model's briefing.
    var storageKey: String {
        switch self {
        case .text: "text"
        case .trip: "trip"
        case .balance: "balance"
        case .itinerary: "itinerary"
        case .spending: "spending"
        case .people: "people"
        }
    }

    init?(storageKey: String) {
        switch storageKey {
        case "text": self = .text
        case "trip": self = .trip
        case "balance": self = .balance
        case "itinerary": self = .itinerary
        case "spending": self = .spending
        case "people": self = .people
        // A card written by a newer build than this one. The reply still reads
        // fine as prose, which is the point of keeping the text beside it.
        default: return nil
        }
    }
}

extension EquiCard {
    /// Rebuilds a card from a saved transcript, or nothing when the row was
    /// plain prose or named a card this build doesn't know.
    init?(storageKey: String?, tripID: UUID?) {
        guard let storageKey, let tripID, let kind = EquiCardKind(storageKey: storageKey) else { return nil }
        self.init(kind: kind, tripID: tripID)
    }
}

// MARK: - Renderer

/// Draws whichever card the model picked, reading the trip live out of the
/// store — so a card that's been sitting in the thread for ten minutes still
/// shows the right number after somebody logs an expense.
struct EquiCardView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.colorScheme) private var scheme

    let card: EquiCard

    var body: some View {
        if let trip = store.trip(card.tripID) {
            content(for: trip)
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

    @ViewBuilder
    private func content(for trip: Trip) -> some View {
        switch card.kind {
        case .trip: EquiTripCard(trip: trip)
        case .balance: EquiBalanceCard(trip: trip)
        case .itinerary: EquiItineraryCard(trip: trip)
        case .spending: EquiSpendingCard(trip: trip)
        case .people: EquiPeopleCard(trip: trip)
        case .text: EmptyView()
        }
    }
}

// MARK: - Shared chrome

/// Every card says what it is on the left and which trip it's about on the
/// right, so a card scrolled back to a week later still explains itself.
private struct EquiCardHeader: View {
    let symbol: String
    let title: String
    let trip: Trip

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(trip.tint)

            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .kerning(0.4)
                .foregroundStyle(AppTheme.inkSecondary)

            Spacer(minLength: 6)

            Text(trip.title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
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
                        .font(AppTheme.display(19))
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

    private var transfers: [SettlementEngine.Transfer] { Array(trip.suggestedTransfers.prefix(3)) }

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
private struct EquiItineraryCard: View {
    let trip: Trip

    private var upcoming: [ItineraryItem] { trip.upcoming(limit: 3) }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "calendar", title: "Up next", trip: trip)

            if upcoming.isEmpty {
                Text("Nothing booked yet.")
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

            let rows = Array(totals.prefix(4))
            let largest = rows.first?.amount ?? 1

            Text(trip.projectedLabel)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if rows.isEmpty {
                Text("Nothing has a price on it yet.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                VStack(spacing: 10) {
                    ForEach(rows, id: \.kind) { row in
                        bar(kind: row.kind, amount: row.amount, fraction: row.amount / largest)
                    }
                }
            }
        }
        .padding(14)
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
            ForEach([EquiCardKind.trip, .balance, .itinerary, .spending, .people], id: \.self) { kind in
                EquiCardView(card: EquiCard(kind: kind, tripID: trip.id))
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "person.2.fill", title: "Who's on it", trip: trip)

            VStack(spacing: 10) {
                ForEach(trip.travellers.prefix(5)) { traveller in
                    row(for: traveller)
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
