//
//  TwinSimulator.swift
//  Equitrip
//

import Foundation

/// Runs the trip through a few hundred plausible futures and counts what
/// happens to each booking.
///
/// Each run picks one ensemble member for the whole trip, so a run is one
/// coherent future — the storm that soaks the morning transfer is the same
/// storm over the afternoon ferry — rather than every booking rolling its own
/// weather independently. Beyond the ensemble's reach the hours are last
/// year's, perturbed widely; for days already past they're reanalysis,
/// barely perturbed at all, which makes a finished trip a replay.
///
/// Inside a run, each booking's weather gives a disruption probability
/// (`ImpactModel`), a draw decides whether it's hit and how, and trouble then
/// moves along the twin's edges: a delay that eats more than the slack
/// before the next booking can take that booking down too, and whatever that
/// booking feeds next. Counting across runs gives each booking a probability,
/// an order (is this the weather, or the weather's knock-on?), and a spread.
///
/// Money is never computed here. Lost bookings are priced with
/// `Trip.shares(of:)` — the same split the ledger uses — and an extra night is
/// the stay's own rate, added to a copy of the trip and asked
/// `cost(for:)` like any other booking. Every run uses the same random
/// stream, so live and what-if differ only by the weather they were given.
struct TwinSimulator {
    let twin: TripTwin
    let trip: Trip
    let weather: [String: PlaceWeather]
    let digest: SignalDigest
    let calibration: TwinCalibration

    static let defaultRuns = 320

    private enum RunState {
        case onTrack
        case delayed(Double)
        case cancelled
        case missed(because: UUID)

        var isLost: Bool {
            switch self {
            case .cancelled, .missed: true
            default: false
            }
        }

        var isAffected: Bool {
            if case .onTrack = self { return false }
            return true
        }
    }

    /// The bookings worth simulating: everything still ahead, or the whole
    /// trip once it's over (a replay).
    var relevantNodes: [TwinNode] {
        guard trip.phase != .past else { return twin.nodes }
        let cutoff = Date().addingTimeInterval(-3 * 3600)
        return twin.nodes.filter { $0.window.end >= cutoff }
    }

    func run(_ scenario: TwinScenario, runs: Int = TwinSimulator.defaultRuns) -> TwinResult {
        let nodes = relevantNodes
        var rng = SeededGenerator(seed: 0x5EED_2026)

        // Per booking, the fixed ingredients.
        struct Prepared {
            let node: TwinNode
            let place: PlaceWeather?
            let during: [WeatherHour]
            let before: [WeatherHour]
            let members: Int
            let basis: WeatherHour.Basis?
            let evidence: Double
            let shares: [UUID: Double]
            // Fixed across runs, so worked out here rather than inside the
            // loop: they were calendar lookups and edge scans repeated
            // runs × bookings times on every dial tick.
            let flood: Double
            let overlay: TwinScenario.Overlay?
            let incoming: [TwinEdge]
        }

        let now = Date()
        let prepared: [Prepared] = nodes.map { node in
            let place = weather[node.weatherPlaceID] ?? weather["dest"]
            let during = place?.hours(in: node.window) ?? []
            let lead = DateInterval(start: node.window.start.addingTimeInterval(-12 * 3600), end: node.window.start)
            let before = place?.hours(in: lead) ?? []
            let members = during.map(\.memberPrecipitation.count).min() ?? 0
            // Reports describe now; they say little about next week.
            let isNear = abs(node.window.start.timeIntervalSince(now)) < 36 * 3600
            let evidence = isNear ? digest.evidence(for: node.exposure, place: node.place.locality) : 0
            let shares = Dictionary(trip.shares(of: node.item).map { ($0.traveller.id, $0.amount) }, uniquingKeysWith: +)
            return Prepared(
                node: node, place: place, during: during, before: before,
                members: members, basis: during.first?.basis, evidence: evidence, shares: shares,
                flood: place?.flood(on: node.window.start) ?? 0,
                overlay: scenario.overlay(window: node.window, at: node.place.point),
                incoming: twin.incoming(node.id)
            )
        }

        let index = Dictionary(uniqueKeysWithValues: prepared.enumerated().map { ($1.node.id, $0) })
        let memberCount = prepared.map(\.members).filter { $0 > 0 }.min() ?? 0

        // Tallies.
        var direct = Array(repeating: 0, count: prepared.count)
        var affected = Array(repeating: 0, count: prepared.count)
        var lost = Array(repeating: 0, count: prepared.count)
        var knocked = Array(repeating: 0, count: prepared.count)
        var delays = Array(repeating: [Double](), count: prepared.count)
        var orders = Array(repeating: [Int: Int](), count: prepared.count)
        var causes = Array(repeating: [UUID: Int](), count: prepared.count)
        var probabilities = Array(repeating: [Double](), count: prepared.count)
        var featureSamples = Array(repeating: [(p: Double, f: WeatherFeatures)](), count: prepared.count)
        var edgeCounts: [String: Int] = [:]
        var affectedCounts: [Double] = []
        var valueAtRisk: [Double] = []
        var atRisk: [UUID: [Double]] = [:]
        var stranded = 0

        for _ in 0..<runs {
            let member = memberCount > 0 ? Int.random(in: 0..<memberCount, using: &rng) : -1
            let g1 = rng.gaussian(), g2 = rng.gaussian(), g3 = rng.gaussian()

            var states = Array(repeating: RunState.onTrack, count: prepared.count)
            var runOrders = Array(repeating: 0, count: prepared.count)

            for (i, item) in prepared.enumerated() {
                var features = baseFeatures(item.during, before: item.before, member: member, basis: item.basis, g: (g1, g2, g3))
                features.flood = item.flood
                features.evidence = item.evidence
                features = scenario.apply(item.overlay, to: features)

                let p = ImpactModel.probability(item.node.exposure, features, calibration: calibration)
                probabilities[i].append(p)
                if featureSamples[i].count < 60 { featureSamples[i].append((p, features)) }

                // Its own weather.
                if Double.random(in: 0..<1, using: &rng) < p {
                    let band = ImpactModel.band(features)
                    if Double.random(in: 0..<1, using: &rng) < ImpactModel.cancellationShare(item.node.exposure, band: band) {
                        states[i] = .cancelled
                    } else {
                        let range = ImpactModel.delayRange(item.node.exposure, band: band)
                        states[i] = .delayed(Double.random(in: range, using: &rng))
                    }
                    runOrders[i] = 1
                    direct[i] += 1
                }

                // Whatever it depends on.
                guard !states[i].isLost else { continue }
                for edge in item.incoming {
                    guard let from = index[edge.from], from < i else { continue }
                    let chance: Double
                    switch states[from] {
                    case .onTrack:
                        chance = 0
                    case .cancelled, .missed:
                        chance = edge.kind == .sequence ? 0.3 : edge.kind == .transfer ? 0.8 : 0.85
                    case .delayed(let minutes):
                        let overshoot = minutes - edge.slack
                        chance = overshoot > 0 ? (1 - exp(-overshoot / 40)) * edge.kind.strength : 0
                    }
                    guard chance > 0, Double.random(in: 0..<1, using: &rng) < chance else { continue }
                    states[i] = .missed(because: edge.from)
                    runOrders[i] = max(runOrders[from], 1) + 1
                    edgeCounts[edge.id, default: 0] += 1
                    break
                }
            }

            // Tally the run.
            var count = 0.0
            var value = 0.0
            var perPerson: [UUID: Double] = [:]
            for (i, state) in states.enumerated() {
                guard state.isAffected else { continue }
                count += 1
                affected[i] += 1
                orders[i][runOrders[i], default: 0] += 1
                switch state {
                case .delayed(let minutes): delays[i].append(minutes)
                case .missed(let cause):
                    knocked[i] += 1
                    lost[i] += 1
                    causes[i][cause, default: 0] += 1
                case .cancelled: lost[i] += 1
                case .onTrack: break
                }
                if state.isLost, prepared[i].node.item.cost > 0 {
                    value += prepared[i].node.item.cost
                    for (person, amount) in prepared[i].shares { perPerson[person, default: 0] += amount }
                }
            }
            affectedCounts.append(count)
            valueAtRisk.append(value)
            for traveller in trip.travellers { atRisk[traveller.id, default: []].append(perPerson[traveller.id] ?? 0) }

            if let home = twin.homeboundID, let i = index[home], states[i].isLost { stranded += 1 }
        }

        // Per booking.
        var outcomes: [UUID: NodeOutcome] = [:]
        for (i, item) in prepared.enumerated() {
            let sortedP = probabilities[i].sorted()
            let median = sortedP.percentile(0.5)
            let typical = featureSamples[i].min { abs($0.p - median) < abs($1.p - median) }?.f ?? WeatherFeatures()
            let n = Double(runs)
            outcomes[item.node.id] = NodeOutcome(
                id: item.node.id,
                pDirect: Double(direct[i]) / n,
                pAffected: Double(affected[i]) / n,
                pCancelled: Double(lost[i]) / n,
                pKnockOn: Double(knocked[i]) / n,
                typicalDelay: delays[i].sorted().percentile(0.5),
                order: orders[i].max { $0.value < $1.value }?.key ?? 1,
                causedBy: causes[i].max { $0.value < $1.value }?.key,
                spread: sortedP.percentile(0.1)...max(sortedP.percentile(0.1), sortedP.percentile(0.9)),
                features: typical,
                drivers: ImpactModel.drivers(item.node.exposure, typical),
                basis: item.basis,
                band: ImpactModel.band(typical)
            )
        }

        let extraNight = strandedNight(probability: Double(stranded) / Double(runs))
        let extraShares = extraNight.map(extraNightShares) ?? [:]

        let shares = trip.travellers.map { traveller in
            ShareImpact(
                travellerID: traveller.id,
                atRisk: Quantiles(atRisk[traveller.id] ?? []),
                extraNight: extraShares[traveller.id] ?? 0,
                currentShare: trip.cost(for: traveller.id)
            )
        }

        let risk = outcomes.values.map(\.risk).max() ?? .calm
        let basis = dominantBasis(prepared.compactMap(\.basis))
        let (headline, detail) = narrate(outcomes: outcomes, risk: risk, basis: basis, extraNight: extraNight, isEmpty: prepared.isEmpty)

        return TwinResult(
            scenario: scenario,
            generatedAt: Date(),
            runs: runs,
            outcomes: outcomes,
            edgeFlow: edgeCounts.mapValues { Double($0) / Double(runs) },
            risk: risk,
            affected: Quantiles(affectedCounts),
            valueAtRisk: Quantiles(valueAtRisk),
            shares: shares,
            extraNight: extraNight,
            basis: basis,
            headline: headline,
            detail: detail
        )
    }

    // MARK: - Weather for one run

    private func baseFeatures(
        _ during: [WeatherHour],
        before: [WeatherHour],
        member: Int,
        basis: WeatherHour.Basis?,
        g: (Double, Double, Double)
    ) -> WeatherFeatures {
        var f = WeatherFeatures()
        guard !during.isEmpty else { return f }

        // How far the unperturbed figures are allowed to wander, by basis.
        let (rainSigma, tempSigma, windSigma): (Double, Double, Double) = switch basis {
        case .observed: (0.05, 0.3, 0.05)
        case .forecast: (0.5, 1.0, 0.15)
        case .seasonal, .none: (0.9, 2.5, 0.3)
        }
        let rainScale = exp(rainSigma * g.0 - rainSigma * rainSigma / 2)

        func rain(_ hour: WeatherHour) -> Double {
            if member >= 0, member < hour.memberPrecipitation.count { return hour.memberPrecipitation[member] }
            return hour.precipitation * rainScale
        }
        func temp(_ hour: WeatherHour) -> Double {
            if member >= 0, member < hour.memberTemperature.count { return hour.memberTemperature[member] }
            return hour.temperature + tempSigma * g.1
        }

        let rains = during.map(rain)
        f.rainRate = rains.max() ?? 0
        f.rainTotal = rains.reduce(0, +) + before.map(rain).reduce(0, +)
        let temps = during.map(temp)
        f.temperature = temps.max() ?? 25
        let apparentLift = during.map { ($0.apparentTemperature ?? $0.temperature) - $0.temperature }.max() ?? 0
        f.apparentTemperature = f.temperature + apparentLift
        f.gusts = (during.map { $0.gusts ?? $0.windSpeed * 1.5 }.max() ?? 0) * max(0.4, 1 + windSigma * g.2)
        let codes = during.map(\.code)
        f.thunder = codes.contains { (95...99).contains($0) }
        f.fog = codes.contains { $0 == 45 || $0 == 48 }
        f.code = codes.max() ?? 0
        return f
    }

    // MARK: - Stranding

    /// The stay people would need one more night of if the way home falls through.
    private func strandedNight(probability: Double) -> ExtraNight? {
        guard probability > 0, let home = twin.homeboundID, let homeNode = twin.node(home) else { return nil }
        let stays = trip.items
            .filter { $0.kind == .stay && $0.day <= homeNode.item.day && $0.cost > 0 }
            .sorted { $0.date < $1.date }
        guard let stay = stays.last else { return nil }

        // Its nights: up to the next stay, or the end of the trip.
        let calendar = Calendar.current
        let next = trip.items.filter { $0.kind == .stay && $0.day > stay.day }.map(\.day).min()
        let end = next ?? calendar.startOfDay(for: trip.endDate)
        let nights = max(1, calendar.dateComponents([.day], from: stay.day, to: end).day ?? 1)

        return ExtraNight(stayID: stay.id, stayTitle: stay.title, nightly: (stay.cost / Double(nights)).rounded(), probability: probability)
    }

    /// Each person's share of that night, by the stay's own split — asked of a
    /// copy of the trip with the night added, exactly as the ledger would.
    private func extraNightShares(_ night: ExtraNight) -> [UUID: Double] {
        guard let stay = trip.items.first(where: { $0.id == night.stayID }) else { return [:] }
        var hypothetical = trip
        hypothetical.items.append(ItineraryItem(
            title: "Extra night · \(stay.title)",
            vendor: stay.vendor,
            kind: .stay,
            date: stay.date,
            cost: night.nightly,
            split: stay.split,
            participantIDs: stay.participantIDs,
            customShares: stay.split.isCustom ? stay.customShares.mapValues { $0 / max(stay.cost, 1) * night.nightly } : [:]
        ))
        return Dictionary(uniqueKeysWithValues: trip.travellers.map {
            ($0.id, hypothetical.cost(for: $0.id) - trip.cost(for: $0.id))
        })
    }

    // MARK: - Words

    private func dominantBasis(_ list: [WeatherHour.Basis]) -> WeatherHour.Basis? {
        guard !list.isEmpty else { return nil }
        if list.contains(.forecast) { return .forecast }
        let counts = Dictionary(grouping: list, by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    private func narrate(
        outcomes: [UUID: NodeOutcome],
        risk: RiskLevel,
        basis: WeatherHour.Basis?,
        extraNight: ExtraNight?,
        isEmpty: Bool
    ) -> (String, String) {
        guard !isEmpty else {
            return ("Nothing ahead to weather", "Every booking on this trip is behind it.")
        }

        let basisNote: String = switch basis {
        case .seasonal: " Beyond the forecast, so this runs on the same week last year."
        case .observed: " A replay of the weather that actually happened."
        default: ""
        }

        let ranked = outcomes.values.sorted { $0.pAffected > $1.pAffected }
        guard risk.isNotable, let top = ranked.first, let node = twin.node(top.id) else {
            return ("Weather looks kind to the plan", "No booking has more than a 15% chance of disruption.\(basisNote)")
        }

        let percent = Int((top.pAffected * 100).rounded())
        let headline: String
        if top.order > 1, let cause = top.causedBy.flatMap(twin.node) {
            headline = "\(node.item.title) could fall through — \(percent)% — because of \(cause.item.title)"
        } else {
            headline = "\(node.item.title) is \(percent)% likely to be disrupted"
        }

        var parts: [String] = []
        let others = ranked.dropFirst().filter { $0.risk.isNotable }.count
        if others > 0 { parts.append("\(others.pluralised("more booking")) at risk") }
        let knockOns = ranked.filter { $0.risk.isNotable && $0.order > 1 }.count
        if knockOns > 0 { parts.append("\(knockOns) through knock-on effects") }
        if let driver = top.drivers.first { parts.append("driven by \(driver.label.lowercased()) (\(driver.value))") }
        if let extraNight, extraNight.probability >= 0.1 {
            parts.append("\(Int((extraNight.probability * 100).rounded()))% chance of an extra night")
        }
        let detail = parts.isEmpty ? basisNote.trimmingCharacters(in: .whitespaces) : parts.joined(separator: " · ").capitalizedFirst + "." + basisNote
        return (headline, detail)
    }
}

// MARK: - Randomness

/// SplitMix64: small, fast, and seeded — so the same trip gives the same
/// answer on every redraw, and live and what-if share one random stream.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Standard normal, by Box–Muller.
    mutating func gaussian() -> Double {
        let u1 = max(Double.random(in: 0..<1, using: &self), 1e-12)
        let u2 = Double.random(in: 0..<1, using: &self)
        return sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
