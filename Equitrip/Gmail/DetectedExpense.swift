//
//  DetectedExpense.swift
//  Equitrip
//

import Foundation
import Observation
import SwiftUI

/// A payment the app believes happened, read out of one email.
///
/// Not an expense. That distinction is the whole design: nothing here ever
/// reaches the ledger on its own, because an email says what left an account
/// and the ledger needs to know who it was for. What this carries is the half
/// the phone can know — how much, when, to whom, by what route — so the person
/// only supplies the half it can't: what the thing was, and who was in on it.
struct DetectedExpense: Identifiable, Codable, Hashable {

    /// How the money moved. Maps onto `PaymentMethod` for the ledger, but is
    /// kept separate because a mail can say "UPI" without the app being ready
    /// to claim that's how the user would have filed it.
    enum Channel: String, Codable, Hashable {
        case upi, card, netBanking, wallet, other

        var label: String {
            switch self {
            case .upi: "UPI"
            case .card: "Card"
            case .netBanking: "Net banking"
            case .wallet: "Wallet"
            case .other: "Payment"
            }
        }

        var symbol: String {
            switch self {
            case .upi: "indianrupeesign.circle"
            case .card: "creditcard"
            case .netBanking: "building.columns"
            case .wallet: "wallet.bifold"
            case .other: "arrow.up.right.circle"
            }
        }

        var paymentMethod: PaymentMethod {
            switch self {
            case .upi: .upi
            case .card: .card
            case .netBanking: .transfer
            case .wallet, .other: .other
            }
        }
    }

    /// Whether this belongs on the trip at all.
    ///
    /// An Amazon order paid for from a hotel room is a real payment and not a
    /// trip expense, and quietly adding it to a group ledger would have four
    /// people splitting somebody's headphones. Those are kept — deleting them
    /// would mean detecting them again tomorrow — and filed away from the list
    /// that asks to be added.
    enum Relevance: String, Codable, Hashable {
        case trip
        case onlineOrder

        var isOnTrip: Bool { self == .trip }
    }

    /// Whether the model and the text agreed.
    enum Confidence: String, Codable, Hashable {
        /// The model's amount was found in the email, character for character.
        case certain
        /// Only one of the two readings produced an amount. Shown, but the
        /// card says the figure is worth a glance.
        case likely
    }

    enum Status: Codable, Hashable {
        case waiting
        /// Already on the trip, as this booking.
        case added(UUID)
        case dismissed

        var isWaiting: Bool { self == .waiting }
    }

    /// The Gmail message id. Being the identity is what makes the whole thing
    /// idempotent: syncing the same week twice can't produce the expense twice,
    /// and a dismissal survives the next sync finding the mail again.
    let id: String

    var tripID: UUID
    var amount: Double
    var currencyCode: String
    /// Whoever the money went to, exactly as the mail wrote it. Often a VPA,
    /// sometimes a merchant string, sometimes nothing at all.
    var payee: String
    var reference: String
    var channel: Channel
    var receivedAt: Date
    /// The bank, for the "how do we know this" line.
    var sender: String
    var subject: String
    var relevance: Relevance
    var confidence: Confidence
    var status: Status
    var detectedAt: Date

    // MARK: Derived

    /// A VPA is not a name. `q4b1x@ybl` in a title field would put "q4b1x@ybl"
    /// on the timeline and in the settle-up screen, so when that's all the
    /// mail gave, the title is left empty for the person to type — which is
    /// exactly the one thing quick add asks for anyway.
    var payeeIsHandle: Bool {
        payee.contains("@") || payee.range(of: #"^[A-Z0-9]{8,}$"#, options: .regularExpression) != nil
    }

    /// Offered as a one-tap fill, never written into the title for you.
    ///
    /// "ASADULLA SEKH" is who the money went to; it is not what the money was
    /// for, and a timeline row reading a stranger's name is worse than a blank
    /// one. But when the payee is a shop — "BLUE TOKAI COFFEE" — it is very
    /// nearly the title already. So it goes in the booking's `vendor`, where
    /// the ledger keeps that sort of thing, and quick add offers it as a chip
    /// under the title field for the cases where it *is* the answer.
    var suggestion: String {
        payeeIsHandle ? "" : payee
    }

    /// The line under the amount: who told us, and how.
    var provenance: String {
        var parts = [sender.isEmpty ? "Your mail" : sender]
        parts.append(channel.label)
        if !reference.isEmpty { parts.append("ref \(reference.suffix(6))") }
        return parts.joined(separator: " · ")
    }

    /// The same line with the payee in front, for quick add — where the card's
    /// "to WHOEVER" headline isn't on screen to say it.
    var fullProvenance: String {
        payee.isEmpty ? provenance : "to \(payee) · \(provenance)"
    }

    var clockText: String {
        DateFormatter.cached("h:mm a").string(from: receivedAt)
    }

    var dayText: String {
        Calendar.current.isDateInToday(receivedAt)
            ? "Today"
            : DateFormatter.cached("EEE d MMM").string(from: receivedAt)
    }
}

// MARK: - Store

/// Everything the mail reader has found, and what became of it.
///
/// On device only, and on purpose. These rows describe somebody's bank mail
/// before they've decided any of it is the group's business — putting them in
/// Supabase would mean a trip's other travellers could, in principle, be shown
/// payments their friend never chose to share. Once one is added it becomes an
/// ordinary itinerary item and syncs like any other.
@MainActor
@Observable
final class DetectedExpenseStore {

    private(set) var items: [DetectedExpense] = []

    private static let fileName = "detected-expenses.json"

    /// Bumped whenever the reading logic changes in a way that would produce a
    /// different answer for the same email.
    ///
    /// Detections are keyed by message id and skipped once seen, which is what
    /// makes the sync cheap and dismissals permanent — and also what would
    /// leave a wrongly-detected payment sitting in the queue forever after the
    /// bug that produced it was fixed. On a bump, everything still *waiting*
    /// is discarded and the sync clock is reset so those emails are read again
    /// by the new logic. Decisions already made — added, dismissed — are
    /// never touched: they were a person's answer, not the reader's.
    ///
    /// 2: money direction decided by proximity to the amount rather than by
    ///    keyword presence, and payees no longer read out of the From header.
    private static let readerVersion = 2
    private static let versionKey = "gmail.readerVersion"

    init() {
        load()
        migrateIfNeeded()
    }

    private func migrateIfNeeded() {
        let stored = UserDefaults.standard.integer(forKey: Self.versionKey)
        guard stored != Self.readerVersion else { return }

        let before = items.count
        items.removeAll { $0.status.isWaiting }
        UserDefaults.standard.set(Self.readerVersion, forKey: Self.versionKey)

        // Without this the next sync would only look back to the last one and
        // never revisit the emails it just dropped.
        UserDefaults.standard.removeObject(forKey: "gmail.lastSyncedAt")

        if before != items.count { save() }
    }

    // MARK: Reading

    func waiting(for tripID: UUID) -> [DetectedExpense] {
        items
            .filter { $0.tripID == tripID && $0.status.isWaiting && $0.relevance.isOnTrip }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    func skipped(for tripID: UUID) -> [DetectedExpense] {
        items
            .filter { $0.tripID == tripID && $0.status.isWaiting && !$0.relevance.isOnTrip }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    func settled(for tripID: UUID) -> [DetectedExpense] {
        items
            .filter { $0.tripID == tripID && !$0.status.isWaiting }
            .sorted { $0.receivedAt > $1.receivedAt }
    }

    func waitingCount(for tripID: UUID?) -> Int {
        guard let tripID else { return 0 }
        return waiting(for: tripID).count
    }

    /// Whether this message has been seen before, in any state. The sync loop
    /// asks before spending a model pass on it.
    func hasSeen(_ messageID: String) -> Bool {
        items.contains { $0.id == messageID }
    }

    // MARK: Writing

    /// Upserts, keeping whatever the person already decided. A re-read of the
    /// same mail must never resurrect something they dismissed.
    func record(_ detection: DetectedExpense) {
        if let index = items.firstIndex(where: { $0.id == detection.id }) {
            guard items[index].status.isWaiting else { return }
            var updated = detection
            updated.status = items[index].status
            items[index] = updated
        } else {
            items.append(detection)
        }
        save()
    }

    func markAdded(_ id: String, as itemID: UUID) {
        update(id) { $0.status = .added(itemID) }
    }

    func dismiss(_ id: String) {
        update(id) { $0.status = .dismissed }
    }

    func restore(_ id: String) {
        update(id) { $0.status = .waiting }
    }

    /// Moves one out of the "not on the trip" bucket. The classifier calling
    /// a hotel booking an online order is exactly the mistake it will make,
    /// and there has to be a way back that isn't retyping it.
    func markOnTrip(_ id: String) {
        update(id) { $0.relevance = .trip }
    }

    func forget(tripID: UUID) {
        items.removeAll { $0.tripID == tripID }
        save()
    }

    private func update(_ id: String, _ change: (inout DetectedExpense) -> Void) {
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
        items = (try? decoder.decode([DetectedExpense].self, from: data)) ?? []
    }

    private func save() {
        guard let url = Self.fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        // `.completeFileProtection`: the file is a list of somebody's payments,
        // and it has no business being readable while the phone is locked.
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}

extension EnvironmentValues {
    @Entry var detectedExpenses = DetectedExpenseStore()
}
