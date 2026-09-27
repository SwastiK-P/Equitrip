//
//  EquiCardComponents.swift
//  Equitrip
//

import SwiftUI

// MARK: - Bookings of one kind

/// Every booking of one kind, in order — "where am I staying?" answered with
/// the stays and their nights, "when do I fly?" with the flights and their
/// routes, instead of whatever happens to be next on the plan.
@MainActor
struct EquiBookingsCard: View {
    let trip: Trip
    var category: ItineraryKind?

    private static let limit = 5

    private var items: [ItineraryItem] {
        trip.items
            .filter { category == nil || $0.kind == category }
            .sorted(by: Trip.chronological)
    }

    private var title: String {
        switch category {
        case .flight: "Flights"
        case .train: "Trains"
        case .drive: "Transfers"
        case .stay: "Stays"
        case .activity: "Activities"
        case .meal: "Food"
        case .other, nil: "Bookings"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: category?.symbol ?? "list.bullet", title: title, trip: trip)

            if items.isEmpty {
                Text(category == nil ? "Nothing booked yet." : "No \(title.lowercased()) booked yet.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                VStack(spacing: 11) {
                    ForEach(items.prefix(Self.limit)) { item in
                        row(for: item)
                            .opacity(isDone(item) ? 0.5 : 1)
                    }
                }

                if items.count > Self.limit {
                    Text("+ \(items.count - Self.limit) more")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
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

    /// Only while the trip is on: before it, nothing is done; after it,
    /// everything is, and a card of greyed rows says nothing.
    private func isDone(_ item: ItineraryItem) -> Bool {
        trip.phase == .live && (item.time ?? item.date.endOfDay) < Date()
    }

    private func subtitle(for item: ItineraryItem) -> String {
        var pieces: [String] = []
        if let flight = item.flight, let from = flight.departureAirport, let to = flight.arrivalAirport {
            pieces.append("\(from) → \(to)")
        }
        pieces.append(DateFormatter.cached("EEE d MMM").string(from: item.day))
        if let time = item.timeLabel { pieces.append(time) }
        if item.kind == .stay, let nights = EquiFacts.nights(of: item, in: trip) {
            pieces.append(nights.pluralised("night"))
        }
        if let vendor = item.vendorName, item.flight == nil { pieces.append(vendor) }
        return pieces.joined(separator: " · ")
    }
}

// MARK: - Several trips

/// Trips side by side: the list for "my past trips", the ranking for "which
/// trip cost the most?", the tally for "do I owe anyone anywhere?".
///
/// The only card about more than one trip, so the only one whose rows open a
/// trip each rather than the card opening one as a whole.
struct EquiTripsCard: View {
    @Environment(\.tripStore) private var store

    let card: EquiCard
    var onOpenTrip: (Trip) -> Void

    private static let limit = 6

    private var trips: [Trip] {
        let listed: [Trip]
        if !card.tripIDs.isEmpty {
            listed = card.tripIDs.compactMap { store.trip($0) }
        } else {
            switch card.tripSet ?? .all {
            case .all: listed = TripMatcher.byRelevance(store.trips)
            case .past: listed = store.trips.filter { $0.phase == .past }.sorted { $0.endDate > $1.endDate }
            case .upcoming: listed = TripMatcher.byRelevance(store.trips.filter { $0.phase != .past })
            }
        }
        switch card.metric {
        case .cost: return listed.sorted { $0.projectedCost > $1.projectedCost }
        case .balance: return listed.filter(\.showsBalance).sorted { abs($0.netBalance) > abs($1.netBalance) }
        case nil: return listed
        }
    }

    private var title: String {
        if !card.tripIDs.isEmpty { return "Side by side" }
        if card.metric == .balance { return "Where you stand" }
        switch card.tripSet ?? .all {
        case .all: return card.metric == .cost ? "By cost" : "Your trips"
        case .past: return "Past trips"
        case .upcoming: return "Coming up"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: card.metric == .balance ? "arrow.left.arrow.right" : "suitcase.fill", title: title, trip: nil)

            if trips.isEmpty {
                Text(card.metric == .balance ? "No money moving on any trip." : "No trips here yet.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                VStack(spacing: 4) {
                    ForEach(trips.prefix(Self.limit)) { trip in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onOpenTrip(trip)
                        } label: {
                            row(for: trip)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                if trips.count > Self.limit {
                    Text("+ \((trips.count - Self.limit).pluralised("more trip"))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .padding(14)
    }

    private func row(for trip: Trip) -> some View {
        HStack(spacing: 10) {
            IconTile(symbol: trip.symbol, tint: trip.tint, size: 34, corner: 10)

            VStack(alignment: .leading, spacing: 1.5) {
                Text(trip.title)
                    .tripTitle(trip.titleStyle, size: 15)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(trip.phase.tint)
                        .frame(width: 5, height: 5)
                    Text("\(trip.destination) · \(DateFormatter.cached("d MMM yyyy").string(from: trip.startDate))")
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                if card.metric == .balance {
                    Text(trip.netLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(trip.netTone)
                    Text(trip.netCaption)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else {
                    Text(trip.projectedLabel)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(trip.phase.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .lineLimit(1)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }
}

// MARK: - A finished trip

/// A trip that's over, told as its totals — the Trip card shows where a trip
/// is going, which for one that's back says nothing.
struct EquiRecapCard: View {
    let trip: Trip

    private var recap: TripRecap { TripRecap(trip: trip) }
    private var code: String { trip.currencyCode }

    var body: some View {
        let recap = recap

        VStack(alignment: .leading, spacing: 12) {
            EquiCardHeader(symbol: "book.closed.fill", title: "Trip recap", trip: trip)

            VStack(alignment: .leading, spacing: 2) {
                Text(Money.format(recap.total(.group).rounded(), code: code))
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("\(trip.items.count.pluralised("booking")) · \(trip.dayCount.pluralised("day")) · \(trip.dateRange)")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                stat("Each", Money.format(recap.perPerson.rounded(), code: code))
                stat("Your share", Money.format(recap.total(.you).rounded(), code: code))
                stat("Per day", Money.format(recap.perDay.rounded(), code: code))
            }

            if let top = recap.biggest(.group) {
                Hairline()
                HStack(spacing: 8) {
                    IconTile(symbol: top.symbol, tint: top.kind.tint, size: 26, corner: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Biggest splurge")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                        Text(top.title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Text(Money.format(top.cost, code: code))
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }
            }

            squaring(recap.squaring(.you))
        }
        .padding(14)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppTheme.ink.opacity(0.04), in: .rect(cornerRadius: 11, style: .continuous))
    }

    @ViewBuilder
    private func squaring(_ state: TripRecap.Squaring) -> some View {
        switch state {
        case .nothingRecorded:
            TagChip(title: "No payments logged", tint: AppTheme.inkTertiary, symbol: "clock.fill")
        case .square:
            TagChip(title: "All square", tint: AppTheme.positive, symbol: "checkmark.seal.fill")
        case .open(let transfers, let pending):
            let count = transfers.count + pending.count
            TagChip(title: "\(count.pluralised("payment")) still open", tint: AppTheme.danger, symbol: "arrow.left.arrow.right")
        }
    }
}

// MARK: - What's missing

/// The holes in the plan (`EquiPlanCheck`), a row each.
struct EquiGapsCard: View {
    let trip: Trip

    private static let limit = 5

    var body: some View {
        let gaps = EquiPlanCheck(trip: trip).gaps

        VStack(alignment: .leading, spacing: 11) {
            EquiCardHeader(symbol: "checklist", title: "Open in the plan", trip: trip)

            if gaps.isEmpty {
                TagChip(title: "Nothing missing", tint: AppTheme.positive, symbol: "checkmark.seal.fill")
            } else {
                VStack(spacing: 10) {
                    ForEach(gaps.prefix(Self.limit)) { gap in
                        HStack(spacing: 10) {
                            IconTile(symbol: gap.symbol, tint: Palette.amber, size: 30, corner: 9)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(gap.label)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                Text(DateFormatter.cached("EEEE d MMM").string(from: gap.date))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(AppTheme.inkTertiary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }

                if gaps.count > Self.limit {
                    Text("+ \(gaps.count - Self.limit) more")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
        }
        .padding(14)
    }
}
