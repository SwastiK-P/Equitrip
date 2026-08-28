//
//  RootTabView.swift
//  Equitrip
//

import SwiftUI

/// The four tabs the product actually needs.
///
/// The problem statement has five moving parts — itinerary, participants,
/// expenses, payments, settlement — but they don't map to five tabs:
///
/// - **Home** is the answer to "where do I stand?" across every trip, plus the
///   feed of changes that moved the numbers. It's also where trips live, so
///   there's no separate Trips tab.
/// - **Itinerary** is the master plan. Participants are edited per booking
///   here, which is where the question is actually asked ("who's on this?"),
///   so there's no standalone People tab either.
/// - **Settle** is the payoff — who owes whom, minimised, and the payment
///   record. It's the one screen a participant opens without wanting to see a
///   trip at all, which is why it's the only money screen still up here.
///
/// There is deliberately no Expenses tab. A trip is the container: its plan,
/// its people and its money are three questions about one thing, and a global
/// ledger has to open by asking which trip you meant — a question you answered
/// by opening a trip. It lives inside the trip now, as `TripLedger`.
enum AppTab: Hashable {
    case home, itinerary, settle
}

struct RootTabView: View {
    var userName: String?
    var onSignOut: () -> Void = {}

    @State private var selection: AppTab = .home
    /// Shared by the trip cards and the itinerary they push — see
    /// `tripZoomSource`. Owned here because it has to outlive both.
    @Namespace private var tripZoom
    @State private var store = TripStore()
    @State private var notifications = NotificationStore()
    /// Set when an `equitrip://join/CODE` link arrives from outside the app.
    @State private var pendingJoinCode: String?

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView(
                    userName: userName,
                    onSignOut: onSignOut,
                    onOpenTrip: { trip in
                        // Hands off to the Itinerary tab's own stack rather
                        // than pushing a second copy of the timeline here.
                        store.open(trip)
                        selection = .itinerary
                    },
                    onShowAllTrips: {
                        store.itineraryPath = []
                        selection = .itinerary
                    }
                )
            }

            Tab("Itinerary", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath.fill", value: AppTab.itinerary) {
                NavigationStack(path: $store.itineraryPath) {
                    TripListView()
                        .navigationDestination(for: UUID.self) { tripID in
                            TripItineraryView(tripID: tripID)
                                .tripZoomDestination(tripID, in: tripZoom)
                        }
                }
            }

            Tab("Settle", systemImage: "arrow.left.arrow.right", value: AppTab.settle) {
                ComingSoonTab(
                    title: "Settle",
                    subtitle: "Who pays whom, in the fewest moves.",
                    symbol: "arrow.left.arrow.right",
                    tint: Palette.violet,
                    points: [
                        "Balances minimised to the fewest transfers",
                        "Mark a payment, the other side confirms it",
                        "A settled trip stays auditable afterwards"
                    ]
                )
            }
        }
        .tint(AppTheme.accent)
        // The tab bar shrinks out of the way as you read down a long ledger.
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.tripStore, store)
        .environment(\.notificationStore, notifications)
        .environment(\.tripZoomNamespace, tripZoom)
        .task {
            // Set before the first sync, so a change made the moment the app
            // opens still reaches the rest of the trip.
            store.notifier = notifications

            // Both feeds come from the server now, and neither blocks the
            // other — an empty notification list shouldn't hold up the trips.
            async let trips: Void = store.sync()
            async let feed: Void = notifications.load()
            _ = await (trips, feed)
        }
        .onOpenURL { url in
            guard url.scheme == "equitrip", url.host == "join" else { return }
            let code = Trip.normaliseCode(url.lastPathComponent)
            guard code.count >= 4 else { return }
            // Land on Trips first, so dismissing the join sheet leaves them
            // somewhere sensible rather than on whatever tab they last used.
            selection = .itinerary
            pendingJoinCode = code
        }
        .fullScreenCover(item: $pendingJoinCode) { code in
            JoinTripFlow(initialCode: code)
                .environment(\.tripStore, store)
                .environment(\.notificationStore, notifications)
        }
    }
}

#Preview {
    RootTabView(userName: "Swastik Patil")
}
