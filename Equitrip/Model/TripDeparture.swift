//
//  TripDeparture.swift
//  Equitrip
//

import SwiftUI

// MARK: - Departure

/// Somebody leaving a trip that's already running, and the arithmetic that
/// closes their side of it.
///
/// The shape of this type is the whole feature. A departure is *not* a
/// deletion — nobody is ever taken out of `Trip.travellers`, because half the
/// ledger points at them: bookings they paid for, bookings they're on, and
/// settlements in both directions. Removing the row would silently re-divide
/// every equally-split booking across the survivors, including ones that were
/// paid and settled days earlier, and the app would start disagreeing with
/// everybody's bank statement. So membership gets an *end* instead of being
/// erased, and this record is that end.
///
/// It's also deliberately two-sided, for exactly the reason `Settlement` is:
/// a balance nobody can move by typing a number into their own app is a
/// balance worth trusting. Leaving changes what other people owe, so it starts
/// as a proposal and only becomes fact when someone else agrees. Until then it
/// affects nothing at all — `Trip.bearers(of:)` ignores anything that isn't
/// `.confirmed`.
struct TripDeparture: Identifiable, Hashable {

    enum Status: String, Codable, Hashable {
        case pending, confirmed, declined

        var label: String {
            switch self {
            case .pending: "Waiting to be confirmed"
            case .confirmed: "Confirmed"
            case .declined: "Declined"
            }
        }

        var tint: Color {
            switch self {
            case .pending: Palette.amber
            case .confirmed: AppTheme.inkTertiary
            case .declined: AppTheme.danger
            }
        }
    }

    /// What happens to one booking the leaver is on.
    ///
    /// Three, not more, because there are only three answers a person can
    /// give: it already happened, it hasn't happened but it's paid for, or
    /// it's still just a plan. Everything else — refundable or not, fixed cost
    /// or per-head — changes the *default* and the wording, not the outcome.
    enum Disposition: String, Codable, Hashable {
        /// Dated on or before the day they left. Theirs, and not up for
        /// discussion — this is the interim-closing-of-the-books rule that
        /// every partnership uses when somebody exits mid-year: total the
        /// actuals up to the exit date, allocate zero after it.
        case consumed
        /// After they left, but the money is already gone and isn't coming
        /// back. Theirs unless the group says otherwise.
        case keeps
        /// After they left and nothing is committed, or the group chose to
        /// carry it. Costs them nothing.
        case dropped

        /// Whether the cost still lands on the person leaving.
        var isBorne: Bool { self != .dropped }

        var label: String {
            switch self {
            case .consumed: "Already happened"
            // Not "paid, not refundable": that's the usual *reason* a booking
            // stays with them, but the group can also agree they'll keep
            // paying their part of something nobody has settled yet. The
            // label says what is true in both cases; `DeparturePlan.reason`
            // says which one it is.
            case .keeps: "Still charged"
            case .dropped: "Not charged"
            }
        }

        var symbol: String {
            switch self {
            case .consumed: "checkmark.circle.fill"
            case .keeps: "lock.fill"
            case .dropped: "minus.circle"
            }
        }

        var tint: Color {
            switch self {
            case .consumed: AppTheme.inkSecondary
            case .keeps: Palette.amber
            case .dropped: AppTheme.positive
            }
        }
    }

    let id: UUID
    let tripID: UUID
    /// Who is leaving.
    let travellerID: UUID
    /// The last day they're on the trip. Day granularity on purpose: "Ravi
    /// left on the 14th" is a thing people can agree on, "Ravi left at
    /// 14:32:06" is not, and a booking with no time on it can't be placed
    /// either side of a clock reading.
    var leftAt: Date
    var status: Status

    /// The agreed answer for every booking the leaver was carrying, decided
    /// when the departure was proposed and frozen when it was confirmed.
    ///
    /// This is what makes the exit final. Without it, a booking edited or a
    /// traveller added six weeks later would quietly reach back and change
    /// what somebody who is no longer here owes.
    var dispositions: [UUID: Disposition]

    /// What each of those bookings worked out to at the moment both sides
    /// agreed — the statement's figures, kept verbatim.
    ///
    /// Deliberately *not* what the ledger divides by. The live ledger keeps
    /// recomputing so that shares always add up to the cost, which is an
    /// invariant worth more than a frozen number; this is the receipt for
    /// what was actually agreed, so a disagreement months later has something
    /// to point at.
    var agreedAmounts: [UUID: Double]

    /// The final figure, positive when the group owes them.
    var agreedBalance: Double

    var note: String
    let proposedByID: UUID
    let proposedAt: Date
    var respondedByID: UUID?
    var respondedAt: Date?

    init(
        id: UUID = UUID(),
        tripID: UUID,
        travellerID: UUID,
        leftAt: Date,
        status: Status = .pending,
        dispositions: [UUID: Disposition] = [:],
        agreedAmounts: [UUID: Double] = [:],
        agreedBalance: Double = 0,
        note: String = "",
        proposedByID: UUID? = nil,
        proposedAt: Date = Date(),
        respondedByID: UUID? = nil,
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.tripID = tripID
        self.travellerID = travellerID
        self.leftAt = Calendar.current.startOfDay(for: leftAt)
        self.status = status
        self.dispositions = dispositions
        self.agreedAmounts = agreedAmounts
        self.agreedBalance = agreedBalance
        self.note = note
        self.proposedByID = proposedByID ?? travellerID
        self.proposedAt = proposedAt
        self.respondedByID = respondedByID
        self.respondedAt = respondedAt
    }

    var isPending: Bool { status == .pending }
    var isConfirmed: Bool { status == .confirmed }
    /// You're the one leaving.
    var isYours: Bool { travellerID == Traveller.you.id }

    /// Whether this booking's cost still lands on the person who left.
    ///
    /// The fallback is the part worth reading. A booking that isn't in
    /// `dispositions` was never considered when the exit was agreed, which
    /// happens two ways: it was added afterwards, or nobody had put a price
    /// on it. Either way the honest rule is the same one the whole feature
    /// rests on — the books closed on the day they left, so an expense *dated*
    /// before that day is theirs even if it was typed in a week later, and
    /// anything after it isn't. A dinner somebody logs on the way home still
    /// belongs to whoever ate it.
    func bears(_ item: ItineraryItem) -> Bool {
        if let decided = dispositions[item.id] { return decided.isBorne }
        return item.day <= leftAt
    }

    /// The bookings they walked away from, in whatever order the caller wants.
    var droppedItemIDs: Set<UUID> {
        Set(dispositions.filter { $0.value == .dropped }.map(\.key))
    }
}

// MARK: - Trip integration

extension Trip {

    /// The departure that's actually in force for someone, if any. Only a
    /// confirmed one counts — a proposal changes no arithmetic anywhere, which
    /// is what makes it safe to put a live preview of it in front of both
    /// sides before either commits.
    func departure(for travellerID: UUID) -> TripDeparture? {
        departures.first { $0.travellerID == travellerID && $0.status == .confirmed }
    }

    /// A proposal waiting on an answer.
    func pendingDeparture(for travellerID: UUID) -> TripDeparture? {
        departures.first { $0.travellerID == travellerID && $0.status == .pending }
    }

    var pendingDepartures: [TripDeparture] {
        departures.filter(\.isPending).sorted { $0.proposedAt > $1.proposedAt }
    }

    var confirmedDepartures: [TripDeparture] {
        departures.filter(\.isConfirmed).sorted { $0.leftAt < $1.leftAt }
    }

    /// Everyone actually on the trip: invitations answered, and not gone home.
    /// What "add someone to this booking", "who can I settle with" and the
    /// traveller count should all read from.
    var activeTravellers: [Traveller] {
        travellers.filter { departure(for: $0.id) == nil && !invitedIDs.contains($0.id) }
    }

    var departedTravellers: [Traveller] {
        travellers.filter { departure(for: $0.id) != nil }
    }

    /// Who to draw greyed. Handed to `AvatarStack` wherever faces appear.
    var departedIDs: Set<UUID> { Set(confirmedDepartures.map(\.travellerID)) }

    func hasLeft(_ travellerID: UUID) -> Bool { departure(for: travellerID) != nil }

    func leftAt(_ travellerID: UUID) -> Date? { departure(for: travellerID)?.leftAt }

    /// "Day 3" — which day of the trip somebody's last one was. Nil when they
    /// left before it started, which is a cancellation rather than a departure
    /// and reads better as a date.
    func departureDayIndex(_ travellerID: UUID) -> Int? {
        guard let left = leftAt(travellerID) else { return nil }
        let start = Calendar.current.startOfDay(for: startDate)
        guard let days = Calendar.current.dateComponents([.day], from: start, to: left).day,
              days >= 0 else { return nil }
        return days + 1
    }

    /// How long they were here, for a line under their name.
    ///
    /// "Day 1–1" is a range of one, which is a clumsy way to say "the first
    /// day" — so a single day says so, and anything longer keeps the span.
    func presenceLabel(_ travellerID: UUID) -> String? {
        guard let left = leftAt(travellerID) else { return nil }
        guard let day = departureDayIndex(travellerID) else {
            return "Left \(DateFormatter.cached("d MMM").string(from: left))"
        }
        return day <= 1 ? "On the trip · Day 1 only" : "On the trip · Day 1–\(day)"
    }

    /// Departures that fall on a given day, so the timeline can mark them
    /// where they happened rather than in a banner at the top.
    func departures(on day: Date) -> [TripDeparture] {
        let target = Calendar.current.startOfDay(for: day)
        return confirmedDepartures.filter { $0.leftAt == target }
    }

    /// Whether a confirmed departure takes this person off this booking.
    ///
    /// The single gate. Everything about who-pays-what still flows through
    /// `bearers(of:)`; this is the one question it now has to ask that it
    /// didn't before.
    func carries(_ item: ItineraryItem, _ travellerID: UUID) -> Bool {
        guard let exit = departure(for: travellerID) else { return true }
        return exit.bears(item)
    }
}
