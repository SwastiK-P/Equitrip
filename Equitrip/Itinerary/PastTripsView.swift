//
//  PastTripsView.swift
//  Equitrip
//

import SwiftUI

/// Every trip that has ended, newest first, grouped by the year it ended.
///
/// Pushed from the "Wrapped up" row on the trip list, which keeps that list
/// about trips still ahead. Same place cards as the list, so a trip looks the
/// same wherever it's found; the menu leads with the recap, which is the
/// reason to come back to a finished trip.
struct PastTripsView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.pane) private var pane
    @Environment(\.dismiss) private var dismiss

    @State private var editing: Trip?
    @State private var inviting: Trip?
    @State private var deleting: Trip?
    @State private var recapping: Trip?

    private var years: [(year: Int, trips: [Trip])] {
        let past = store.trips.filter { $0.phase == .past }.sorted { $0.endDate > $1.endDate }
        let grouped = Dictionary(grouping: past) { Calendar.current.component(.year, from: $0.endDate) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    private var count: Int { years.reduce(0) { $0 + $1.trips.count } }

    var body: some View {
        ZStack {
            CanvasBackground()

            if count == 0 {
                empty
            } else {
                list
            }
        }
        .safeAreaBar(edge: .top) { header }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $recapping) { trip in
            TripRecapView(trip: trip)
        }
        .sheet(item: $editing) { trip in
            TripEditorSheet(
                trip: trip,
                onSave: { store.update($0) },
                onDelete: trip.youAreOrganiser ? { store.delete(trip.id) } : nil
            )
        }
        .sheet(item: $inviting) { trip in
            TripInviteSheet(trip: trip)
        }
        .confirmationDialog(
            deleting.map { "Delete \($0.title)?" } ?? "Delete trip?",
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete trip", role: .destructive) {
                if let trip = deleting {
                    store.delete(trip.id)
                    GlassToastCenter.shared.show(.init(
                        symbol: "trash",
                        tint: AppTheme.danger,
                        title: "Trip deleted",
                        subtitle: "\"\(trip.title)\" and everything on it is gone."
                    ))
                }
                deleting = nil
            }
            Button("Keep it", role: .cancel) { deleting = nil }
        } message: {
            Text("This removes it for everyone on the trip, along with every booking on it. It can't be undone.")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            CircleGlyphButton(symbol: "chevron.left", size: pane.scaled(38, regular: 42)) { dismiss() }
                .accessibilityLabel("Back to trips")

            VStack(alignment: .leading, spacing: 0) {
                Text("Wrapped up")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(count.pluralised("trip"))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 0)
        }
        .gutter()
        .pageWidth()
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: pane.spacing(26)) {
                ForEach(years, id: \.year) { group in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(String(group.year))
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(AppTheme.inkTertiary)
                            .padding(.leading, 6)

                        CardGrid(items: group.trips, columns: pane.tripColumns, spacing: pane.spacing(14)) { trip in
                            TripPlaceCard(
                                trip: trip,
                                onOpen: { store.itineraryPath.append(.trip(trip.id)) },
                                onEdit: { editing = trip },
                                onInvite: { inviting = trip },
                                onRecap: { recapping = trip },
                                onDelete: { deleting = trip }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, pane.isRegular ? pane.gutter : 16)
            .pageWidth()
            .padding(.top, 2)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "suitcase")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)
            Text("No finished trips")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}
