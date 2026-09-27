//
//  WeatherTwinStore.swift
//  Equitrip
//

import SwiftUI
import Observation

/// The Weather Twin for each trip: where its bookings are, the weather over
/// them, what people on the ground are saying, and what that's likely to do.
///
/// A mirror, never a writer. Everything here is read from the trip and the
/// outside world and simulated on the phone; nothing is saved to the trip,
/// and a what-if is a pure function of the live state — which is how the twin
/// can play out a cyclone over somebody's holiday without any of it reaching
/// the ledger.
///
/// Refreshes are cheap to ask for and decide for themselves whether to run:
/// the live state is kept ten minutes, a changed itinerary re-simulates
/// without refetching the weather, and new places trigger a fresh fetch.
@MainActor
@Observable
final class WeatherTwinStore {

    enum Phase: Equatable {
        case idle
        case locating
        case fetching
        case simulating
        case ready
        case failed(String)

        var isWorking: Bool { [.locating, .fetching, .simulating].contains(self) }

        var label: String {
            switch self {
            case .idle, .ready: ""
            case .locating: "Placing bookings on the map"
            case .fetching: "Reading stations, forecasts and reports"
            case .simulating: "Running the trip through the weather"
            case .failed(let message): message
            }
        }
    }

    struct TripState {
        var twin: TripTwin?
        var weather: [String: PlaceWeather] = [:]
        var digest: SignalDigest = .empty
        var live: TwinResult?
        var phase: Phase = .idle
        var updatedAt: Date?
        /// Hash of what the graph was built from, so an edited itinerary is noticed.
        var signature: Int = 0
        var places: [UUID: TwinGeocoder.Place] = [:]
    }

    private(set) var states: [UUID: TripState] = [:]
    let learning = TwinLearning()
    let actions = TwinActionQueue()

    private var loadedCalibration = false
    private var inFlight: Set<UUID> = []

    /// How long a live state stays fresh.
    static let freshFor: TimeInterval = 10 * 60

    // MARK: - Reading

    func state(for tripID: UUID) -> TripState? { states[tripID] }
    func live(for tripID: UUID) -> TwinResult? { states[tripID]?.live }

    func outcome(for itemID: UUID, in tripID: UUID) -> NodeOutcome? {
        states[tripID]?.live?.outcomes[itemID]
    }

    /// The forecast hour a booking starts in, at its own place.
    func hour(for item: ItineraryItem, in tripID: UUID) -> WeatherHour? {
        guard let state = states[tripID], let node = state.twin?.node(item.id) else { return nil }
        let place = state.weather[node.weatherPlaceID] ?? state.weather["dest"]
        return place?.hour(at: item.time ?? node.window.start.addingTimeInterval(node.window.duration / 2))
    }

    func day(_ date: Date, in tripID: UUID) -> WeatherDay? {
        states[tripID]?.weather["dest"]?.day(for: date)
    }

    func destinationWeather(for tripID: UUID) -> PlaceWeather? {
        states[tripID]?.weather["dest"]
    }

    // MARK: - Refreshing

    /// Brings a trip's twin up to date. Safe to call on every appearance.
    func refresh(_ trip: Trip, force: Bool = false) async {
        guard !inFlight.contains(trip.id) else { return }
        let signature = Self.signature(of: trip)
        var state = states[trip.id] ?? TripState()

        let isFresh = state.updatedAt.map { Date().timeIntervalSince($0) < Self.freshFor } ?? false
        if isFresh, !force, state.signature == signature { return }

        inFlight.insert(trip.id)
        defer { inFlight.remove(trip.id) }

        if !loadedCalibration {
            loadedCalibration = true
            Task { await learning.load() }
        }

        // Only the graph changed: re-simulate on the weather already here.
        if isFresh, !force, state.signature != signature, !state.weather.isEmpty,
           let destination = state.twin?.destination {
            let places = await locate(trip, around: destination, known: state.places)
            if Set(places.keys) == Set(state.places.keys) || places.count <= state.places.count {
                state.places = places
                state.twin = TripTwin.build(trip: trip, destination: destination, places: places)
                state.signature = signature
                states[trip.id] = state
                simulateLive(trip)
                return
            }
        }

        setPhase(.locating, for: trip.id)
        guard let destination = await TwinGeocoder.destination(of: trip) else {
            setPhase(.failed("Couldn't find \(trip.destination.isEmpty ? trip.title : trip.destination) on the map."), for: trip.id)
            return
        }
        let places = await locate(trip, around: destination, known: state.places)
        let twin = TripTwin.build(trip: trip, destination: destination, places: places)

        state = states[trip.id] ?? TripState()
        state.twin = twin
        state.places = places
        state.signature = signature
        state.phase = .fetching
        states[trip.id] = state

        let window = DateInterval(
            start: Calendar.current.startOfDay(for: trip.startDate).addingTimeInterval(-86_400),
            end: Calendar.current.startOfDay(for: trip.endDate).addingTimeInterval(2 * 86_400)
        )
        // Ground reports ride alongside, but nothing waits for them: the posts
        // take several round trips and the on-device model reads them in
        // batches after that, which used to hold the whole twin back by
        // seconds. The weather is what the answer needs; reports refine it.
        async let posts = SocialSignalService.posts(about: twin.placeNames, near: destination.point)
        let weatherValue = await WeatherFusion.weather(for: twin.weatherPlaces, window: window)

        guard !weatherValue.isEmpty else {
            setPhase(.failed(
                OpenMeteoService.isRateLimited
                    ? "The free weather service's daily limit is used up on this network. It resets tomorrow."
                    : "The forecast couldn't be reached. Pull to try again."
            ), for: trip.id)
            return
        }

        state = states[trip.id] ?? state
        state.weather = weatherValue
        state.updatedAt = Date()
        state.phase = .simulating
        states[trip.id] = state
        simulateLive(trip)

        let signals = await SignalReader.read(await posts, places: twin.placeNames, primary: destination.name)
        guard var current = states[trip.id] else { return }
        current.digest = SignalDigest(signals: signals, fetchedAt: Date())
        states[trip.id] = current
        simulateLive(trip)
    }

    /// A what-if, on the trip's current live state. Nil until that exists.
    func simulate(_ scenario: TwinScenario, for trip: Trip) -> TwinResult? {
        guard let state = states[trip.id], let twin = state.twin, !state.weather.isEmpty else { return nil }
        let t0 = ContinuousClock.now; defer { NSLog("TWINPERF simulate %@", String(describing: ContinuousClock.now - t0)) } // TEMP
        return TwinSimulator(
            twin: twin,
            trip: trip,
            weather: state.weather,
            digest: state.digest,
            calibration: learning.calibration
        ).run(scenario)
    }

    /// Plan B suggestions for a result — live or what-if.
    func plan(for result: TwinResult, trip: Trip) -> [TwinAction] {
        guard let state = states[trip.id], let twin = state.twin else { return [] }
        return TwinActionPlanner.plan(result: result, twin: twin, trip: trip, weather: state.weather)
    }

    /// A traveller's answer to "did the weather get this?" — the most direct
    /// evidence the model gets.
    func recordAnswer(_ disrupted: Bool, for item: ItineraryItem, in trip: Trip) {
        guard let state = states[trip.id], let node = state.twin?.node(item.id) else { return }
        let band = state.live?.outcomes[item.id]?.band ?? 0
        learning.record(
            itemID: item.id,
            exposure: node.exposure,
            band: band,
            disrupted: disrupted,
            source: .traveller,
            city: state.twin?.destination.name
        )
        simulateLive(trip)
    }

    // MARK: - Internals

    private func simulateLive(_ trip: Trip) {
        guard var state = states[trip.id], let twin = state.twin else { return }
        let result = TwinSimulator(
            twin: twin,
            trip: trip,
            weather: state.weather,
            digest: state.digest,
            calibration: learning.calibration
        ).run(TwinScenario())

        state.live = result
        state.phase = .ready
        states[trip.id] = state

        actions.update(TwinActionPlanner.plan(result: result, twin: twin, trip: trip, weather: state.weather), for: trip.id)
        learning.harvest(
            from: trip,
            twin: twin,
            bands: result.outcomes.mapValues(\.band),
            city: twin.destination.name
        )
    }

    /// Every booking's place at once — one search at a time made a
    /// 20-booking trip wait on 20 round trips in a row.
    private func locate(_ trip: Trip, around destination: TwinGeocoder.Place, known: [UUID: TwinGeocoder.Place]) async -> [UUID: TwinGeocoder.Place] {
        // A booking renamed or moved to another vendor (an indoor swap) is
        // somewhere else now: its old spot is forgotten and searched afresh.
        var places = known.filter { id, place in
            guard let item = trip.items.first(where: { $0.id == id }) else { return false }
            return place.isApproximate || TwinGeocoder.searchQueries(for: item).contains(place.name)
        }
        let missing = trip.items.filter { places[$0.id] == nil }
        await withTaskGroup(of: (UUID, TwinGeocoder.Place).self) { group in
            for item in missing {
                group.addTask { (item.id, await TwinGeocoder.place(for: item, around: destination)) }
            }
            for await (id, place) in group { places[id] = place }
        }
        return places
    }

    private func setPhase(_ phase: Phase, for tripID: UUID) {
        var state = states[tripID] ?? TripState()
        state.phase = phase
        states[tripID] = state
    }

    /// What the graph depends on: the bookings' identity, kind, time and cost.
    private static func signature(of trip: Trip) -> Int {
        var hasher = Hasher()
        hasher.combine(trip.destination)
        hasher.combine(trip.startDate)
        hasher.combine(trip.endDate)
        for item in trip.items.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            hasher.combine(item.id)
            hasher.combine(item.kind)
            hasher.combine(item.date)
            hasher.combine(item.time)
            hasher.combine(item.cost)
            hasher.combine(item.title)
            hasher.combine(item.vendor)
            hasher.combine(item.flight?.status)
        }
        return hasher.finalize()
    }
}

extension WeatherTwinStore {
    /// The environment's fallback. `RootTabView` injects the real one; this
    /// exists so the default isn't reallocated on every environment read.
    static let detached = WeatherTwinStore()
}

extension EnvironmentValues {
    @Entry var weatherTwin = WeatherTwinStore.detached
}
