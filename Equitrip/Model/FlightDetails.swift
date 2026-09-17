//
//  FlightDetails.swift
//  Equitrip
//

import SwiftUI

// MARK: - Flight tracking

/// What live lookup adds on top of a manually entered flight: the route,
/// scheduled times as the airline states them, and whether it's running to
/// plan. The flight number is the only field that's ever hand-typed —
/// everything else here comes from a lookup, boarding-pass scan included.
struct FlightDetails: Hashable, Codable {
    enum Status: String, Codable {
        case scheduled, active, landed, delayed, cancelled, unknown

        var label: String {
            switch self {
            case .scheduled: "Scheduled"
            case .active: "In the air"
            case .landed: "Landed"
            case .delayed: "Delayed"
            case .cancelled: "Cancelled"
            case .unknown: "Status unknown"
            }
        }

        var tint: Color {
            switch self {
            case .scheduled: AppTheme.inkSecondary
            case .active: Palette.blue
            case .landed: AppTheme.positive
            case .delayed: Palette.amber
            case .cancelled: AppTheme.danger
            case .unknown: AppTheme.inkTertiary
            }
        }
    }

    /// As entered or scanned, e.g. "6E 5312". Kept exactly as typed so it
    /// still displays sensibly even when a lookup never resolves it.
    var number: String
    var airlineName: String?

    var departureAirport: String?
    /// Full airport name, which is what people actually recognise — "JFK"
    /// alone means nothing to most of a group.
    var departureAirportName: String?
    var departureCity: String?
    var departureTerminal: String?
    var departureGate: String?

    var arrivalAirport: String?
    var arrivalAirportName: String?
    var arrivalCity: String?
    var arrivalTerminal: String?

    var scheduledDeparture: Date?
    var scheduledArrival: Date?
    /// Minutes late at the gate, when the airline admits to any.
    var departureDelay: Int?

    var status: Status?
    /// Nil until a lookup has actually run — distinguishes "haven't checked"
    /// from "checked and the airline gave nothing back".
    var lastChecked: Date?

    var isResolved: Bool { lastChecked != nil }

    /// The single line a boarding-pass-style card leads with. Falls back
    /// through the identifiers we actually have rather than showing "—".
    var displayAirline: String {
        airlineName ?? "Flight"
    }

    /// Countdown to the gate, but only while it's still ahead and close
    /// enough to matter — "departs in 84 days" is noise, not information.
    func departsIn(from now: Date = Date()) -> String? {
        guard let scheduledDeparture else { return nil }
        let seconds = scheduledDeparture.timeIntervalSince(now)
        guard seconds > 0, seconds < 60 * 60 * 48 else { return nil }

        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
