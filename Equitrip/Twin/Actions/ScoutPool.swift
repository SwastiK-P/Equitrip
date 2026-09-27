//
//  ScoutPool.swift
//  Equitrip
//

import Foundation

/// Every place found during one search for an indoor swap — by Swift's sweep
/// or by the model's own searches — and the travel times measured to them.
///
/// The one source of names the model's answer is checked against: a name it
/// hands back that isn't in here was never returned by Maps, and is dropped.
actor ScoutPool {
    private var places: [String: ScoutPlace] = [:]
    private var order: [String] = []
    private var times: [String: (minutes: Int, onFoot: Bool)] = [:]

    func add(_ list: [ScoutPlace]) {
        for place in list where places[place.key] == nil {
            places[place.key] = place
            order.append(place.key)
        }
    }

    var all: [ScoutPlace] { order.compactMap { places[$0] } }

    /// The place the model means: its exact name, or the one place whose name
    /// contains what it wrote (it sometimes drops a suffix like "Museum").
    func place(named name: String) -> ScoutPlace? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard key.count >= 3 else { return nil }
        if let exact = places[key] { return exact }
        let partial = places.values.filter { $0.key.contains(key) || key.contains($0.key) }
        return partial.count == 1 ? partial[0] : nil
    }

    func setTime(_ minutes: Int, onFoot: Bool, for key: String) {
        times[key] = (minutes, onFoot)
    }

    func time(for key: String) -> (minutes: Int, onFoot: Bool)? { times[key] }
}
