//
//  RootTabView.swift
//  Equitrip
//

import Combine
import SwiftUI

/// The tabs the product actually needs.
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
/// - **Equi** is the assistant, kept apart from the per-trip group thread in
///   `TripChatView` on purpose — one is people talking to each other about a
///   trip, the other is one person asking a question and getting an answer.
///
/// There is deliberately no Expenses tab. A trip is the container: its plan,
/// its people and its money are three questions about one thing, and a global
/// ledger has to open by asking which trip you meant — a question you answered
/// by opening a trip. It lives inside the trip now, as `TripLedger`.
enum AppTab: Hashable {
    case home, itinerary, settle, equi
}

struct RootTabView: View {
    var userName: String?
    var onSignOut: () -> Void = {}

    @Environment(\.scenePhase) private var scenePhase

    @State private var selection: AppTab = .home
    /// How many times Equi has been opened this session. The value itself is
    /// meaningless — it's the *change* the tab watches, to replay its arrival.
    @State private var equiArrivals = 0
    /// Shared by the trip cards and the itinerary they push — see
    /// `tripZoomSource`. Owned here because it has to outlive both.
    @Namespace private var tripZoom
    @State private var store = TripStore()
    @State private var notifications = NotificationStore()
    /// The per-trip change history. Owned here rather than by the trip screen
    /// so entries recorded from Home, the Settle tab or a background
    /// confirmation land in the same trail the ledger reads.
    @State private var audit = AuditTrail()
    @State private var toasts = ToastCenter()
    /// Set when an `equitrip://join/CODE` link arrives from outside the app.
    @State private var pendingJoinCode: String?
    /// Bumped when something outside Home asks for the quick-add sheet — the
    /// Control Centre button, the Lock Screen control, a widget tap. Home owns
    /// the sheet (it owns the trip the expense lands on), so the root can only
    /// ask; a counter rather than a flag because two presses in a row are two
    /// requests, and a `Bool` that is already `true` is silently the second
    /// one going missing.
    @State private var quickAddRequests = 0
    /// Opened from a toast tap, or from the Home pending-action card — either
    /// way it has to work regardless of which tab is on screen, so it's
    /// presented from the root rather than from Home or Settle individually.
    @State private var incomingSettlement: Settlement?
    /// Payments read out of the mailbox, and the loop that reads them. Owned
    /// here rather than by Home because the itinerary shows the same queue,
    /// and because the sync has to survive a tab switch mid-read.
    @State private var detections = DetectedExpenseStore()
    @State private var gmailSync: GmailExpenseSync?

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView(
                    userName: userName,
                    quickAddRequests: quickAddRequests,
                    onSignOut: {
                        // The channel outlives the screens that opened it —
                        // see `startSettlementRealtime` — so it has to be
                        // told explicitly rather than trusting deinit to
                        // catch a socket an `async let` still has open.
                        store.stopSettlementRealtime()
                        onSignOut()
                    },
                    onOpenTrip: { trip in
                        // Hands off to the Itinerary tab's own stack rather
                        // than pushing a second copy of the timeline here.
                        store.open(trip)
                        selection = .itinerary
                    },
                    onShowAllTrips: {
                        store.itineraryPath = []
                        selection = .itinerary
                    },
                    onSettleUp: { selection = .settle },
                    onReviewSettlement: { incomingSettlement = $0 }
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
                SettleView()
            }

            // `role: .search` is what actually detaches a tab from the rest
            // of the bar — the same gap-and-circle treatment Apple TV gives
            // Search. Equi isn't a search feature, but it's the one tab that
            // deserves to read as "apart from the other four" rather than a
            // fifth peer among them, so it borrows the role for the layout.
            Tab(value: AppTab.equi, role: .search) {
                EquiAssistantView(arrival: equiArrivals, onOpenTrip: { trip in
                    store.open(trip)
                    selection = .itinerary
                })
            } label: {
                Label("Equi", image: "Equi")
            }
        }
        .tint(AppTheme.accent)
        // The tab bar shrinks out of the way as you read down a long ledger.
        .tabBarMinimizeBehavior(.onScrollDown)
        // Equi announces itself on every visit — see `EquiAssistantView`'s
        // `playEntrance`. Counted here rather than watched from inside the tab
        // because a `TabView` may keep a tab's view alive after you leave it,
        // and then `onAppear` only ever fires the once.
        .onChange(of: selection) { _, tab in
            if tab == .equi { equiArrivals += 1 }
        }
        .environment(\.tripStore, store)
        .environment(\.notificationStore, notifications)
        .environment(\.auditTrail, audit)
        .environment(\.toastCenter, toasts)
        .environment(\.tripZoomNamespace, tripZoom)
        .environment(\.detectedExpenses, detections)
        .environment(\.gmailSync, gmailSync)
        .overlay { ToastOverlay() }
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            guard AppSettings.shakeToAddExpense else { return }

            // Every shake that opens the sheet says so with a thump, timed
            // to the sheet arriving rather than to the shake itself — the
            // gesture is silent, the sheet sliding up is the thing that just
            // happened.
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            requestQuickAdd()

            guard !AppSettings.hasSeenShakeHint else { return }
            AppSettings.hasSeenShakeHint = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Lives in `GlobalOverlayWindow`, not a plain `.overlay` here —
            // the quick-add sheet this shake just opened would otherwise
            // cover it the instant it arrives, the way any `.sheet` covers
            // whatever presented it.
            GlassToastCenter.shared.show(.init(
                symbol: "iphone.gen3.radiowaves.left.and.right",
                tint: AppTheme.accent,
                title: "Shake for a quick expense",
                subtitle: "Shake your phone anytime to log one. Turn it off in Profile → Preferences.",
                duration: .seconds(5)
            ))
        }
        .sheet(item: $incomingSettlement) { settlement in
            if let trip = store.trip(settlement.tripID) {
                SettlementReviewSheet(trip: trip, settlement: settlement)
            }
        }
        .task {
            // The window scene exists by the time the root's own `.task`
            // runs, and this has to be up before anything tries to show a
            // global toast — including the shake hint, which can fire on
            // the very first gesture.
            GlobalOverlayWindow.install()

            // Set before the first sync, so a change made the moment the app
            // opens still reaches the rest of the trip.
            // Registered before anything is awaited: a control pressed while
            // the app is already on screen has nothing else to wake it.
            ControlRoutes.startListening()
            consumePendingControlRoute()

            store.notifier = notifications
            store.auditor = audit
            store.toaster = toasts
            WatchBridge.shared.attach(store)
            // A toast is a summary; tapping it should always land on the full
            // review — for a request that's yours to answer, and for a
            // response to a request you raised, which just wants you looking
            // at the same record either way.
            toasts.onTap = { toast in
                selection = .settle
                if let settlement = toast.settlement { incomingSettlement = settlement }
            }

            // Trips and notifications come from the server on every launch;
            // the settlements channel stays open for the rest of the session
            // so a confirmation lands the instant it happens, not on the next
            // pull-to-refresh.
            if gmailSync == nil { gmailSync = GmailExpenseSync(detections: detections) }

            async let trips: Void = store.sync()
            async let feed: Void = notifications.load()
            async let realtime: Void = store.startSettlementRealtime()
            _ = await (trips, feed, realtime)

            // After the trips land, not before: the sync needs to know whether
            // one is actually running, and asks the store to find out.
            gmailSync?.sync(for: liveTrip)
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back to the app is the moment worth re-reading: the
            // payment happened while the phone was in a pocket and the alert
            // arrived while it was locked. `sync` throttles itself, so this
            // costs nothing when nothing has changed.
            guard phase == .active else { return }
            // A control pressed from the Lock Screen or from Control Centre
            // over another app arrives here — the route was written before the
            // app came forward, so it is already waiting.
            consumePendingControlRoute()
            gmailSync?.sync(for: liveTrip)
        }
        .onChange(of: store.trips.count) { _, _ in
            gmailSync?.sync(for: liveTrip)
        }
        .onReceive(NotificationCenter.default.publisher(for: ControlRoutes.posted)) { _ in
            consumePendingControlRoute()
        }
        .onOpenURL { url in
            guard url.scheme == "equitrip" else { return }

            switch url.host {
            case "join":
                let code = Trip.normaliseCode(url.lastPathComponent)
                guard code.count >= 4 else { return }
                // Land on Trips first, so dismissing the join sheet leaves
                // them somewhere sensible rather than on whatever tab they
                // last used.
                selection = .itinerary
                pendingJoinCode = code

            // The balance widget's whole subject is the balance, and Settle
            // is the only screen that does anything about it.
            case "settle":
                selection = .settle

            case "trips":
                store.itineraryPath = []
                selection = .itinerary

            // `equitrip://trip/<uuid>` — the timeline widget, which is a
            // summary of exactly one trip's plan and should open that plan.
            case "trip":
                guard let id = UUID(uuidString: url.lastPathComponent),
                      let trip = store.trip(id) else { return }
                store.open(trip)
                selection = .itinerary

            case "add-expense":
                requestQuickAdd()

            case "equi":
                selection = .equi

            default:
                break
            }
        }
        .fullScreenCover(item: $pendingJoinCode) { code in
            JoinTripFlow(initialCode: code)
                .environment(\.tripStore, store)
                .environment(\.notificationStore, notifications)
        }
    }

    /// Acts on a route left behind by a control press, if there is one.
    ///
    /// `takePendingRoute` clears as it reads, so the several places that call
    /// this — launch, foreground, and the live Darwin post — can all fire for
    /// one press without opening the sheet three times.
    private func consumePendingControlRoute() {
        switch SharedStore.takePendingRoute() {
        case .addExpense: requestQuickAdd()
        case .settle: selection = .settle
        // Switching to the tab is the whole job: `equiArrivals` is bumped by
        // the selection change, so Equi replays its arrival the same way it
        // does for a tap on the tab bar.
        case .equi: selection = .equi
        case nil: break
        }
    }

    /// Quick add belongs to Home, because it belongs to a trip and Home is
    /// where the trip is chosen. The root switches tabs and asks.
    private func requestQuickAdd() {
        selection = .home
        quickAddRequests += 1
    }

    /// The one trip mail is read for. Nil is the normal state — most days
    /// nobody is on a trip — and it's what switches the whole feature off.
    private var liveTrip: Trip? {
        store.trips.first { $0.phase == .live }
    }
}

#Preview {
    RootTabView(userName: "Swastik Patil")
}
