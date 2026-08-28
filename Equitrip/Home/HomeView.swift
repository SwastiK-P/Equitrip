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

    var userName: String?
    var onSignOut: () -> Void = {}
    /// Selecting a trip hands off to the Itinerary tab rather than pushing a
    /// second copy of the timeline inside Home.
    var onOpenTrip: (Trip) -> Void = { _ in }
    var onShowAllTrips: () -> Void = {}

    @State private var appeared = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var showNewTrip = false
    @State private var showChat = false
    /// The trip a quick expense would land on. Set when the shortcut is
    /// tapped, which is also what presents the sheet.
    @State private var quickAddTrip: Trip?
    /// The handover from quick to the full editor, which needs both the trip
    /// and what was typed.
    @State private var detailedAdd: DetailedAdd?

    private struct DetailedAdd: Identifiable {
        let trip: Trip
        let seed: ItineraryItem
        var id: UUID { seed.id }
    }
    /// Which trips the hero's figures cover. Nil is the whole portfolio.
    @State private var balanceTripID: UUID?

    private var unreadCount: Int { notifications.unreadCount }

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
                // Horizontal padding is per-section, not on the stack, so the
                // trip carousel can bleed past the margin while everything
                // else stays aligned to it.
                LazyVStack(spacing: 26) {
                    greeting
                        .padding(.horizontal, 20)
                        .staggered(0, appeared)

                    // A read failure and a write failure are both worth
                    // interrupting for, but never both at once — the read one
                    // is the more fundamental of the two, so it wins.
                    if let failure = store.state.failure ?? store.writeFailure {
                        ConnectionBanner(message: failure) {
                            store.clearWriteFailure()
                            Task { await store.reload() }
                        }
                        .padding(.horizontal, 20)
                    }

                    balanceHero
                        .padding(.horizontal, 20)
                        .staggered(1, appeared)

                    quickActions
                        .padding(.horizontal, 20)
                        .staggered(2, appeared)

                    currentTripSection
                        .staggered(3, appeared)

                    if !upNext.isEmpty {
                        upNextSection
                            .padding(.horizontal, 20)
                            .staggered(4, appeared)
                    }

                    activitySection
                        .padding(.horizontal, 20)
                        .staggered(5, appeared)
                }
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await store.reload()
                await notifications.load()
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
            .safeAreaBar(edge: .top, spacing: 0) { topBar }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsSheet()
        }
        .sheet(isPresented: $showProfile) {
            ProfileSheet(userName: userName, onSignOut: onSignOut)
        }
        .fullScreenCover(isPresented: $showChat) {
            if let trip = store.currentTrip {
                TripChatView(trip: trip)
            }
        }
        .sheet(item: $quickAddTrip) { trip in
            QuickAddSheet(
                travellers: trip.travellers,
                currencyCode: trip.currencyCode,
                day: Calendar.current.startOfDay(for: Date()),
                onSave: { store.addItem($0, to: trip.id) },
                // Home has no itinerary stack to hand off to, so the full
                // editor opens over it in the same place.
                onSwitchToDetailed: { partial in
                    quickAddTrip = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(320))
                        detailedAdd = DetailedAdd(trip: trip, seed: partial)
                    }
                }
            )
        }
        .sheet(item: $detailedAdd) { pending in
            ItineraryItemEditor(
                item: pending.seed,
                travellers: pending.trip.travellers,
                currencyCode: pending.trip.currencyCode,
                isNew: true,
                onSave: { store.addItem($0, to: pending.trip.id) }
            )
        }
        .fullScreenCover(isPresented: $showNewTrip) {
            NewTripFlow { draft in
                store.add(draft.makeTrip())
            }
        }
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Top bar

    /// Fixed while the page scrolls beneath it. The blur ramps out instead of
    /// ending on a line, so there's no bar edge cutting across the canvas —
    /// content dissolves as it passes under the controls.
    private var topBar: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 12) {
                // Deliberately smaller than the avatar opposite it. The bell
                // is a passive indicator most of the time — the face is the
                // thing you reach for — so the glass ring around it was
                // carrying more weight than the control deserved.
                NotificationBellButton(unread: unreadCount, size: 38) {
                    showNotifications = true
                }

                Spacer(minLength: 0)

                // The dashed ring reads as "this is yours to change" the way a
                // dotted outline does on an empty slot, without putting the
                // face in a solid box.
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showProfile = true
                } label: {
                    MemojiAvatar(traveller: .you, size: 38)
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
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(timeOfDayGreeting)
                .font(.system(size: 14.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)

            Text(firstName)
                .font(.system(size: 30, weight: .bold, design: .rounded))
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
        Menu {
            Button {
                balanceTripID = nil
            } label: {
                Label("All trips", systemImage: balanceTripID == nil ? "checkmark" : "square.stack.3d.up")
            }

            if !store.trips.isEmpty { Divider() }

            ForEach(store.trips) { trip in
                Button {
                    balanceTripID = trip.id
                } label: {
                    // The dates go on as a subtitle: groups reuse trip names
                    // ("Paris Escape" twice in a year is normal), and a menu of
                    // identical rows is a menu you can't choose from.
                    Text(trip.title)
                    Text(trip.dateRange)
                    Image(systemName: balanceTripID == trip.id ? "checkmark" : trip.symbol)
                }
            }
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
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("Balance scope, \(balanceTrip?.title ?? "all trips")")
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
                .font(.system(size: 46, weight: .bold, design: .rounded))
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
            .padding(.top, 18)
        }
        .padding(20)
        .cardSurface(corner: 28, shadow: 16)
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

    /// Owed-to-you against owed-by-you as one bar — the ratio is what you
    /// read at a glance, not the two figures.
    ///
    /// Segmented to match the trip card's progress bar, so the two bars on
    /// this screen read as one family rather than two unrelated indicators.
    private var splitBar: some View {
        let total = owedToYou + youOwe
        let fraction = total > 0 ? owedToYou / total : 0.5
        let owed = min(Self.splitCells, max(0, Int((Double(Self.splitCells) * fraction).rounded())))

        return HStack(spacing: 2.5) {
            ForEach(0..<Self.splitCells, id: \.self) { index in
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
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 0) {
                ForEach(QuickAction.all) { action in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        switch action.title {
                        case "New trip": showNewTrip = true
                        case "Chat": showChat = store.currentTrip != nil
                        case "Expense": quickAddTrip = liveTrip
                        default: break
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: action.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(isEnabled(action) ? AppTheme.accent : AppTheme.inkTertiary)
                                .frame(width: 54, height: 54)
                                .glassEffect(.regular.interactive(), in: .circle)

                            Text(action.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled(action))
                }
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

    /// Both of these belong to a trip, so they're dimmed until there's one to
    /// belong to — Chat to any trip, Expense to one that's under way.
    private func isEnabled(_ action: QuickAction) -> Bool {
        switch action.title {
        case "Chat": store.currentTrip != nil
        case "Expense": liveTrip != nil
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
                .padding(.horizontal, 20)

                Button {
                    onOpenTrip(trip)
                } label: {
                    CurrentTripCard(trip: trip)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 20)
            }
        } else {
            VStack(alignment: .leading, spacing: 13) {
                SectionHeader(title: "Your trips")
                    .padding(.horizontal, 20)

                NewTripCard { showNewTrip = true }
                    .padding(.horizontal, 20)
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
                showNotifications = true
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

// MARK: - Current trip card

/// Full width, because it's the only trip on the screen — there's no carousel
/// left to fit it into. Leads with the photograph, then the two numbers that
/// matter today, then what's next on it.
private struct CurrentTripCard: View {
    @Environment(\.tripStore) private var store
    @Environment(\.notificationStore) private var notifications
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover

            VStack(spacing: 12) {
                HStack {
                    Text(trip.progressLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)

                    Spacer(minLength: 6)

                    HStack(spacing: 5) {
                        Circle()
                            .fill(trip.phase.tint)
                            .frame(width: 5, height: 5)
                        Text(trip.phase.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkSecondary)
                    }
                }

                ProgressTrack(value: trip.progress, tint: trip.tint, cells: trip.dayCount)

                Hairline()

                HStack(alignment: .bottom, spacing: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        AvatarStack(travellers: trip.travellers, size: 28, max: 5)

                        Text("\(trip.bookingCount.pluralised("booking")) · \(trip.projectedLabel)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Spacer(minLength: 4)

                    // Before the trip starts there is no balance to report —
                    // see `Trip.showsBalance`. What it'll cost you is the
                    // figure that means something at that point.
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(trip.showsBalance ? trip.netLabel : Money.format(trip.yourShare, code: trip.currencyCode))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(trip.showsBalance ? trip.netTone : AppTheme.ink)
                        Text(trip.showsBalance ? trip.netCaption : "your share")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .lineLimit(1)
                    .fixedSize()
                }
            }
            .padding(16)
        }
        .background(AppTheme.card, in: .rect(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.05))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 12, y: 5)
    }

    private var cover: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.title)
                    .font(AppTheme.display(21))
                    .foregroundStyle(.white)
                Text("\(trip.dateRange) · \(trip.travellers.count.pluralised("traveller"))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .lineLimit(1)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
            .padding(14)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .frame(height: 80)
                .allowsHitTesting(false)
        }
        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
    }
}

/// The affordance that stops an empty or short trip list from being a dead end.
private struct NewTripCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)

                VStack(spacing: 2) {
                    Text("New trip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Import a PDF or\nadd it yourself")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 164)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 24)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        AppTheme.cardStroke.opacity(0.16),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                    )
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Segmented progress: equal-width capsules rather than one continuous fill.
///
/// One cell per day of the trip, so the bar and the "Day 2 of 5" label above
/// it are visibly counting the same thing — a continuous fill made you
/// estimate the same number the label states exactly. Kept local because the
/// only other bar in the app (the hero split) is a two-tone variant of a
/// different thing.
private struct ProgressTrack: View {
    let value: Double
    let tint: Color
    /// Days on the trip. `dayCount` is already at least 1, but this clamps
    /// anyway rather than trusting a caller not to hand over an empty range.
    let cells: Int

    private var count: Int { max(1, cells) }

    /// Rounded up: any progress at all lights the first cell, because a bar
    /// showing nothing on a trip that has started reads as broken.
    private var filled: Int {
        let clamped = min(1, max(0, value))
        guard clamped > 0 else { return 0 }
        return min(count, max(1, Int((Double(count) * clamped).rounded(.up))))
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? tint : AppTheme.cardStroke.opacity(0.08))
                    // Equal share of the row each, so the cells stay identical
                    // at any card width without measuring anything.
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: filled)
    }
}

// MARK: - Itinerary row

private struct ItineraryRow: View {
    let item: ItineraryItem
    let trip: Trip?

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                if let clock = item.clock {
                    Text(clock.value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(clock.meridiem)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else {
                    Text("All\nday")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .fixedSize()
            .frame(width: 44)

            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .lineLimit(1)
            .layoutPriority(1)

            Spacer(minLength: 4)

            if let trip {
                AvatarStack(travellers: trip.participants(of: item), size: 22, max: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// Vendor when there is one, otherwise how the cost is being shared —
    /// which is the next most useful thing to know about a booking.
    private var subtitle: String {
        let money = item.cost > 0 && trip != nil
            ? Money.format(item.cost, code: trip!.currencyCode)
            : nil

        let lead = item.vendor.isEmpty ? item.split.label : item.vendor
        guard let money else { return lead }
        return "\(lead) · \(money)"
    }
}

// MARK: - Activity row

private struct ActivityRow: View {
    let item: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.kind.symbol, tint: item.kind.tint, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13.5, weight: item.isUnread ? .semibold : .regular))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.body.isEmpty ? item.time : "\(item.body) · \(item.time)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            if item.isUnread {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

#Preview("Light") {
    RootTabView(userName: "Swastik Patil")
}

#Preview("Dark") {
    RootTabView(userName: "Swastik Patil")
        .preferredColorScheme(.dark)
}
