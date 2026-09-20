//
//  DeparturePlan.swift
//  Equitrip
//

import SwiftUI

/// Everything that happens if a given person leaves on a given day, worked out
/// before anybody commits to it.
///
/// This exists so that the sheet somebody reads before leaving and the ledger
/// everybody reads afterwards can't disagree. It doesn't re-derive any
/// arithmetic of its own: it builds the trip *as it would be* with the
/// departure applied, and then asks that trip the ordinary questions —
/// `share(of:for:)`, `remainingBalance(for:)`. Whatever the preview says is
/// what the ledger will say, because it's the same code answering.
struct DeparturePlan {

    /// One booking and what's going to happen to it.
    struct Line: Identifiable {
        let item: ItineraryItem
        var disposition: TripDeparture.Disposition
        /// Whether there's actually a decision here. A booking that already
        /// happened isn't one — you can't un-eat a dinner — and offering a
        /// switch that only has one valid position is worse than offering none.
        let isChoosable: Bool
        /// What this booking costs the leaver under the current disposition,
        /// or what dropping it saves them.
        let amount: Double
        /// What dropping it does to everybody else's share, per head. Zero
        /// when the cost shrinks with the headcount; positive when it doesn't,
        /// which is the case worth putting in front of people before they
        /// agree to anything.
        let othersDelta: Double
        let reason: String

        var id: UUID { item.id }
        var isBorne: Bool { disposition.isBorne }
    }

    let trip: Trip
    let traveller: Traveller
    /// Their last day. Moving it re-sorts every line between "already
    /// happened" and "hasn't yet", which is why the sheet lets it be changed
    /// and recomputes rather than asking for it once at the end.
    var leftAt: Date
    /// The current answers, keyed by booking. Starts at the defaults and is
    /// whatever the two sides have since agreed.
    var dispositions: [UUID: TripDeparture.Disposition]
    var note: String = ""

    // MARK: - Building

    init(trip: Trip, traveller: Traveller, leftAt: Date? = nil) {
        self.trip = trip
        self.traveller = traveller
        // Today, clamped into the trip. Leaving is something you do now; a
        // date picker opening on a day outside the trip is a form asking a
        // question it already knows the answer to.
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: trip.startDate)
        let end = Calendar.current.startOfDay(for: trip.endDate)
        self.leftAt = Calendar.current.startOfDay(for: leftAt ?? min(max(today, start), end))
        self.dispositions = [:]
        self.dispositions = Self.defaults(trip: trip, traveller: traveller, leftAt: self.leftAt)
    }

    /// Re-seeds every line that nobody has overridden, for a new leaving date.
    /// Overrides survive: someone who has already said "I'll still pay for the
    /// villa" shouldn't have to say it again because they moved their flight.
    mutating func setLeftAt(_ date: Date) {
        let day = Calendar.current.startOfDay(for: date)
        guard day != leftAt else { return }

        let oldDefaults = Self.defaults(trip: trip, traveller: traveller, leftAt: leftAt)
        let overridden = dispositions.filter { oldDefaults[$0.key] != $0.value }

        leftAt = day
        dispositions = Self.defaults(trip: trip, traveller: traveller, leftAt: day)
        // A past booking has no choice to preserve — an override from when it
        // was still in the future stops applying the moment it isn't.
        for (id, value) in overridden where dispositions[id] != .consumed {
            dispositions[id] = value
        }
    }

    /// The rule, in one place.
    ///
    /// Before the exit date it's theirs and there's nothing to decide. After
    /// it, the only question that matters is whether money has already left
    /// somebody's hands: a paid booking is a debt and stays with them, an
    /// unpaid one is a plan and goes away with them. That second half is a
    /// rule the ledger already lives by — `Trip.owed(by:)` has always counted
    /// only bookings with a payer — so this doesn't introduce a new idea, it
    /// just applies the existing one at the moment somebody walks off.
    private static func defaults(
        trip: Trip,
        traveller: Traveller,
        leftAt: Date
    ) -> [UUID: TripDeparture.Disposition] {
        let base = Self.stripped(trip, of: traveller.id)
        var result: [UUID: TripDeparture.Disposition] = [:]

        for item in base.items where base.bearers(of: item).contains(where: { $0.id == traveller.id }) {
            if item.day <= leftAt {
                result[item.id] = .consumed
            } else if item.paidByID != nil {
                result[item.id] = .keeps
            } else {
                result[item.id] = .dropped
            }
        }
        return result
    }

    /// The trip with any existing departure for this person taken back out, so
    /// a plan can be recomputed from scratch — including when an organiser is
    /// re-reviewing one that's already been proposed.
    private static func stripped(_ trip: Trip, of travellerID: UUID) -> Trip {
        var copy = trip
        copy.departures.removeAll { $0.travellerID == travellerID }
        return copy
    }

    // MARK: - Derived trips

    /// The trip as it stands, ignoring this departure entirely.
    var baseTrip: Trip { Self.stripped(trip, of: traveller.id) }

    /// The trip as it would be once this is confirmed. Everything the sheet
    /// shows is read off this.
    var previewTrip: Trip {
        var copy = baseTrip
        copy.items = adjustedItems
        copy.departures.append(appliedRecord)
        return copy
    }

    /// The bare record the preview needs: a date and a decision per booking,
    /// and nothing derived.
    ///
    /// Separate from `record(status:)` because that one carries the agreed
    /// figures, and computing those means reading `lines`, which reads
    /// `previewTrip`, which would be right back here. Only the two fields
    /// `Trip.carries(_:_:)` actually consults are needed to apply a departure;
    /// the figures are for storage, and they're computed once, at the end.
    private var appliedRecord: TripDeparture {
        TripDeparture(
            tripID: trip.id,
            travellerID: traveller.id,
            leftAt: leftAt,
            status: .confirmed,
            dispositions: dispositions
        )
    }

    /// Bookings with the leaver's cost taken out of them where that's what
    /// actually happens.
    ///
    /// The distinction is the one thing here that can't be fudged. Five people
    /// splitting five museum tickets is a per-head cost: one person drops out
    /// and the booking genuinely costs less, so the price comes down and
    /// nobody else's share moves. Five people splitting one villa is not: the
    /// villa costs what it costs, and if the price came down for a departure
    /// the group would be quietly pretending to have money it doesn't. So
    /// fixed costs keep their price, and the extra it lands on everybody else
    /// gets shown rather than absorbed silently.
    var adjustedItems: [ItineraryItem] {
        let base = baseTrip

        return base.items.map { item in
            guard dispositions[item.id] == .dropped,
                  item.paidByID == nil,
                  item.kind.costBasis == .perPerson,
                  item.cost > 0
            else { return item }

            var copy = item
            copy.cost = Swift.max(0, item.cost - base.share(of: item, for: traveller.id))
            // A typed figure has to go with the person it was typed for, or
            // the exact amounts stop adding up to the cost.
            copy.customShares.removeValue(forKey: traveller.id)
            copy.participantIDs.remove(traveller.id)
            return copy
        }
    }

    // MARK: - Lines

    /// Every booking with a decision attached, in trip order. Grouped by the
    /// sheet, not here — the order things happened in is the order they should
    /// be read in.
    var lines: [Line] {
        let base = baseTrip
        let preview = previewTrip

        return base.items
            .filter { dispositions[$0.id] != nil }
            .sorted(by: Trip.chronological)
            .map { item in
                let disposition = dispositions[item.id] ?? .consumed
                let mine = base.share(of: item, for: traveller.id)

                return Line(
                    item: item,
                    disposition: disposition,
                    isChoosable: disposition != .consumed,
                    amount: mine,
                    othersDelta: othersDelta(for: item, base: base, preview: preview),
                    reason: reason(for: item, disposition: disposition)
                )
            }
    }

    /// What one other bearer's share of this booking moves by. Read off a real
    /// traveller rather than computed from headcounts, so it stays right for
    /// custom splits and for bookings only some of the group is on.
    private func othersDelta(for item: ItineraryItem, base: Trip, preview: Trip) -> Double {
        // Skip the payer where possible: they carry the split's leftover unit.
        let others = base.bearers(of: item).filter { $0.id != traveller.id }
        guard let other = others.first(where: { $0.id != item.paidByID }) ?? others.first else { return 0 }
        guard let updated = preview.items.first(where: { $0.id == item.id }) else { return 0 }

        let delta = preview.share(of: updated, for: other.id) - base.share(of: item, for: other.id)
        return abs(delta) < SettlementEngine.epsilon ? 0 : delta
    }

    /// Whose exit this is, from the reader's point of view. The same plan is
    /// read by the person leaving and by whoever is answering them, and
    /// "Before you left" on somebody else's request is simply wrong.
    private var subject: (they: String, left: String) {
        traveller.id == Traveller.you.id ? ("you", "you left") : ("they", "they left")
    }

    private func reason(for item: ItineraryItem, disposition: TripDeparture.Disposition) -> String {
        switch disposition {
        case .consumed:
            return "Before \(subject.left)"
        case .keeps:
            // Two ways a future booking stays with them, and they read very
            // differently to the person about to agree to it.
            guard let payer = item.paidByID.flatMap(trip.traveller) else {
                return traveller.id == Traveller.you.id
                    ? "You're still paying your share"
                    : "Still paying their share"
            }
            return "\(payer.id == Traveller.you.id ? "You" : payer.name) already paid this"
        case .dropped:
            if item.paidByID != nil { return "The group is covering this" }
            if item.kind.costBasis == .fixed { return "Nobody's paid it yet" }
            return traveller.id == Traveller.you.id ? "Not booked for you" : "Not booked for them"
        }
    }

    // MARK: - Totals

    /// What they still owe, or are still owed, once this goes through. The one
    /// number the whole sheet exists to produce.
    var finalBalance: Double { previewTrip.remainingBalance(for: traveller.id) }

    /// Their share of everything they're still carrying.
    var carriedTotal: Double {
        lines.filter(\.isBorne).reduce(0) { $0 + $1.amount }
    }

    /// What walking away takes off their bill.
    var droppedTotal: Double {
        lines.filter { !$0.isBorne }.reduce(0) { $0 + $1.amount }
    }

    /// What the rest of the group picks up as a result — the number that
    /// answers "is this costing anyone else anything?", and the reason it's
    /// impossible for that to happen quietly.
    var groupImpact: Double {
        let base = baseTrip
        let preview = previewTrip

        return base.travellers
            .filter { $0.id != traveller.id }
            .reduce(0) { total, other in
                total + (preview.cost(for: other.id) - base.cost(for: other.id))
            }
    }

    /// Per head, which is how anybody actually thinks about it.
    var groupImpactEach: Double {
        let others = Swift.max(1, baseTrip.travellers.count - 1)
        return groupImpact / Double(others)
    }

    var affectsOthers: Bool { abs(groupImpact) > SettlementEngine.epsilon }

    /// Bookings the leaver paid for that outlive them. Worth calling out on
    /// its own: the group owes this person money, and "I've left" is the
    /// moment somebody is most likely to assume the opposite.
    var paidForOthers: [ItineraryItem] {
        trip.items.filter { $0.paidByID == traveller.id }
    }

    /// Nothing to settle, and nothing outstanding either way.
    var isClean: Bool { abs(finalBalance) < SettlementEngine.epsilon }

    /// Whether leaving is even a sensible thing to offer.
    ///
    /// Two blocks, and only two. A trip needs somebody who can edit it, and a
    /// trip needs somebody on it — both are states you can't come back from
    /// inside the app.
    enum Block {
        case lastOrganiser, lastTraveller

        var title: String {
            switch self {
            case .lastOrganiser: "You're the only organiser"
            case .lastTraveller: "You're the only one here"
            }
        }

        var detail: String {
            switch self {
            case .lastOrganiser: "Make someone else an organiser first, so the trip still has someone who can edit it."
            case .lastTraveller: "There'd be nobody left. Delete the trip instead if you're not going."
            }
        }
    }

    var block: Block? {
        let remaining = trip.activeTravellers.filter { $0.id != traveller.id }
        if remaining.isEmpty { return .lastTraveller }
        if trip.organiserIDs.contains(traveller.id),
           !remaining.contains(where: { trip.organiserIDs.contains($0.id) }) {
            return .lastOrganiser
        }
        return nil
    }

    // MARK: - Committing

    /// Turns the plan into the record that gets stored.
    func record(status: TripDeparture.Status, respondedBy: UUID? = nil) -> TripDeparture {
        let existing = trip.departures.first { $0.travellerID == traveller.id }

        return TripDeparture(
            id: existing?.id ?? UUID(),
            tripID: trip.id,
            travellerID: traveller.id,
            leftAt: leftAt,
            status: status,
            dispositions: dispositions,
            agreedAmounts: lines.filter(\.isBorne).reduce(into: [:]) { $0[$1.item.id] = $1.amount },
            agreedBalance: finalBalance,
            note: note,
            proposedByID: existing?.proposedByID ?? Traveller.you.id,
            proposedAt: existing?.proposedAt ?? Date(),
            respondedByID: respondedBy,
            respondedAt: respondedBy == nil ? nil : Date()
        )
    }

    /// Rebuilds a plan from a proposal somebody else made, so the person
    /// reviewing it sees exactly the lines that were proposed rather than a
    /// fresh set of defaults computed from today.
    static func review(_ departure: TripDeparture, in trip: Trip) -> DeparturePlan? {
        guard let traveller = trip.traveller(departure.travellerID) else { return nil }

        var plan = DeparturePlan(trip: trip, traveller: traveller, leftAt: departure.leftAt)
        plan.dispositions = departure.dispositions.isEmpty ? plan.dispositions : departure.dispositions
        plan.note = departure.note
        return plan
    }
}
