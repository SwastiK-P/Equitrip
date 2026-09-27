//
//  TwinAction.swift
//  Equitrip
//

import SwiftUI

/// Something the group could do about a booking the weather threatens.
///
/// The twin's job ends at "this is likely to go wrong, and here's why"; this
/// is the seam where the app starts helping with what to do about it. An
/// action is a *proposal* — built by `TwinActionPlanner` from a simulation,
/// queued by a person into Plan B, and carried out by whichever
/// `TwinActionExecutor` claims its kind. Nothing here edits a booking on its
/// own: every executor that changes the trip goes through the same editor
/// and store paths a person would, so the audit trail and RLS see an
/// ordinary edit by an ordinary member.
struct TwinAction: Identifiable, Hashable, Codable {

    enum Kind: String, Codable, CaseIterable, Hashable {
        /// Move it to a drier slot the forecast already knows about.
        case reschedule
        /// Swap an outdoor plan for something under a roof nearby.
        case swapIndoor
        /// Leave earlier for a transfer that feeds a flight or train.
        case addBuffer
        /// Look at other departures before the airline's options run out.
        case rebookTransport
        /// Hold one more night where the group is, in case the way home fails.
        case extendStay
        /// Read the booking's cancellation terms while there's still time.
        case checkRefund
        /// Put it in front of the group, in the trip chat.
        case discussWithGroup
        /// Keep watching, and say if it gets worse.
        case monitor

        var label: String {
            switch self {
            case .reschedule: "Move to a drier slot"
            case .swapIndoor: "Swap for something indoors"
            case .addBuffer: "Leave earlier"
            case .rebookTransport: "Check other departures"
            case .extendStay: "Hold an extra night"
            case .checkRefund: "Check refund terms"
            case .discussWithGroup: "Ask the group"
            case .monitor: "Watch closely"
            }
        }

        var symbol: String {
            switch self {
            case .reschedule: "calendar.badge.clock"
            case .swapIndoor: "building.2.fill"
            case .addBuffer: "clock.arrow.2.circlepath"
            case .rebookTransport: "arrow.triangle.swap"
            case .extendStay: "bed.double.fill"
            case .checkRefund: "arrow.uturn.backward.circle.fill"
            case .discussWithGroup: "bubble.left.and.bubble.right.fill"
            case .monitor: "bell.badge.fill"
            }
        }

        var tint: Color {
            switch self {
            case .reschedule, .addBuffer: AppTheme.accent
            case .swapIndoor: Palette.violet
            case .rebookTransport, .extendStay: Palette.blue
            case .checkRefund: Palette.amberDeep
            case .discussWithGroup: Palette.teal
            case .monitor: AppTheme.inkSecondary
            }
        }
    }

    enum Status: String, Codable, Hashable {
        /// Proposed by the planner, untouched.
        case suggested
        /// A person put it in Plan B.
        case queued
        /// An executor is carrying it out.
        case running
        case done
        case dismissed

        var label: String {
            switch self {
            case .suggested: "Suggested"
            case .queued: "In Plan B"
            case .running: "Working on it"
            case .done: "Done"
            case .dismissed: "Dismissed"
            }
        }
    }

    /// What an executor needs beyond the booking itself. Every figure here
    /// is read off the forecast or the booking; none is invented.
    struct Payload: Hashable, Codable {
        /// A slot the forecast rates drier, for `.reschedule`.
        var suggestedStart: Date?
        /// Its peak rain, next to the current slot's, so the card can compare.
        var suggestedRain: Double?
        var currentRain: Double?
        /// For `.addBuffer`.
        var bufferMinutes: Int?
        /// For `.extendStay`: the stay and its own nightly rate.
        var stayID: UUID?
        var nightly: Double?
        /// For `.discussWithGroup`: the words the chat composer opens with.
        var draft: String?
    }

    let kind: Kind
    let tripID: UUID
    let itemID: UUID
    var title: String
    var rationale: String
    var urgency: RiskLevel
    /// Act before this, or the action stops being useful (the booking starts,
    /// or a transfer would have to leave).
    var deadline: Date?
    var payload: Payload
    var status: Status
    var createdAt: Date

    /// Stable across simulations, so re-planning updates an action instead of
    /// duplicating it — and a dismissed one stays dismissed.
    var id: String { "\(kind.rawValue)|\(itemID)" }
}
