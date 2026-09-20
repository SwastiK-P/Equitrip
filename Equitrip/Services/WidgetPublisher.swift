//
//  WidgetPublisher.swift
//  Equitrip
//

import Foundation
import WidgetKit

/// Flattens the live trip list into the shape the widgets read.
///
/// Called from `TripStore` whenever `trips` changes, which covers the sync,
/// every booking edit and every settlement — anything that can move a number
/// somebody is looking at on their home screen. It is cheap and it is
/// idempotent: the snapshot is `Equatable`, so a change that leaves
/// everything published identical writes nothing and doesn't wake the widget
/// process. (A cover photo resolving *does* count now — the watch draws the
/// cover, and that publish is how it hears there is one.)
enum WidgetPublisher {

    private nonisolated(unsafe) static var lastPublished: EquitripSnapshot?

    static func publish(_ trips: [Trip]) {
        let snapshot = snapshot(for: trips)
        guard snapshot.differs(from: lastPublished) else { return }

        lastPublished = snapshot
        SharedStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
        WatchBridge.shared.publish(snapshot)
    }

    /// Clears everything on sign-out. A widget still showing the last
    /// account's balance after somebody has signed out is a privacy problem,
    /// not a stale-data one.
    static func clear() {
        lastPublished = EquitripSnapshot.empty
        SharedStore.save(.empty)
        WidgetCenter.shared.reloadAllTimelines()
        WatchBridge.shared.publish(.empty)
    }

    // MARK: - Building

    static func snapshot(for trips: [Trip]) -> EquitripSnapshot {
        guard !trips.isEmpty else { return .empty }

        let you = Traveller.you.id
        let currency = primaryCurrency(of: trips)

        // Only trips actually denominated in the headline currency are added
        // together. The portfolio figure is already a compromise — see
        // `TripStore.primaryCurrency` — but silently adding euros to rupees
        // is a different and much worse one, so the odd-currency trips sit
        // out of the total rather than corrupting it.
        let counted = trips.filter { $0.currencyCode == currency }
        let owedToYou = counted.reduce(0) { $0 + $1.owedTo(you) }
        let youOwe = counted.reduce(0) { $0 + $1.owing(you) }
        let net = owedToYou - youOwe

        let active = trips.filter { $0.phase != .past }
        let current = trips.first { $0.phase == .live }
            ?? active.min { $0.startDate < $1.startDate }

        let eventsByTrip = Dictionary(uniqueKeysWithValues: active.map { ($0.id, events(of: $0, for: you)) })

        return EquitripSnapshot(
            generatedAt: Date(),
            currencyCode: currency,
            owedToYou: owedToYou,
            youOwe: youOwe,
            owedToYouLabel: glance(owedToYou, code: currency),
            youOweLabel: glance(youOwe, code: currency),
            netLabel: net == 0 ? "Settled" : glance(net, code: currency, signed: true),
            netCompactLabel: compact(net, code: currency),
            netCaption: caption(for: net),
            scopeCaption: scopeCaption(net: net, activeCount: active.count),
            activeTripCount: active.count,
            scopeTitle: nil,
            scopeTripID: nil,
            currentTrip: current.map { summary(of: $0, for: you) },
            upNext: current.map { events(of: $0, for: you) } ?? [],
            allTrips: active.map { summary(of: $0, for: you) },
            eventsByTrip: eventsByTrip,
            settleRequests: settleRequests(across: trips, for: you),
            hasTrips: true,
            balanceIsMeaningful: trips.contains { $0.showsBalance }
        )
    }

    private static func summary(of trip: Trip, for you: UUID) -> EquitripSnapshot.TripSummary {
        let net = trip.balance(for: you)
        let phase: EquitripSnapshot.TripSummary.Phase = switch trip.phase {
        case .upcoming: .upcoming
        case .live: .live
        case .past: .past
        }

        return .init(
            id: trip.id,
            title: trip.title,
            destination: trip.destination,
            progressLabel: trip.progressLabel,
            progress: trip.progress,
            dateRange: trip.dateRange,
            phase: phase,
            netLabel: net == 0 ? "Settled" : glance(net, code: trip.currencyCode, signed: true),
            netCaption: caption(for: net),
            net: net,
            showsBalance: trip.showsBalance,
            startDate: trip.startDate,
            dayCount: trip.dayCount,
            travellerCount: trip.travellers.count,
            yourShareLabel: glance(trip.yourShare, code: trip.currencyCode),
            titleStyle: trip.titleStyle.rawValue,
            bookingLabel: trip.bookingCount.pluralised("booking"),
            projectedLabel: trip.projectedLabel,
            coverURL: trip.cover.map { $0.thumbURL ?? $0.url },
            symbol: trip.symbol
        )
    }

    /// How many bookings any surface shows. The widgets take the first five
    /// at most — every family prefixes its own — and the watch's agenda runs
    /// on through the rest of the day, which is what the other five are for.
    private static let eventLimit = 10

    private static func events(of trip: Trip, for you: UUID) -> [EquitripSnapshot.Event] {
        trip.upcoming(limit: eventLimit).map { item in
            let share = trip.share(of: item, for: you)
            return .init(
                id: item.id,
                title: item.title,
                vendor: item.vendorName,
                symbol: item.symbol,
                kind: item.kind.rawValue,
                date: item.time ?? item.date,
                clockValue: item.clock?.value,
                clockMeridiem: item.clock?.meridiem,
                costLabel: item.cost > 0 ? glance(item.cost, code: trip.currencyCode) : nil,
                shareLabel: share > 0 ? "\(glance(share, code: trip.currencyCode)) you" : nil,
                isToday: Calendar.current.isDateInToday(item.date),
                flightNumber: item.flight?.number,
                routeLabel: item.flight.flatMap { route(of: $0) },
                terminal: item.flight?.departureTerminal,
                gate: item.flight?.departureGate,
                costCompactLabel: item.cost > 0 ? compact(item.cost, code: trip.currencyCode, signed: false) : nil,
                shareAmountLabel: share > 0 ? glance(share, code: trip.currencyCode) : nil,
                detail: detail(of: item, in: trip),
                kindLabel: item.kind.label,
                paidBy: item.paidByID.flatMap(trip.traveller).map { person($0, you: you) },
                paymentMethodLabel: item.paymentMethod?.label,
                splitLabel: item.cost > 0 ? item.split.label : nil,
                splitSymbol: item.cost > 0 ? item.split.symbol : nil,
                eachLabel: eachLabel(of: item, in: trip),
                participants: participants(of: item, in: trip, for: you),
                isDisputed: item.isDisputed,
                airline: resolved(item.flight)?.airlineName,
                departureCity: resolved(item.flight)?.departureCity,
                arrivalCity: resolved(item.flight)?.arrivalCity,
                departureTimeLabel: resolved(item.flight)?.scheduledDeparture.map { clock($0) },
                arrivalTimeLabel: resolved(item.flight)?.scheduledArrival.map { clock($0) },
                flightStatus: resolved(item.flight)?.status?.label
            )
        }
    }

    /// A flight's looked-up details, only once a lookup has run — the same
    /// test the phone's detail sheet makes before showing the ticket.
    private static func resolved(_ flight: FlightDetails?) -> FlightDetails? {
        flight.flatMap { $0.isResolved ? $0 : nil }
    }

    /// `6:30 AM` — the phone ticket card's own pattern.
    private static func clock(_ date: Date) -> String {
        DateFormatter.cached("h:mm a").string(from: date)
    }

    /// One figure for everybody, only when it is one figure: under any other
    /// split the shares differ and "each" would be a lie about all but one.
    /// Nothing for a party of one, where "each" just repeats the total.
    private static func eachLabel(of item: ItineraryItem, in trip: Trip) -> String? {
        let heads = trip.shares(of: item).count
        guard item.cost > 0, item.split == .equal, heads > 1 else { return nil }
        return "\(glance(Money.wholeShare(of: item.cost, heads: heads), code: trip.currencyCode)) each"
    }

    private static func participants(of item: ItineraryItem, in trip: Trip, for you: UUID) -> [EquitripSnapshot.Person] {
        let people = trip.participants(of: item)
        return (people.filter { $0.id == you } + people.filter { $0.id != you })
            .map { person($0, you: you) }
    }

    private static func person(_ traveller: Traveller, you: UUID) -> EquitripSnapshot.Person {
        .init(
            name: traveller.id == you ? "You" : traveller.name,
            avatar: Traveller.artwork(for: traveller.asset),
            photoURL: traveller.avatarURL
        )
    }

    /// The one line under a booking's name on the watch.
    ///
    /// The route for a flight, because that is the whole identity of one.
    /// Otherwise how many are sharing it when that's fewer than everyone —
    /// "3 of us" is the thing worth knowing about a dinner, and says more than
    /// a vendor name lifted whole out of a booking PDF. The vendor when it's
    /// everyone's.
    private static func detail(of item: ItineraryItem, in trip: Trip) -> String? {
        if let route = item.flight.flatMap({ route(of: $0) }) { return route }

        let sharing = trip.participants(of: item)
        if sharing.count < trip.travellers.count {
            if sharing.count > 1 { return "\(sharing.count) of us" }
            if let only = sharing.first { return only.id == Traveller.you.id ? "Just you" : only.name }
        }
        return item.vendorName
    }

    /// The same list as `TripStore.settlementsAwaitingYou`, across every
    /// trip rather than only the active ones — a payment on a trip that has
    /// ended still wants an answer.
    private static func settleRequests(across trips: [Trip], for you: UUID) -> [EquitripSnapshot.SettleRequest] {
        trips.flatMap { trip in
            trip.pendingSettlements
                .filter { $0.toID == you }
                .map { settlement in
                    EquitripSnapshot.SettleRequest(
                        id: settlement.id,
                        tripID: trip.id,
                        tripTitle: trip.title,
                        fromName: trip.traveller(settlement.fromID)?.name ?? "Someone",
                        // Exact, not `glance`: this is the figure somebody is
                        // checking against their bank app before confirming.
                        amountLabel: Money.format(settlement.amount, code: settlement.currencyCode),
                        methodLabel: settlement.method.label,
                        methodSymbol: settlement.method.symbol,
                        note: settlement.note,
                        createdAt: settlement.createdAt
                    )
                }
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    /// `BOM → GOI`, or nil until both ends are known.
    private static func route(of flight: FlightDetails) -> String? {
        guard let from = flight.departureAirport, let to = flight.arrivalAirport else { return nil }
        return "\(from) → \(to)"
    }

    // MARK: - Wording

    private static func primaryCurrency(of trips: [Trip]) -> String {
        let counts = Dictionary(grouping: trips, by: \.currencyCode).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? "INR"
    }

    /// Whole units, always.
    ///
    /// `Money.format` keeps the paise when there are any, which is right on a
    /// screen somebody is reconciling against a bill and wrong on every
    /// surface here: `₹74,983.33 in · ₹71,331 out` on a lock-screen line is
    /// two decimals nobody reads pushing the figures that matter into an
    /// ellipsis. A widget is a glance, and a glance rounds.
    private static func glance(_ amount: Double, code: String, signed: Bool = false) -> String {
        Money.format(amount.rounded(), code: code, signed: signed)
    }

    private static func caption(for net: Double) -> String {
        if net > 0 { return "you get back" }
        if net < 0 { return "you owe" }
        return "all square"
    }

    private static func scopeCaption(net: Double, activeCount: Int) -> String {
        guard activeCount > 0 else { return "No trips under way" }
        let trips = activeCount == 1 ? "1 active trip" : "\(activeCount) active trips"
        if net > 0 { return "You're ahead across \(trips)" }
        if net < 0 { return "You're behind across \(trips)" }
        return "Everything's square across \(trips)"
    }

    /// `+₹3.2k`, for the circular lock-screen slot.
    ///
    /// Rounded rather than truncated, and only above a thousand — `₹840`
    /// already fits, and `₹0.8k` is both longer to read and less precise than
    /// the thing it replaced.
    ///
    /// Unsigned for a cost, where `+₹32k` would read as money coming in.
    private static func compact(_ amount: Double, code: String, signed: Bool = true) -> String {
        guard amount != 0 else { return "—" }

        let sign = signed ? (amount > 0 ? "+" : "−") : ""
        let magnitude = abs(amount)
        let symbol = Money.symbol(for: code)

        switch magnitude {
        case 1_000_000...:
            return "\(sign)\(symbol)\(trimmed(magnitude / 1_000_000))m"
        case 1_000...:
            return "\(sign)\(symbol)\(trimmed(magnitude / 1_000))k"
        default:
            return sign + glance(magnitude, code: code)
        }
    }

    /// `1.2` but `12` — a decimal place is worth a character at 1.2k and
    /// worth nothing at 12.0k.
    private static func trimmed(_ value: Double) -> String {
        value < 10
            ? String(format: "%.1f", value).replacingOccurrences(of: ".0", with: "")
            : String(Int(value.rounded()))
    }
}

private extension EquitripSnapshot {
    /// Everything except the timestamp, which changes on every call and would
    /// otherwise make every publish look like news.
    func differs(from other: EquitripSnapshot?) -> Bool {
        guard var other else { return true }
        other.generatedAt = generatedAt
        return self != other
    }
}
