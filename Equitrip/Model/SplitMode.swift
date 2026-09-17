//
//  SplitMode.swift
//  Equitrip
//

import SwiftUI

// MARK: - Cost sharing

/// The models the brief calls for. Each one answers "whose cost is this?"
/// differently, which is the whole reason a group ledger is hard.
enum SplitMode: String, CaseIterable, Identifiable, Codable {
    case equal
    case participants
    /// Everyone named pays a figure somebody typed. The only mode where the
    /// shares aren't derived from the cost.
    case custom
    case organiser
    case individual

    var id: String { rawValue }

    /// Reads a stored value, including ones this app no longer offers.
    ///
    /// `room` was a sixth mode meaning "divided across each room's occupants",
    /// and it never did that — there is no concept of a room anywhere in the
    /// model, so `bearers(of:)` handled it identically to `participants`. It
    /// was a button that duplicated the button next to it. Rows written before
    /// it was dropped land on the mode it was actually behaving as, so nobody's
    /// existing arithmetic changes.
    static func decode(_ raw: String) -> SplitMode {
        if raw == "room" { return .participants }
        return SplitMode(rawValue: raw) ?? .equal
    }

    var label: String {
        switch self {
        case .equal: "Split equally"
        case .participants: "Only participants"
        case .custom: "Exact amounts"
        case .organiser: "Organiser pays"
        case .individual: "One person"
        }
    }

    /// Fits a tile; `label` is the full sentence for lists and summaries.
    var shortLabel: String {
        switch self {
        case .equal: "Equally"
        case .participants: "Participants"
        case .custom: "Exact"
        case .organiser: "Organiser"
        case .individual: "One person"
        }
    }

    var detail: String {
        switch self {
        case .equal: "Divided evenly across everyone on the trip, whether or not they're on this booking"
        case .participants: "Divided evenly, but only across the people named on this booking"
        case .custom: "You set what each person owes. The amounts have to add up to the cost"
        case .organiser: "Carried by whoever is organising the trip, not shared out"
        case .individual: "One named person carries the whole cost"
        }
    }

    var symbol: String {
        switch self {
        case .equal: "equal"
        case .participants: "person.2.fill"
        case .custom: "slider.horizontal.3"
        case .organiser: "star.fill"
        case .individual: "person.fill"
        }
    }

    /// Whether this mode wants exactly one person named, rather than a set.
    var isSinglePerson: Bool { self == .individual }

    /// Whether the shares are typed rather than computed.
    var isCustom: Bool { self == .custom }
}
