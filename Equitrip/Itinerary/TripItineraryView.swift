//
//  TripItineraryView.swift
//  Equitrip
//

import SwiftUI

/// The master itinerary, as a timeline.
///
/// Two things drive the layout. First, a trip is a sequence, so it gets a rail
/// rather than a list — the gaps between things are information. Second, not
/// everyone is on everything, so the same timeline can be read as the group's
/// plan or as yours, and switching between them is one tap rather than a
/// different screen.
struct TripItineraryView: View {
    @Environment(\.tripStore) private var store
    @Environment(\.notificationStore) private var notifications
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pane) private var pane

    /// The trip this screen is for. Passed in by the list that pushed it,
    /// rather than read from a shared "selected" slot, so pushing two
    /// different trips can't end up showing the same one.
    let tripID: UUID

    @State private var section: Section = .timeline
    @State private var scope: Scope = .group
    /// Days folded shut. Keyed by the day's own date rather than an index, so
    /// a day someone closed stays closed across a reload that reorders or
    /// adds days around it.
    @State private var collapsedDays: Set<Date> = []
    @State private var showEditor = false
    @State private var editingItem: ItineraryItem?
    @State private var viewingItem: ItineraryItem?
    /// Seeds for the two ways in. Separate sheets rather than one with a mode,
    /// because swapping the item under a live `sheet(item:)` re-presents it
    /// mid-animation — the handover is sequenced explicitly instead.
    @State private var quickAdd: ItineraryItem?
    @State private var detailedAdd: ItineraryItem?
    @State private var showTravellers = false
    @State private var showShare = false
    /// Who is being taken off the trip, when the leave flow is open.
    @State private var leaving: Traveller?
    /// A proposal being answered, and a closed exit being read. Two sheets
    /// rather than one with a mode: one of them has an answer to give and the
    /// other is a receipt, and they should never be mistaken for each other.
    /// The cover photograph's own colour, which the iPad trip sheet is washed
    /// in. Nil until it's been sampled; the sheet falls back to the trip tint.
    @State private var coverTint: Color?
    @Namespace private var pillSpace
    @State private var reviewingDeparture: TripDeparture?
    @State private var viewingStatement: TripDeparture?

    /// The trip's two faces. Not two destinations — the plan and its money are
    /// the same trip asked two different questions, and making the money a tab
    /// of its own is what put a trip picker in front of a screen you could only
    /// reach by picking a trip.
    enum Section: Hashable { case timeline, ledger }

    enum Scope: Hashable { case group, mine }

    private var trip: Trip? { store.trip(tripID) }

    var body: some View {
        ZStack {
            CanvasBackground()

            if let trip {
                content(for: trip)
            } else {
                emptyState
            }
        }
        // An overlay rather than a `safeAreaInset`: the timeline scrolls
        // underneath it and the hero runs up behind it, which a top inset
        // would make impossible.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .overlay(alignment: .top) {
            // The iPad sheet carries its own actions; the floating bar is the
            // phone's, where there's no panel to put them in.
            if !(pane.isWide && trip != nil) { topBar }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showTravellers) {
            if let trip {
                TravellerPickerSheet(
                    travellers: Binding(
                        get: { trip.travellers },
                        // Removals only. Somebody joining a trip that exists
                        // now goes through `onInvite` — an addition can't
                        // arrive here any more, and the arrival announcement
                        // that used to live on this setter moved with it, to
                        // `announceInvitation`. Writing straight through keeps
                        // this the plain "the roster changed" path it reads as.
                        set: { updated in
                            var copy = trip
                            copy.travellers = updated
                            copy.invitedIDs = copy.invitedIDs.intersection(updated.map(\.id))
                            store.update(copy)
                        }
                    ),
                    organiserIDs: trip.youAreOrganiser
                        ? Binding(
                            get: { trip.organiserIDs },
                            set: { updated in
                                var copy = trip
                                copy.organiserIDs = updated
                                store.update(copy)
                            }
                        )
                        : nil,
                    isEditable: trip.youAreOrganiser,
                    trip: trip,
                    // Sequenced the same way the editor hand-off is: swapping
                    // one sheet for another while the first is still on screen
                    // makes SwiftUI juggle two presentations at once.
                    onLeave: { person in
                        showTravellers = false
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(320))
                            leaving = person
                        }
                    },
                    onInvite: { store.invite($0, to: trip.id) },
                    onCancelInvite: { store.cancelInvitation(of: $0.id, in: trip.id) }
                )
            }
        }
        .sheet(item: $leaving) { person in
            if let trip { LeaveTripSheet(trip: trip, traveller: person) }
        }
        .sheet(item: $reviewingDeparture) { departure in
            if let trip { DepartureReviewSheet(trip: trip, departure: departure) }
        }
        .sheet(item: $viewingStatement) { departure in
            if let trip { DepartureStatementSheet(trip: trip, departure: departure) }
        }
        .sheet(isPresented: $showShare) {
            if let trip { TripInviteSheet(trip: trip) }
        }
        .sheet(isPresented: $showEditor) {
            if let trip {
                TripEditorSheet(
                    trip: trip,
                    onSave: { store.update($0) },
                    // Deleting the trip you're looking at has to take this
                    // screen with it, or the timeline sits there showing a
                    // trip that no longer exists.
                    onDelete: trip.youAreOrganiser
                        ? {
                            let id = trip.id
                            dismiss()
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(280))
                                store.delete(id)
                            }
                        }
                        : nil
                )
            }
        }
        .sheet(item: $viewingItem) { item in
            if let trip {
                ItineraryItemDetailView(
                    item: item,
                    trip: trip,
                    onRecordPayment: { payer, method, receipt in
                        var updated = item
                        updated.paidByID = payer
                        updated.paymentMethod = method
                        updated.receiptURL = receipt
                        store.updateItem(updated, in: trip.id)
                        viewingItem = updated
                    },
                    // Editing is offered only to those who can actually do it.
                    // Presenting the editor while the detail sheet is still on
                    // screen makes SwiftUI juggle two `sheet(item:)` bindings
                    // at once, so the swap is sequenced explicitly.
                    onEdit: trip.youAreOrganiser
                        ? {
                            let target = item
                            viewingItem = nil
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(320))
                                editingItem = target
                            }
                        }
                        : nil,
                    onDisputePayment: { reason in
                        var updated = item
                        updated.isDisputed = true
                        updated.disputedByID = Traveller.you.id
                        updated.disputedAt = Date()
                        updated.disputeReason = reason
                        updated.disputeResolvedAt = nil
                        updated.disputeResolvedByID = nil
                        store.disputePayment(for: item.id, in: trip.id, reason: reason)
                        viewingItem = updated
                    },
                    onResolveDispute: {
                        var updated = item
                        updated.isDisputed = false
                        updated.disputeResolvedAt = Date()
                        updated.disputeResolvedByID = Traveller.you.id
                        store.resolvePaymentDispute(for: item.id, in: trip.id)
                        viewingItem = updated
                    }
                )
            }
        }
        .sheet(item: $editingItem) { item in
            if let trip {
                ItineraryItemEditor(
                    item: item,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    onSave: { store.updateItem($0, in: trip.id) },
                    onDelete: { store.removeItem(item.id, in: trip.id) }
                )
            }
        }
        .sheet(item: $quickAdd) { _ in
            if let trip {
                QuickAddSheet(
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    day: addDay(for: trip),
                    onSave: { store.addItem($0, to: trip.id) },
                    onSwitchToDetailed: { partial in
                        quickAdd = nil
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(320))
                            detailedAdd = partial
                        }
                    }
                )
            }
        }
        .sheet(item: $detailedAdd) { seed in
            if let trip {
                ItineraryItemEditor(
                    item: seed,
                    travellers: trip.travellers,
                    currencyCode: trip.currencyCode,
                    isNew: true,
                    onSave: { store.addItem($0, to: trip.id) }
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(for trip: Trip) -> some View {
        Group {
            if pane.isWide {
                splitContent(for: trip)
            } else {
                stackedContent(for: trip)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: scope)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: section)
    }

    /// The phone layout: one column, banner at the top, everything under it.
    private func stackedContent(for trip: Trip) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Outside the measure, unlike everything below it: the banner
                // is a photograph that runs to the edges of the screen, and a
                // cap would leave it floating in two thin strips of canvas.
                banner(for: trip)

                VStack(alignment: .leading, spacing: 0) {
                    GlassSegments(
                        options: [(Section.timeline, "Timeline"), (Section.ledger, "Ledger")],
                        selection: $section
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    sectionBody(for: trip, showsScope: true)

                    Color.clear.frame(height: 28)
                }
                .pageWidth()
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
    }

    /// The iPad layout: the trip as a sheet on the left, its days on the right.
    ///
    /// Not the phone screen with a column taken off it. On a phone the banner
    /// is a photograph the plan scrolls past; here there's room for the trip
    /// to be *described* — its picture, its dates, who's on it, what's settled
    /// — in a panel that stays put while the plan moves beside it. The plan
    /// itself changes shape too: a week of bookings on one continuous rail is
    /// a very long scroll on a very wide screen, so days become cards that
    /// open and close, and the whole trip fits on one screen as an overview.
    ///
    /// The money floats over the foot of the plan, because it's what every
    /// booking above it is moving and it shouldn't scroll out of sight.
    private func splitContent(for trip: Trip) -> some View {
        HStack(spacing: 0) {
            tripSheet(for: trip)
                .frame(width: pane.railWidth + 72)

            plan(for: trip)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func sectionBody(for trip: Trip, showsScope: Bool) -> some View {
        switch section {
        case .timeline:
            timeline(for: trip, showsScope: showsScope)
                .transition(.opacity)

        case .ledger:
            ledger(for: trip)
        }
    }

    private func ledger(for trip: Trip) -> some View {
        TripLedger(
            trip: trip,
            onOpen: { viewingItem = $0 },
            onReviewDeparture: { reviewingDeparture = $0 },
            onOpenStatement: { viewingStatement = $0 }
        )
        .transition(.opacity)
    }

    // MARK: - Trip sheet

    /// Everything the trip *is*, as a panel running the full height of the
    /// window: photograph, name and dates, four figures, then the small print.
    ///
    /// Scrollable in its own right: on a short landscape iPad it runs a little
    /// past the window, and a panel that can't reach its last row is worse
    /// than one that moves.
    private func tripSheet(for trip: Trip) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sheetCover(for: trip)

                sheetIdentity(for: trip)
                    .padding(.top, 18)

                sheetFacts(for: trip)
                    .padding(.top, 18)

                sheetSummary(for: trip)
                    .padding(.top, 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 32)
        }
        // A bar rather than a row in the scroll: the buttons stay put, and the
        // system's soft scroll edge effect blurs the panel out underneath them.
        .safeAreaBar(edge: .top) {
            sheetActions(for: trip)
                .padding(.horizontal, 20)
                .padding(.top, windowTopInset)
                .padding(.bottom, 6)
        }
        // The top tab bar adds its height to the safe area of everything under
        // it, but it floats over the plan column, not this one. Clearing only
        // the status bar puts the back button on the same line as the tabs
        // instead of a tab bar's height below them.
        .ignoresSafeArea(.container, edges: .top)
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background { sheetBackground(for: trip) }
        .task(id: trip.cover?.url) {
            guard let cover = trip.cover else { return }
            let tint = await CoverTint.shared.tint(for: cover)
            withAnimation(.easeInOut(duration: 0.5)) { coverTint = tint }
        }
    }

    /// The window's own top inset — the status bar — without the tab bar's
    /// share that the view's safe area includes.
    private var windowTopInset: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        return window?.safeAreaInsets.top ?? 24
    }

    /// The photograph, dissolved into the sheet it sits on.
    ///
    /// The top of the panel is the cover itself, blurred past recognition so
    /// only its light and colour survive; below that a wash of the photo's
    /// average colour fades down into the canvas. The sheet ends up looking
    /// like it belongs to *this* trip — dusk purple for Paris, glacier blue
    /// for a trek — without any of the detail that would fight the type.
    private func sheetBackground(for trip: Trip) -> some View {
        let tint = coverTint ?? trip.tint

        return ZStack(alignment: .top) {
            AppTheme.canvasTop

            LinearGradient(
                stops: [
                    .init(color: tint.opacity(0.55), location: 0),
                    .init(color: tint.opacity(0.28), location: 0.45),
                    .init(color: tint.opacity(0.08), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint
            )
            .frame(height: 520)
            .frame(maxWidth: .infinity)
            .blur(radius: 70, opaque: true)
            .saturation(1.3)
            .opacity(0.6)
            .mask {
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
            }
            .clipped()

            // A soft lift of white so dark ink stays legible on any photo.
            LinearGradient(
                colors: [.white.opacity(0.18), .white.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppTheme.cardStroke.opacity(0.08))
                .frame(width: 1)
        }
        .ignoresSafeArea()
    }

    /// Back on the left, what you can do to the trip on the right. Adding a
    /// booking isn't here — it's the cost bar's button, next to the figure it
    /// changes.
    private func sheetActions(for trip: Trip) -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                CircleGlyphButton(symbol: "chevron.left", size: 44) { dismiss() }
                    .accessibilityLabel("Back to trips")

                Spacer(minLength: 0)

                CircleGlyphButton(symbol: "person.badge.plus", size: 44) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showShare = true
                }
                .accessibilityLabel("Invite people")

                if trip.youAreOrganiser {
                    CircleGlyphButton(symbol: "slider.horizontal.3", size: 44) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showEditor = true
                    }
                    .accessibilityLabel("Edit trip")
                }
            }
        }
    }

    /// The photograph on its own, no type over it. With a panel to put the
    /// name in there's nothing it has to be blurred for.
    private func sheetCover(for trip: Trip) -> some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
        .frame(height: pane.railWidth * 0.6)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.35))
        }
        .shadow(color: (coverTint ?? trip.tint).opacity(0.35), radius: 22, y: 12)
    }

    private func sheetIdentity(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(trip.title)
                .font(AppTheme.display(28))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Label(trip.destination.isEmpty ? "Destination not set" : trip.destination, systemImage: "mappin.and.ellipse")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineLimit(1)

            Label(
                "\(DateFormatter.cached("EEE, d MMM").string(from: trip.startDate)) – \(DateFormatter.cached("EEE, d MMM").string(from: trip.endDate))",
                systemImage: "calendar"
            )
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.inkSecondary)
            .lineLimit(1)
        }
        .labelStyle(SheetLabelStyle())
    }

    private func sheetFacts(for trip: Trip) -> some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        let timing = sheetTiming(for: trip)

        return LazyVGrid(columns: columns, spacing: 10) {
            TripFactTile(symbol: "clock", label: "Duration", value: trip.dayCount.pluralised("day"))

            TripFactTile(
                symbol: "person.2",
                label: "Travellers",
                value: "\(trip.travellers.count)",
                accessory: AnyView(
                    AvatarStack(travellers: trip.travellers, size: 22, max: 3, departedIDs: trip.departedIDs)
                ),
                action: { showTravellers = true }
            )

            TripFactTile(symbol: "ticket", label: "Bookings", value: "\(trip.items.count)")

            TripFactTile(symbol: timing.symbol, label: timing.label, value: timing.value)
        }
    }

    /// The fourth tile changes its question with the trip: how long until it
    /// starts, how far through it you are, or how long ago it ended.
    private func sheetTiming(for trip: Trip) -> (symbol: String, label: String, value: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        switch trip.phase {
        case .upcoming:
            let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: trip.startDate)).day ?? 0
            return ("hourglass", "Starts in", days == 1 ? "Tomorrow" : days.pluralised("day"))
        case .live:
            return ("figure.walk", "Right now", trip.progressLabel)
        case .past:
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: trip.endDate), to: today).day ?? 0
            return ("checkmark.seal", "Ended", "\(days.pluralised("day")) ago")
        }
    }

    private func sheetSummary(for trip: Trip) -> some View {
        let paid = trip.items.filter { $0.paidByID != nil }.reduce(0) { $0 + $1.cost }
        let unpaid = trip.items.filter { $0.paidByID == nil && $0.cost > 0 }.count
        let organisers = trip.organisers.map { $0.id == Traveller.you.id ? "You" : $0.name }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Trip details")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 2)

            TripSummaryRow(
                symbol: "star",
                label: "Organised by",
                value: organisers.isEmpty ? "—" : organisers.joined(separator: ", ")
            )
            TripSummaryRow(
                symbol: "checkmark.circle",
                label: "Paid so far",
                value: Money.format(paid, code: trip.currencyCode)
            )
            TripSummaryRow(
                symbol: "exclamationmark.circle",
                label: "Awaiting a payer",
                value: unpaid == 0 ? "None" : unpaid.pluralised("booking"),
                valueTint: unpaid == 0 ? AppTheme.ink : Palette.amberDeep
            )
            TripSummaryRow(symbol: "banknote", label: "Currency", value: trip.currencyCode)
            TripSummaryRow(symbol: "number", label: "Invite code", value: Trip.formatCode(trip.inviteCode))
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Plan

    /// The right-hand column: a heading, the section tabs, and either the days
    /// or the ledger, with the cost bar floating over the bottom of both.
    private func plan(for trip: Trip) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                planHeader(for: trip)
                    .padding(.horizontal, 20)

                Group {
                    switch section {
                    case .timeline:
                        timeline(for: trip, showsScope: false)
                            .transition(.opacity)
                    case .ledger:
                        ledger(for: trip)
                    }
                }
                .padding(.top, 8)

                // Clears the floating cost bar, so the last day can scroll
                // fully above it rather than finishing underneath.
                Color.clear.frame(height: 104)
            }
            .padding(.horizontal, max(0, pane.gutter - 20))
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            TripCostBar(
                trip: trip,
                actionTitle: trip.youAreOrganiser ? "Add booking" : "Invite people",
                actionSymbol: trip.youAreOrganiser ? "plus" : "person.badge.plus",
                action: {
                    if trip.youAreOrganiser { beginAdding() } else { showShare = true }
                }
            )
            .padding(.horizontal, pane.gutter)
            .padding(.bottom, 14)
        }
    }

    private func planHeader(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(trip.title) · \(trip.dayCount)-day plan")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 8) {
                PillTab(value: Section.timeline, title: "Itinerary", selection: $section, namespace: pillSpace)
                PillTab(value: Section.ledger, title: "Ledger", selection: $section, namespace: pillSpace)

                Spacer(minLength: 12)

                if section == .timeline {
                    let mine = trip.items.filter { isYours($0, in: trip) }.count

                    scopeChip(.group, "Everyone", trip.items.count)
                    scopeChip(.mine, "Just you", mine)

                }
            }
        }
    }

    // MARK: - Timeline

    @ViewBuilder
    private func timeline(for trip: Trip, showsScope: Bool) -> some View {
        if showsScope { scopeFilter(for: trip) }

        let days = visibleDays(of: trip)

        if days.isEmpty {
            noBookings(for: trip)
        } else {
            ForEach(days) { day in
                DayHeader(day: day, isCollapsed: collapsedDays.contains(day.id)) {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                        if collapsedDays.contains(day.id) {
                            collapsedDays.remove(day.id)
                        } else {
                            collapsedDays.insert(day.id)
                        }
                    }
                }

                if !collapsedDays.contains(day.id) {
                    ForEach(Array(day.items.enumerated()), id: \.element.id) { index, item in
                        let isLastOfDay = index == day.items.count - 1
                        let row = TimelineRow(
                            item: item,
                            trip: trip,
                            isLast: isLastOfDay && day.id == days.last?.id,
                            closesDay: isLastOfDay
                        )

                        Button { viewingItem = item } label: { row }
                            .buttonStyle(PressableButtonStyle())
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))

                    // After the day's bookings, because that's when it
                    // happened — somebody's last day includes everything on
                    // it. Only in the group view: "just you" is a filter on
                    // your own bookings, and other people's comings and goings
                    // aren't part of that question.
                    if scope == .group {
                        let leaving = trip.departures(on: day.date)
                            .compactMap { trip.traveller($0.travellerID) }

                        if !leaving.isEmpty {
                            DepartureMarker(travellers: leaving, isLast: day.id == days.last?.id)
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Banner

    /// The destination, as a banner rather than a poster.
    ///
    /// It used to be 340pt of photograph with a summary bar under it — better
    /// than half the screen before a single booking appeared, on a screen whose
    /// entire job is the bookings. A trip does deserve to look like somewhere
    /// rather than like a spreadsheet, so the picture stays; it just stops
    /// being the content.
    ///
    /// The two figures sit *on* it now instead of in a white strip below,
    /// which is what buys most of the height back. They're legible there
    /// because of the progressive blur rather than a black gradient — see
    /// `ProgressiveBlur`. The bottom of the photograph goes out of focus, the
    /// colour of the place survives, and small white type has nothing
    /// fine-grained left to fight.
    private func banner(for trip: Trip) -> some View {
        let height: CGFloat = 320

        return GeometryReader { proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let stretch = max(0, minY)

            DestinationImage(
                query: trip.destination,
                photo: trip.cover,
                fallbackSymbol: trip.symbol,
                fallbackTint: trip.tint,
                onResolve: { store.setCover($0, for: trip.id) }
            )
            .frame(width: proxy.size.width, height: height + stretch)
            .clipped()
            .offset(y: -stretch)
        }
        .frame(height: height)
        // Overlays hang off the outer frame, not the stretching image, so the
        // title stays put while the photograph grows behind it.
        // The ramp is confined to the bottom half. Run across the whole banner
        // it turns the photograph into a grey panel, which defeats the point of
        // having one.
        .overlay { ProgressiveBlur(edge: .bottom, begins: 0.44, scrim: 0.34) }
        .overlay(alignment: .bottomLeading) { bannerContent(for: trip) }
    }

    private func bannerContent(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 10.5, weight: .bold))
                Text(trip.destination.isEmpty ? "Destination not set" : trip.destination)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.85))

            Text(trip.title)
                .font(AppTheme.display(27))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 3)

            HStack(spacing: 9) {
                Text("\(trip.dateRange) · \(trip.dayCount) days")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Spacer(minLength: 4)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showTravellers = true
                } label: {
                    AvatarStack(travellers: trip.travellers, size: 24, max: 4, departedIDs: trip.departedIDs)
                        .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 5)

            Rectangle()
                .fill(.white.opacity(0.22))
                .frame(height: 1)
                .padding(.top, 12)

            HStack(spacing: 0) {
                bannerFigure(
                    value: trip.projectedLabel,
                    label: "Projected cost"
                )

                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 1, height: 26)
                    .padding(.horizontal, 14)

                bannerFigure(
                    value: Money.format(trip.yourShare.rounded(), code: trip.currencyCode),
                    label: "Your share"
                )
            }
            .padding(.top, 11)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)
        .padding(.horizontal, 20)
        // The photograph runs to the edges of the screen; the type on it lines
        // up with the timeline underneath instead, so the trip's name and the
        // first booking share a left margin rather than missing it by 27pt.
        // A no-op on a phone, where the page has no measure to line up with.
        .pageWidth()
        .padding(.bottom, 16)
    }

    private func bannerFigure(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Scope

    /// Whose plan you're reading. A filter, not a mode.
    ///
    /// This was a full-width segmented control directly under a second
    /// full-width segmented control, which made the screen look like it had two
    /// levels of navigation stacked on top of each other. It only ever hides
    /// rows, so it's sized like the thing it is: two small chips, secondary to
    /// the section switch above them.
    private func scopeFilter(for trip: Trip) -> some View {
        let mine = trip.items.filter { isYours($0, in: trip) }.count

        return HStack(spacing: 8) {
            scopeChip(.group, "Everyone", trip.items.count)
            scopeChip(.mine, "Just you", mine)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }

    private func scopeChip(_ value: Scope, _ title: String, _ count: Int) -> some View {
        let on = scope == value

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { scope = value }
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .opacity(0.65)
            }
            .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 6.5)
            .background {
                Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
            }
            .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07)) }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty states

    private func noBookings(for trip: Trip) -> some View {
        VStack(spacing: 11) {
            Image(systemName: scope == .mine ? "person.crop.circle.badge.questionmark" : "calendar.badge.plus")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.inkTertiary)

            Text(scope == .mine ? "You're not on anything yet" : "Nothing booked yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(
                scope == .mine
                    ? "The group has \(trip.items.count.pluralised("booking")), but none of them list you."
                    : "Add flights, stays and activities and they'll line up here."
            )
            .font(.system(size: 13.5))
            .foregroundStyle(AppTheme.inkSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 34)
        .readableWidth()
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            IconTile(symbol: "map.fill", tint: AppTheme.accent, size: 58, corner: 19)

            Text("No trip yet")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("Create one from Home and its itinerary lands here.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .readableWidth()
    }

    // MARK: - Top bar

    /// Back on the left, everything you can *do* to the trip on the right —
    /// as one pill rather than three separate discs.
    ///
    /// Three glass circles in a row read as three unrelated decisions floating
    /// over the photograph, and each one needed its own tap target carved out
    /// of a busy image. Grouped into a single capsule with hairlines between
    /// them they read as what they are: one toolbar for this trip.
    private var topBar: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 10) {
                CircleGlyphButton(symbol: "chevron.left", size: 40) { dismiss() }
                    .accessibilityLabel("Back to trips")

                Spacer(minLength: 0)

                actionCluster
            }
        }
        .padding(.horizontal, pane.gutter)
        .pageWidth()
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var actionCluster: some View {
        HStack(spacing: 0) {
            clusterButton(symbol: "person.badge.plus", label: "Invite people") {
                showShare = true
            }

            if let trip, trip.youAreOrganiser {
                clusterDivider

                clusterButton(symbol: "plus", label: "Add booking") {
                    beginAdding()
                }

                clusterDivider

                clusterButton(symbol: "slider.horizontal.3", label: "Edit trip") {
                    showEditor = true
                }
            }
        }
        .frame(height: 40)
        .glassEffect(.regular, in: .capsule)
        // Animated so the two organiser-only controls slide out of the pill
        // rather than the pill snapping to a new width.
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: trip?.youAreOrganiser)
    }

    private func clusterButton(
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .frame(width: 44, height: 40)
                .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label)
    }

    private var clusterDivider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.12))
            .frame(width: 1, height: 18)
    }

    // MARK: - Adding

    /// Which day a new booking lands on: today while the trip is running,
    /// otherwise its first day.
    private func addDay(for trip: Trip) -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return trip.phase == .live ? today : max(trip.startDate, today)
    }

    /// Quick add is only offered mid-trip.
    ///
    /// Before the first day nothing has "just happened" — everything being
    /// entered is a booking made in advance, which is the case the full editor
    /// exists for, with its dates and vendors and flight numbers. Offering a
    /// "log this now" form for a hotel you booked last month would just be a
    /// form missing half its fields.
    private func beginAdding() {
        guard let trip else { return }

        let seed = ItineraryItem(
            title: "",
            date: addDay(for: trip),
            participantIDs: Set(trip.travellers.map(\.id))
        )

        if trip.phase == .live {
            quickAdd = seed
        } else {
            detailedAdd = seed
        }
    }

    // MARK: - Scope

    private func visibleDays(of trip: Trip) -> [TripDay] {
        guard scope == .mine else { return trip.days }

        return trip.days.compactMap { day in
            let mine = day.items.filter { isYours($0, in: trip) }
            return mine.isEmpty ? nil : TripDay(index: day.index, date: day.date, items: mine)
        }
    }

    private func isYours(_ item: ItineraryItem, in trip: Trip) -> Bool {
        // An item with nobody named is a whole-group cost, so it's yours too.
        item.participantIDs.isEmpty || item.participantIDs.contains(Traveller.you.id)
    }
}

/// Icon and text with a fixed-width icon column, so the lines under the trip
/// name start their words on the same left edge.
private struct SheetLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .font(.system(size: 13, weight: .medium))
                .frame(width: 18)
            configuration.title
        }
    }
}

#Preview {
    RootTabView(userName: "Swastik Patil")
}
