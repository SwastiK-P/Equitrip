//
//  WatchBridge.swift
//  Equitrip
//

import UIKit
import WatchConnectivity

/// The phone's half of the watch app.
///
/// The watch never signs in. It draws the same `EquitripSnapshot` the widgets
/// do, delivered here as WatchConnectivity's application context, and the only
/// thing it can ask for in return is an answer to a settlement request — which
/// this carries out through `TripStore`, so the watch's "Confirm" is the same
/// write, the same audit entry and the same notification as the Settle tab's.
///
/// Activated from `EquitripApp.init()`, not from any view. A message from the
/// watch launches the app in the background with no scene at all, and a
/// session activated from a view that never appears never hears it.
final class WatchBridge: NSObject {

    static let shared = WatchBridge()

    private var session: WCSession? { WCSession.isSupported() ? .default : nil }

    // MARK: - Lifecycle

    func activate() {
        guard let session, session.delegate == nil else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Publishing

    /// Hands the watch the latest snapshot. Application context keeps only
    /// the newest value and delivers it whenever the watch app next runs, which
    /// is exactly right for a figure where only the current one matters.
    func publish(_ snapshot: EquitripSnapshot) {
        guard let session,
              session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled
        else { return }

        try? session.updateApplicationContext(WatchWire.encode(snapshot))
    }

    /// Re-sends whatever was last published. For the moments the watch side
    /// changes under us — the session finishing activation, or the watch app
    /// being installed after the phone app last published.
    private func republish() {
        guard let snapshot = SharedStore.loadSnapshot() else { return }
        publish(snapshot)
    }

    // MARK: - Commands

    private func handle(_ command: WatchCommand) async -> WatchReply {
        switch command {
        case .requestSnapshot:
            // From the shared container, not the store: it answers from a
            // background launch before any trip has loaded, and it's the
            // same figure the widgets are showing.
            return .snapshot(SharedStore.loadSnapshot() ?? .empty)

        case let .respondToSettlement(settlementID, tripID, confirm):
            return await respond(to: settlementID, in: tripID, confirm: confirm)
        }
    }

    /// Answers a settlement the watch was shown.
    ///
    /// Everything is re-checked against the phone's own copy. The watch's
    /// list can be minutes old: the request may have been answered on the
    /// phone, withdrawn by the payer, or — on a watch that paired with a new
    /// phone — belong to someone else entirely.
    ///
    /// `.accepted` means the answer was handed to the store, not that the
    /// server has it. If the write fails, the store rolls the settlement back
    /// to pending, `trips` changes, the snapshot republishes, and the request
    /// reappears on the watch by itself.
    private func respond(to settlementID: UUID, in tripID: UUID, confirm: Bool) async -> WatchReply {
        // The UI's store when there is one, a headless one otherwise — see
        // `AppContext`, which Siri and Shortcuts share this path with.
        guard let store = await AppContext.shared.store() else {
            return .rejected(reason: "Open Equitrip on your iPhone and sign in.")
        }

        if store.trip(tripID) == nil { await store.sync() }

        guard let trip = store.trip(tripID),
              let settlement = trip.settlements.first(where: { $0.id == settlementID })
        else {
            return .rejected(reason: "That request isn't on the trip any more.")
        }
        guard settlement.status == .pending else {
            return .rejected(reason: "Already answered on your iPhone.")
        }
        guard settlement.youAreRecipient else {
            return .rejected(reason: "That request isn't yours to answer.")
        }

        store.respondToSettlement(settlement, with: confirm ? .confirmed : .declined, in: tripID)
        return .accepted
    }

    /// Runs a command inside a background task. The watch can wake the app
    /// with only a few seconds of runtime, and a headless answer is a session
    /// restore, a sync and a write — cut short, the write is what gets lost.
    private func perform(_ command: WatchCommand) async -> WatchReply {
        let task = UIApplication.shared.beginBackgroundTask(withName: "watch-command")
        defer {
            if task != .invalid { UIApplication.shared.endBackgroundTask(task) }
        }
        return await handle(command)
    }
}

// MARK: - WCSessionDelegate

/// Every callback arrives on a WatchConnectivity queue, and the app target is
/// main-actor by default — so each one is `nonisolated` and hops over before
/// touching anything.
extension WatchBridge: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        Task { @MainActor in self.republish() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Switching to a different watch deactivates the session; reactivating
    /// is what lets the new one connect.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    /// Covers the watch app being installed after the phone last published —
    /// otherwise it would sit on "Open Equitrip on your iPhone" until the next
    /// balance change.
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.republish() }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let command = WatchWire.decode(WatchCommand.self, from: message) else {
            replyHandler(WatchWire.encode(WatchReply.rejected(reason: "Update Equitrip on your iPhone.")))
            return
        }
        Task { @MainActor in
            let reply = await self.perform(command)
            replyHandler(WatchWire.encode(reply))
        }
    }

    /// The queued path: a watch answer made while the phone was out of reach,
    /// delivered whenever the two next meet. Nobody is waiting for a reply.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let command = WatchWire.decode(WatchCommand.self, from: userInfo) else { return }
        Task { @MainActor in _ = await self.perform(command) }
    }
}
