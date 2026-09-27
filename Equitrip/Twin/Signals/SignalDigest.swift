//
//  SignalDigest.swift
//  Equitrip
//

import Foundation

/// What the public signals add up to: which conditions people are reporting,
/// whether that's building or easing, and how much it should move each kind
/// of booking.
///
/// This is the only door social signals have into the twin. The model never
/// sees a post — it sees `evidence(for:)`, a 0–1 number per exposure, built
/// from recency-weighted, source-weighted reports. An "all clear" from the
/// ground pulls the number down as well as reports of trouble push it up.
struct SignalDigest: Hashable {
    enum Trend: String, Hashable {
        case building, steady, easing, quiet

        var label: String {
            switch self {
            case .building: "Reports building"
            case .steady: "Steady reports"
            case .easing: "Reports easing"
            case .quiet: "Quiet"
            }
        }

        var symbol: String {
            switch self {
            case .building: "arrow.up.right"
            case .steady: "arrow.right"
            case .easing: "arrow.down.right"
            case .quiet: "minus"
            }
        }
    }

    struct Bucket: Hashable, Identifiable {
        let category: SocialSignal.Category
        let count: Int
        let strength: Double
        var id: SocialSignal.Category { category }
    }

    let signals: [SocialSignal]
    let fetchedAt: Date

    static let empty = SignalDigest(signals: [], fetchedAt: .distantPast)

    var buckets: [Bucket] {
        Dictionary(grouping: signals, by: \.category)
            .map { Bucket(category: $0.key, count: $0.value.count, strength: $0.value.reduce(0) { $0 + $1.strength }) }
            .sorted { $0.strength > $1.strength }
    }

    /// The loudest thing being reported, if anything is.
    var dominant: Bucket? {
        buckets.first { $0.category != .allClear && $0.strength > 0.15 }
    }

    var officialAlerts: [SocialSignal] {
        signals.filter { $0.source.isOfficial }
    }

    var trend: Trend {
        let now = Date()
        let recent = signals.filter { now.timeIntervalSince($0.postedAt) < 12 * 3600 && $0.category != .allClear }.count
        let earlier = signals.filter {
            let age = now.timeIntervalSince($0.postedAt)
            return age >= 12 * 3600 && age < 36 * 3600 && $0.category != .allClear
        }.count
        if recent + earlier == 0 { return .quiet }
        // Normalised per hour: the recent window is half as long.
        let recentRate = Double(recent) / 12
        let earlierRate = Double(earlier) / 24
        if recentRate > earlierRate * 1.4 + 0.05 { return .building }
        if recentRate < earlierRate * 0.6 { return .easing }
        return .steady
    }

    var sourceCounts: [(SocialSignal.Source, Int)] {
        SocialSignal.Source.allCases.compactMap { source in
            let count = signals.filter { $0.source == source }.count
            return count > 0 ? (source, count) : nil
        }
    }

    /// 0–1: how strongly the ground reports bear on bookings exposed this way,
    /// at `place` (reports naming another place on the trip count for half).
    func evidence(for exposure: WeatherExposure, place: String? = nil) -> Double {
        var pressure = 0.0
        for signal in signals {
            let relevance = Self.relevance(signal.category, exposure)
            guard relevance != 0 else { continue }
            let local = place.map { signal.place.caseInsensitiveCompare($0) == .orderedSame } ?? true
            pressure += signal.strength * relevance * (local ? 1 : 0.5)
        }
        return pressure >= 0 ? 1 - exp(-pressure) : max(-0.3, pressure * 0.3)
    }

    /// How much a category of report says about an exposure. Negative for
    /// reports that argue the other way.
    private static func relevance(_ category: SocialSignal.Category, _ exposure: WeatherExposure) -> Double {
        switch (category, exposure) {
        case (.allClear, _): return -0.6
        case (.flooding, .road), (.flooding, .rail): return 1
        case (.flooding, .outdoor), (.flooding, .marine): return 0.7
        case (.flooding, .shelter): return 0.35
        case (.flooding, .air): return 0.25
        case (.heavyRain, .outdoor), (.heavyRain, .marine): return 0.8
        case (.heavyRain, .road): return 0.6
        case (.heavyRain, .air), (.heavyRain, .rail): return 0.3
        case (.storm, .marine), (.storm, .air): return 1
        case (.storm, .outdoor): return 0.8
        case (.storm, .road), (.storm, .rail): return 0.4
        case (.heat, .outdoor): return 0.8
        case (.heat, .marine): return 0.3
        case (.transport, .road), (.transport, .rail), (.transport, .air): return 1
        case (.closure, .outdoor), (.closure, .indoor): return 0.6
        case (.closure, .marine): return 0.8
        case (.airQuality, .outdoor): return 0.5
        default: return 0
        }
    }
}
