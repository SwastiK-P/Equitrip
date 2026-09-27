//
//  OfflineOutbox.swift
//  Equitrip
//

import Foundation

/// Changes made on this phone that the server hasn't taken yet, in the order
/// they were made.
///
/// Expenses happen offline: the taxi from the airport, dinner on the boat.
/// Every write used to go straight to Postgres, so without signal an expense
/// appeared on screen, failed, and was gone after the next sync. Now it
/// comes here first. The queue is written to disk before anything is sent,
/// sent in order, and each entry is removed only when the server answers.
///
/// Two kinds of failure are handled differently, and the difference matters:
///
/// - **Couldn't reach the server** (`NetworkMonitor.isConnectivity`). The
///   entry stays at the head of the queue and nothing behind it is tried.
///   Order is kept because an audit entry or a notification about an expense
///   must not arrive before the expense does.
/// - **The server said no.** RLS, a constraint, a trip that was deleted in
///   the meantime. Sending it again would get the same answer, so it's
///   dropped, and `onRejected` reports it the way a failed write always has.
///
/// Money written here is only ever copied from the booking the person
/// entered. Nothing is recalculated on the way out, so a replayed expense
/// is exactly the one that was typed.
@MainActor
@Observable
final class OfflineOutbox {
    static let shared = OfflineOutbox()

    enum Operation: Codable {
        case createTrip(Trip)
        case upsertItem(ItineraryItem, tripID: UUID)
        case deleteItem(UUID, title: String, tripID: UUID)
        case audit(AuditEventRow)
        case notify(NotificationRow)

        /// Whether a person would count this as one of their changes. Audit
        /// rows and notifications ride along behind the change they describe
        /// and aren't counted separately.
        var isChange: Bool {
            switch self {
            case .createTrip, .upsertItem, .deleteItem: true
            case .audit, .notify: false
            }
        }

        var tripID: UUID? {
            switch self {
            case .createTrip(let trip): trip.id
            case .upsertItem(_, let tripID), .deleteItem(_, _, let tripID): tripID
            case .audit(let row): row.trip_id
            case .notify(let row): row.trip_id
            }
        }

        func creates(_ tripID: UUID) -> Bool {
            if case .createTrip(let trip) = self { trip.id == tripID } else { false }
        }
    }

    struct Entry: Codable, Identifiable {
        var id = UUID()
        var operation: Operation
        var queuedAt = Date()
    }

    private(set) var entries: [Entry] = []

    /// A drain is under way.
    private(set) var isFlushing = false

    /// The last drain stopped because the server couldn't be reached, with
    /// entries still waiting. The banner uses this to offer a retry while the
    /// phone reports it is online.
    private(set) var isStalled = false

    /// Changes still waiting, as a person would count them.
    var pendingChanges: Int { entries.filter(\.operation.isChange).count }

    /// Told about a change the server refused. `TripStore` wires this to
    /// `writeFailure`, so a refused offline write is reported like any other
    /// failed write.
    @ObservationIgnored var onRejected: ((String) -> Void)?

    @ObservationIgnored private var account: UUID?
    @ObservationIgnored private var drain: Task<Void, Never>?

    private init() {
        NetworkMonitor.shared.onReconnect { [weak self] in
            Task { await self?.flush() }
        }
    }

    // MARK: - Account

    /// Loads what an earlier session left queued for this account. A
    /// different account gets its own queue; nobody else's writes are ever
    /// sent under this login.
    func open(account: UUID) {
        guard self.account != account else { return }
        self.account = account
        entries = OfflineCache.load([Entry].self, .outbox, account: account) ?? []
        isStalled = false
    }

    /// Forgets the queue on sign-out. The file itself goes with
    /// `OfflineCache.wipe`.
    func close() {
        drain?.cancel()
        drain = nil
        account = nil
        entries = []
        isFlushing = false
        isStalled = false
    }

    // MARK: - Queueing

    /// Adds a change behind everything already waiting, and saves the queue
    /// before returning.
    ///
    /// A booking saved twice in a row, which the editor and quick add do on
    /// purpose (see `TripStore.addItem`), needs only its last version sent.
    /// The earlier one is removed. Each is a whole-row upsert, so the last
    /// one is enough.
    func enqueue(_ operation: Operation) {
        switch operation {
        case .upsertItem(let item, _):
            entries.removeAll {
                if case .upsertItem(let queued, _) = $0.operation { queued.id == item.id } else { false }
            }
        case .deleteItem(let itemID, _, _):
            entries.removeAll {
                if case .upsertItem(let queued, _) = $0.operation { queued.id == itemID } else { false }
            }
        default:
            break
        }

        entries.append(Entry(operation: operation))
        persist()
    }

    /// Drops a trip that was made offline and never sent, along with
    /// everything queued about it. Returns false when the trip isn't waiting
    /// here, meaning the server has it and must be asked to delete it.
    func discardUnsentTrip(_ tripID: UUID) -> Bool {
        guard entries.contains(where: { $0.operation.creates(tripID) }) else { return false }
        entries.removeAll { $0.operation.tripID == tripID }
        persist()
        return true
    }

    /// Puts an edit into a trip that's still waiting to be created, so it's
    /// created as edited. Returns false when the server already has the trip.
    func reviseUnsentTrip(_ trip: Trip) -> Bool {
        guard let index = entries.firstIndex(where: { $0.operation.creates(trip.id) }) else { return false }
        entries[index].operation = .createTrip(trip)
        persist()
        return true
    }

    // MARK: - Sending

    /// Sends everything waiting, oldest first, until the queue is empty or
    /// the network gives out. A call made while a drain is running waits for
    /// that drain instead of starting a second one. The running drain picks
    /// up anything queued after it began, since it reads the head of the
    /// queue on each pass.
    func flush() async {
        if let drain { return await drain.value }
        guard account != nil, !entries.isEmpty else { return }

        isFlushing = true
        let task = Task { await drainQueue() }
        drain = task
        await task.value
        drain = nil
        isFlushing = false
    }

    private func drainQueue() async {
        while let entry = entries.first, !Task.isCancelled {
            do {
                try await send(entry.operation)
                remove(entry.id)
            } catch where NetworkMonitor.isConnectivity(error) {
                isStalled = true
                return
            } catch {
                remove(entry.id)
                if let message = Self.rejection(of: entry.operation, error: error) {
                    onRejected?(message)
                }
            }
        }
        isStalled = false
    }

    private func send(_ operation: Operation) async throws {
        let repository = SupabaseRepository.shared
        switch operation {
        case .createTrip(let trip):
            try await repository.createTrip(trip)
            try await repository.upsertItems(trip.items, tripID: trip.id)
            // Only once it's actually saved. Telling four people they're on
            // a trip that then failed to write is worse than telling them
            // nothing.
            await repository.announce(trip)
        case .upsertItem(let item, let tripID):
            try await repository.upsertItem(item, tripID: tripID)
        case .deleteItem(let itemID, _, _):
            try await repository.deleteItem(itemID)
        case .audit(let row):
            try await repository.insertAuditRow(row)
        case .notify(let row):
            try await repository.deliver(row)
        }
    }

    /// What to say about a refused entry, or nil for a silent drop. Audit
    /// rows and notifications were always best-effort (see
    /// `SupabaseRepository.insertAuditRow`), and the outbox keeps that.
    private static func rejection(of operation: Operation, error: Error) -> String? {
        let reason = AuthService.message(for: error)
        switch operation {
        case .createTrip(let trip): return "\(trip.title) didn't save. \(reason)"
        case .upsertItem(let item, _): return "\(item.title) didn't save. \(reason)"
        case .deleteItem(_, let title, _): return "\(title) couldn't be deleted. \(reason)"
        case .audit, .notify: return nil
        }
    }

    private func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let account else { return }
        OfflineCache.saveNow(entries, .outbox, account: account)
    }

    // MARK: - Reading through the queue

    /// The server's trips with the changes still waiting applied on top.
    ///
    /// A sync that lands while an expense is still queued would otherwise
    /// replace the list with the server's copy, and the expense would vanish
    /// from the screen until the queue drained, which is exactly when it
    /// looks lost.
    func applied(to trips: [Trip]) -> [Trip] {
        var trips = trips
        for entry in entries {
            switch entry.operation {
            case .createTrip(let trip):
                if !trips.contains(where: { $0.id == trip.id }) { trips.append(trip) }
            case .upsertItem(let item, let tripID):
                guard let index = trips.firstIndex(where: { $0.id == tripID }) else { continue }
                if let slot = trips[index].items.firstIndex(where: { $0.id == item.id }) {
                    trips[index].items[slot] = item
                } else {
                    trips[index].items.append(item)
                }
            case .deleteItem(let itemID, _, let tripID):
                guard let index = trips.firstIndex(where: { $0.id == tripID }) else { continue }
                trips[index].items.removeAll { $0.id == itemID }
            case .audit, .notify:
                continue
            }
        }
        return trips
    }

    /// Whether a change to this booking is still waiting to go up. The
    /// timeline marks those rows, so nobody takes one for settled with the
    /// group before the group can see it.
    func isPending(_ itemID: UUID) -> Bool {
        entries.contains { entry in
            switch entry.operation {
            case .upsertItem(let item, _): item.id == itemID
            case .createTrip(let trip): trip.items.contains { $0.id == itemID }
            default: false
            }
        }
    }
}
