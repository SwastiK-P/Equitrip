//
//  TwinLearning.swift
//  Equitrip
//

import Foundation
import Supabase

/// What's actually happened to bookings like this, in weather like this —
/// the counts the model's priors are pulled towards.
struct TwinCalibration: Hashable {
    struct Key: Hashable {
        let exposure: WeatherExposure
        let band: Int
    }

    var counts: [Key: (disrupted: Int, total: Int)] = [:]

    /// How many observations it takes to outweigh the prior. Low enough that
    /// a season of monsoon reports moves the model; high enough that one
    /// unlucky ferry doesn't.
    static let priorStrength = 12.0

    /// The prior, moved towards the observed rate by as much as the evidence warrants.
    func adjust(_ prior: Double, exposure: WeatherExposure, band: Int) -> Double {
        guard let cell = counts[Key(exposure: exposure, band: band)], cell.total > 0 else { return prior }
        let k = Self.priorStrength
        return (prior * k + Double(cell.disrupted)) / (k + Double(cell.total))
    }

    var observationCount: Int { counts.values.reduce(0) { $0 + $1.total } }

    static func == (lhs: TwinCalibration, rhs: TwinCalibration) -> Bool {
        lhs.counts.mapValues { [$0.disrupted, $0.total] } == rhs.counts.mapValues { [$0.disrupted, $0.total] }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(observationCount)
    }
}

/// The twin's learning loop: record what happened, pool it, calibrate on it.
///
/// Outcomes come from three places, none of which the twin invents:
///
/// - **Flight status** the airline reported through `FlightLookupService` — a
///   delayed or cancelled flight the twin had scored.
/// - **Booking changes** read out of the mail (`BookingChangeReader`) — a
///   cancellation or reschedule during weather the twin had scored.
/// - **Travellers**, answering "did the weather get this?" on an affected
///   booking.
///
/// Each becomes one anonymous row in `twin_observations` (exposure, weather
/// band, hit or not, city) and is kept locally too, so learning still happens
/// with the migration unapplied or the phone offline. `calibration` merges the
/// pooled counts with the local ones.
@MainActor
@Observable
final class TwinLearning {
    private(set) var calibration = TwinCalibration()
    private(set) var pooledCount = 0

    enum Source: String {
        case flightStatus = "flight_status"
        case bookingChange = "booking_change"
        case traveller
    }

    private struct LocalObservation: Codable {
        let exposure: WeatherExposure
        let band: Int
        let disrupted: Bool
    }

    private nonisolated struct Row: Decodable {
        let exposure: String
        let band: Int
        let disrupted: Int
        let total: Int
    }

    private nonisolated struct Insert: Encodable {
        let exposure: String
        let band: Int
        let disrupted: Bool
        let source: String
        let city: String?
    }

    private static let localKey = "twin.observations"
    private static let recordedKey = "twin.recordedOutcomes"

    private var local: [LocalObservation] = []
    private var pooled: [TwinCalibration.Key: (disrupted: Int, total: Int)] = [:]
    /// Booking ids (plus source) already recorded, so an outcome counts once.
    private var recorded: Set<String>

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.localKey),
           let list = try? JSONDecoder().decode([LocalObservation].self, from: data) {
            local = list
        }
        recorded = Set(UserDefaults.standard.stringArray(forKey: Self.recordedKey) ?? [])
        rebuild()
    }

    /// Pulls the pooled counts. Fails quietly: until `0022_weather_twin.sql`
    /// is applied the local counts are all there is, and that's fine.
    func load() async {
        do {
            let rows: [Row] = try await AuthService.shared.client
                .rpc("twin_calibration")
                .execute()
                .value
            var map: [TwinCalibration.Key: (disrupted: Int, total: Int)] = [:]
            for row in rows {
                guard let exposure = WeatherExposure(rawValue: row.exposure) else { continue }
                map[.init(exposure: exposure, band: row.band)] = (row.disrupted, row.total)
            }
            pooled = map
            pooledCount = rows.reduce(0) { $0 + $1.total }
            rebuild()
        } catch {
            // Keep whatever was there.
        }
    }

    /// Whether this outcome has already been counted.
    func hasRecorded(_ itemID: UUID, source: Source) -> Bool {
        recorded.contains("\(source.rawValue):\(itemID)")
    }

    /// One outcome. Written locally at once and pooled in the background.
    func record(itemID: UUID, exposure: WeatherExposure, band: Int, disrupted: Bool, source: Source, city: String?) {
        let key = "\(source.rawValue):\(itemID)"
        guard !recorded.contains(key) else { return }
        recorded.insert(key)
        UserDefaults.standard.set(Array(recorded), forKey: Self.recordedKey)

        local.append(LocalObservation(exposure: exposure, band: band, disrupted: disrupted))
        if let data = try? JSONEncoder().encode(local.suffix(500)) {
            UserDefaults.standard.set(data, forKey: Self.localKey)
        }
        rebuild()

        let row = Insert(
            exposure: exposure.rawValue,
            band: band,
            disrupted: disrupted,
            source: source.rawValue,
            city: city.map { String($0.prefix(80)) }
        )
        Task {
            _ = try? await AuthService.shared.client.from("twin_observations").insert(row).execute()
        }
    }

    /// Reads outcomes the app already knows about off a trip: flights whose
    /// status the airline has reported, for bookings the twin scored.
    func harvest(from trip: Trip, twin: TripTwin, bands: [UUID: Int], city: String?) {
        for node in twin.nodes where node.exposure == .air {
            guard let status = node.item.flight?.status, let band = bands[node.id] else { continue }
            let disrupted: Bool
            switch status {
            case .delayed: disrupted = (node.item.flight?.departureDelay ?? 60) >= 30
            case .cancelled: disrupted = true
            case .landed: disrupted = (node.item.flight?.departureDelay ?? 0) >= 45
            default: continue
            }
            record(itemID: node.id, exposure: .air, band: band, disrupted: disrupted, source: .flightStatus, city: city)
        }
    }

    private func rebuild() {
        var counts = pooled
        for observation in local {
            let key = TwinCalibration.Key(exposure: observation.exposure, band: observation.band)
            let cell = counts[key] ?? (0, 0)
            counts[key] = (cell.disrupted + (observation.disrupted ? 1 : 0), cell.total + 1)
        }
        calibration = TwinCalibration(counts: counts)
    }
}
