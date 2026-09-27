//
//  EquiPlanCheck.swift
//  Equitrip
//

import Foundation

/// The holes in a trip's plan: nights with nowhere to sleep, days with nothing
/// on, and no way there.
///
/// Answers "anything I've forgotten?" by counting rather than by asking the
/// model to eyeball a list of bookings — which it did by naming things that
/// were already booked. Shared by the reply (`EquiFacts`) and the card, so
/// the two can't disagree about what's missing.
@MainActor
struct EquiPlanCheck {

    struct Gap: Identifiable, Hashable {
        enum Kind: Hashable {
            case noStay, emptyDay, noWayThere, noWayBack
        }

        let kind: Kind
        let date: Date
        var id: String { "\(kind)-\(date.timeIntervalSince1970)" }

        var symbol: String {
            switch kind {
            case .noStay: "bed.double"
            case .emptyDay: "calendar.badge.exclamationmark"
            case .noWayThere: "airplane.departure"
            case .noWayBack: "airplane.arrival"
            }
        }

        var label: String {
            switch kind {
            case .noStay: "No stay booked"
            case .emptyDay: "Nothing planned"
            case .noWayThere: "No way there booked"
            case .noWayBack: "No way home booked"
            }
        }
    }

    let gaps: [Gap]

    init(trip: Trip) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        let dates = (0..<max(1, trip.dayCount)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let items = trip.items.sorted(by: Trip.chronological)
        let travel: Set<ItineraryKind> = [.flight, .train, .drive]

        var found: [Gap] = []

        // A night is covered from a stay's first day up to the next stay, or
        // the end of the trip — bookings carry a check-in date, not a length.
        let stays = items.filter { $0.kind == .stay }.map(\.day)
        let nights = dates.filter { $0 < end }
        if !items.isEmpty || trip.phase != .past {
            for night in nights where !stays.contains(where: { $0 <= night }) {
                found.append(Gap(kind: .noStay, date: night))
            }
        }

        let booked = Set(items.map(\.day))
        for date in dates where !booked.contains(date) && dates.count > 1 {
            found.append(Gap(kind: .emptyDay, date: date))
        }

        if !items.contains(where: { travel.contains($0.kind) && $0.day <= start }) {
            found.append(Gap(kind: .noWayThere, date: start))
        }
        if dates.count > 1, !items.contains(where: { travel.contains($0.kind) && $0.day >= end }) {
            found.append(Gap(kind: .noWayBack, date: end))
        }

        // An empty day that's also a night with no bed is one problem, not two.
        let noStay = Set(found.filter { $0.kind == .noStay }.map(\.date))
        gaps = found
            .filter { $0.kind != .emptyDay || !noStay.contains($0.date) }
            .sorted { ($0.date, $0.kind.order) < ($1.date, $1.kind.order) }
    }
}

private extension EquiPlanCheck.Gap.Kind {
    var order: Int {
        switch self {
        case .noWayThere: 0
        case .noStay: 1
        case .emptyDay: 2
        case .noWayBack: 3
        }
    }
}
