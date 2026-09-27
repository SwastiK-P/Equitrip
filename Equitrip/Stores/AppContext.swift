//
//  AppContext.swift
//  Equitrip
//

import Foundation

/// The stores, for code that runs with no screen on it: Siri, Shortcuts,
/// Spotlight, Visual Intelligence and the watch.
///
/// Every one of those can launch the app in the background with no scene at
/// all, and then there is no `RootTabView` — and so none of the stores it owns
/// — to borrow. This used to live inside `WatchBridge`, which was the first
/// caller to hit the problem. It moved here when App Intents became the second:
/// two private copies of "sign in from the keychain and sync" would drift, and
/// the one that forgot to wire the audit trail would write bookings nobody
/// could account for.
///
/// When the UI is up, its store is the answer — it has the live data and the
/// realtime channel, and a change made through Siri appears on screen at once.
@MainActor
final class AppContext {

    static let shared = AppContext()

    /// The store the signed-in UI is using. Weak: this outlives every screen
    /// and must not keep a signed-out account's trips alive.
    private weak var uiStore: TripStore?

    /// A store of our own for background launches. Held with its notifier and
    /// audit trail because the store references both weakly, and a write whose
    /// audit entry quietly doesn't file is the failure this path exists to
    /// avoid.
    private var headless: (store: TripStore, notifications: NotificationStore, audit: AuditTrail)?

    private init() {}

    /// Called by `RootTabView` once its store is wired up. A headless store
    /// left over from a background launch is dropped here — from now on the
    /// UI's store is the one with the live data.
    func attach(_ store: TripStore) {
        uiStore = store
        headless = nil
    }

    /// Forgets everything held for a background launch. Called on sign-out, so
    /// the next account never answers Siri with the last one's trips.
    func reset() {
        headless = nil
        lastHeadlessSync = .distantPast
    }

    /// The UI's store when there is one; otherwise a headless one, signed in
    /// from the persisted session and synced fresh. Nil when nobody is signed
    /// in — the one thing no background caller can fix.
    ///
    /// `fresh: false` is for callers that run again and again over one
    /// request — a snippet redrawing after a button, an entity lookup — and
    /// want whatever store there is rather than another round trip.
    func store(fresh: Bool = true) async -> TripStore? {
        if let uiStore {
            // Launched straight into the foreground by an intent: the screen
            // exists, but its first sync may not have landed yet, and an
            // answer read off an empty store is a confident wrong answer.
            if uiStore.trips.isEmpty, uiStore.state.isLoading { await uiStore.sync() }
            return uiStore
        }

        if !fresh, let headless, lastHeadlessSync != .distantPast {
            return headless.store
        }

        // One Siri request resolves its trip, runs the intent and draws the
        // snippet at the same moment, and each used to see a store that had
        // never synced — so a cold launch restored the session and pulled the
        // whole trip graph two or three times over. Everyone arriving while a
        // load is under way waits on that one.
        if let loading { return await loading.value }

        // Fresh for each answer, within reason. One Siri request resolves its
        // entities several times over — a sync per lookup would be a network
        // round trip per word — but a background process can also live for
        // minutes, and a watch confirming a settlement against a list from
        // before it was withdrawn is the bug `WatchBridge` guards against.
        if let headless, Date().timeIntervalSince(lastHeadlessSync) <= Self.headlessFreshness {
            return headless.store
        }

        let task = Task { await loadHeadless() }
        loading = task
        let store = await task.value
        loading = nil
        return store
    }

    private func loadHeadless() async -> TripStore? {
        let auth = AuthService.shared
        if !auth.isSignedIn {
            await auth.restore()
            guard auth.isSignedIn else { return nil }
            await auth.bindIdentity()
        }

        let context = headless ?? {
            let context = (store: TripStore(), notifications: NotificationStore(), audit: AuditTrail())
            context.store.notifier = context.notifications
            context.store.auditor = context.audit
            return context
        }()
        headless = context

        await context.store.sync(includeInvitations: false)
        lastHeadlessSync = Date()
        return context.store
    }

    private var loading: Task<TripStore?, Never>?
    private var lastHeadlessSync = Date.distantPast
    private static let headlessFreshness: TimeInterval = 20
}
