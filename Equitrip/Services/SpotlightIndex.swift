//
//  SpotlightIndex.swift
//  Equitrip
//

import AppIntents
import CoreSpotlight
import Foundation

/// Keeps every trip and booking in the system's semantic index.
///
/// What this buys is bigger than a Spotlight row. Entities in the index are
/// Apple Intelligence's personal context: "when's my flight to Rome?" asked of
/// Siri, "what did we book in Goa?" typed into Spotlight, and Equi's own
/// `SpotlightSearchTool` all read from here. An entity that isn't indexed is,
/// to all of them, a thing that doesn't exist.
///
/// Fed from `TripStore.trips` the same way `WidgetPublisher` is — on the
/// property, not the two dozen call sites — and debounced, because a sync, a
/// cover photo and a realtime settlement can move it three times in a second.
/// Only entities whose indexed content changed are re-sent: the first publish
/// after launch sends everything, and every later one sends what moved.
@MainActor
enum SpotlightIndex {

    private static var pending: Task<Void, Never>?

    /// What was last sent, by entity id, as a fingerprint of its contents.
    private static var sent: [UUID: Int] = [:]

    /// Ids indexed in earlier launches, so a trip deleted while the app was
    /// closed still leaves the index on the next publish.
    private static let knownKey = "spotlight.indexedIDs.v1"

    static func publish(_ trips: [Trip]) {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            teachTripNames(trips)
            try? await index(trips)
        }
    }

    /// The trip names Siri last learned, so it's told again only when they
    /// change.
    private static var taughtNames: Set<String>?

    /// Siri's phrases that name a trip ("what's next on Goa") learn the names
    /// from the trip entity query, but only when told the names changed.
    /// That used to be a side effect of indexing — after the index write, so
    /// an indexing error meant Siri never heard of "Goa" at all.
    private static func teachTripNames(_ trips: [Trip]) {
        let names = Set(trips.map { "\($0.title)|\($0.destination)" })
        guard names != taughtNames else { return }
        taughtNames = names
        EquitripShortcuts.updateAppShortcutParameters()
    }

    /// The system asking for a rebuild — after a restore, or when its own
    /// copy was purged. Forgets what it thinks it sent and starts over.
    nonisolated static func reindex() async throws {
        guard let store = await AppContext.shared.store() else { return }
        await MainActor.run { sent = [:] }
        try await index(store.trips)
    }

    /// Removes everything, for signing out: the next person on this phone
    /// shouldn't find the last one's flights in Spotlight.
    static func clear() {
        pending?.cancel()
        sent = [:]
        taughtNames = nil
        UserDefaults.standard.removeObject(forKey: knownKey)
        Task {
            try? await CSSearchableIndex.default().deleteAppEntities(ofType: TripEntity.self)
            try? await CSSearchableIndex.default().deleteAppEntities(ofType: BookingEntity.self)
        }
    }

    private static func index(_ trips: [Trip]) async throws {
        var tripEntities: [TripEntity] = []
        var bookingEntities: [BookingEntity] = []
        var fingerprints: [UUID: Int] = [:]

        for trip in trips {
            let tripEntity = TripEntity(trip)
            fingerprints[trip.id] = fingerprint(tripEntity)
            if sent[trip.id] != fingerprints[trip.id] { tripEntities.append(tripEntity) }

            for item in trip.items {
                let booking = BookingEntity(item, in: trip)
                fingerprints[item.id] = fingerprint(booking)
                if sent[item.id] != fingerprints[item.id] { bookingEntities.append(booking) }
            }
        }

        let index = CSSearchableIndex.default()
        if !tripEntities.isEmpty { try await index.indexAppEntities(tripEntities) }
        if !bookingEntities.isEmpty { try await index.indexAppEntities(bookingEntities) }

        // Gone since last time — in this launch or an earlier one.
        let known = Set((UserDefaults.standard.stringArray(forKey: knownKey) ?? []).compactMap(UUID.init))
            .union(sent.keys)
        let removed = known.subtracting(fingerprints.keys)
        if !removed.isEmpty {
            let tripIDs = Array(removed)
            try? await index.deleteAppEntities(identifiedBy: tripIDs, ofType: TripEntity.self)
            try? await index.deleteAppEntities(identifiedBy: tripIDs, ofType: BookingEntity.self)
        }

        sent = fingerprints
        UserDefaults.standard.set(fingerprints.keys.map(\.uuidString), forKey: knownKey)
    }

    /// Everything an entity puts in the index, hashed. Rebuilt from the same
    /// text the index holds, so a change that doesn't show there — a cover
    /// photo — doesn't resend anything.
    private static func fingerprint(_ trip: TripEntity) -> Int {
        var hasher = Hasher()
        hasher.combine(trip.title)
        hasher.combine(trip.destination)
        hasher.combine(trip.startDate)
        hasher.combine(trip.endDate)
        hasher.combine(trip.travellerNames)
        return hasher.finalize()
    }

    private static func fingerprint(_ booking: BookingEntity) -> Int {
        var hasher = Hasher()
        hasher.combine(fingerprint(booking.calendar))
        hasher.combine(booking.title)
        hasher.combine(booking.startDate)
        hasher.combine(booking.endDate)
        hasher.combine(booking.note.map { String($0.characters) })
        hasher.combine(booking.status?.rawValue)
        hasher.combine(booking.vendor)
        return hasher.finalize()
    }
}
