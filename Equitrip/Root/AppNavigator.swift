//
//  AppNavigator.swift
//  Equitrip
//

import Observation
import Foundation

/// Where Siri, Spotlight or a Shortcut has asked the app to go.
///
/// The screens that can answer all live under `RootTabView`, which owns the
/// tab selection, and under `TripItineraryView`, which owns its own sheets.
/// An intent has neither: it runs in `perform()`, off in the App Intents
/// runtime, and can only leave a note. So it leaves one here, and the root and
/// the trip screen each take the part that's theirs.
///
/// Held until taken rather than fired and forgotten, because the likeliest
/// time for a request to arrive is a cold launch — before the trips have
/// loaded, before the trip screen exists — and a request nobody was there to
/// hear is "open the Goa trip" landing on Home and nothing else.
@MainActor
@Observable
final class AppNavigator {

    static let shared = AppNavigator()

    enum Destination: Equatable {
        case trip(UUID)
        case booking(tripID: UUID, itemID: UUID)
        /// A trip's group chat, optionally with words already in the composer
        /// — Siri's "draft a message" leaves the sending to the person.
        case chat(tripID: UUID, draft: String?)
    }

    /// What a trip's own screen should put up once it's showing that trip.
    enum TripFocus: Equatable {
        case booking(UUID)
        case chat(draft: String?)
    }

    /// The root's part. A fresh id per request, so asking for the same place
    /// twice in a row is still two changes for `onChange` to see.
    private(set) var request: Request?

    struct Request: Equatable {
        let id = UUID()
        let destination: Destination
    }

    /// A request that came too early — its trip hadn't loaded — kept out of
    /// `request` so putting it back doesn't read as a new one and spin.
    @ObservationIgnored private var deferred: Destination?

    /// The trip screen's part, keyed to the trip it belongs to.
    private(set) var tripFocus: PendingFocus?

    struct PendingFocus: Equatable {
        let id = UUID()
        let tripID: UUID
        let focus: TripFocus
    }

    private init() {}

    func go(_ destination: Destination) {
        deferred = nil
        request = Request(destination: destination)
    }

    /// Hands the pending request to the root, once.
    func takeRequest() -> Destination? {
        if let request {
            self.request = nil
            return request.destination
        }
        defer { deferred = nil }
        return deferred
    }

    /// Put back a request that arrived before it could be answered. The root
    /// asks again when the trips land.
    func deferRequest(_ destination: Destination) {
        deferred = destination
    }

    func focus(_ focus: TripFocus, on tripID: UUID) {
        tripFocus = PendingFocus(tripID: tripID, focus: focus)
    }

    func takeFocus(for tripID: UUID) -> TripFocus? {
        guard let tripFocus, tripFocus.tripID == tripID else { return nil }
        self.tripFocus = nil
        return tripFocus.focus
    }
}
