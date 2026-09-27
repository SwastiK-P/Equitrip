//
//  NetworkMonitor.swift
//  Equitrip
//

import Foundation
import Network

/// Whether this phone can reach anything at all, as the system sees it.
///
/// A trip is exactly when a phone loses signal: a flight, a ferry, a
/// homestay with no Wi-Fi. The app used to find out one failed request at a
/// time, so each screen said "Couldn't reach the server" in its own words.
/// Now one observer says it once. `OfflineBanner` shows it, and
/// `OfflineOutbox` uses the return of the path as its cue to send what
/// piled up.
///
/// Losing the connection is reported after a short grace period, so moving
/// from Wi-Fi to cellular doesn't flash the banner for half a second. Getting
/// it back is reported at once, because people are waiting on that.
@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    /// Optimistic until the first path arrives, which takes milliseconds.
    /// Starting pessimistic flashed the offline banner on every launch.
    private(set) var isOnline = true

    /// Went offline this session and hasn't been told it's caught up yet.
    /// Kept here rather than in `OfflineBanner` because every tab has its own
    /// banner, and the one on screen when the connection comes back may not
    /// be the one that saw it go.
    private(set) var isRecovering = false

    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var pendingDrop: Task<Void, Never>?
    @ObservationIgnored private var reconnectHandlers: [() -> Void] = []

    private init() {
        #if DEBUG
        // `SIMCTL_CHILD_EQUITRIP_FORCE_OFFLINE=1 xcrun simctl launch …` runs
        // the app as if there were no signal, without turning the Mac's
        // Wi-Fi off — see `SimulatedOffline`.
        if SimulatedOffline.isOn {
            isOnline = false
            isRecovering = true
            return
        }
        #endif

        // Held strongly: this is a process-wide singleton that never goes away.
        monitor.pathUpdateHandler = { @Sendable [self] path in
            let reachable = path.status == .satisfied
            Task { @MainActor in self.update(reachable: reachable) }
        }
        monitor.start(queue: DispatchQueue(label: "equitrip.network-monitor", qos: .utility))
    }

    /// Runs `handler` each time the connection comes back. Registered once,
    /// by whatever owns the work that needs redoing.
    func onReconnect(_ handler: @escaping () -> Void) {
        reconnectHandlers.append(handler)
    }

    /// Called once "back online, everything's up to date" has been shown.
    func finishRecovery() {
        guard isOnline else { return }
        isRecovering = false
    }

    private func update(reachable: Bool) {
        if reachable {
            pendingDrop?.cancel()
            pendingDrop = nil
            guard !isOnline else { return }
            isOnline = true
            reconnectHandlers.forEach { $0() }
            return
        }

        guard isOnline, pendingDrop == nil else { return }
        pendingDrop = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled, let self else { return }
            self.isOnline = false
            self.isRecovering = true
            self.pendingDrop = nil
        }
    }

    /// Whether an error means the network wasn't there, rather than that the
    /// server answered and said no.
    ///
    /// Only these can be retried later. A write that failed this way waits
    /// in the outbox. One the server refused is dropped and reported, because
    /// sending it again would get the same answer.
    nonisolated static func isConnectivity(_ error: Error) -> Bool {
        let codes: Set<URLError.Code> = [
            .notConnectedToInternet, .networkConnectionLost, .timedOut,
            .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
            .internationalRoamingOff, .dataNotAllowed, .callIsActive,
            .secureConnectionFailed, .cannotLoadFromNetwork
        ]
        if let urlError = error as? URLError { return codes.contains(urlError.code) }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return codes.contains(URLError.Code(rawValue: nsError.code))
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return isConnectivity(underlying)
        }
        return false
    }
}

#if DEBUG
/// Fails every request the way a phone with no signal does.
///
/// Only showing the offline banner wasn't enough to test offline: every
/// request still succeeded, so none of the failure paths ran (session
/// restore, a sync that can't load, the outbox holding its entries). With
/// this installed on the Supabase client's session, they all do.
final class SimulatedOffline: URLProtocol {
    nonisolated static var isOn: Bool {
        ProcessInfo.processInfo.environment["EQUITRIP_FORCE_OFFLINE"] == "1"
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override func stopLoading() {}
}
#endif
