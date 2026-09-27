//
//  BookingChangeSync.swift
//  Equitrip
//

import Foundation
import Observation
import SwiftUI

/// The loop for booking changes: cancellations, reschedules, amendments.
///
/// A separate loop from `GmailExpenseSync`, with a separate switch, because
/// it answers to a different promise. Payments are only read while a trip is
/// running. Booking changes mostly arrive *before* one — the airline moves
/// the flight a fortnight out — so this reads from `lookahead` days before a
/// trip starts until it ends, and not otherwise. Between trips, and for trips
/// further off than that, it does not open the mailbox.
///
/// Everything else is the expense loop's rules: read-only, on this device,
/// and a narrow Gmail search so only mail that says something was cancelled
/// or changed is downloaded at all.
///
/// Nothing it finds is applied here. Every change is recorded and then put
/// in front of the person by `BookingChangeReviewSheet`, which waits for
/// Confirm — or, when `appliesAutomatically` is on and the match is certain,
/// runs the same steps on its own while they watch.
@MainActor
@Observable
final class BookingChangeSync {

    enum State: Equatable {
        case idle
        case syncing
        case failed(String)

        var isSyncing: Bool { self == .syncing }
        var failure: String? { if case .failed(let message) = self { message } else { nil } }
    }

    private(set) var state: State = .idle
    private(set) var lastSyncedAt: Date?

    /// Watch the mailbox for booking changes at all.
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }
    /// Skip Confirm when the booking is unmistakable. Off unless turned on.
    var appliesAutomatically: Bool {
        didSet { UserDefaults.standard.set(appliesAutomatically, forKey: Self.autoApplyKey) }
    }
    /// Tell the trip chat when a change is applied.
    var postsToChat: Bool {
        didSet { UserDefaults.standard.set(postsToChat, forKey: Self.chatKey) }
    }

    /// How long before a trip starts its bookings are watched.
    static let lookahead: TimeInterval = 30 * 86_400
    private static let minimumInterval: TimeInterval = 90
    /// A first sync looks back this far: long enough to catch a change mailed
    /// last week, short enough not to replay a month of old reschedules.
    private static let coldStartWindow: TimeInterval = 10 * 86_400
    private static let overlap: TimeInterval = 30 * 60

    private static let enabledKey = "gmail.bookingChanges.enabled"
    private static let autoApplyKey = "gmail.bookingChanges.applyAutomatically"
    private static let chatKey = "gmail.bookingChanges.postToChat"
    private static let lastSyncKey = "gmail.bookingChanges.lastSyncedAt"

    private let account: GmailAccount
    private let changes: BookingChangeStore
    private let store: TripStore
    private var syncTask: Task<Void, Never>?

    init(account: GmailAccount? = nil, changes: BookingChangeStore, store: TripStore) {
        self.account = account ?? .shared
        self.changes = changes
        self.store = store
        let defaults = UserDefaults.standard
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        appliesAutomatically = defaults.object(forKey: Self.autoApplyKey) as? Bool ?? false
        postsToChat = defaults.object(forKey: Self.chatKey) as? Bool ?? true
        lastSyncedAt = defaults.object(forKey: Self.lastSyncKey) as? Date
    }

    // MARK: - Which trips

    /// Trips whose bookings can be changed by mail right now: running, or
    /// starting within `lookahead`.
    static func watchedTrips(in trips: [Trip], now: Date = Date()) -> [Trip] {
        trips.filter { trip in
            switch trip.phase {
            case .live: true
            case .upcoming: trip.startDate.timeIntervalSince(now) <= lookahead
            case .past: false
            }
        }
    }

    /// Where pasted text may land: any trip that hasn't ended. Pasting is a
    /// person choosing to show the app one email, so the lookahead is theirs
    /// to overrule.
    static func pasteableTrips(in trips: [Trip]) -> [Trip] {
        trips.filter { $0.phase != .past }
    }

    // MARK: - Gmail

    func sync(force: Bool = false) {
        guard isEnabled, account.isActive, !state.isSyncing else { return }
        guard !Self.watchedTrips(in: store.trips).isEmpty else { return }
        if !force, let last = lastSyncedAt, Date().timeIntervalSince(last) < Self.minimumInterval { return }

        syncTask?.cancel()
        syncTask = Task { await run() }
    }

    private func run() async {
        let now = Date()
        let floor = lastSyncedAt.map { $0.addingTimeInterval(-Self.overlap) } ?? now.addingTimeInterval(-Self.coldStartWindow)
        guard floor < now else { return }

        state = .syncing
        do {
            let token = try await account.authorizedToken()
            let ids = try await GmailAPI.messageIDs(token: token, query: GmailAPI.bookingChangeQuery, after: floor, before: now)
            let fresh = ids.filter { !changes.hasSeen($0) }

            if !fresh.isEmpty {
                let messages = try await GmailAPI.messages(ids: fresh, token: token)
                for message in messages where message.receivedAt >= floor {
                    if Task.isCancelled { break }
                    // Re-read every time: a trip added mid-sync counts.
                    let trips = Self.watchedTrips(in: store.trips)
                    guard !trips.isEmpty else { break }
                    if case .found(let change) = await BookingChangeReader.read(message, trips: trips, source: .gmail) {
                        changes.record(change)
                    }
                }
            }

            lastSyncedAt = Date()
            UserDefaults.standard.set(lastSyncedAt, forKey: Self.lastSyncKey)
            state = .idle
        } catch let error as GmailError {
            state = .failed(error.errorDescription ?? "Gmail couldn't be read.")
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Pasted text

    enum PasteOutcome: Equatable {
        case found(id: String)
        case skipped(String)
    }

    /// Reads text handed over directly as if it had arrived by mail — the
    /// same reader, matcher and card; only the source differs. Nothing on
    /// screen offers this yet: debug builds use it to feed fixture emails in
    /// (`EQUITRIP_BOOKING_MAIL`), and it's the door a share extension would use.
    func read(pasted raw: String, limitedTo tripID: UUID? = nil) async -> PasteOutcome {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 20 else { return .skipped("That's too short to be a booking email") }

        var trips = Self.pasteableTrips(in: store.trips)
        if let tripID { trips = trips.filter { $0.id == tripID } }
        guard !trips.isEmpty else { return .skipped("There's no upcoming or running trip to match it against") }

        // First line as the subject when it reads like one.
        let lines = text.components(separatedBy: .newlines)
        let first = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        let subject = first.lowercased().hasPrefix("subject:")
            ? String(first.dropFirst("subject:".count)).trimmingCharacters(in: .whitespaces)
            : ""
        let body = subject.isEmpty ? text : lines.dropFirst().joined(separator: "\n")

        let message = MailMessage(
            id: "pasted-\(Traveller.stableHash(text))",
            threadID: "",
            labelIDs: [],
            receivedAt: Date(),
            fromName: "",
            fromAddress: "",
            subject: subject,
            snippet: "",
            body: String(body.prefix(MailMessage.bodyLimit))
        )

        // The same text twice: say where it went rather than reading it again.
        if let existing = changes.change(message.id) {
            if existing.status.isWaiting { return .found(id: existing.id) }
            return .skipped("You've already dealt with this email")
        }

        switch await BookingChangeReader.read(message, trips: trips, source: .pasted) {
        case .found(let change):
            changes.record(change)
            return .found(id: change.id)
        case .skipped(let reason):
            return .skipped(reason)
        }
    }

}

extension EnvironmentValues {
    @Entry var bookingChangeSync: BookingChangeSync? = nil
}
