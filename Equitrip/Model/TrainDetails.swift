//
//  TrainDetails.swift
//  Equitrip
//

import SwiftUI

// MARK: - Train tracking

/// What a PNR lookup adds to a train booking: the train, the stations, each
/// passenger's berth, whether the chart is out, and — once it's running — where
/// the train is. The PNR is the only hand-typed field; the rest is RailRadar's.
///
/// Kept separate from `FlightDetails` because the thing people check is
/// different: on a flight it's the gate, on an Indian train it's "is my
/// waitlisted seat confirmed yet, and which coach".
struct TrainDetails: Hashable, Codable {
    struct Station: Hashable, Codable {
        var code: String
        var name: String?
    }

    struct Passenger: Hashable, Codable {
        var number: Int
        var bookingStatus: String?
        var currentStatus: String?
        var coach: String?
        var berth: Int?
        var berthCode: String?

        enum Standing: String, Codable { case confirmed, rac, waitlisted, cancelled, unknown }
        var standing: Standing

        /// "B4 · 58 LB" when there's a seat, otherwise the status itself ("WL 12").
        var seatLabel: String {
            if let coach, !coach.isEmpty, let berth, berth > 0 {
                return [coach, "\(berth)", berthCode].compactMap { $0 }.joined(separator: " · ")
            }
            return currentStatus ?? bookingStatus ?? "—"
        }
    }

    /// Where the train is, as of the last live check. Nil until one has run.
    struct Live: Hashable, Codable {
        enum Status: String, Codable {
            case notStarted, running, completed, cancelled, unknown
        }
        var status: Status
        var delayMinutes: Int?
        var previousStation: Station?
        var nextStation: Station?
        /// 0…1 between the previous and next halt.
        var segmentProgress: Double?
        var speedKmh: Double?
        var updatedAt: Date?
    }

    var pnr: String
    var trainNumber: String?
    var trainName: String?
    var from: Station?
    var to: Station?
    var journeyDate: Date?
    var travelClass: String?
    var quota: String?
    var chartPrepared: Bool?
    var passengers: [Passenger]
    var live: Live?
    /// Nil until a lookup has actually run.
    var lastChecked: Date?

    var isResolved: Bool { lastChecked != nil }

    var displayName: String {
        (trainName?.capitalized).flatMap { $0.isEmpty ? nil : $0 } ?? "Train"
    }

    /// The worst standing across the group — one waitlisted person means the
    /// booking isn't settled yet, however many confirmed seats sit beside it.
    var overallStanding: Passenger.Standing {
        let order: [Passenger.Standing] = [.cancelled, .waitlisted, .rac, .unknown, .confirmed]
        return order.first { s in passengers.contains { $0.standing == s } } ?? .unknown
    }

    /// "1234 567 890" — how a PNR is read aloud and checked against an SMS.
    static func displayPNR(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count == 10 else { return digits }
        let a = digits.prefix(3), b = digits.dropFirst(3).prefix(3), c = digits.suffix(4)
        return "\(a) \(b) \(c)"
    }
}

extension TrainDetails.Passenger.Standing {
    var label: String {
        switch self {
        case .confirmed: "Confirmed"
        case .rac: "RAC"
        case .waitlisted: "Waitlisted"
        case .cancelled: "Cancelled"
        case .unknown: "Unknown"
        }
    }

    var tint: Color {
        switch self {
        case .confirmed: AppTheme.positive
        case .rac: Palette.amber
        case .waitlisted: Palette.amber
        case .cancelled: AppTheme.danger
        case .unknown: AppTheme.inkTertiary
        }
    }
}

extension TrainDetails.Live.Status {
    var label: String {
        switch self {
        case .notStarted: "Not started"
        case .running: "Running"
        case .completed: "Arrived"
        case .cancelled: "Cancelled"
        case .unknown: "Status unknown"
        }
    }

    var tint: Color {
        switch self {
        case .notStarted: AppTheme.inkSecondary
        case .running: Palette.teal
        case .completed: AppTheme.positive
        case .cancelled: AppTheme.danger
        case .unknown: AppTheme.inkTertiary
        }
    }
}
