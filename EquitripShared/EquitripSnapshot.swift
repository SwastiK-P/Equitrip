//
//  EquitripSnapshot.swift
//  Equitrip
//

import Foundation

/// What the widgets are allowed to know.
///
/// The app's own numbers come from Supabase, behind a session the widget
/// process has no access to — a widget cannot sign in, and asking it to would
/// mean a network round trip on every timeline refresh for a figure that is
/// already sitting in memory a few hundred milliseconds after launch. So the
/// app publishes a flattened copy into the shared container each time the
/// ledger moves, and the widget reads that.
///
/// Deliberately a *snapshot* and not a mirror of the model: no travellers, no
/// bookings, no split rules, nothing the widget would have to re-derive. Every
/// figure arrives both as a number (so a bar can be drawn from it) and as the
/// string the app already formatted (so the widget never invents a second,
/// subtly different currency formatter — the app's `Money` stays the one place
/// that decides what ₹1,240 looks like).
nonisolated struct EquitripSnapshot: Codable, Equatable {

    // MARK: Position

    /// When the app last wrote this. Shown as a relative age once it's stale
    /// enough to matter, because a widget quietly showing yesterday's balance
    /// is worse than one admitting it.
    var generatedAt: Date

    /// Currency of the portfolio figures. Mixed-currency groups get the most
    /// common code — the same compromise `TripStore.primaryCurrency` makes.
    var currencyCode: String

    var owedToYou: Double
    var youOwe: Double
    var owedToYouLabel: String
    var youOweLabel: String

    /// The headline, pre-signed: `+₹1,240`, `−₹380`, or `Settled`.
    var netLabel: String
    /// The same figure with a thousand shortened to `1.2k`, for the circular
    /// lock-screen slot where the full string has nowhere to go.
    var netCompactLabel: String
    /// "you get back" / "you owe" / "all square".
    var netCaption: String
    /// "You're ahead across 2 active trips" — the fuller sentence, for the
    /// medium sizes that have a line to spare.
    var scopeCaption: String

    var activeTripCount: Int

    /// The trip everything above is scoped to, when the app is showing one
    /// trip rather than the portfolio. Nil means these are portfolio figures.
    var scopeTitle: String?
    var scopeTripID: UUID?

    // MARK: Plan

    /// The trip a "what's next" widget narrates: the one under way, or the
    /// next one to start.
    var currentTrip: TripSummary?

    /// The next few things happening, across that trip. Ordered.
    var upNext: [Event]

    /// Every trip a widget could be pointed at — not just `currentTrip`.
    /// Populated so the "Up next" widget's edit sheet can offer a real list
    /// of trips to pin to, instead of only ever following whichever one is
    /// live or next.
    var allTrips: [TripSummary] = []

    /// `upNext`, but for every trip in `allTrips`, keyed by trip id. Lets the
    /// widget show a *pinned* trip's own agenda rather than always falling
    /// back to whichever trip is current.
    var eventsByTrip: [UUID: [Event]] = [:]

    // MARK: Settle

    /// "Priya says she paid you ₹800" — every pending settlement across every
    /// trip where you're the one being asked to agree, newest first. The same
    /// list as `TripStore.settlementsAwaitingYou`, flattened.
    ///
    /// Optional, like every field added after the first release: the watch and
    /// the phone update on their own schedules, and synthesized `Codable`
    /// treats a missing non-optional key as a failed decode — which would turn
    /// one side's older build into a blank screen on the other.
    var settleRequests: [SettleRequest]?

    // MARK: State

    /// False before the first sign-in, or for an account on no trips. The
    /// widgets say something useful in that case rather than drawing a
    /// confident `₹0`.
    var hasTrips: Bool

    /// Whether the money side means anything yet — the same test
    /// `Trip.showsBalance` makes, rolled up. Nothing has been paid for on a
    /// trip that hasn't started, and "Settled · all square" is a lie there.
    var balanceIsMeaningful: Bool

    var net: Double { owedToYou - youOwe }

    /// Owed-to-you as a fraction of everything outstanding. `0.5` when there
    /// is nothing outstanding at all, so the split bar sits centred rather
    /// than slamming to one end.
    var owedFraction: Double {
        let total = owedToYou + youOwe
        return total > 0 ? owedToYou / total : 0.5
    }

    // MARK: Nested

    struct TripSummary: Codable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var destination: String
        /// "Day 3 of 6", "4 booked", "9 bookings" — whatever the trip's own
        /// phase makes true, already worded.
        var progressLabel: String
        var progress: Double
        var dateRange: String
        var phase: Phase
        /// Your position on this trip alone, pre-signed and formatted.
        var netLabel: String
        var netCaption: String
        var net: Double
        /// `Trip.showsBalance`, carried over rather than re-derived: a widget
        /// has no booking list to check `paidByID` against, only the figures
        /// already rolled up here. False means `netLabel` would be a lie
        /// ("Settled" before anyone's paid for anything) — show
        /// `yourShareLabel` instead. Optional for the same cross-build reason
        /// as `settleRequests`; nil keeps the old behaviour of showing `net`.
        var showsBalance: Bool?

        // For the watch's trip card, which draws the same one-cell-per-day
        // progress track as Home and needs the days to count and to number.
        var startDate: Date?
        var dayCount: Int?
        var travellerCount: Int?
        /// What the trip will cost you, for before it starts — when there is
        /// no balance yet and "Settled" would be a lie.
        var yourShareLabel: String?
        /// `TripTitleStyle.rawValue` — the typeface the organiser picked for
        /// this trip's name, so the watch sets it the way the phone does
        /// rather than in its own serif. Nil reads as `.classic`.
        var titleStyle: String?
        /// "1 booking" / "9 bookings", already pluralised by the phone.
        var bookingLabel: String?
        /// Everything the trip is projected to cost, all travellers together —
        /// the third figure in Home's card subtitle.
        var projectedLabel: String?

        /// The trip's cover photo, the smallest size the phone has. The watch
        /// fetches and downsizes it itself — an image is far too heavy for
        /// the application context, and a URL is the whole of what it needs.
        var coverURL: URL?
        /// The trip's SF Symbol, for the cover's place when there's no photo.
        var symbol: String?

        enum Phase: String, Codable { case upcoming, live, past }
    }

    /// One booking, reduced to what a row can draw.
    struct Event: Codable, Equatable, Identifiable {
        var id: UUID
        var title: String
        var vendor: String?
        /// SF Symbol name, already resolved through the item's suggestion.
        var symbol: String
        /// `ItineraryKind.rawValue`, so the widget can pick the rail colour
        /// without the app shipping a `Color` through JSON.
        var kind: String
        var date: Date
        /// `("9:40", "AM")`, or nil for an all-day item.
        var clockValue: String?
        var clockMeridiem: String?
        /// What it costs, when it costs anything.
        var costLabel: String?
        /// What it costs *you*, which is the figure this app exists to show.
        var shareLabel: String?
        var isToday: Bool

        // Flight specifics, for the watch's booking detail. Nil on anything
        // that isn't a flight, and on a flight nobody has looked up yet.
        var flightNumber: String?
        /// `"BOM → GOI"`.
        var routeLabel: String?
        var terminal: String?
        var gate: String?

        // The watch's agenda row: a figure short enough to sit at the end of
        // a line, the share on its own without the widget's " you" suffix,
        // and one line of what makes this booking this booking.
        /// `₹32k`.
        var costCompactLabel: String?
        /// `₹533`.
        var shareAmountLabel: String?
        /// `BOM → BAH`, `3 of us`, or the vendor.
        var detail: String?

        // The watch's booking detail: the phone's detail sheet with the
        // editing, the receipt and the per-person working left out. Optional
        // like every field added after the first release.
        /// `ItineraryKind.label` — "Flight", "Stay".
        var kindLabel: String?
        /// Whoever paid; nil while nobody has.
        var paidBy: Person?
        /// "UPI", "Cash" — nil when the payer didn't say.
        var paymentMethodLabel: String?
        /// `SplitMode.label` and `.symbol` — "Split equally".
        var splitLabel: String?
        var splitSymbol: String?
        /// "₹500 each", only under an equal split, where every share is the
        /// same and one figure is the whole of the working.
        var eachLabel: String?
        /// Everyone the cost lands on, you first.
        var participants: [Person]?
        var isDisputed: Bool?

        // A resolved flight, as the phone's ticket card lays it out.
        var airline: String?
        var departureCity: String?
        var arrivalCity: String?
        /// `6:30 AM`, formatted on the phone like its ticket card.
        var departureTimeLabel: String?
        var arrivalTimeLabel: String?
        /// `FlightDetails.Status.label` — "Delayed", "In the air".
        var flightStatus: String?
    }

    /// A traveller as a face — what the phone's `TravellerAvatar` draws from.
    struct Person: Codable, Equatable {
        /// "You" for the signed-in traveller.
        var name: String
        /// `Traveller.artwork(for:)`, already resolved — an asset name the
        /// watch's catalogue holds a small copy of.
        var avatar: String
        /// A photograph they uploaded, which wins over the artwork.
        var photoURL: URL?
    }

    /// One incoming "I paid you", reduced to what a row can draw and the ids
    /// the phone needs to act on an answer.
    struct SettleRequest: Codable, Equatable, Identifiable {
        var id: UUID
        var tripID: UUID
        var tripTitle: String
        var fromName: String
        /// Formatted by the app, like every other figure here.
        var amountLabel: String
        var methodLabel: String
        var methodSymbol: String
        var note: String
        var createdAt: Date
    }

    // MARK: Empty

    /// What the widgets draw before the app has ever published anything —
    /// on a fresh install, or in the gallery preview.
    static let placeholder: EquitripSnapshot = {
        let goa = TripSummary(
            id: UUID(),
            title: "Goa Reset",
            destination: "Goa, India",
            progressLabel: "Day 3 of 6",
            progress: 0.5,
            dateRange: "12–17 Mar",
            phase: .live,
            netLabel: "+₹2,140",
            netCaption: "you get back",
            net: 2_140,
            showsBalance: true,
            startDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            dayCount: 6,
            travellerCount: 4,
            yourShareLabel: "₹18,400",
            titleStyle: TripTitleStyle.airy.rawValue,
            bookingLabel: "9 bookings",
            projectedLabel: "₹73,600",
            symbol: "beach.umbrella.fill"
        )

        // Not yet under way — nobody's paid for anything, so the figure
        // worth showing is what it'll cost, not a "Settled" that isn't true.
        let manali = TripSummary(
            id: UUID(),
            title: "Manali Loop",
            destination: "Manali, India",
            progressLabel: "In 3 weeks",
            progress: 0,
            dateRange: "2–8 Apr",
            phase: .upcoming,
            netLabel: "Settled",
            netCaption: "all square",
            net: 0,
            showsBalance: false,
            startDate: Calendar.current.date(byAdding: .day, value: 21, to: .now),
            dayCount: 7,
            travellerCount: 5,
            yourShareLabel: "₹9,600",
            titleStyle: TripTitleStyle.classic.rawValue,
            bookingLabel: "4 bookings",
            projectedLabel: "₹48,000",
            symbol: "mountain.2.fill"
        )

        let kerala = TripSummary(
            id: UUID(),
            title: "Kerala Backwaters",
            destination: "Alleppey, India",
            progressLabel: "In 2 months",
            progress: 0,
            dateRange: "14–19 May",
            phase: .upcoming,
            netLabel: "Settled",
            netCaption: "all square",
            net: 0,
            showsBalance: false,
            startDate: Calendar.current.date(byAdding: .day, value: 60, to: .now),
            dayCount: 6,
            travellerCount: 3,
            yourShareLabel: "₹14,200",
            titleStyle: TripTitleStyle.poster.rawValue,
            bookingLabel: "1 booking",
            projectedLabel: "₹42,600",
            symbol: "sailboat.fill"
        )

        return EquitripSnapshot(
            generatedAt: .now,
            currencyCode: "INR",
            owedToYou: 4_820,
            youOwe: 1_640,
            owedToYouLabel: "₹4,820",
            youOweLabel: "₹1,640",
            netLabel: "+₹3,180",
            netCompactLabel: "+₹3.2k",
            netCaption: "you get back",
            scopeCaption: "You're ahead across 2 active trips",
            activeTripCount: 2,
            scopeTitle: nil,
            scopeTripID: nil,
            currentTrip: goa,
            upNext: [
                Event(id: UUID(), title: "Sunset kayak", vendor: "Palolem Beach",
                      symbol: "figure.hiking", kind: "activity", date: .now,
                      clockValue: "4:30", clockMeridiem: "PM",
                      costLabel: "₹3,200", shareLabel: "₹800 each", isToday: true,
                      costCompactLabel: "₹3.2k", shareAmountLabel: "₹800", detail: "Palolem Beach",
                      kindLabel: "Activity", paidBy: Person(name: "Priya", avatar: "Avatar04"), paymentMethodLabel: "UPI",
                      splitLabel: "Split equally", splitSymbol: "equal", eachLabel: "₹800 each",
                      participants: [Person(name: "You", avatar: "Avatar01"), Person(name: "Priya", avatar: "Avatar04"),
                                     Person(name: "Rohan", avatar: "Avatar07"), Person(name: "Ananya", avatar: "Avatar11")],
                      isDisputed: false),
                Event(id: UUID(), title: "Dinner at Gunpowder", vendor: "Assagao",
                      symbol: "fork.knife", kind: "meal", date: .now,
                      clockValue: "8:00", clockMeridiem: "PM",
                      costLabel: "₹4,600", shareLabel: "₹1,150 each", isToday: true,
                      costCompactLabel: "₹4.6k", shareAmountLabel: "₹1,150", detail: "3 of us",
                      kindLabel: "Food", splitLabel: "Only participants", splitSymbol: "person.2.fill",
                      participants: [Person(name: "You", avatar: "Avatar01"), Person(name: "Priya", avatar: "Avatar04"),
                                     Person(name: "Rohan", avatar: "Avatar07")],
                      isDisputed: false),
                Event(id: UUID(), title: "Check out", vendor: "Villa Kalinga",
                      symbol: "bed.double.fill", kind: "stay", date: .now,
                      clockValue: "11:00", clockMeridiem: "AM",
                      costLabel: nil, shareLabel: nil, isToday: false,
                      detail: "Villa Kalinga")
            ],
            allTrips: [goa, manali, kerala],
            settleRequests: [
                SettleRequest(id: UUID(), tripID: goa.id, tripTitle: "Goa Reset",
                              fromName: "Priya", amountLabel: "₹800",
                              methodLabel: "UPI", methodSymbol: "indianrupeesign.circle",
                              note: "Kayak share", createdAt: .now),
                SettleRequest(id: UUID(), tripID: goa.id, tripTitle: "Goa Reset",
                              fromName: "Rohan", amountLabel: "₹1,150",
                              methodLabel: "Cash", methodSymbol: "banknote",
                              note: "Dinner", createdAt: .now.addingTimeInterval(-3_600)),
                SettleRequest(id: UUID(), tripID: goa.id, tripTitle: "Goa Reset",
                              fromName: "Ananya", amountLabel: "₹2,400",
                              methodLabel: "Bank transfer", methodSymbol: "building.columns",
                              note: "Villa deposit", createdAt: .now.addingTimeInterval(-7_200))
            ],
            hasTrips: true,
            balanceIsMeaningful: true
        )
    }()

    /// A signed-in account with nothing on it. Distinct from `placeholder`:
    /// that one is a sales pitch, this is a real, empty state.
    static let empty = EquitripSnapshot(
        generatedAt: .now,
        currencyCode: "INR",
        owedToYou: 0,
        youOwe: 0,
        owedToYouLabel: "₹0",
        youOweLabel: "₹0",
        netLabel: "Settled",
        netCompactLabel: "—",
        netCaption: "all square",
        scopeCaption: "No trips yet",
        activeTripCount: 0,
        scopeTitle: nil,
        scopeTripID: nil,
        currentTrip: nil,
        upNext: [],
        hasTrips: false,
        balanceIsMeaningful: false
    )
}

// MARK: - Shared container

/// The one address the app writes to and the widgets read from.
///
/// A JSON blob in the group's `UserDefaults` rather than a file: it is a few
/// hundred bytes, it is replaced wholesale every time, and `UserDefaults`
/// already handles the cross-process coordination that a file would need
/// arranging by hand.
enum SharedStore {

    /// Must match the App Groups capability on both targets. Changing it
    /// silently detaches every installed widget from the app, so it lives
    /// here as one constant rather than being spelled out at each end.
    static let appGroup = "group.com.swastik.Equitrip"

    private static let snapshotKey = "widget.snapshot"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    // MARK: Snapshot

    static func save(_ snapshot: EquitripSnapshot) {
        guard let data = try? JSONEncoder.snapshot.encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    /// What the widget draws. Falls back to the empty state rather than to
    /// the sales-pitch placeholder — an account whose app has never published
    /// is much more likely to be signed out than to be on a trip.
    static func loadSnapshot() -> EquitripSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder.snapshot.decode(EquitripSnapshot.self, from: data)
    }

    // MARK: Routing

    /// Where a control or widget press wants the app to land.
    ///
    /// A widget's own `widgetURL`/`Link` still travels as a URL — the system
    /// delivers those to `onOpenURL` reliably. A *control* is different: a
    /// `ControlWidgetButton` runs its intent in the widget extension, and an
    /// intent that both sets `openAppWhenRun` and returns an `OpensIntent`
    /// asks the system for two conflicting things at once, which is why the
    /// press produced nothing at all. So a control press leaves the route in
    /// this container and lets `openAppWhenRun` do the opening.
    ///
    /// The pairing matters. The stamp is read on launch and on every return
    /// to the foreground, which covers a cold launch and an unlock; the
    /// Darwin notification covers the case a stamp alone cannot — Control
    /// Centre opens *over* a running app without ever taking it out of the
    /// foreground, so pressing there brings forward an app that never left
    /// and no "became active" moment ever arrives.
    enum Route: String {
        case addExpense = "add-expense"
        case settle
        case equi

        var url: URL { URL(string: "equitrip://\(rawValue)")! }
    }

    private static let pendingRouteKey = "widget.pendingRoute"
    private static let pendingRouteStampKey = "widget.pendingRouteStamp"

    /// Broadcast across the process boundary so a foreground app hears a
    /// control press immediately. Darwin notifications carry no payload —
    /// the route itself is read back out of the defaults.
    public static let routePostedNotification = "com.swastik.Equitrip.routePosted"

    /// Called from the extension. The stamp is what makes a second press of
    /// the same control a new request rather than a no-op.
    static func post(_ route: Route) {
        defaults?.set(route.rawValue, forKey: pendingRouteKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: pendingRouteStampKey)

        // Darwin for the other process, Foundation for this one. Which
        // process actually runs the intent is not ours to decide —
        // `openAppWhenRun` re-runs `perform()` inside the app, but a press
        // can also be served by the extension — so the post has to reach
        // whichever side is listening, including itself.
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(routePostedNotification as CFString),
            nil, nil, true
        )
        NotificationCenter.default.post(name: Notification.Name(routePostedNotification), object: nil)
    }

    /// Reads and clears the pending route. Cleared on read so a press is
    /// acted on once, however many of the app's wake-ups notice it.
    ///
    /// Anything older than a couple of minutes is dropped: a route written
    /// while the app was force-quit and never opened is a press the person
    /// has long since given up on, and answering it at the next launch would
    /// throw a keypad up over whatever they actually opened the app to do.
    static func takePendingRoute(maxAge: TimeInterval = 120) -> Route? {
        guard let defaults else { return nil }
        guard let raw = defaults.string(forKey: pendingRouteKey),
              let route = Route(rawValue: raw) else { return nil }

        let stamp = defaults.double(forKey: pendingRouteStampKey)
        defaults.removeObject(forKey: pendingRouteKey)
        defaults.removeObject(forKey: pendingRouteStampKey)

        guard stamp > 0, Date().timeIntervalSince1970 - stamp <= maxAge else { return nil }
        return route
    }
}

// MARK: - Coders

/// Both ends encode dates and both ends have to agree on how.
///
/// Built per call rather than held as a shared instance: `JSONEncoder` is not
/// `Sendable`, the snapshot is written a handful of times a session, and a
/// global mutable coder shared across an app and an extension is a data race
/// waiting for the one launch where both write at once.
extension JSONEncoder {
    nonisolated static var snapshot: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    nonisolated static var snapshot: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
