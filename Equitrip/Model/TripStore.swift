//
//  TripStore.swift
//  Equitrip
//

import SwiftUI

/// Single source of truth for trips, backed entirely by Supabase.
///
/// Screens read from here and the creation flow writes to it, so a trip made
/// on Tuesday shows up on Home, in the tab bar and on the timeline at once.
/// It starts *empty* and stays empty until the server answers — there is no
/// local sample data behind it any more. That matters beyond tidiness: the
/// old samples were rebuilt with fresh UUIDs on every launch, so a trip you
/// were looking at had a different identity each time the app started, and
/// anything keyed to it server-side (chat above all) could never be read back.
@MainActor
@Observable
final class TripStore {

    /// What the trip list currently is. `.loading` and an empty `.ready` are
    /// different screens — "we haven't asked yet" and "you're on no trips" ask
    /// completely different things of the person looking at them.
    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)

        var isLoading: Bool { self == .loading }
        var failure: String? { if case let .failed(message) = self { message } else { nil } }
    }

    private(set) var trips: [Trip]
    private(set) var state: LoadState = .loading

    /// The last write that didn't make it. Separate from `state`, which is
    /// about reading — "we couldn't load your trips" and "we couldn't save
    /// this one" need different words and only one of them should ever be on
    /// screen at a time.
    private(set) var writeFailure: String?

    /// Trips created on this device whose upsert hasn't come back yet. `sync`
    /// preserves these: replacing the list wholesale while a create was still
    /// in flight is what made a brand-new trip vanish a second after it was
    /// made.
    private var unsynced: Set<UUID> = []

    /// The trip the Expenses and Settle tabs are scoped to.
    var selectedTripID: UUID?

    /// Navigation stack for the Itinerary tab. Home pushes onto this when a
    /// trip is opened from there, so "open this trip" and "browse to it" land
    /// in the same place instead of two parallel screens.
    var itineraryPath: [UUID] = []

    init(trips: [Trip] = []) {
        self.trips = trips
        self.selectedTripID = trips.first(where: { $0.phase == .live })?.id ?? trips.first?.id
        self.state = trips.isEmpty ? .loading : .ready
    }

    /// Pulls the whole graph down from Postgres.
    ///
    /// An empty result is a success — it means you're on no trips yet, and the
    /// screens have an empty state that says so. Only a thrown error becomes
    /// `.failed`, and it keeps whatever is already on screen rather than
    /// blanking it, so a dropped connection mid-session doesn't wipe the view.
    func sync() async {
        if trips.isEmpty { state = .loading }

        do {
            let remote = try await SupabaseRepository.shared.loadTrips()
            let arrived = Set(remote.map(\.id))

            // Anything still on its way to the server stays put, and stops
            // being "unsynced" the moment the server confirms it.
            let pending = trips.filter { unsynced.contains($0.id) && !arrived.contains($0.id) }
            unsynced.subtract(arrived)

            trips = (remote + pending).sorted { $0.startDate > $1.startDate }
            state = .ready

            if selectedTripID == nil || !trips.contains(where: { $0.id == selectedTripID }) {
                selectedTripID = currentTrip?.id ?? trips.first?.id
            }
        } catch {
            state = .failed(AuthService.message(for: error))
        }
    }

    /// Pull-to-refresh and "try again" both land here.
    func reload() async {
        await sync()
    }

    var selectedTrip: Trip? {
        guard let selectedTripID else { return trips.first }
        return trips.first { $0.id == selectedTripID } ?? trips.first
    }

    // MARK: - Portfolio totals

    /// Everything owed to you across trips, and everything you owe. Kept as
    /// two figures rather than one net, because "you're square" and "you're
    /// owed ₹9,150 and owe ₹9,150" are very different situations.
    var owedToYou: Double { trips.reduce(0) { $0 + $1.owedTo(Traveller.you.id) } }
    var youOwe: Double { trips.reduce(0) { $0 + $1.owing(Traveller.you.id) } }
    var netPosition: Double { owedToYou - youOwe }

    var activeTrips: [Trip] { trips.filter { $0.phase != .past } }

    /// Currency of the portfolio headline. Mixed-currency groups need real
    /// conversion; until then the most common code wins and we don't pretend.
    var primaryCurrency: String {
        let counts = Dictionary(grouping: trips, by: \.currencyCode).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "INR"
    }

    // MARK: - Mutation

    func add(_ trip: Trip) {
        trips.insert(trip, at: 0)
        selectedTripID = trip.id
        unsynced.insert(trip.id)

        Task {
            do {
                try await SupabaseRepository.shared.upsertTrip(trip)
                try await SupabaseRepository.shared.upsertItems(trip.items, tripID: trip.id)
                unsynced.remove(trip.id)
                writeFailure = nil

                // Only once it's actually saved. Telling four people they're on
                // a trip that then failed to write is worse than telling them
                // nothing.
                await SupabaseRepository.shared.announce(trip)
            } catch {
                writeFailure = "\(trip.title) didn't save. \(AuthService.message(for: error))"
            }
        }
    }

    /// Opens a trip's itinerary, replacing whatever was on the stack.
    func open(_ trip: Trip) {
        selectedTripID = trip.id
        itineraryPath = [trip.id]
    }

    /// The one trip Home leads with: what's happening now, else what's next.
    var currentTrip: Trip? {
        trips.first { $0.phase == .live }
            ?? trips.filter { $0.phase == .upcoming }.min { $0.startDate < $1.startDate }
    }

    func update(_ trip: Trip) {
        guard let index = trips.firstIndex(where: { $0.id == trip.id }) else { return }
        trips[index] = trip
        write { try await SupabaseRepository.shared.upsertTrip(trip) }
    }

    func updateItem(_ item: ItineraryItem, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
              let itemIndex = trips[tripIndex].items.firstIndex(where: { $0.id == item.id })
        else { return }
        trips[tripIndex].items[itemIndex] = item
        write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
    }

    func removeItem(_ itemID: UUID, in tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[tripIndex].items.removeAll { $0.id == itemID }
        write { try await SupabaseRepository.shared.deleteItem(itemID) }
    }

    func addItem(_ item: ItineraryItem, to tripID: UUID) {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripID }) else { return }
        trips[tripIndex].items.append(item)
        // A booking outside the current span widens the trip rather than
        // falling off the end of the timeline.
        if item.day < trips[tripIndex].startDate { trips[tripIndex].startDate = item.day }
        if item.day > trips[tripIndex].endDate { trips[tripIndex].endDate = item.day }
        write { try await SupabaseRepository.shared.upsertItem(item, tripID: tripID) }
    }

    /// Runs a write in the background and keeps whatever went wrong, so the
    /// screens can say so instead of the change quietly not existing.
    private func write(_ body: @escaping () async throws -> Void) {
        Task {
            do {
                try await body()
                writeFailure = nil
            } catch {
                writeFailure = AuthService.message(for: error)
            }
        }
    }

    func clearWriteFailure() { writeFailure = nil }

    func setCover(_ photo: TripPhoto, for tripID: UUID) {
        guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
        guard trips[index].cover == nil else { return }

        // Show the provider's URL straight away, then quietly swap in the
        // stored copy so every later appearance — and every other member of
        // the trip — reads the same file instead of re-searching.
        trips[index].cover = photo

        Task {
            let stored = await CoverStore.shared.persist(photo, for: tripID)
            guard let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
            trips[index].cover = stored
        }
    }

    /// A cover the user chose themselves always wins over a searched one.
    func setCustomCover(_ imageData: Data, for tripID: UUID) {
        Task {
            guard let stored = await CoverStore.shared.persist(imageData: imageData, for: tripID),
                  let index = trips.firstIndex(where: { $0.id == tripID }) else { return }
            trips[index].cover = stored
        }
    }

    /// Finds a trip by its invite code, however it was typed or scanned.
    func trip(code: String) -> Trip? {
        let target = Trip.normaliseCode(code)
        guard !target.isEmpty else { return nil }
        return trips.first { Trip.normaliseCode($0.inviteCode) == target }
    }

    /// Finds a trip by invite code, on the server if it isn't already here.
    ///
    /// The local list can only ever contain trips you're *already* on, which
    /// is exactly the set you're not trying to join — so a local-only lookup
    /// could never find anybody else's trip. `trips_read` is open to any
    /// signed-in user precisely so this preview can work before membership.
    /// Server first, local only as an offline fallback. The server's copy is
    /// the authoritative one — it carries the current traveller list and
    /// bookings, where a local copy may be several edits behind — and asking
    /// it every time means the path that matters is the path that runs.
    func findTrip(code: String) async -> Trip? {
        if let remote = await SupabaseRepository.shared.trip(code: code) { return remote }
        return trip(code: code)
    }

    enum JoinOutcome: Equatable {
        case joined
        case alreadyMember
        case failed(String)
    }

    /// Joins a trip for real: writes the membership, then re-reads everything
    /// so the trip arrives with its people and bookings attached.
    func join(_ tripID: UUID) async -> JoinOutcome {
        do {
            let isNew = try await SupabaseRepository.shared.join(tripID: tripID)
            await sync()
            return isNew ? .joined : .alreadyMember
        } catch {
            return .failed(AuthService.message(for: error))
        }
    }

    func trip(_ id: UUID?) -> Trip? {
        guard let id else { return nil }
        return trips.first { $0.id == id }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    @Entry var tripStore = TripStore()
}
