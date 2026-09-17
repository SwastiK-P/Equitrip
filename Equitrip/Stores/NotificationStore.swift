//
//  NotificationStore.swift
//  Equitrip
//

import SwiftUI

/// The notification list, and whether you've read it.
///
/// Separate from `TripStore` because notifications outlive the thing they
/// describe — a refund on a trip that's since been settled is still worth
/// reading — and because the unread count is consulted from the top bar on
/// every screen.
///
/// Backed by the `notifications` table. Reads and writes are optimistic: the
/// list updates on device first and the server catches up, because marking
/// something read is not worth a spinner.
@MainActor
@Observable
final class NotificationStore {
    /// Everything the server has for this account, muted channels included.
    /// `feed` is what the screens read.
    private(set) var items: [AppNotification]
    private(set) var isLoading = false

    init(items: [AppNotification] = []) {
        self.items = items.sorted { $0.date > $1.date }
    }

    /// What the app actually shows: everything whose channel is switched on.
    ///
    /// Filtered on read rather than on receipt. A muted channel is "don't tell
    /// me about this", not "throw it away" — switching Payments back on should
    /// reveal what happened while it was off, not present an account of the
    /// trip with a hole in it.
    var feed: [AppNotification] {
        items.filter { $0.kind.channel.isOn }
    }

    var unreadCount: Int { feed.filter(\.isUnread).count }
    var unread: [AppNotification] { feed.filter(\.isUnread) }
    var read: [AppNotification] { feed.filter { !$0.isUnread } }

    // MARK: - Loading

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // A failure leaves the list exactly as it was. An empty feed is a
        // perfectly ordinary state here and the sheet says so itself, so
        // there's nothing an error banner would add that the bell doesn't
        // already communicate by staying quiet.
        guard let remote = try? await SupabaseRepository.shared.loadNotifications() else { return }
        items = remote.sorted { $0.date > $1.date }
    }

    // MARK: - Read state

    func markRead(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].isUnread else { return }
        items[index].isUnread = false
        Task { await SupabaseRepository.shared.markNotificationRead(id) }
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        for index in items.indices where items[index].isUnread {
            items[index].isUnread = false
        }
        Task { await SupabaseRepository.shared.markAllNotificationsRead() }
    }

    // MARK: - Posting

    /// Files a notification for everyone named, and shows it here immediately
    /// if you're one of them.
    func post(_ notification: AppNotification, to recipients: [UUID]) {
        if recipients.contains(Traveller.you.id) {
            items.insert(notification, at: 0)
        }

        Task {
            for recipient in recipients {
                await SupabaseRepository.shared.post(notification, to: recipient)
            }
        }
    }

    /// Everyone on the trip hears about a new arrival.
    ///
    /// The joiner is excluded on purpose — being told you joined something you
    /// just joined is noise, and it's the people already on the trip who need
    /// to know the split maths just changed under them.
    func announceJoin(of joiner: Traveller, to trip: Trip) {
        guard joiner.id != Traveller.you.id else { return }

        let recipients = trip.travellers.map(\.id).filter { $0 != joiner.id }
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .joined,
                title: "\(joiner.name) joined \(trip.title)",
                body: trip.items.isEmpty
                    ? "They're on the trip. Nothing is shared with them yet."
                    : "Shares on \(trip.items.count.pluralised("booking")) will recalculate once they're added to them.",
                tripID: trip.id
            ),
            to: recipients
        )
    }

    /// Somebody has been asked to join.
    ///
    /// Goes only to the person invited. The rest of the group hears when the
    /// invitation is *accepted* — that's the moment shares actually move, and
    /// announcing the asking would have the group told twice about one arrival.
    func announceInvitation(of traveller: Traveller, to trip: Trip) {
        guard traveller.id != Traveller.you.id else { return }

        post(
            AppNotification(
                kind: .invited,
                title: "\(Traveller.you.name) invited you to \(trip.title)",
                body: "\(trip.destination.isEmpty ? "A trip" : trip.destination) · \(trip.dateRange). Have a look before you accept — you won't be on it, or on its ledger, until you do.",
                tripID: trip.id
            ),
            to: [traveller.id]
        )
    }

    /// Somebody has asked to leave a trip that's already running.
    ///
    /// This goes to the organisers rather than the whole group, because it's
    /// addressed to whoever has to answer it — everyone else hears about it
    /// once it's actually happened, which is `announceDeparture`. Two events
    /// for two different facts: a request, and a change.
    func announceDepartureRequest(_ plan: DeparturePlan, in trip: Trip) {
        let recipients = trip.organisers
            .map(\.id)
            .filter { $0 != plan.traveller.id && !trip.hasLeft($0) }
        guard !recipients.isEmpty else { return }

        let name = plan.traveller.id == Traveller.you.id ? "You" : plan.traveller.name
        let verb = plan.traveller.id == Traveller.you.id ? "want" : "wants"

        post(
            AppNotification(
                kind: .departureRequested,
                title: "\(name) \(verb) to leave \(trip.title)",
                body: plan.affectsOthers
                    ? "Review it before it's final — it moves everyone else's share by \(Money.format(abs(plan.groupImpactEach).rounded(), code: trip.currencyCode))."
                    : "Review it before it's final. Nobody else's share changes.",
                tripID: trip.id
            ),
            to: recipients
        )
    }

    /// The exit went through. Everyone hears, because everyone's ledger just
    /// stopped moving for that person — and the figure in the body is the
    /// thing anybody will actually want to know.
    func announceDeparture(_ departure: TripDeparture, of traveller: Traveller, in trip: Trip) {
        let recipients = trip.travellers.map(\.id).filter { $0 != Traveller.you.id }
        guard !recipients.isEmpty else { return }

        let day = trip.departureDayIndex(traveller.id).map { "Day \($0)" }
            ?? DateFormatter.cached("d MMM").string(from: departure.leftAt)
        let balance = departure.agreedBalance

        post(
            AppNotification(
                kind: .left,
                title: "\(traveller.name) left \(trip.title)",
                body: abs(balance) < SettlementEngine.epsilon
                    ? "They were on it to \(day), and they're square with everyone."
                    : balance > 0
                        ? "They were on it to \(day). The group owes them \(Money.format(abs(balance).rounded(), code: trip.currencyCode))."
                        : "They were on it to \(day). They owe \(Money.format(abs(balance).rounded(), code: trip.currencyCode)).",
                tripID: trip.id
            ),
            to: recipients
        )
    }
}

// MARK: - Itinerary events

/// What the rest of the group hears when a booking moves.
///
/// Every one of these used to be silent. The app told you when somebody joined
/// a trip and when a trip was created, and nothing else — so a hotel could be
/// deleted, a price could double and a payment could be recorded against your
/// name, and the first you'd know was the next time you happened to open the
/// itinerary and read it closely enough to notice. On a shared ledger every
/// one of those is a change to what you owe.
extension NotificationStore {

    /// Everyone on the trip except you. The person who made the change was
    /// there when it happened.
    private func audience(of trip: Trip) -> [UUID] {
        trip.travellers.map(\.id).filter { $0 != Traveller.you.id }
    }

    private func actor() -> String { Traveller.you.name }

    func announceBookingAdded(_ item: ItineraryItem, to trip: Trip) {
        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .booking,
                title: "\(actor()) added \(item.title) to \(trip.title)",
                body: [
                    item.kind.label,
                    DateFormatter.cached("d MMM").string(from: item.date),
                    item.cost > 0 ? Money.format(item.cost, code: trip.currencyCode) : nil,
                    item.cost > 0 ? item.split.shortLabel.lowercased() : nil
                ]
                .compactMap { $0 }
                .joined(separator: " · "),
                tripID: trip.id
            ),
            to: recipients
        )
    }

    /// The whole trip, gone. Worth telling everyone: their share of it goes
    /// with it, and a trip that simply vanishes from the list with no
    /// explanation is indistinguishable from a bug.
    func announceTripDeleted(_ trip: Trip) {
        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .bookingRemoved,
                title: "\(actor()) deleted \(trip.title)",
                body: trip.items.isEmpty
                    ? "The trip is gone. Nothing was booked on it."
                    : "\(trip.items.count.pluralised("booking")) went with it, and any balance on it no longer applies.",
                tripID: trip.id
            ),
            to: recipients
        )
    }

    func announceBookingRemoved(_ item: ItineraryItem, from trip: Trip) {
        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .bookingRemoved,
                title: "\(actor()) removed \(item.title) from \(trip.title)",
                body: item.cost > 0
                    ? "\(Money.format(item.cost, code: trip.currencyCode)) came off the trip. Shares have recalculated."
                    : "It's off the itinerary.",
                tripID: trip.id
            ),
            to: recipients
        )
    }

    /// A booking that changed, and specifically *what* changed.
    ///
    /// The diff is the whole value of this one. "Villa Aroma was updated" is
    /// an event; "Villa Aroma ₹18,000 → ₹24,000" is a reason to go and look,
    /// and the difference between the two is whether anybody does.
    func announceBookingChanged(from old: ItineraryItem, to new: ItineraryItem, in trip: Trip) {
        // A payment appearing on a booking is its own event, and a much bigger
        // one than a retitle — it's the moment the cost becomes a debt.
        if old.paidByID != new.paidByID, let payerID = new.paidByID {
            announcePayment(of: new, by: payerID, in: trip)
            return
        }

        let changes = Self.differences(from: old, to: new, currency: trip.currencyCode, trip: trip)
        guard !changes.isEmpty else { return }

        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .bookingChanged,
                title: "\(actor()) changed \(new.title)",
                body: changes.joined(separator: " · "),
                tripID: trip.id
            ),
            to: recipients
        )
    }

    /// Somebody paid. Goes to everybody the cost lands on — purely as news:
    /// the payment is taken as confirmed the moment it's recorded, and
    /// anyone who thinks it's wrong reports it from the booking itself
    /// rather than answering this.
    func announcePayment(of item: ItineraryItem, by payerID: UUID, in trip: Trip) {
        let payer = trip.traveller(payerID)?.name ?? "Someone"
        let bearers = Set(trip.bearers(of: item).map(\.id))

        // Only the people it costs something — nobody else has a stake in
        // knowing.
        let recipients = trip.travellers
            .map(\.id)
            .filter { $0 != Traveller.you.id && ($0 == payerID || bearers.contains($0)) }
        guard !recipients.isEmpty else { return }

        let each = trip.shares(of: item).first?.amount ?? 0
        let method = item.paymentMethod.map { " by \($0.label.lowercased())" } ?? ""

        post(
            AppNotification(
                kind: .payment,
                title: "\(payer) paid for \(item.title)",
                body: each > 0
                    ? "\(Money.format(item.cost, code: trip.currencyCode))\(method). Your share is \(Money.format(each, code: trip.currencyCode))."
                    : "\(Money.format(item.cost, code: trip.currencyCode))\(method).",
                tripID: trip.id,
                itemID: item.id
            ),
            to: recipients
        )
    }

    /// Payment on a booking was disputed.
    func announceDispute(of item: ItineraryItem, in trip: Trip) {
        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        let reasonSuffix = item.disputeReason.map { " (\($0))" } ?? ""
        post(
            AppNotification(
                kind: .disputed,
                title: "\(actor()) disputed a payment on \(trip.title)",
                body: "\(item.title)\(reasonSuffix) — worth reviewing before anyone settles up.",
                tripID: trip.id,
                itemID: item.id
            ),
            to: recipients
        )
    }

    /// Dispute on a booking was resolved.
    func announceDisputeResolved(for item: ItineraryItem, in trip: Trip) {
        let recipients = audience(of: trip)
        guard !recipients.isEmpty else { return }

        post(
            AppNotification(
                kind: .confirmed,
                title: "\(actor()) resolved payment dispute on \(trip.title)",
                body: "\(item.title) — payment dispute has been marked as resolved.",
                tripID: trip.id,
                itemID: item.id
            ),
            to: recipients
        )
    }

    /// The human-readable diff. Ordered by how much each field costs somebody:
    /// money first, then when, then who, then what it's called.
    private static func differences(
        from old: ItineraryItem,
        to new: ItineraryItem,
        currency: String,
        trip: Trip
    ) -> [String] {
        var changes: [String] = []

        if old.cost != new.cost {
            changes.append("\(Money.format(old.cost, code: currency)) → \(Money.format(new.cost, code: currency))")
        }

        if old.split != new.split {
            changes.append("Split \(old.split.shortLabel.lowercased()) → \(new.split.shortLabel.lowercased())")
        }

        if !Calendar.current.isDate(old.date, inSameDayAs: new.date) {
            changes.append("Moved to \(DateFormatter.cached("d MMM").string(from: new.date))")
        }

        if old.time != new.time {
            changes.append("Now at \(new.timeLabel ?? "no set time")")
        }

        if old.participantIDs != new.participantIDs {
            let added = new.participantIDs.subtracting(old.participantIDs)
            let dropped = old.participantIDs.subtracting(new.participantIDs)

            let names = { (ids: Set<UUID>) in
                ids.compactMap { trip.traveller($0)?.name }.sorted().joined(separator: ", ")
            }

            if !added.isEmpty { changes.append("Added \(names(added))") }
            if !dropped.isEmpty { changes.append("Dropped \(names(dropped))") }
        }

        if old.title != new.title {
            changes.append("Renamed from \(old.title)")
        }

        if old.kind != new.kind {
            changes.append("Now a \(new.kind.label.lowercased())")
        }

        return changes
    }
}

extension EnvironmentValues {
    @Entry var notificationStore = NotificationStore()
}
