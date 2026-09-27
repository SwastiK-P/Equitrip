//
//  WeatherExposure.swift
//  Equitrip
//

import SwiftUI

/// How weather gets at a booking — the property the twin reasons about,
/// rather than the booking's category.
///
/// A snorkelling trip and a museum visit are both "activities"; one is
/// cancelled by a 25 km/h wind and the other doesn't notice a cyclone until
/// the roads to it close. So each booking is read once into an exposure, from
/// its category and the words in its title, and the model's weights hang off
/// that.
enum WeatherExposure: String, Codable, Hashable, CaseIterable {
    /// Open air: treks, sightseeing, beach time, a rooftop dinner.
    case outdoor
    /// On or in the water: boats, ferries, snorkelling, surfing.
    case marine
    /// Roads: transfers, taxis, self-drive.
    case road
    case rail
    case air
    /// Where people sleep: hit only by the extremes, and the end of most cascades.
    case shelter
    /// Under a roof: museums, spas, cooking classes, most restaurants.
    case indoor

    var label: String {
        switch self {
        case .outdoor: "Outdoors"
        case .marine: "On the water"
        case .road: "By road"
        case .rail: "By rail"
        case .air: "By air"
        case .shelter: "Stay"
        case .indoor: "Indoors"
        }
    }

    var symbol: String {
        switch self {
        case .outdoor: "sun.horizon.fill"
        case .marine: "water.waves"
        case .road: "road.lanes"
        case .rail: "tram.fill"
        case .air: "airplane"
        case .shelter: "house.fill"
        case .indoor: "building.2.fill"
        }
    }

    /// Whether this booking moves people from one place to another — the
    /// bookings whose delay can make others miss.
    var isTransport: Bool { [.road, .rail, .air, .marine].contains(self) }

    /// The booking's exposure, from what it is and what it's called.
    static func of(_ item: ItineraryItem) -> WeatherExposure {
        let words = "\(item.title) \(item.vendor)".lowercased()
        func has(_ list: [String]) -> Bool { list.contains { words.contains($0) } }

        let marine = ["boat", "cruise", "ferry", "snorkel", "scuba", "dive", "diving", "kayak", "raft",
                      "surf", "sail", "yacht", "dolphin", "parasail", "jet ski", "island hop", "backwater", "houseboat"]
        let indoor = ["museum", "gallery", "spa", "massage", "class", "workshop", "cinema", "theatre", "theater",
                      "show", "mall", "aquarium", "casino", "bowling", "escape room", "cooking", "palace interior",
                      "library", "planetarium"]
        let outdoor = ["trek", "hike", "beach", "fort", "safari", "sunset", "sunrise", "view point", "viewpoint",
                       "waterfall", "falls", "park", "garden", "tour", "walk", "market", "rooftop", "shack",
                       "paraglid", "zip", "camp", "bonfire", "festival", "temple", "church", "lake", "peak"]

        switch item.kind {
        case .flight: return .air
        case .train: return .rail
        case .drive: return has(["ferry", "boat"]) ? .marine : .road
        case .stay: return has(["houseboat", "tent", "camp"]) ? .outdoor : .shelter
        case .meal: return has(["beach", "shack", "rooftop", "cruise", "boat", "picnic", "barbecue", "bbq"]) ? .outdoor : .indoor
        case .activity, .other:
            if has(marine) { return .marine }
            if has(indoor) { return .indoor }
            if has(outdoor) || item.kind == .activity { return .outdoor }
            return .indoor
        }
    }

    /// How long the booking holds people in the weather, around its start.
    func window(for item: ItineraryItem) -> DateInterval {
        let calendar = Calendar.current
        guard let start = item.time else {
            // No time given: a stay is the evening and night, anything else the daytime.
            let day = calendar.startOfDay(for: item.date)
            switch self {
            case .shelter:
                return DateInterval(start: day.addingTimeInterval(16 * 3600), duration: 16 * 3600)
            default:
                return DateInterval(start: day.addingTimeInterval(9 * 3600), duration: 12 * 3600)
            }
        }
        switch self {
        case .air:
            // The weather that grounds a flight is at departure, and the road
            // to the airport is the two hours before it.
            return DateInterval(start: start.addingTimeInterval(-1800), duration: 2 * 3600)
        case .road, .rail: return DateInterval(start: start, duration: 2 * 3600)
        case .marine: return DateInterval(start: start, duration: 3 * 3600)
        case .outdoor: return DateInterval(start: start, duration: 3 * 3600)
        case .indoor: return DateInterval(start: start, duration: 2 * 3600)
        case .shelter: return DateInterval(start: start, duration: 14 * 3600)
        }
    }
}
