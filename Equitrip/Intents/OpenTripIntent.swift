//
//  OpenTripIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// "Open the Goa trip in Equitrip" — and what a trip picked from Spotlight or
/// a Siri answer opens into.
///
/// Adopts the system domain's *open* schema, which is what lets Siri route
/// "open …" at an entity without a phrase of its own, and what Spotlight uses
/// when a trip result is tapped. The work is a note to `AppNavigator`: the
/// intent runs in the App Intents runtime, the tab bar lives under
/// `RootTabView`, and only the navigator reaches both.
@AppIntent(schema: .system.open)
struct OpenTripIntent: OpenIntent {

    static let title: LocalizedStringResource = "Open Trip"
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Trip")
    var target: TripEntity

    init() {}

    init(target: TripEntity) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppNavigator.shared.go(.trip(target.id))
        return .result()
    }
}

/// Opens a booking's detail on its trip's timeline.
@AppIntent(schema: .system.open)
struct OpenBookingIntent: OpenIntent {

    static let title: LocalizedStringResource = "Open Booking"
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Booking")
    var target: BookingEntity

    init() {}

    init(target: BookingEntity) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        AppNavigator.shared.go(.booking(tripID: target.calendar.id, itemID: target.id))
        return .result()
    }
}
