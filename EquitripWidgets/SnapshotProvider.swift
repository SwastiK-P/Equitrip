//
//  SnapshotProvider.swift
//  EquitripWidgets
//

import WidgetKit

/// One timeline provider for every widget in the bundle.
///
/// There is nothing per-widget about the loading: they all read the same
/// published snapshot, and they all want to be refreshed for the same reason
/// (the app moved a number and asked for a reload). Splitting it per widget
/// would have produced three copies of the same eight lines with three
/// slightly different refresh policies.
struct SnapshotProvider: TimelineProvider {

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    /// The gallery preview. Always the sales-pitch snapshot rather than the
    /// real one — the widget being chosen out of a list of grey rectangles is
    /// the one moment where showing somebody else's plausible trip beats
    /// showing an honest "no trips yet".
    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : (SharedStore.loadSnapshot() ?? .empty)
        completion(SnapshotEntry(date: .now, snapshot: snapshot))
    }

    /// A single entry, reloaded on request rather than on a schedule.
    ///
    /// The figures only change when the app changes them, and the app calls
    /// `WidgetCenter.reloadAllTimelines()` the moment it does — so a timeline
    /// of future entries would be a list of guesses about a number that
    /// cannot drift on its own. The hourly `.after` is a backstop for the one
    /// thing that *does* move without the app: the day rolling over
    /// underneath "up next".
    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let snapshot = SharedStore.loadSnapshot() ?? .empty
        let entry = SnapshotEntry(date: .now, snapshot: snapshot)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: EquitripSnapshot
}

// MARK: - Per-trip timeline (the "Up next" widget)

/// Resolves `SelectTripIntent` against the published snapshot: a pinned trip
/// if one was chosen and it still exists, otherwise the same "whichever trip
/// is current" behaviour the widget always had.
struct TripTimelineProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> TripTimelineEntry {
        let snapshot = EquitripSnapshot.placeholder
        return TripTimelineEntry(date: .now, trip: snapshot.currentTrip, events: snapshot.upNext, hasTrips: true)
    }

    func snapshot(for configuration: SelectTripIntent, in context: Context) async -> TripTimelineEntry {
        let snapshot = context.isPreview ? .placeholder : (SharedStore.loadSnapshot() ?? .empty)
        return entry(for: configuration, snapshot: snapshot)
    }

    func timeline(for configuration: SelectTripIntent, in context: Context) async -> Timeline<TripTimelineEntry> {
        let snapshot = SharedStore.loadSnapshot() ?? .empty
        let entry = entry(for: configuration, snapshot: snapshot)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(next))
    }

    /// Picking the trip. A pinned trip that has since ended or been deleted
    /// falls back to "current" rather than freezing on the last trip it ever
    /// found — a widget still narrating a trip that's over is worse than one
    /// that quietly moves on to the next.
    private func entry(for configuration: SelectTripIntent, snapshot: EquitripSnapshot) -> TripTimelineEntry {
        if let pinnedID = configuration.trip?.id,
           let pinned = snapshot.allTrips.first(where: { $0.id == pinnedID }) {
            return TripTimelineEntry(
                date: .now,
                trip: pinned,
                events: snapshot.eventsByTrip[pinnedID] ?? [],
                hasTrips: snapshot.hasTrips
            )
        }

        return TripTimelineEntry(date: .now, trip: snapshot.currentTrip, events: snapshot.upNext, hasTrips: snapshot.hasTrips)
    }
}

struct TripTimelineEntry: TimelineEntry {
    let date: Date
    let trip: EquitripSnapshot.TripSummary?
    let events: [EquitripSnapshot.Event]
    let hasTrips: Bool
}
