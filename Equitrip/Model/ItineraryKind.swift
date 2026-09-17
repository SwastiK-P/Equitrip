//
//  ItineraryKind.swift
//  Equitrip
//

import SwiftUI

// MARK: - Itinerary kinds

/// What a booking *is*, which decides its glyph, its colour on the timeline,
/// and the default way its cost gets shared.
enum ItineraryKind: String, CaseIterable, Identifiable, Codable {
    case flight, train, drive, stay, activity, meal, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flight: "Flight"
        case .train: "Train"
        case .drive: "Transfer"
        case .stay: "Stay"
        case .activity: "Activity"
        case .meal: "Food"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .flight: "airplane"
        case .train: "tram.fill"
        case .drive: "car.fill"
        case .stay: "bed.double.fill"
        case .activity: "figure.hiking"
        case .meal: "fork.knife"
        case .other: "mappin.and.ellipse"
        }
    }

    var tint: Color {
        switch self {
        case .flight: Palette.blue
        case .train: Palette.teal
        case .drive: Palette.indigo
        case .stay: Palette.violet
        case .activity: Palette.green
        case .meal: Palette.amber
        case .other: Palette.stone
        }
    }

    var defaultSplit: SplitMode {
        switch self {
        // A room is shared by whoever is in it, which is what "only
        // participants" already means — the old `.room` mode was the same rule
        // under a different name.
        case .stay: .participants
        case .activity: .participants
        default: .equal
        }
    }

    /// Whether the price moves when the headcount does.
    ///
    /// Only asked when somebody leaves mid-trip, and it's the question that
    /// decides whether their departure costs anybody else money. Four people
    /// paying for four train tickets pay less when one of them doesn't go;
    /// four people paying for one villa do not. Getting this backwards is how
    /// a group ends up quietly absorbing somebody's share without ever being
    /// told — see `DeparturePlan.adjustedItems`.
    ///
    /// Derived from the category rather than stored, for the same reason
    /// `defaultSplit` is: it's right often enough to be a good default and
    /// there's a visible number next to it when it isn't.
    var costBasis: CostBasis {
        switch self {
        // A room and a car are booked once, whoever ends up in them.
        case .stay, .drive: .fixed
        default: .perPerson
        }
    }
}

/// Whether a booking's price is per head or for the booking.
enum CostBasis: String, Codable, Hashable {
    case perPerson, fixed
}
