//
//  WatchRootView.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// Balance, then the plan, then anything waiting on you — one vertical
/// page each, turned with the crown.
struct WatchRootView: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            content
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
        .alert(
            "Couldn't answer",
            isPresented: Binding(
                get: { store.failure != nil },
                set: { if !$0 { store.failure = nil } }
            ),
            actions: { Button("OK") { store.failure = nil } },
            message: { Text(store.failure ?? "") }
        )
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.snapshot {
            if snapshot.hasTrips {
                TabView {
                    BalancePage()
                    AgendaPage()
                    SettleRequestsPage()
                }
                .tabViewStyle(.verticalPage)
                .toolbar {
                    if snapshot.allTrips.count > 1 {
                        ToolbarItem(placement: .topBarLeading) { TripPicker() }
                    }
                }
            } else {
                WatchNotice(
                    symbol: "suitcase",
                    title: "No trips yet",
                    detail: "Sign in and create or join a trip on your iPhone — it shows up here."
                )
            }
        } else {
            WatchNotice(
                symbol: "iphone",
                title: "Open Equitrip on your iPhone",
                detail: "Your balance and plans arrive here once you're signed in."
            )
        }
    }
}

// MARK: - Trip picker

/// Pins the trip the Balance card and Up next narrate. "Current" follows
/// whichever trip the phone calls current, the way the widget does.
private struct TripPicker: View {
    @Environment(WatchStore.self) private var store
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            // Dark on the accent disc — the toolbar fills the button with
            // the app tint, and an accent glyph on it disappears.
            Image(systemName: "suitcase.fill")
                .foregroundStyle(Brand.ctaLabel)
        }
        .accessibilityLabel("Choose trip")
        .sheet(isPresented: $isPresented) {
            ScrollView {
                VStack(spacing: 6) {
                    followRow

                    ForEach(store.snapshot?.allTrips ?? []) { trip in
                        Button {
                            choose(trip.id)
                        } label: {
                            TripCoverRow(trip: trip, isSelected: store.selectedTripID == trip.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Trips")
        }
    }

    /// "Follow the current trip" — the default, and what un-pins. Worded as
    /// a behaviour rather than as another trip, with the trip it currently
    /// resolves to underneath so it's clear what choosing it will show.
    private var followRow: some View {
        Button {
            choose(nil)
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "location.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 30, height: 30)
                    .background(Brand.accent.opacity(0.2), in: .circle)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Current trip")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Brand.ink)
                    if let current = store.snapshot?.currentTrip {
                        Text(current.title)
                            .font(.caption2)
                            .foregroundStyle(Brand.inkSecondary)
                    }
                }
                .lineLimit(1)

                Spacer(minLength: 4)

                if store.selectedTripID == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.accent)
                }
            }
            .watchCard(padding: 10)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(store.selectedTripID == nil ? .isSelected : [])
    }

    private func choose(_ id: UUID?) {
        store.selectedTripID = id
        isPresented = false
    }
}

// MARK: - Trip cover row

/// A trip as its photograph, the way the phone's trip list shows one — the
/// picture is how people tell trips apart long before they read the name.
/// Dates under the name all the same: two trips to one place are common, and
/// two identical photos with identical titles would be a guess.
private struct TripCoverRow: View {
    let trip: EquitripSnapshot.TripSummary
    let isSelected: Bool

    @ScaledMetric(relativeTo: .headline) private var height: CGFloat = 76

    var body: some View {
        CoverImage(url: trip.coverURL, symbol: trip.symbol)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.2),
                        .init(color: .black.opacity(0.72), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(trip.title)
                        .font(.display(.headline))
                        .foregroundStyle(.white)
                    Text(trip.dateRange)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .lineLimit(1)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
                .padding(.horizontal, 10)
                .padding(.bottom, 7)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Brand.accent)
                        .padding(7)
                }
            }
            .clipShape(.rect(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Brand.accent : .clear, lineWidth: 2)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(trip.title), \(trip.dateRange)")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    WatchRootView().environment(WatchStore(preview: .placeholder))
}
