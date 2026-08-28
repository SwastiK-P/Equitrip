//
//  FlightConfig.swift
//  Equitrip
//

import Foundation

/// Where live flight data comes from.
///
/// AviationStack has a free tier that's enough for a trip's worth of lookups —
/// sign up at https://aviationstack.com/signup/free and drop the access key
/// below. Until then, flight numbers can still be entered or scanned from a
/// boarding pass; they just won't resolve to a route, times or a live status.
enum FlightConfig {
    static let aviationStackKey = "bb2744c93a3ee202f461430f99545442"

    static var isConfigured: Bool { !aviationStackKey.isEmpty }
}
