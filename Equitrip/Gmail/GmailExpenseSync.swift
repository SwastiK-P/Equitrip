//
//  GmailExpenseSync.swift
//  Equitrip
//

import Foundation
import Observation
import SwiftUI

/// The loop: while a trip is running, read what arrived since last time.
///
/// Three conditions, all of which must hold, and the first two are the reason
/// this is defensible at all. The account has to be connected, the switch has
/// to be on, and **a trip has to be under way**. Outside a trip the app does
/// not touch the mailbox — not to warm a cache, not to keep a token fresh.
/// That's the promise the settings screen makes, so it's enforced in one place
/// where it can be read: `window(for:)` returns nil and nothing runs.
///
/// Messages are matched to the running trip and to nothing else. A payment
/// email from three weeks before the trip started can't become a trip expense
/// even if Gmail's date search hands it over, because the window is clamped to
/// the trip's own days.
@MainActor
@Observable
final class GmailExpenseSync {

    enum State: Equatable {
        case idle
        case syncing(read: Int, of: Int)
        case failed(String)

        var isSyncing: Bool { if case .syncing = self { true } else { false } }
        var failure: String? { if case .failed(let message) = self { message } else { nil } }
    }

    private(set) var state: State = .idle
    private(set) var lastSyncedAt: Date?
    /// What the last run turned up, for the toast and the settings line.
    private(set) var lastFoundCount = 0

    private let account: GmailAccount
    private let detections: DetectedExpenseStore

    /// Two syncs in a minute find the same nothing. Pull-to-refresh, becoming
    /// active and opening Home all want to trigger this, and without a floor
    /// they'd each do so within a second of one another.
    private static let minimumInterval: TimeInterval = 90

    /// How far back a first sync on a running trip reaches. Long enough to
    /// pick up the morning's payments when the account is connected at lunch,
    /// short enough that connecting mid-trip doesn't import a fortnight.
    private static let coldStartWindow: TimeInterval = 3 * 86_400

    /// Re-read a little before the last sync. Gmail's `after:` is day-grained
    /// in the account's timezone, and a message can be indexed a moment after
    /// it arrives — an overlap costs one cached round trip and closes a gap
    /// that would otherwise be silent.
    private static let overlap: TimeInterval = 30 * 60

    private var syncTask: Task<Void, Never>?

    init(account: GmailAccount? = nil, detections: DetectedExpenseStore) {
        self.account = account ?? .shared
        self.detections = detections
        lastSyncedAt = UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date
    }

    private static let lastSyncKey = "gmail.lastSyncedAt"

    // MARK: - Entry point

    /// Reads the mailbox for one running trip. Safe to call from anywhere and
    /// as often as you like — it decides for itself whether there's anything
    /// to do.
    func sync(for trip: Trip?, force: Bool = false) {
        guard account.isActive else { return }
        guard let trip, trip.phase == .live else { return }
        guard !state.isSyncing else { return }

        if !force, let last = lastSyncedAt, Date().timeIntervalSince(last) < Self.minimumInterval {
            return
        }

        syncTask?.cancel()
        syncTask = Task { await run(for: trip) }
    }

    func cancel() {
        syncTask?.cancel()
        syncTask = nil
        if state.isSyncing { state = .idle }
    }

    // MARK: - The run

    private func run(for trip: Trip) async {
        guard let window = window(for: trip) else {
            state = .idle
            return
        }

        state = .syncing(read: 0, of: 0)
        lastFoundCount = 0

        do {
            let token = try await account.authorizedToken()
            let ids = try await GmailAPI.messageIDs(token: token, after: window.lowerBound, before: window.upperBound)

            // Anything already decided on is skipped before it's downloaded:
            // a dismissed alert must not cost a fetch every ninety seconds for
            // the rest of the trip.
            let fresh = ids.filter { !detections.hasSeen($0) }
            guard !fresh.isEmpty else {
                finish()
                return
            }

            state = .syncing(read: 0, of: fresh.count)
            let messages = try await GmailAPI.messages(ids: fresh, token: token)

            var read = 0
            for message in messages {
                if Task.isCancelled { break }

                // The clamp. Gmail's date search is generous at the edges and
                // this is what makes "only during the trip" true rather than
                // approximately true.
                guard window.contains(message.receivedAt) else {
                    read += 1
                    state = .syncing(read: read, of: messages.count)
                    continue
                }

                if let detection = await ExpenseMailReader.read(message, tripID: trip.id) {
                    detections.record(detection)
                    if detection.relevance.isOnTrip { lastFoundCount += 1 }
                }

                read += 1
                state = .syncing(read: read, of: messages.count)
            }

            finish()
        } catch let error as GmailError {
            state = .failed(error.errorDescription ?? "Gmail couldn't be read.")
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func finish() {
        lastSyncedAt = Date()
        UserDefaults.standard.set(lastSyncedAt, forKey: Self.lastSyncKey)
        state = .idle
    }

    // MARK: - When to look

    /// The stretch of time this sync is allowed to see, or nil for "not now".
    ///
    /// The upper bound is now, never the trip's end date — a trip that ends
    /// tonight is still running this afternoon. The lower bound is the latest
    /// of: when the trip began, and shortly before the last sync. Which means
    /// the first sync of a trip looks back a few days at most, and every one
    /// after that looks back half an hour.
    private func window(for trip: Trip) -> ClosedRange<Date>? {
        let now = Date()
        let tripStart = Calendar.current.startOfDay(for: trip.startDate)
        guard tripStart <= now else { return nil }

        let floor = lastSyncedAt.map { $0.addingTimeInterval(-Self.overlap) }
            ?? now.addingTimeInterval(-Self.coldStartWindow)

        let lower = max(tripStart, floor)
        guard lower < now else { return nil }
        return lower...now
    }
}

extension EnvironmentValues {
    @Entry var gmailSync: GmailExpenseSync? = nil
}
