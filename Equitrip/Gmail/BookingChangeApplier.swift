//
//  BookingChangeApplier.swift
//  Equitrip
//

import Foundation

/// What the group is told when a booking changes because an email said so.
struct BookingNotice: Hashable {
    var title: String
    var body: String
}

/// One line of the before-and-after: the booking's day, time or cost as it
/// is, and as the email says it now is.
struct BookingDiffRow: Identifiable, Hashable {
    let label: String
    let before: String
    let after: String
    var changed: Bool { before != after }
    var id: String { label }
}

/// Turns a `BookingChange` into an edit on the trip — and back.
///
/// Applying goes through `TripStore.updateItem` and `removeItem`, the same
/// two doors every other edit uses, so it is saved, announced to everyone on
/// the trip and written to the audit trail exactly like a change made by
/// hand. The only difference is the announcement's wording (`BookingNotice`):
/// the group hears what the airline did, and whose mail it came from.
@MainActor
enum BookingChangeApplier {

    /// Where a change stands against the trip as it is right now.
    enum Standing {
        case ready(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?)
        /// Somebody — maybe another traveller reading the same airline mail —
        /// already made the booking look like this.
        case alreadyApplied(item: ItineraryItem, trip: Trip)
        /// The booking was deleted, or the trip left, since the mail was read.
        case bookingGone
        /// Several bookings fit; a person has to say which.
        case needsChoice
    }

    static func standing(of change: BookingChange, in store: TripStore) -> Standing {
        if change.needsChoice { return .needsChoice }
        guard let trip = store.trip(change.tripID),
              let item = trip.items.first(where: { $0.id == change.itemID })
        else { return .bookingGone }

        guard change.changesAnything(item, tripCurrency: trip.currencyCode) else {
            return .alreadyApplied(item: item, trip: trip)
        }
        return .ready(item: item, trip: trip, proposed: change.proposed(from: item, tripCurrency: trip.currencyCode))
    }

    // MARK: - Before and after

    /// Day, time and cost always — they're what a booking *is* at a glance —
    /// then whatever else the change touches.
    static func rows(for change: BookingChange, item: ItineraryItem, proposed: ItineraryItem?, trip: Trip) -> [BookingDiffRow] {
        let code = trip.currencyCode
        let dayFormat = DateFormatter.cached("EEE d MMM")
        var rows: [BookingDiffRow] = []

        guard let proposed else {
            rows.append(.init(label: "Day", before: dayFormat.string(from: item.date), after: "Off the plan"))
            rows.append(.init(label: "Time", before: item.timeLabel ?? "Any time", after: "—"))
            rows.append(.init(label: "Cost", before: Money.format(item.cost, code: code), after: Money.format(0, code: code)))
            if let refund = change.refund {
                rows.append(.init(label: "Refund", before: "—", after: Money.format(refund, code: change.currencyCode ?? code)))
            }
            appendShare(for: item, proposed: nil, trip: trip, into: &rows)
            return rows
        }

        rows.append(.init(label: "Day", before: dayFormat.string(from: item.date), after: dayFormat.string(from: proposed.date)))
        rows.append(.init(label: "Time", before: item.timeLabel ?? "Any time", after: proposed.timeLabel ?? "Any time"))
        rows.append(.init(label: "Cost", before: Money.format(item.cost, code: code), after: Money.format(proposed.cost, code: code)))

        if change.kind == .cancelled {
            rows.append(.init(label: "Status", before: "Booked", after: "Cancelled"))
            if let charge = change.cancellationCharge {
                rows.append(.init(label: "Charge", before: "—", after: Money.format(charge, code: change.currencyCode ?? code)))
            }
            if let refund = change.refund {
                rows.append(.init(label: "Refund", before: "—", after: Money.format(refund, code: change.currencyCode ?? code)))
            }
        } else if proposed.title != item.title {
            rows.append(.init(label: "Name", before: item.title, after: proposed.title))
        }

        appendShare(for: item, proposed: proposed, trip: trip, into: &rows)
        return rows
    }

    /// Your share, asked of the trip the normal way — once of the booking as
    /// it is, once of the booking as it would be.
    private static func appendShare(for item: ItineraryItem, proposed: ItineraryItem?, trip: Trip, into rows: inout [BookingDiffRow]) {
        let you = Traveller.you.id
        guard item.participantIDs.contains(you) || trip.share(of: item, for: you) > 0 else { return }
        let before = trip.share(of: item, for: you)
        let after = proposed.map { trip.share(of: $0, for: you) } ?? 0
        guard before != after else { return }
        rows.append(.init(label: "Your share", before: Money.format(before, code: trip.currencyCode), after: Money.format(after, code: trip.currencyCode)))
    }

    /// "7:05 AM → 9:40 AM · ₹54,000 → ₹58,500" — the changed rows, in words.
    static func summary(of rows: [BookingDiffRow], removed: Bool) -> String {
        if removed {
            let refund = rows.first { $0.label == "Refund" }.map { "\($0.after) refund" }
            return ["Off the plan", refund].compactMap { $0 }.joined(separator: " · ")
        }
        return rows
            .filter { $0.changed && $0.label != "Your share" && $0.label != "Status" }
            .map { $0.before == "—" ? "\($0.label) \($0.after)" : "\($0.before) → \($0.after)" }
            .joined(separator: " · ")
    }

    // MARK: - Applying

    /// Makes the change. Returns false when there was nothing to apply.
    @discardableResult
    static func apply(
        _ change: BookingChange,
        store: TripStore,
        changes: BookingChangeStore,
        postToChat: Bool,
        automatically: Bool = false
    ) -> Bool {
        guard case .ready(let item, let trip, let proposed) = standing(of: change, in: store) else { return false }

        let rows = rows(for: change, item: item, proposed: proposed, trip: trip)
        let headline = change.headline(for: item, tripCurrency: trip.currencyCode)
        let notice = BookingNotice(title: headline, body: summary(of: rows, removed: proposed == nil))

        if let proposed {
            store.updateItem(proposed, in: trip.id, notice: notice)
        } else {
            store.removeItem(item.id, in: trip.id, notice: notice)
        }
        changes.markApplied(change.id, before: BookingRecord(item), automatically: automatically)

        if postToChat {
            let text = proposed == nil
                ? "\(headline) — \(notice.body). I've taken it off the plan."
                : "\(headline): \(notice.body). I've updated the plan."
            let attachment: ChatAttachment? = proposed.map { .booking(itemID: $0.id) }
            Task {
                await ChatService(trip: trip).send(text, attachment: attachment)
            }
        }
        return true
    }

    /// Puts the booking back exactly as it was and returns the change to the
    /// queue, where it can be applied again or dismissed.
    static func undo(_ change: BookingChange, store: TripStore, changes: BookingChangeStore) {
        guard let record = change.before, let trip = store.trip(change.tripID) else { return }
        if trip.items.contains(where: { $0.id == record.id }) {
            store.updateItem(record.item, in: trip.id)
        } else {
            store.addItem(record.item, to: trip.id)
        }
        changes.restore(change.id)
    }
}
