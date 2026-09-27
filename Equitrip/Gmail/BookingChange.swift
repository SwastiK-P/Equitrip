//
//  BookingChange.swift
//  Equitrip
//

import Foundation
import Observation
import SwiftUI

/// A booking an email says has moved or been cancelled, matched to the one
/// on the plan it's about.
///
/// The sibling of `DetectedExpense`, with one difference that shapes all of
/// it: an expense is new, while this is a claim about something the group
/// already agreed on. So it carries the *new values* the email stated rather
/// than a new booking, and the card works out "before" from the booking as it
/// stands right now — if somebody else on the trip applied the same airline
/// email first, the before and after are already equal and the card says so
/// instead of offering to change it twice. What the booking was when this
/// change was applied is frozen in `before`, which is what Undo restores.
///
/// Every value is one the email contains, found by `BookingMailFacts` or by
/// the model and then found again in the text. Nothing here is computed from
/// a model's arithmetic; the one sum anywhere — what a partial refund leaves
/// on the ledger — is Swift subtracting two figures the email and the ledger
/// both state.
struct BookingChange: Identifiable, Codable, Hashable {

    enum Kind: String, Codable, Hashable {
        case cancelled
        /// Anything else: a date, a time, a price.
        case changed
    }

    enum Source: String, Codable, Hashable {
        case gmail
        /// Pasted from the clipboard — a forwarded mail, an SMS.
        case pasted
    }

    enum Confidence: String, Codable, Hashable {
        /// One booking fits, clearly, on identifiers (a flight number, the
        /// booking's own name), and the new values were labelled as new.
        case certain
        /// It fits, but the evidence is thinner — worth a look before applying.
        case likely
    }

    enum Status: Codable, Hashable {
        case waiting
        case applied(at: Date, automatically: Bool)
        case dismissed

        var isWaiting: Bool { self == .waiting }
        var wasApplied: Bool { if case .applied = self { true } else { false } }
        var wasAutomatic: Bool { if case .applied(_, true) = self { true } else { false } }
    }

    /// One of several bookings the email could be about, when it can't tell.
    struct Candidate: Codable, Hashable, Identifiable {
        var tripID: UUID
        var itemID: UUID
        var reasons: [String]
        var id: UUID { itemID }
    }

    /// Gmail's message id, or `pasted-…` for pasted text. Being the identity
    /// is what stops one email being applied twice.
    let id: String

    /// Nil until the booking is known — see `alternatives`.
    var tripID: UUID?
    var itemID: UUID?
    /// Set when two or more bookings fit about equally well.
    var alternatives: [Candidate]
    /// Why this booking: "Flight 6E 5307", "Rohan named".
    var reasons: [String]

    var kind: Kind
    var newDay: Date?
    /// Minutes past midnight.
    var newMinute: Int?
    var newCost: Double?
    var refund: Double?
    var cancellationCharge: Double?
    /// The currency the email's figures are in, when it said.
    var currencyCode: String?
    var reference: String?

    var sender: String
    var subject: String
    var receivedAt: Date
    var source: Source
    var confidence: Confidence
    var status: Status
    var detectedAt: Date
    /// The booking as it was the moment this was applied.
    var before: BookingRecord?
    /// False for an automatic change nobody has looked at yet. Home keeps
    /// saying so until someone has.
    var seen: Bool

    var needsChoice: Bool { itemID == nil && !alternatives.isEmpty }

    // MARK: The change, against a booking

    /// What the booking becomes, or nil when it comes off the plan.
    ///
    /// A cancellation keeps the booking only when money stays spent: a stated
    /// cancellation charge, or a refund smaller than what the booking cost.
    /// Then it stays on the ledger at that figure, marked cancelled, because
    /// the group still paid it. Otherwise it's removed — and a cancellation
    /// that names no money at all is removed too, with the card saying so.
    func proposed(from item: ItineraryItem, tripCurrency: String) -> ItineraryItem? {
        var next = item

        switch kind {
        case .cancelled:
            guard let retained = retainedCost(of: item, tripCurrency: tripCurrency) else { return nil }
            next.cost = retained
            next.customShares = scaled(item.customShares, from: item.cost, to: retained)
            if !next.title.hasPrefix(Self.cancelledPrefix) { next.title = Self.cancelledPrefix + next.title }
            next.flight?.status = .cancelled
            return next

        case .changed:
            let calendar = Calendar.current
            if let newDay, !calendar.isDate(newDay, inSameDayAs: item.date) {
                next.date = newDay
                // Same clock, new day, unless the email gave a new clock too.
                if let time = item.time {
                    let parts = calendar.dateComponents([.hour, .minute], from: time)
                    next.time = .at(parts.hour ?? 0, parts.minute ?? 0, on: newDay)
                }
            }
            if let newMinute {
                next.time = .at(newMinute / 60, newMinute % 60, on: next.date)
            }
            if let newCost, currencyMatches(tripCurrency), newCost != item.cost {
                next.cost = newCost
                next.customShares = scaled(item.customShares, from: item.cost, to: newCost)
            }
            if var flight = next.flight, let time = next.time, let old = item.time, time != old {
                let delta = time.timeIntervalSince(old)
                flight.scheduledDeparture = flight.scheduledDeparture.map { $0.addingTimeInterval(delta) } ?? time
                flight.scheduledArrival = flight.scheduledArrival?.addingTimeInterval(delta)
                next.flight = flight
            }
            return next
        }
    }

    /// Whether applying this to `item` would change anything at all.
    func changesAnything(_ item: ItineraryItem, tripCurrency: String) -> Bool {
        guard let next = proposed(from: item, tripCurrency: tripCurrency) else { return true }
        return next != item
    }

    /// Only the clock or the day moves — the one kind of change that can be
    /// applied without asking, because it changes nobody's share of anything.
    func movesScheduleOnly(_ item: ItineraryItem, tripCurrency: String) -> Bool {
        guard kind == .changed, let next = proposed(from: item, tripCurrency: tripCurrency), next != item else { return false }
        return next.cost == item.cost && next.title == item.title && next.participantIDs == item.participantIDs
    }

    /// "Rescheduled" when the date or time moved, "Changed" otherwise.
    func label(for item: ItineraryItem?, tripCurrency: String) -> String {
        switch kind {
        case .cancelled: return "Cancelled"
        case .changed:
            guard let item, let next = proposed(from: item, tripCurrency: tripCurrency) else { return "Changed" }
            return next.date != item.date || next.time != item.time ? "Rescheduled" : "Changed"
        }
    }

    func headline(for item: ItineraryItem?, tripCurrency: String) -> String {
        let name = item?.title ?? "A booking"
        switch label(for: item, tripCurrency: tripCurrency) {
        case "Cancelled": return "\(name) was cancelled"
        case "Rescheduled": return "\(name) was rescheduled"
        default: return "\(name) was changed"
        }
    }

    /// What stays spent after a cancellation, or nil when nothing does.
    func retainedCost(of item: ItineraryItem, tripCurrency: String) -> Double? {
        guard currencyMatches(tripCurrency) else { return nil }
        if let charge = cancellationCharge, charge > 0, charge < item.cost { return charge }
        if let refund, refund > 0, refund < item.cost, cancellationCharge == nil {
            return (item.cost - refund).rounded(toPlaces: 2)
        }
        return nil
    }

    func currencyMatches(_ tripCurrency: String) -> Bool {
        currencyCode == nil || currencyCode == tripCurrency
    }

    static let cancelledPrefix = "Cancelled · "

    /// Custom shares follow the total they were shares of.
    private func scaled(_ shares: [UUID: Double], from old: Double, to new: Double) -> [UUID: Double] {
        guard !shares.isEmpty, old > 0 else { return shares }
        let ratio = new / old
        return shares.mapValues { ($0 * ratio).rounded(toPlaces: 2) }
    }

    // MARK: Provenance

    /// "IndiGo · PNR X7K9QP", or "Pasted" for pasted text.
    var provenance: String {
        var parts = [source == .pasted ? "Pasted" : (sender.isEmpty ? "Your mail" : sender)]
        if let reference { parts.append(reference) }
        return parts.joined(separator: " · ")
    }

    var dayText: String {
        Calendar.current.isDateInToday(receivedAt) ? "Today" : DateFormatter.cached("EEE d MMM").string(from: receivedAt)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let scale = pow(10, Double(places))
        return (self * scale).rounded() / scale
    }
}

// MARK: - Record

/// A booking, whole, as it stood — so Undo can put back exactly what was
/// there, including a booking the change removed.
struct BookingRecord: Codable, Hashable {
    var id: UUID
    var title: String
    var vendor: String
    var kind: ItineraryKind
    var date: Date
    var time: Date?
    var cost: Double
    var split: SplitMode
    var participantIDs: Set<UUID>
    var customShares: [UUID: Double]
    var photoQuery: String?
    var cover: TripPhoto?
    var suggestedSymbol: String?
    var flight: FlightDetails?
    var paidByID: UUID?
    var paymentMethod: PaymentMethod?
    var receiptURL: URL?
    var createdByID: UUID?
    var createdAt: Date
    var isDisputed: Bool
    var disputedByID: UUID?
    var disputedAt: Date?
    var disputeReason: String?
    var disputeResolvedAt: Date?
    var disputeResolvedByID: UUID?

    init(_ item: ItineraryItem) {
        id = item.id
        title = item.title
        vendor = item.vendor
        kind = item.kind
        date = item.date
        time = item.time
        cost = item.cost
        split = item.split
        participantIDs = item.participantIDs
        customShares = item.customShares
        photoQuery = item.photoQuery
        cover = item.cover
        suggestedSymbol = item.suggestedSymbol
        flight = item.flight
        paidByID = item.paidByID
        paymentMethod = item.paymentMethod
        receiptURL = item.receiptURL
        createdByID = item.createdByID
        createdAt = item.createdAt
        isDisputed = item.isDisputed
        disputedByID = item.disputedByID
        disputedAt = item.disputedAt
        disputeReason = item.disputeReason
        disputeResolvedAt = item.disputeResolvedAt
        disputeResolvedByID = item.disputeResolvedByID
    }

    var item: ItineraryItem {
        ItineraryItem(
            id: id, title: title, vendor: vendor, kind: kind, date: date, time: time, cost: cost,
            split: split, participantIDs: participantIDs, customShares: customShares,
            photoQuery: photoQuery, cover: cover, suggestedSymbol: suggestedSymbol, flight: flight,
            paidByID: paidByID, paymentMethod: paymentMethod, receiptURL: receiptURL,
            createdByID: createdByID, createdAt: createdAt,
            isDisputed: isDisputed, disputedByID: disputedByID, disputedAt: disputedAt,
            disputeReason: disputeReason, disputeResolvedAt: disputeResolvedAt,
            disputeResolvedByID: disputeResolvedByID
        )
    }
}

// MARK: - Store

/// Every booking change the mail reader has found, and what became of it.
///
/// On this device only, for the same reason as `DetectedExpenseStore`: these
/// rows are read out of one person's inbox. What the group sees is the
/// booking once somebody applies the change — an ordinary edit, announced and
/// audited like any other.
@MainActor
@Observable
final class BookingChangeStore {

    private(set) var items: [BookingChange] = []

    private static let fileName = "booking-changes.json"

    init() { load() }

    // MARK: Reading

    func waiting(for tripID: UUID? = nil) -> [BookingChange] {
        items
            .filter { $0.status.isWaiting && (tripID == nil || $0.tripID == tripID || $0.alternatives.contains { $0.tripID == tripID }) }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    func handled(for tripID: UUID? = nil) -> [BookingChange] {
        items
            .filter { !$0.status.isWaiting && (tripID == nil || $0.tripID == tripID) }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    /// Applied on their own and not yet looked at.
    var unseenAutomatic: [BookingChange] {
        items.filter { $0.status.wasAutomatic && !$0.seen }
    }

    func hasSeen(_ id: String) -> Bool { items.contains { $0.id == id } }

    func change(_ id: String) -> BookingChange? { items.first { $0.id == id } }

    // MARK: Writing

    /// Upserts, keeping whatever was already decided.
    func record(_ change: BookingChange) {
        if let index = items.firstIndex(where: { $0.id == change.id }) {
            guard items[index].status.isWaiting else { return }
            items[index] = change
        } else {
            items.append(change)
        }
        save()
    }

    func choose(_ candidate: BookingChange.Candidate, for id: String) {
        update(id) {
            $0.tripID = candidate.tripID
            $0.itemID = candidate.itemID
            $0.reasons = candidate.reasons
            $0.alternatives = []
            // A person picked it; the choice is theirs, not the matcher's.
            $0.confidence = .likely
        }
    }

    func markApplied(_ id: String, before: BookingRecord, automatically: Bool) {
        update(id) {
            $0.status = .applied(at: Date(), automatically: automatically)
            $0.before = before
            $0.seen = !automatically
        }
    }

    func dismiss(_ id: String) { update(id) { $0.status = .dismissed } }

    /// Back into the queue — after an undo, or a dismissal taken back.
    func restore(_ id: String) {
        update(id) {
            $0.status = .waiting
            $0.before = nil
            $0.seen = true
        }
    }

    func markAllSeen() {
        guard items.contains(where: { !$0.seen }) else { return }
        for index in items.indices { items[index].seen = true }
        save()
    }

    func forget(tripID: UUID) {
        items.removeAll { $0.tripID == tripID }
        save()
    }

    private func update(_ id: String, _ change: (inout BookingChange) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[index])
        save()
    }

    // MARK: Persistence

    private static var fileURL: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: fileName)
    }

    private func load() {
        guard let url = Self.fileURL, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([BookingChange].self, from: data)) ?? []
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}

extension BookingChangeStore {
    /// What a view outside `RootTabView` reads — a preview, mostly. One
    /// instance, so the environment doesn't build a new store per access.
    static let detached = BookingChangeStore()
}

extension EnvironmentValues {
    @Entry var bookingChanges = BookingChangeStore.detached
}
