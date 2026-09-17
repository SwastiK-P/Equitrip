//
//  WatchStore.swift
//  EquitripWatch Watch App
//

import Foundation
import Observation
import WatchConnectivity
import WatchKit

/// Everything the watch knows, and the only thing on it that talks to the
/// phone.
///
/// The watch never signs in. It draws the snapshot the phone publishes for
/// the widgets — delivered as WatchConnectivity's application context — and
/// sends back exactly one kind of request: an answer to "I paid you". The
/// phone carries that out through its own `TripStore`, so the watch never
/// needs the model, the split rules or a Supabase session.
@Observable
final class WatchStore: NSObject {

    /// Where an answer is on its way to the phone. Cleared once a snapshot
    /// arrives without the request in it — which is the phone saying it's
    /// done — or once the phone refuses it.
    enum Answer: Equatable {
        /// Sent to a reachable phone; waiting on its reply or its republish.
        case sending
        /// Phone out of reach. Queued with `transferUserInfo`, which the
        /// system delivers whenever the two next meet.
        case queued
    }

    private(set) var snapshot: EquitripSnapshot?
    /// When the phone last actually answered — not when the figures last
    /// changed. The age a person should be told is the age of the *check*.
    private(set) var lastSynced: Date?
    private(set) var isPhoneReachable = false
    private(set) var answers: [UUID: Answer] = [:]

    /// A pinned trip, from the toolbar picker. Nil follows whichever trip
    /// the phone calls current.
    var selectedTripID: UUID?

    /// The last refusal, for the alert.
    var failure: String?

    private let defaults = UserDefaults.standard
    private static let cacheKey = "watch.snapshot"
    private static let syncedKey = "watch.lastSynced"

    override init() {
        super.init()
        loadCache()
    }

    /// Set by the preview initialiser, so `activate()` can't replace the
    /// sample data with whatever the paired phone is holding.
    private var isPreview = false

    /// For previews, and the `-demoSnapshot` debug launch: a store that never
    /// touches a session.
    init(preview snapshot: EquitripSnapshot) {
        super.init()
        self.isPreview = true
        self.snapshot = snapshot
        self.lastSynced = .now
        self.isPhoneReachable = true
    }

    // MARK: - Session

    func activate() {
        guard !isPreview else { return }
        let session = WCSession.default
        guard session.delegate == nil else { return }
        session.delegate = self
        session.activate()
    }

    /// Asks the phone for what it has. Only when it can answer now — an
    /// unanswerable request just leaves the cached figures where they are.
    func refresh() {
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }

        session.sendMessage(
            WatchWire.encode(WatchCommand.requestSnapshot),
            replyHandler: { reply in
                guard case let .snapshot(snapshot)? = WatchWire.decode(WatchReply.self, from: reply) else { return }
                Task { @MainActor in self.apply(snapshot) }
            },
            errorHandler: nil
        )
    }

    // MARK: - Reading

    /// The pinned trip if it still exists, otherwise the phone's current one
    /// — the same rule the "Up next" widget follows, so a pinned trip that
    /// has ended moves on rather than freezing.
    var trip: EquitripSnapshot.TripSummary? {
        guard let snapshot else { return nil }
        if let selectedTripID, let pinned = snapshot.allTrips.first(where: { $0.id == selectedTripID }) {
            return pinned
        }
        return snapshot.currentTrip
    }

    var events: [EquitripSnapshot.Event] {
        guard let snapshot else { return [] }
        if let id = trip?.id, let events = snapshot.eventsByTrip[id] { return events }
        return snapshot.upNext
    }

    /// Requests still waiting on an answer from this wrist.
    var openRequests: [EquitripSnapshot.SettleRequest] {
        (snapshot?.settleRequests ?? []).filter { answers[$0.id] == nil }
    }

    /// Answers made while the phone was away, still in the system's queue.
    var queuedRequests: [EquitripSnapshot.SettleRequest] {
        (snapshot?.settleRequests ?? []).filter { answers[$0.id] == .queued }
    }

    /// Worth admitting to once the phone is out of reach, or the last word
    /// from it is more than half an hour old.
    var isStale: Bool {
        guard let lastSynced else { return true }
        return !isPhoneReachable || Date().timeIntervalSince(lastSynced) > 30 * 60
    }

    // MARK: - Answering

    func respond(to request: EquitripSnapshot.SettleRequest, confirm: Bool) {
        let payload = WatchWire.encode(
            WatchCommand.respondToSettlement(settlementID: request.id, tripID: request.tripID, confirm: confirm)
        )
        let session = WCSession.default

        guard session.activationState == .activated, session.isReachable else {
            queue(payload, for: request.id)
            return
        }

        answers[request.id] = .sending
        session.sendMessage(
            payload,
            replyHandler: { reply in
                let decoded = WatchWire.decode(WatchReply.self, from: reply)
                Task { @MainActor in self.finish(request.id, with: decoded) }
            },
            errorHandler: { _ in
                // Queued rather than failed. If the message did arrive after
                // all, the phone finds the settlement already answered and
                // drops the second copy — so a retry can't answer twice.
                Task { @MainActor in self.queue(payload, for: request.id) }
            }
        )
    }

    private func queue(_ payload: [String: Any], for id: UUID) {
        WCSession.default.transferUserInfo(payload)
        answers[id] = .queued
        WKInterfaceDevice.current().play(.click)
    }

    private func finish(_ id: UUID, with reply: WatchReply?) {
        switch reply {
        case .accepted:
            // Left in `answers` until the phone's republish drops the row.
            WKInterfaceDevice.current().play(.success)
        case let .rejected(reason):
            answers[id] = nil
            failure = reason
            WKInterfaceDevice.current().play(.failure)
        case .snapshot, nil:
            answers[id] = nil
            failure = "Your iPhone didn't understand that. Update Equitrip on both devices."
            WKInterfaceDevice.current().play(.failure)
        }
    }

    // MARK: - Applying

    private func apply(_ snapshot: EquitripSnapshot) {
        self.snapshot = snapshot
        lastSynced = .now

        // An answer is finished once the phone's list no longer has it. One
        // that failed on the server comes back as pending, isn't in
        // `answers` any more by then, and so reappears by itself.
        let pending = Set((snapshot.settleRequests ?? []).map(\.id))
        answers = answers.filter { pending.contains($0.key) }

        if let selectedTripID, !snapshot.allTrips.contains(where: { $0.id == selectedTripID }) {
            self.selectedTripID = nil
        }

        saveCache()
    }

    private func loadCache() {
        guard let data = defaults.data(forKey: Self.cacheKey),
              let cached = try? JSONDecoder.snapshot.decode(EquitripSnapshot.self, from: data)
        else { return }
        snapshot = cached
        lastSynced = defaults.object(forKey: Self.syncedKey) as? Date
    }

    private func saveCache() {
        guard let snapshot, let data = try? JSONEncoder.snapshot.encode(snapshot) else { return }
        defaults.set(data, forKey: Self.cacheKey)
        defaults.set(lastSynced, forKey: Self.syncedKey)
    }
}

// MARK: - WCSessionDelegate

/// Callbacks arrive on a WatchConnectivity queue; the target is main-actor by
/// default, so each one is `nonisolated` and hops over before touching state.
extension WatchStore: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        let context = WatchWire.decode(EquitripSnapshot.self, from: session.receivedApplicationContext)
        let reachable = session.isReachable

        Task { @MainActor in
            self.isPhoneReachable = reachable
            if let context { self.apply(context) }
            self.refresh()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isPhoneReachable = reachable
            if reachable { self.refresh() }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let snapshot = WatchWire.decode(EquitripSnapshot.self, from: applicationContext) else { return }
        Task { @MainActor in self.apply(snapshot) }
    }
}
