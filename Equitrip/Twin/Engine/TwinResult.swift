//
//  TwinResult.swift
//  Equitrip
//

import Foundation

/// A distribution, reduced to what fits on a card.
struct Quantiles: Hashable {
    var p10: Double
    var p50: Double
    var p90: Double
    var mean: Double

    static let zero = Quantiles(p10: 0, p50: 0, p90: 0, mean: 0)

    init(p10: Double, p50: Double, p90: Double, mean: Double) {
        self.p10 = p10
        self.p50 = p50
        self.p90 = p90
        self.mean = mean
    }

    init(_ samples: [Double]) {
        guard !samples.isEmpty else { self = .zero; return }
        let sorted = samples.sorted()
        self.init(
            p10: sorted.percentile(0.1),
            p50: sorted.percentile(0.5),
            p90: sorted.percentile(0.9),
            mean: samples.reduce(0, +) / Double(samples.count)
        )
    }
}

/// What the simulation expects for one booking.
struct NodeOutcome: Identifiable, Hashable {
    let id: UUID
    /// Hit by its own weather.
    var pDirect: Double
    /// Hit at all — directly, or by something upstream going wrong.
    var pAffected: Double
    var pCancelled: Double
    /// Hit only because of something upstream.
    var pKnockOn: Double
    /// Median delay when it runs late, minutes.
    var typicalDelay: Double
    /// 1 when trouble is usually its own weather, 2+ when it usually arrives
    /// through a dependency — the effect's order.
    var order: Int
    /// The booking upstream that most often takes this one down with it.
    var causedBy: UUID?
    /// P10–P90 of the disruption probability across ensemble futures: how
    /// sure the twin is about its own number.
    var spread: ClosedRange<Double>
    var features: WeatherFeatures
    var drivers: [ImpactDriver]
    var basis: WeatherHour.Basis?
    var band: Int

    var risk: RiskLevel { RiskLevel(probability: pAffected) }
}

/// What the weather could do to everyone's money.
struct ShareImpact: Identifiable, Hashable {
    let travellerID: UUID
    /// Their share of bookings that might not happen, across runs.
    var atRisk: Quantiles
    /// What an extra night would add to their share, if it comes to that.
    var extraNight: Double
    /// Their share of the plan today.
    var currentShare: Double
    var id: UUID { travellerID }
}

/// Being stranded: the homebound flight or train lost, and a night more.
struct ExtraNight: Hashable {
    let stayID: UUID
    let stayTitle: String
    /// The stay's own nightly rate — its cost over its nights. No price here
    /// comes from anywhere but the booking.
    let nightly: Double
    let probability: Double
}

/// Everything one simulation found.
struct TwinResult: Hashable {
    let scenario: TwinScenario
    let generatedAt: Date
    let runs: Int
    let outcomes: [UUID: NodeOutcome]
    /// Per edge: how often trouble actually crossed it.
    let edgeFlow: [String: Double]
    let risk: RiskLevel
    let affected: Quantiles
    let valueAtRisk: Quantiles
    let shares: [ShareImpact]
    let extraNight: ExtraNight?
    /// Whether any booking's weather came from a live forecast. A trip beyond
    /// the forecast runs on last year's weather, and says so.
    let basis: WeatherHour.Basis?
    let headline: String
    let detail: String

    /// Bookings in order of concern, calm ones last.
    var ranked: [NodeOutcome] {
        outcomes.values.sorted { $0.pAffected > $1.pAffected }
    }

    var notable: [NodeOutcome] {
        ranked.filter { $0.risk.isNotable }
    }

    /// Notable bookings grouped by the order of their effect: what the
    /// weather does, then what that does, then what *that* does.
    var cascade: [(order: Int, outcomes: [NodeOutcome])] {
        let grouped = Dictionary(grouping: notable) { min($0.order, 3) }
        return grouped.keys.sorted().map { ($0, grouped[$0]!.sorted { $0.pAffected > $1.pAffected }) }
    }

    func share(for travellerID: UUID) -> ShareImpact? {
        shares.first { $0.travellerID == travellerID }
    }

    static func == (lhs: TwinResult, rhs: TwinResult) -> Bool {
        lhs.generatedAt == rhs.generatedAt && lhs.scenario == rhs.scenario
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(generatedAt)
        hasher.combine(scenario)
    }
}
