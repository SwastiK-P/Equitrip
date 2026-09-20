//
//  ItineraryRoute.swift
//  Equitrip
//

import Foundation

/// A screen on the Itinerary tab's stack.
///
/// The stack used to be a plain list of trip ids, which left no room for the
/// past-trips screen in between. Pushed from outside the path instead, it
/// fell off the stack the moment a trip was opened from it — back went
/// straight to the list — and the trip lost its zoom transition, because the
/// card it zoomed from was no longer on a screen the path knew about.
enum ItineraryRoute: Hashable {
    case trip(UUID)
    case pastTrips
}
