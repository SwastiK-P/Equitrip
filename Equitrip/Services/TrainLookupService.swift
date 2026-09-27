//
//  TrainLookupService.swift
//  Equitrip
//

import Foundation
import Supabase

/// Turns a PNR into a train, berths and a live running status.
///
/// Backed by RailRadar through the `railradar` Supabase function, which holds
/// the key (a key in the binary can be read by anyone with the IPA). The
/// function passes RailRadar's `data` through; mapping it to `TrainDetails`
/// stays here so the wire format can change without a redeploy.
enum TrainLookupService {

    enum LookupError: LocalizedError {
        case invalidPNR
        case notFound
        case network
        case service(String)

        var errorDescription: String? {
            switch self {
            case .invalidPNR: "A PNR is the 10-digit number on your ticket or IRCTC SMS."
            case .notFound: "No booking found for that PNR. It may have expired after the journey."
            case .network: "Couldn't reach the train data service."
            case .service(let message): message
            }
        }
    }

    private static let function = "railradar"

    /// Looks up the PNR, then — when the journey is today or already under
    /// way — asks where the train is. A live failure never sinks the PNR.
    static func lookup(pnr raw: String, previous: TrainDetails? = nil) async throws -> TrainDetails {
        let pnr = raw.filter(\.isNumber)
        guard pnr.count == 10 else { throw LookupError.invalidPNR }
        if pnr == demoPNR { return demo() }

        let response: Envelope<PNRData> = try await mapped {
            try await AuthService.shared.client.functions.invoke(
                function, options: FunctionInvokeOptions(body: Request(action: "pnr", pnr: pnr))
            )
        }
        var details = response.data.asDetails(pnr: pnr)
        details.journeyDate = response.data.journey?.date.flatMap { SupabaseFormat.day.date(from: $0) }
        details.live = previous?.live

        if let number = details.trainNumber, let date = details.journeyDate, isLiveWindow(date) {
            details.live = (try? await live(train: number, date: date)) ?? details.live
        }
        details.lastChecked = Date()
        return details
    }

    /// RailRadar's documented example PNR. Answered here, without a network
    /// call, so the whole card — berths, chart, live strip — can be shown on a
    /// demo device with no function deployed and no quota spent.
    static let demoPNR = "1234567890"

    /// Gatimaan Express, New Delhi → Agra Cantt, running today and mid-way.
    private static func demo(now: Date = Date()) -> TrainDetails {
        TrainDetails(
            pnr: demoPNR,
            trainNumber: "12050",
            trainName: "GATIMAAN EXPRESS",
            from: .init(code: "NZM", name: "Hazrat Nizamuddin"),
            to: .init(code: "AGC", name: "Agra Cantt"),
            journeyDate: Calendar.current.startOfDay(for: now),
            travelClass: "CC",
            quota: "GN",
            chartPrepared: true,
            passengers: [
                .init(number: 1, bookingStatus: "CNF/C3/41/GN", currentStatus: "CNF", coach: "C3", berth: 41, berthCode: "WS", standing: .confirmed),
                .init(number: 2, bookingStatus: "WL/4/GN", currentStatus: "CNF", coach: "C3", berth: 42, berthCode: "MS", standing: .confirmed),
                .init(number: 3, bookingStatus: "WL/7/GN", currentStatus: "RAC 2", coach: nil, berth: nil, berthCode: nil, standing: .rac),
            ],
            live: .init(
                status: .running,
                delayMinutes: 8,
                previousStation: .init(code: "NZM", name: "Hazrat Nizamuddin"),
                nextStation: .init(code: "AGC", name: "Agra Cantt"),
                segmentProgress: 0.58,
                speedKmh: 142,
                updatedAt: now.addingTimeInterval(-120)
            ),
            lastChecked: now
        )
    }

    /// Where the train is right now. Separate so the detail screen can refresh
    /// position without re-reading the PNR.
    static func live(train: String, date: Date) async throws -> TrainDetails.Live {
        let request = Request(action: "live", train: train, date: SupabaseFormat.day.string(from: date))
        let response: Envelope<LiveData> = try await mapped {
            try await AuthService.shared.client.functions.invoke(function, options: FunctionInvokeOptions(body: request))
        }
        return response.data.asLive()
    }

    /// From the evening before departure until two days after — long trains
    /// run 40+ hours, and before that window there's nothing to show.
    static func isLiveWindow(_ journeyDate: Date, now: Date = Date()) -> Bool {
        let start = journeyDate.addingTimeInterval(-6 * 3600)
        let end = journeyDate.addingTimeInterval(3 * 86_400)
        return (start...end).contains(now)
    }

    /// Turns the function client's errors into ones worth showing.
    private static func mapped<T>(_ call: () async throws -> T) async throws -> T {
        do {
            return try await call()
        } catch let FunctionsError.httpError(code, data) {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message
            if code == 404 { throw LookupError.notFound }
            throw LookupError.service(message ?? "The train service refused that request.")
        } catch is DecodingError {
            throw LookupError.service("The train service sent something unexpected.")
        } catch {
            throw LookupError.network
        }
    }
}

// MARK: - Wire format

private nonisolated struct Request: Encodable {
    let action: String
    var pnr: String?
    var train: String?
    var date: String?
}

private nonisolated struct Envelope<T: Decodable>: Decodable { let data: T }
private nonisolated struct ErrorBody: Decodable {
    struct Inner: Decodable { let message: String }
    let error: Inner
}

private nonisolated struct StationRef: Decodable {
    let code: String?
    let name: String?

    var station: TrainDetails.Station? {
        guard let code, !code.isEmpty else { return nil }
        return .init(code: code, name: name)
    }
}

private nonisolated struct PNRData: Decodable {
    struct Train: Decodable {
        let number: String?
        let name: String?
        let source: StationRef?
        let destination: StationRef?
        let boardingPoint: StationRef?
        let reservationUpto: StationRef?
    }
    struct Journey: Decodable {
        let date: String?
        let `class`: String?
        let quota: String?
    }
    struct Charting: Decodable { let isPrepared: Bool? }
    struct Passenger: Decodable {
        let passengerNumber: Int?
        let bookingStatus: String?
        let currentStatus: String?
        let coach: String?
        let berthNumber: Int?
        let berthCode: String?
        let isConfirmed: Bool?
        let isRAC: Bool?
        let isWaitlisted: Bool?
        let isCancelled: Bool?
    }

    let train: Train?
    let journey: Journey?
    let charting: Charting?
    let passengers: [Passenger]?

    func asDetails(pnr: String) -> TrainDetails {
        TrainDetails(
            pnr: pnr,
            trainNumber: train?.number,
            trainName: train?.name,
            // Where *this* ticket gets on and off, not the train's termini.
            from: train?.boardingPoint?.station ?? train?.source?.station,
            to: train?.reservationUpto?.station ?? train?.destination?.station,
            journeyDate: nil,
            travelClass: journey?.class,
            quota: journey?.quota,
            chartPrepared: charting?.isPrepared,
            passengers: (passengers ?? []).enumerated().map { index, p in
                let standing: TrainDetails.Passenger.Standing =
                    p.isCancelled == true ? .cancelled
                    : p.isConfirmed == true ? .confirmed
                    : p.isRAC == true ? .rac
                    : p.isWaitlisted == true ? .waitlisted
                    : .unknown
                return .init(
                    number: p.passengerNumber ?? index + 1,
                    bookingStatus: p.bookingStatus,
                    currentStatus: p.currentStatus,
                    coach: p.coach,
                    berth: p.berthNumber,
                    berthCode: p.berthCode,
                    standing: standing
                )
            },
            live: nil,
            lastChecked: nil
        )
    }
}

private nonisolated struct LiveData: Decodable {
    struct Halt: Decodable {
        let stationCode: String?
        let stationName: String?
    }
    struct Location: Decodable {
        let segmentProgress: Double?
        let speedKmh: Double?
    }

    let status: String?
    let delayMinutes: Int?
    let lastUpdatedAt: String?
    let currentLocation: Location?
    let previousHalt: Halt?
    let nextHalt: Halt?

    func asLive() -> TrainDetails.Live {
        let mapped: TrainDetails.Live.Status = switch status?.lowercased() {
        case "running", "active": .running
        case "completed", "arrived", "reached": .completed
        case "cancelled", "canceled": .cancelled
        case "not_started", "notstarted", "scheduled", "yet_to_start": .notStarted
        default: .unknown
        }
        func station(_ halt: Halt?) -> TrainDetails.Station? {
            guard let code = halt?.stationCode, !code.isEmpty else { return nil }
            return .init(code: code, name: halt?.stationName)
        }
        return .init(
            status: mapped,
            delayMinutes: delayMinutes,
            previousStation: station(previousHalt),
            nextStation: station(nextHalt),
            segmentProgress: currentLocation?.segmentProgress,
            speedKmh: currentLocation?.speedKmh,
            updatedAt: lastUpdatedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
