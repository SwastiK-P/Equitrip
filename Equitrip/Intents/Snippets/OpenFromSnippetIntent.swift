//
//  OpenFromSnippetIntent.swift
//  Equitrip
//

import AppIntents
import Foundation

/// The "Open" and "Review" buttons on a Siri card: the app, brought forward
/// on the thing the card was about.
///
/// One intent for every card rather than one per screen, because a snippet
/// button can only run an intent and these differ only in where they land.
/// Ids travel as strings — a snippet's buttons carry their intents' values
/// through the system, and a UUID isn't a type an intent parameter can hold.
/// Hidden from Shortcuts: out of a card, it's just a worse "Open Trip".
struct OpenFromSnippetIntent: AppIntent {

    static let title: LocalizedStringResource = "Open in Equitrip"
    static let isDiscoverable = false
    static var supportedModes: IntentModes { .foreground(.immediate) }

    @Parameter(title: "Place")
    var place: SnippetPlace

    @Parameter(title: "Trip")
    var tripID: String?

    @Parameter(title: "Item")
    var itemID: String?

    init() {}

    init(_ place: SnippetPlace, tripID: UUID? = nil, itemID: UUID? = nil) {
        self.place = place
        self.tripID = tripID?.uuidString
        self.itemID = itemID?.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let trip = tripID.flatMap(UUID.init(uuidString:))
        let item = itemID.flatMap(UUID.init(uuidString:))

        switch place {
        case .trip:
            if let trip { AppNavigator.shared.go(.trip(trip)) }
        case .booking:
            if let trip, let item { AppNavigator.shared.go(.booking(tripID: trip, itemID: item)) }
            else if let trip { AppNavigator.shared.go(.trip(trip)) }
        case .settle:
            AppNavigator.shared.go(.settle(tripID: trip, settlementID: item))
        }
        return .result()
    }
}

/// Where a card's button can land. Raw values are stored in the system's copy
/// of a snippet's buttons: append, never rename.
enum SnippetPlace: String, AppEnum {
    case trip
    case booking
    case settle

    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Place"
    nonisolated static let caseDisplayRepresentations: [SnippetPlace: DisplayRepresentation] = [
        .trip: "Trip",
        .booking: "Booking",
        .settle: "Settle"
    ]
}
