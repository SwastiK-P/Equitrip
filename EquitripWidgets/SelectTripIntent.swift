//
//  SelectTripIntent.swift
//  EquitripWidgets
//

import AppIntents
import WidgetKit

/// One trip, as the widget-gallery edit sheet can offer it.
///
/// A thin shadow of `EquitripSnapshot.TripSummary` — an `AppEntity` only
/// needs enough to display itself in the picker and to be looked back up by
/// id when the intent resolves, not the figures the widget draws with. Those
/// still come from the snapshot at render time.
struct TripEntity: AppEntity {
    let id: UUID
    let title: String
    let dateRange: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Trip"
    static let defaultQuery = TripEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(dateRange)")
    }
}

/// Looks trips up out of whatever the app last published — the same snapshot
/// the widget itself reads, so the picker never lists a trip the widget then
/// can't find.
struct TripEntityQuery: EntityQuery {
    func entities(for identifiers: [TripEntity.ID]) async throws -> [TripEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TripEntity] {
        all()
    }

    private func all() -> [TripEntity] {
        let snapshot = SharedStore.loadSnapshot() ?? .empty
        return snapshot.allTrips.map {
            TripEntity(id: $0.id, title: $0.title, dateRange: $0.dateRange)
        }
    }
}

/// The "Up next" widget's edit-sheet configuration: which trip to follow, or
/// none for the old behaviour of trailing whichever trip is current.
struct SelectTripIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose Trip"
    static let description = IntentDescription(
        "Pick a trip for this widget to follow, or leave it on Current Trip to always show the one under way."
    )

    /// Nil means "current trip" — the behaviour before this setting existed,
    /// and still the sensible default: most people widget-pin the app once
    /// and never open the edit sheet again.
    @Parameter(title: "Trip")
    var trip: TripEntity?
}
