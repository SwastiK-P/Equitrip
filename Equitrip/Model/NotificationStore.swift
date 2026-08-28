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

    /// Payment answers, by notification id. Kept on device: the
    /// `notifications` table has no column for them, and the answer is worth
    /// keeping so the two buttons don't come back every time the sheet opens.
    private var responses: [UUID: AppNotification.Response] = [:]

    private static let responsesKey = "notifications.responses"

    init(items: [AppNotification] = []) {
        self.items = items.sorted { $0.date > $1.date }
        loadResponses()
        applyResponses()
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

    /// Payments still waiting on you. Surfaced separately because they're the
    /// only notifications that are a question rather than a statement.
    var awaitingResponse: [AppNotification] { feed.filter(\.needsResponse) }

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
        applyResponses()
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

    // MARK: - Responding

    /// Answers a payment: yes that happened, or no it didn't.
    ///
    /// Both answers travel. A confirmation is what makes the ledger something
    /// the group agreed to rather than something one person typed, and a
    /// dispute is useless if only the person raising it can see it — the payer
    /// is exactly who needs to know, and the rest of the group is who decides
    /// whose account of it is right.
    func respond(
        _ response: AppNotification.Response,
        to notification: AppNotification,
        in trip: Trip?
    ) {
        guard let index = items.firstIndex(where: { $0.id == notification.id }) else { return }

        items[index].response = response
        items[index].isUnread = false
        responses[notification.id] = response
        saveResponses()

        Task { await SupabaseRepository.shared.markNotificationRead(notification.id) }

        guard let trip else { return }
        let recipients = trip.travellers.map(\.id).filter { $0 != Traveller.you.id }
        guard !recipients.isEmpty else { return }

        let me = Traveller.you.name
        post(
            AppNotification(
                kind: response.event,
                title: response == .confirmed
                    ? "\(me) confirmed a payment on \(trip.title)"
                    : "\(me) disputed a payment on \(trip.title)",
                body: response == .confirmed
                    ? notification.title
                    : "\(notification.title) — worth checking before anyone settles up.",
                tripID: trip.id
            ),
            to: recipients
        )
    }

    private func loadResponses() {
        guard let raw = UserDefaults.standard.dictionary(forKey: Self.responsesKey) as? [String: String] else { return }
        responses = raw.reduce(into: [:]) { store, entry in
            guard let id = UUID(uuidString: entry.key),
                  let response = AppNotification.Response(rawValue: entry.value) else { return }
            store[id] = response
        }
    }

    private func saveResponses() {
        let raw = responses.reduce(into: [String: String]()) { store, entry in
            store[entry.key.uuidString] = entry.value.rawValue
        }
        UserDefaults.standard.set(raw, forKey: Self.responsesKey)
    }

    /// Re-attaches saved answers after a load, which brings back plain rows
    /// from the server with no idea what was said about them.
    private func applyResponses() {
        guard !responses.isEmpty else { return }
        for index in items.indices {
            items[index].response = responses[items[index].id]
        }
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

    /// Somebody paid. Goes to everybody the cost lands on, and asks them.
    func announcePayment(of item: ItineraryItem, by payerID: UUID, in trip: Trip) {
        let payer = trip.traveller(payerID)?.name ?? "Someone"
        let bearers = Set(trip.bearers(of: item).map(\.id))

        // Only the people it costs something. Being asked to confirm a
        // payment you have no share in is a question you can't answer.
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
                tripID: trip.id
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
