//
//  HomeView.swift
//  Equitrip
//

import SwiftUI

/// The "where do I stand?" screen.
///
/// Ordered by what someone opens the app to find out: their net position
/// first, then the thing they can do about it, then the trips those numbers
/// came from, then what's about to happen, then what changed while they were
/// away.
struct HomeView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.notificationStore) private var notifications
    @Environment(\.detectedExpenses) private var detections
    @Environment(\.gmailSync) private var gmailSync
    @Environment(\.bookingChanges) private var bookingChanges
    @Environment(\.bookingChangeSync) private var bookingSync
    @Environment(\.pane) private var pane

    var userName: String?
    /// A counter the root bumps when something outside Home wants the
    /// quick-add sheet — see `RootTabView.requestQuickAdd`. Home watches the
    /// *change*, not the value: pressing the Control Centre button twice is
    /// two requests, and a `Bool` would have swallowed the second.
    var quickAddRequests: Int = 0
    var onSignOut: () -> Void = {}
    /// Selecting a trip hands off to the Itinerary tab rather than pushing a
    /// second copy of the timeline inside Home.
    var onOpenTrip: (Trip) -> Void = { _ in }
    var onShowAllTrips: () -> Void = {}
    /// Settling is its own tab, so Home hands off rather than presenting.
    var onSettleUp: () -> Void = {}
    /// A settlement request wants a full-screen answer, not an inline one, so
    /// Home hands off to a sheet the root presents — see `RootTabView`.
    var onReviewSettlement: (Settlement) -> Void = { _ in }

    @State private var appeared = false
    /// Everything Home can present, as two slots rather than six flags.
    ///
    /// SwiftUI honours one `sheet` and one `fullScreenCover` per view. Six
    /// separate modifiers stacked on this one ZStack meant the first of each
    /// worked — the bell — and every later one silently did nothing, which is
    /// exactly how New trip, Chat and Expense came to be buttons that fired
    /// their action and produced no screen. Routing through a single binding
    /// each also makes the set of destinations something you can read in one
    /// place instead of inferring from a column of booleans.
    @State private var sheet: Sheet?
    @State private var cover: Cover?
    private enum Sheet: Identifiable {
        case notifications
        case profile
        /// The trip, and the day the expense is filed against — today for a
        /// trip that's running, and the trip's own first day otherwise. Quick
        /// add used to stamp today unconditionally, which is only true while
        /// you're actually on the trip.
        case quickAdd(Trip, Date)
        /// The handover from quick add to the full editor, which needs both
        /// the trip and whatever was already typed.
        case detailedAdd(Trip, ItineraryItem)
        /// The queue of payments read out of Gmail.
        case detected(Trip)
        /// Cancellations and reschedules read out of Gmail, across every trip.
        case bookingChanges
        /// A trip you've been asked to join, before you've answered.
        case invitation(TripInvitation)

        var id: String {
            switch self {
            case .notifications: "notifications"
            case .profile: "profile"
            case .quickAdd(let trip, _): "quick-\(trip.id)"
            case .detailedAdd(_, let seed): "detailed-\(seed.id)"
            case .detected(let trip): "detected-\(trip.id)"
            case .bookingChanges: "booking-changes"
            case .invitation(let invite): "invitation-\(invite.id)"
            }
        }
    }

    private enum Cover: Identifiable {
        case chat(Trip)
        case newTrip
        /// A receipt, from capture to a filled-in booking editor, for this trip.
        case receipt(Trip)

        var id: String {
            switch self {
            case .chat(let trip): "chat-\(trip.id)"
            case .newTrip: "new-trip"
            case .receipt(let trip): "receipt-\(trip.id)"
            }
        }
    }
    /// Which trips the hero's figures cover. Nil is the whole portfolio.
    @State private var balanceTripID: UUID?
    @State private var showTripScopePicker = false
    /// The last `quickAddRequests` value acted on. Kept so a request that
    /// arrives before Home is on screen — a cold launch from the Lock Screen
    /// control — is still answered once it is, and only once.
    @State private var answeredQuickAddRequests = 0

    private var unreadCount: Int { notifications.unreadCount }

    /// Payments detected on the running trip and not yet dealt with.
    private var detectedCount: Int { detections.waitingCount(for: liveTrip?.id) }

    /// Home shows the top of the notification feed rather than a second,
    /// separately-invented "activity" list. There is one record of what
    /// changed and it lives in Postgres; showing a different one here was how
    /// the screen ended up narrating events that had never happened.
    private var activity: [AppNotification] { Array(notifications.feed.prefix(4)) }

    private var upNext: [ItineraryItem] {
        store.selectedTrip?.upcoming(limit: 3) ?? []
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: pane.sectionSpacing) {
                    greeting
                        .staggered(0, appeared)

                    // A read failure and a write failure are both worth
                    // interrupting for, but never both at once — the read one
                    // is the more fundamental of the two, so it wins.
                    if let failure = store.state.failure ?? store.writeFailure {
                        ConnectionBanner(message: failure) {
                            store.clearWriteFailure()
                            Task { await store.reload() }
                        }
                    }

                    // On a phone this is one column and the order below is the
                    // reading order, unchanged: the inbox first, because an
                    // invitation and a payment waiting on your word are the two
                    // things on this screen that are asking you something, then
                    // the balance, then the trip, then the feed.
                    //
                    // Given a second column the page splits by what the halves
                    // are *for* rather than by what happens to be next. Left is
                    // where you stand and what you can do about it; right is
                    // what the app has to tell you — and the inbox moves into
                    // it. That's the same priority expressed differently: it's
                    // beside the balance rather than in front of it, so a
                    // payment waiting on you and the figure it's about to
                    // change are on screen together and neither is scrolled
                    // past to reach the other.
                    if !pane.isWide { inbox }

                    AdaptiveColumns(ratio: 0.55, stackSpacing: pane.sectionSpacing) {
                        VStack(alignment: .leading, spacing: pane.sectionSpacing) {
                            balanceHero
                                .staggered(1, appeared)

                            quickActions
                                .staggered(2, appeared)

                            currentTripSection
                                .staggered(3, appeared)
                        }
                    } trailing: {
                        VStack(alignment: .leading, spacing: pane.sectionSpacing) {
                            if pane.isWide { inbox }

                            if !upNext.isEmpty {
                                upNextSection
                                    .staggered(4, appeared)
                            }

                            activitySection
                                .staggered(5, appeared)
                        }
                    }
                }
                .gutter()
                .pageWidth()
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await store.reload()
                await notifications.load()
                // Pull-to-refresh on Home is the gesture people use to mean
                // "is there anything new" — the mailbox is part of the answer.
                gmailSync?.sync(for: liveTrip, force: true)
                bookingSync?.sync(force: true)
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .tabAlignedHeader { topBar }
        }
        .sheet(item: $sheet) { destination in
            switch destination {
            case .notifications:
                NotificationsSheet()

            case .profile:
                ProfileSheet(userName: userName, onSignOut: onSignOut)

            case .quickAdd(let trip, let day):
                QuickAddSheet(
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    day: day,
                    onSave: {
                        SiriDonations.expenseLogged($0, on: trip.id, in: store)
                        store.addItem($0, to: trip.id)
                    },
                    // Home has no itinerary stack to hand off to, so the full
                    // editor opens over it in the same place. Sequenced rather
                    // than swapped, because changing the item under a live
                    // sheet re-presents it mid-animation.
                    onSwitchToDetailed: { partial in
                        sheet = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(320))
                            sheet = .detailedAdd(trip, partial)
                        }
                    }
                )

            case .invitation(let invite):
                TripInvitationSheet(invitation: invite)

            case .detected(let trip):
                DetectedExpensesSheet(trip: trip)

            case .bookingChanges:
                BookingChangesSheet()

            case .detailedAdd(let trip, let seed):
                ItineraryItemEditor(
                    item: seed,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    isNew: true,
                    onSave: { store.addItem($0, to: trip.id) }
                )
            }
        }
        .fullScreenCover(item: $cover) { destination in
            switch destination {
            case .chat(let trip):
                TripChatView(trip: trip)

            case .newTrip:
                NewTripFlow { draft in
                    store.add(draft.makeTrip())
                }

            case .receipt(let trip):
                ReceiptScanFlow(
                    trip: trip,
                    onSave: {
                        SiriDonations.expenseLogged($0, on: trip.id, in: store)
                        store.addItem($0, to: trip.id)
                    }
                )
            }
        }
        .onAppear {
            withAnimation { appeared = true }
            answerQuickAddRequest()
        }
        .onChange(of: quickAddRequests) { _, _ in answerQuickAddRequest() }
        // A request that landed during a cold launch arrives before the trips
        // do, and there is nothing to file an expense against until they have.
        .onChange(of: store.trips.count) { _, _ in answerQuickAddRequest() }
    }

    // MARK: - Inbox

    /// The cards that are asking you something: a trip you've been invited
    /// to, a payment somebody says they made, a booking an email says has
    /// changed, and expenses read out of the mailbox that nobody has filed yet.
    ///
    /// Grouped as one block rather than three siblings because on iPad they
    /// travel together into the second column, and because all three are the
    /// same kind of thing — an unanswered question — however different they
    /// look. Most days it renders nothing at all, which is the point.
    @ViewBuilder
    private var inbox: some View {
        let invitations = store.invitations
        let settlements = store.settlementsAwaitingYou
        let detected = liveTrip.flatMap { detectedCount > 0 ? $0 : nil }
        let changed = bookingChanges.waiting()
        let updated = bookingChanges.unseenAutomatic

        if !invitations.isEmpty || !settlements.isEmpty || detected != nil || !changed.isEmpty || !updated.isEmpty {
            // Tighter than between sections: these are one group of
            // questions, not separate parts of the page.
            VStack(alignment: .leading, spacing: 10) {
                // First, and above the settlement card, because it is the
                // only thing on this screen about a trip you are not yet
                // on — and because somebody is waiting on the answer.
                if !invitations.isEmpty {
                    TripInvitationsCard(invitations: invitations) {
                        sheet = .invitation($0)
                    }
                }

                if !settlements.isEmpty {
                    PendingSettlementsCard(
                        entries: settlements,
                        onOpen: onReviewSettlement
                    )
                }

                // Above the expenses: a booking that moved changes what's
                // about to happen, not just what it cost.
                if !changed.isEmpty || !updated.isEmpty {
                    BookingChangesInboxCard(waiting: changed, applied: updated) {
                        sheet = .bookingChanges
                    }
                }

                if let trip = detected {
                    DetectedExpensesCard(
                        count: detectedCount,
                        tripTitle: trip.title,
                        isReading: gmailSync?.state.isSyncing ?? false
                    ) {
                        sheet = .detected(trip)
                    }
                }
            }
            .staggered(1, appeared)
        }
    }

    // MARK: - Quick add hand-off

    /// Opens quick add for whoever asked from outside Home.
    ///
    /// Deliberately more forgiving than the on-screen Expense shortcut, which
    /// is simply dimmed when no trip is running. A control pressed from the
    /// Lock Screen has already taken the app over the whole phone: coming up
    /// and doing nothing visible is the worst possible answer, and "you can't
    /// do that right now" is not something a control can say from inside
    /// Control Centre. So it falls back to the trip Home is already about —
    /// filing the expense against that trip's first day rather than against
    /// today, since a day today is a day an upcoming trip doesn't have.
    ///
    /// Only ever marked answered once it has actually opened something, so a
    /// press that arrives during a cold launch is still waiting when the trips
    /// finally land rather than being quietly thrown away.
    private func answerQuickAddRequest() {
        guard quickAddRequests > answeredQuickAddRequests else { return }
        guard let trip = liveTrip ?? store.currentTrip ?? store.trips.first else { return }

        answeredQuickAddRequests = quickAddRequests
        sheet = .quickAdd(trip, quickAddDay(for: trip))
    }

    /// Today when today is on the trip, and the trip's first day otherwise.
    private func quickAddDay(for trip: Trip) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.startOfDay(for: trip.startDate)
        let end = Calendar.current.startOfDay(for: trip.endDate)
        return (start...end).contains(today) ? today : start
    }

    // MARK: - Top bar

    /// Fixed while the page scrolls beneath it. The blur ramps out instead of
    /// ending on a line, so there's no bar edge cutting across the canvas —
    /// content dissolves as it passes under the controls.
    private var topBar: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 12) {
                // Same visible size as the avatar opposite it: the avatar's
                // 38pt face plus its 3.5pt ring reads as a 45pt circle, so
                // the bell matches at 45 rather than sitting a size down.
                NotificationBellButton(unread: unreadCount, size: 45) {
                    sheet = .notifications
                }

                Spacer(minLength: 0)

                // The dashed ring reads as "this is yours to change" the way a
                // dotted outline does on an empty slot, without putting the
                // face in a solid box.
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    sheet = .profile
                } label: {
                    TravellerAvatar(traveller: .you, size: 38)
                        .padding(3.5)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    AppTheme.accent.opacity(0.6),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [4.5, 3.5])
                                )
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("Your profile")
            }
        }
        .gutter()
        // Capped to the same measure as the page under it, so the bell and the
        // avatar sit over the first and last columns rather than out at the
        // bezel with a metre of glass between them and anything they act on.
        .pageWidth()
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(timeOfDayGreeting)
                .font(.system(size: pane.isRegular ? 16 : 14.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Text(firstName)
                .font(.system(size: pane.isRegular ? 36 : 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "Good morning,"
        case 12..<17: "Good afternoon,"
        case 17..<22: "Good evening,"
        default: "Still up,"
        }
    }

    private var firstName: String {
        guard let userName, !userName.isEmpty else { return "Traveller" }
        // Emails get used as the display name when signup metadata is missing.
        let base = userName.contains("@") ? String(userName.split(separator: "@")[0]) : userName
        return base.split(separator: " ").first.map(String.init)?.capitalized ?? base
    }

    // MARK: - Balance scope

    /// The trip the hero is scoped to, or nil for all of them. Resolved rather
    /// than stored as a `Trip` so a sync that replaces the list doesn't leave
    /// the card showing a stale copy — and so a trip that disappears falls
    /// back to the portfolio instead of to nothing.
    private var balanceTrip: Trip? {
        balanceTripID.flatMap { id in store.trips.first { $0.id == id } }
    }

    private var owedToYou: Double {
        balanceTrip.map { $0.owedTo(Traveller.you.id) } ?? store.owedToYou
    }

    private var youOwe: Double {
        balanceTrip.map { $0.owing(Traveller.you.id) } ?? store.youOwe
    }

    private var netPosition: Double { owedToYou - youOwe }

    private var balanceCurrency: String {
        balanceTrip?.currencyCode ?? store.primaryCurrency
    }

    /// One tap to narrow the whole card to a single trip.
    ///
    /// The portfolio figure answers "am I ahead or behind overall", which is
    /// the right lead — but the question people actually act on is per-trip
    /// ("what do I owe from Goa?"), and reaching it meant opening the trip and
    /// reading a different card. Mixed currencies are the other half of it:
    /// the portfolio total picks the most common code and adds unlike things
    /// together, and scoping to one trip is the only honest figure when a
    /// group runs one trip in rupees and the next in euros.
    private var balanceScopePicker: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showTripScopePicker = true
        } label: {
            HStack(spacing: 5) {
                Text(balanceTrip?.title ?? "All trips")
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.accent.opacity(0.12), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Balance scope, \(balanceTrip?.title ?? "all trips")")
        .popover(isPresented: $showTripScopePicker, arrowEdge: .top) {
            TripScopePickerMenu(trips: store.trips, selection: $balanceTripID)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Balance hero

    /// The one number the app exists to answer, given the room to be read as
    /// a number rather than decorated as a banner: quiet label, large figure,
    /// the two sides of it underneath, and a single action.
    private var balanceHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                balanceScopePicker

                Spacer(minLength: 6)

                Text("Net position")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Text(Money.format(netPosition, code: balanceCurrency, signed: true))
                .font(.system(size: pane.isRegular ? 54 : 46, weight: .bold, design: .rounded))
                .foregroundStyle(netTone)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: netPosition)
                .padding(.top, 10)

            Text(positionCaption)
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .padding(.top, 1)

            splitBar
                .padding(.top, 20)

            HStack(spacing: 0) {
                heroFigure(
                    label: "You're owed",
                    value: Money.format(owedToYou, code: balanceCurrency),
                    dot: AppTheme.moneyIn
                )

                Rectangle()
                    .fill(AppTheme.cardStroke.opacity(0.10))
                    .frame(width: 1, height: 32)

                heroFigure(
                    label: "You owe",
                    value: Money.format(youOwe, code: balanceCurrency),
                    dot: AppTheme.moneyOut
                )
                .padding(.leading, 16)
            }
            .padding(.top, 16)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSettleUp()
            } label: {
                HStack(spacing: 6) {
                    Text("Settle up")
                        .font(.system(size: 15.5, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12.5, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.glassProminent)
            .tint(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
        }
        .padding(pane.isRegular ? 24 : 20)
        .cardSurface(corner: pane.corner(28), shadow: 16)
    }

    private var netTone: Color {
        if netPosition > 0 { return AppTheme.moneyIn }
        if netPosition < 0 { return AppTheme.moneyOut }
        return AppTheme.ink
    }

    private var positionCaption: String {
        if let trip = balanceTrip {
            if netPosition > 0 { return "You're ahead on \(trip.title)" }
            if netPosition < 0 { return "You're behind on \(trip.title)" }
            return "Everything's square on \(trip.title)"
        }

        let count = store.activeTrips.count
        let trips = count == 1 ? "1 active trip" : "\(count) active trips"
        if netPosition > 0 { return "You're ahead across \(trips)" }
        if netPosition < 0 { return "You're behind across \(trips)" }
        return "Everything's square across \(trips)"
    }

    /// How many cells the split bar is divided into.
    ///
    /// Fixed, unlike the trip card's bar. That one counts days and has a real
    /// unit to use; this is a ratio, so the count is only about how finely the
    /// balance reads. It's also what sets the cell's shape: at this width each
    /// one lands narrower than it is tall, which is what makes them read as
    /// upright cells rather than a row of dots.
    private static let splitCells = 28

    /// More cells on a wider card, for the reason the fixed count exists at
    /// all: each one has to stay narrower than it is tall. Twenty-eight of
    /// them across a 600pt column are squat little bricks, and the bar stops
    /// reading as a row of cells and starts reading as a dashed line.
    private var splitCellCount: Int {
        pane.isRegular ? 44 : Self.splitCells
    }

    /// Owed-to-you against owed-by-you as one bar — the ratio is what you
    /// read at a glance, not the two figures.
    ///
    /// Segmented to match the trip card's progress bar, so the two bars on
    /// this screen read as one family rather than two unrelated indicators.
    private var splitBar: some View {
        let cells = splitCellCount
        let total = owedToYou + youOwe
        let fraction = total > 0 ? owedToYou / total : 0.5
        let owed = min(cells, max(0, Int((Double(cells) * fraction).rounded())))

        return HStack(spacing: 2.5) {
            ForEach(0..<cells, id: \.self) { index in
                // Softly rounded rather than a capsule: a capsule this narrow
                // rounds away to a lozenge and the cell stops reading as a
                // cell.
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(index < owed ? AppTheme.moneyIn : AppTheme.moneyOut.opacity(0.32))
                    // Equal share each, so no cell is wider than its neighbour
                    // whatever the balance happens to be.
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 13)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: owed)
        .accessibilityElement()
        .accessibilityLabel(
            "You're owed \(Money.format(owedToYou, code: balanceCurrency)), you owe \(Money.format(youOwe, code: balanceCurrency))"
        )
    }

    private func heroFigure(label: String, value: String, dot: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle()
                    .fill(dot)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            Text(value)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 2)
    }

    // MARK: - Quick actions

    /// One glyph colour across all four. They're peers — colouring them apart
    /// would imply a difference in kind that isn't there, and a row of four
    /// saturated tiles fights the hero for attention.
    private var quickActions: some View {
        // A plain `HStack`, not a `GlassEffectContainer`.
        //
        // The container is for glass shapes that need to merge and morph into
        // one another; these four never move, never merge, and sit far enough
        // apart that it had nothing to do. What it did do was sit between the
        // row and the touch: nothing inside it received a tap — not the
        // buttons, not a bare `onTapGesture`, not even after the glass itself
        // was removed — while a button in the card directly above worked. Four
        // shortcuts that highlighted on press and did nothing.
        HStack(spacing: 0) {
            ForEach(QuickAction.all) { action in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    switch action.title {
                    case "New trip":
                        cover = .newTrip
                    case "Chat":
                        if let trip = store.currentTrip { cover = .chat(trip) }
                    case "Expense":
                        if let trip = liveTrip {
                            sheet = .quickAdd(trip, Calendar.current.startOfDay(for: Date()))
                        }
                    case "Receipt":
                        if let trip = receiptTrip { cover = .receipt(trip) }
                    default:
                        break
                    }
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: action.symbol)
                            .font(.system(size: pane.isRegular ? 23 : 20, weight: .semibold))
                            .foregroundStyle(isEnabled(action) ? AppTheme.accent : AppTheme.inkTertiary)
                            .frame(width: pane.scaled(54, regular: 62), height: pane.scaled(54, regular: 62))
                            .contentShape(.circle)
                            // Interactive, so the disc answers a press the way
                            // the system's own glass buttons do — it swells and
                            // lights under the finger. Off while the action has
                            // nothing to act on, so a dead shortcut doesn't
                            // pretend to press.
                            .glassEffect(.regular.interactive(isEnabled(action)), in: .circle)

                        Text(action.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    // The caption is part of the target: a circle with a word
                    // under it reads as one control, so the whole cell takes
                    // the tap rather than just the 54pt disc.
                    .contentShape(.rect)
                }
                // Plain rather than `PressableButtonStyle`: its shrink-and-dim
                // on the whole cell fought the glass's own swell, and the two
                // together read as the button flinching.
                .buttonStyle(.plain)
                .disabled(!isEnabled(action))
            }
        }
    }

    /// The trip a "log this now" expense belongs to.
    ///
    /// Has to be one that's actually running. Quick add stamps the current
    /// date and time onto whatever it creates, which is only true of a trip
    /// you're on — filing today's beach snacks against a trip that starts in
    /// three weeks puts a booking on a day the trip doesn't have.
    private var liveTrip: Trip? {
        store.trips.first { $0.phase == .live }
    }

    /// The trip a scanned receipt is filed against: the one under way, or
    /// else the next one.
    ///
    /// Looser than `liveTrip` on purpose. Quick add stamps *now* onto what it
    /// creates; a receipt carries its own date, and the ones that arrive
    /// before a trip starts — the hotel deposit, the ferry tickets bought at
    /// the counter a week early — are receipts all the same.
    private var receiptTrip: Trip? {
        liveTrip ?? store.currentTrip
    }

    /// All three of these belong to a trip, so they're dimmed until there's
    /// one to belong to — Chat and Receipt to any trip, Expense to one that's
    /// under way.
    private func isEnabled(_ action: QuickAction) -> Bool {
        switch action.title {
        case "Chat": store.currentTrip != nil
        case "Expense": liveTrip != nil
        case "Receipt": receiptTrip != nil
        default: true
        }
    }

    // MARK: - Current trip

    /// One trip, not the portfolio. Home answers "what's happening now"; the
    /// Itinerary tab is where all of them live. A carousel here made the two
    /// screens compete to be the same list.
    @ViewBuilder
    private var currentTripSection: some View {
        if let trip = store.currentTrip {
            VStack(alignment: .leading, spacing: 13) {
                SectionHeader(
                    title: trip.phase == .live ? "Happening now" : "Up next",
                    actionTitle: "All trips"
                ) {
                    onShowAllTrips()
                }

                Button {
                    onOpenTrip(trip)
                } label: {
                    CurrentTripCard(trip: trip)
                }
                .buttonStyle(PressableButtonStyle())
            }
        } else {
            VStack(alignment: .leading, spacing: 13) {
                SectionHeader(title: "Your trips")

                NewTripCard { cover = .newTrip }
            }
        }
    }

    // MARK: - Up next

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(
                title: "Up next",
                caption: store.selectedTrip?.title,
                actionTitle: "Itinerary"
            ) {
                if let trip = store.selectedTrip { onOpenTrip(trip) }
            }

            VStack(spacing: 0) {
                ForEach(Array(upNext.enumerated()), id: \.element.id) { index, item in
                    ItineraryRow(item: item, trip: store.selectedTrip)

                    if index < upNext.count - 1 {
                        Hairline(inset: 16)
                    }
                }
            }
            .cardSurface(corner: 24)
        }
    }

    // MARK: - Activity

    @ViewBuilder
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeader(
                title: "Recent activity",
                actionTitle: activity.isEmpty ? nil : "See all"
            ) {
                sheet = .notifications
            }

            if activity.isEmpty {
                Text("Nothing has changed yet. Bookings, arrivals and payments show up here.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface(corner: 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                        ActivityRow(item: item)

                        if index < activity.count - 1 {
                            Hairline(inset: 16)
                        }
                    }
                }
                .cardSurface(corner: 24)
            }
        }
    }
}
