//
//  WeatherTwinView.swift
//  Equitrip
//

import SwiftUI
import MapKit

/// A trip's Weather Twin: the map of where everything is and what the weather
/// is doing to it, with the live picture and the what-if lab in one panel.
///
/// Two modes over one map. **Live** is the twin mirroring the world — station
/// readings, the forecast, ground reports — and what that means for each
/// booking. **What-if** is the same twin handed weather that isn't forecast:
/// drag the rain up and the map's lines redden, the cascade grows, the money
/// moves. The trip itself is never touched; the banner in what-if says so,
/// and the only way anything reaches the plan is a person choosing an action
/// and finishing it on the ordinary screens.
struct WeatherTwinView: View {
    let tripID: UUID

    @Environment(\.tripStore) private var store
    @Environment(\.weatherTwin) private var twinStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pane) private var pane

    enum Mode: Hashable { case live, whatIf }

    @State private var mode: Mode = .live
    @State private var scenario = TwinScenario.Preset.monsoonBurst.scenario
    @State private var whatIf: TwinResult?
    @State private var detent: TwinPanelDetent = .half
    @State private var selection: UUID?
    /// A ground-report pin that's been tapped, by the place it names.
    @State private var signalSelection: String?
    @State private var camera: MapCameraPosition = .automatic
    @State private var showsWholeRoute = false
    @State private var chat: ChatDraft?
    @State private var editing: ItineraryItem?
    @State private var pending: Task<Void, Never>?
    /// Whether the what-if answer card is on screen; when it isn't, the
    /// panel header carries its figures.
    @State private var impactVisible = true

    private struct ChatDraft: Identifiable {
        let id = UUID()
        let text: String
    }

    private var trip: Trip? { store.trip(tripID) }
    private var state: WeatherTwinStore.TripState? { twinStore.state(for: tripID) }

    private var displayed: TwinResult? {
        mode == .live ? state?.live : (whatIf ?? state?.live)
    }

    var body: some View {
        ZStack {
            CanvasBackground()

            if let twin = state?.twin {
                TwinMap(
                    twin: twin,
                    result: displayed,
                    weather: state?.weather ?? [:],
                    digest: state?.digest ?? .empty,
                    scenario: mode == .whatIf ? scenario : TwinScenario(),
                    selection: $selection,
                    signalSelection: $signalSelection,
                    camera: $camera
                )
                .ignoresSafeArea()
            } else {
                placeholder
            }

            TwinPanel(detent: $detent, resetKey: mode) {
                panelHeader
            } content: {
                panelContent
            }
        }
        .overlay(alignment: .top) {
            if pane.isWide {
                // Top bar across the window; the callout floats over the map,
                // beside the column rather than on top of it.
                VStack(spacing: 10) {
                    topBar
                    if let callout = activeCallout {
                        callout
                            .frame(maxWidth: 440)
                            .padding(.leading, pane.twinColumnFootprint - 16)
                            .frame(maxWidth: .infinity)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, PaneMetrics.twinColumnInset)
            } else {
                VStack(spacing: 10) {
                    topBar
                    // Pulled up full, the panel reaches the top bar: a callout
                    // there sat over the mode picker. The expanded row says it.
                    if detent != .full, let callout = activeCallout {
                        callout
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: selection)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: signalSelection)
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: detent)
        .task(id: tripID) {
            guard let trip else { return }
            await twinStore.refresh(trip)
            frameMap()
        }
        .onChange(of: scenario) { _, _ in scheduleSimulation() }
        .onChange(of: mode) { _, newMode in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            impactVisible = true
            if newMode == .whatIf {
                if whatIf == nil { runSimulation() }
                if detent == .peek { withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { detent = .half } }
            }
        }
        .onChange(of: state?.updatedAt) { _, _ in
            if mode == .whatIf { runSimulation() }
            frameMap()
        }
        // An edited booking rebuilds the graph on the weather already here,
        // without a new `updatedAt`; the what-if has to follow it too.
        .onChange(of: state?.signature) { _, _ in
            if mode == .whatIf { runSimulation() }
        }
        // Ground reports land after the weather; the what-if weighs them too.
        .onChange(of: state?.digest.fetchedAt) { _, _ in
            if mode == .whatIf { runSimulation() }
        }
        .fullScreenCover(item: $chat) { draft in
            if let trip { TripChatView(trip: trip, draft: draft.text) }
        }
        .sheet(item: $editing) { item in
            if let trip {
                ItineraryItemEditor(
                    item: item,
                    travellers: trip.travellers,
                    organiserIDs: trip.organiserIDs,
                    currencyCode: trip.currencyCode,
                    onSave: {
                        store.updateItem($0, in: trip.id)
                        refreshAfterEdit()
                    }
                )
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 10) {
            CircleGlyphButton(symbol: "xmark", size: 42) { dismiss() }
                .accessibilityLabel("Close weather twin")

            VStack(alignment: .leading, spacing: 0) {
                Text("Weather Twin")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(trip?.title ?? "")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .glassEffect(.regular, in: .capsule)

            Spacer(minLength: 0)

            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    CircleGlyphButton(symbol: showsWholeRoute ? "scope" : "arrow.up.left.and.arrow.down.right", size: 42) {
                        showsWholeRoute.toggle()
                        frameMap()
                    }
                    .accessibilityLabel(showsWholeRoute ? "Focus on the destination" : "Show the whole route")

                    GlassCircleButton(size: 42) {
                        guard let trip else { return }
                        Task { await twinStore.refresh(trip, force: true) }
                    } content: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .rotationEffect(.degrees(state?.phase.isWorking == true ? 360 : 0))
                            .animation(
                                state?.phase.isWorking == true ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: state?.phase.isWorking
                            )
                    }
                    .accessibilityLabel("Refresh")
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Panel

    private var panelHeader: some View {
        VStack(spacing: 10) {
            Picker("Mode", selection: $mode.animation(.spring(response: 0.35, dampingFraction: 0.85))) {
                Text("Live").tag(Mode.live)
                Text("What if").tag(Mode.whatIf)
            }
            .pickerStyle(.segmented)

            ZStack { statusLine }
                .frame(height: 20)
                .animation(.default, value: statusKey)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    /// One line under the picker. In what-if it becomes the answer itself
    /// once the answer card has scrolled away, so a dial far down the panel
    /// still shows what it's doing to the trip as it moves.
    private var statusLine: some View {
        HStack(spacing: 7) {
            if let phase = state?.phase, phase.isWorking {
                ProgressView().controlSize(.mini)
                Text(phase.label)
            } else if case .failed(let message) = state?.phase {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(AppTheme.danger)
                Text(message)
            } else if mode == .whatIf, let whatIf, let trip {
                if impactVisible {
                    Image(systemName: "lock.fill").font(.system(size: 9.5, weight: .bold))
                    Text("A simulation — nothing on the trip changes")
                } else {
                    Circle().fill(whatIf.risk.tint).frame(width: 7, height: 7)
                    Text("\(Int(whatIf.affected.p50.rounded())) of \(whatIf.outcomes.count) bookings hit · \(Money.format(whatIf.valueAtRisk.p50, code: trip.currencyCode)) at risk")
                        .foregroundStyle(AppTheme.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            } else if let live = state?.live {
                Circle().fill(live.risk.tint).frame(width: 7, height: 7)
                Text("\(live.risk.label) · updated \(TwinFormat.ago(state?.updatedAt))")
            } else {
                ProgressView().controlSize(.mini)
                Text("Starting the twin")
            }
        }
        .font(.system(size: 12.5, weight: .medium))
        .foregroundStyle(AppTheme.inkSecondary)
        .lineLimit(1)
        // One line swapped for another, never both drawn at once: a plain
        // crossfade stacked them mid-animation.
        .id(statusKey)
        .transition(.asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.18).delay(0.1)),
            removal: .opacity.animation(.easeIn(duration: 0.1))
        ))
    }

    private var statusKey: String {
        if state?.phase.isWorking == true { return "working" }
        if case .failed = state?.phase { return "failed" }
        return mode == .whatIf ? (impactVisible ? "sim" : "answer") : "live"
    }

    @ViewBuilder
    private var panelContent: some View {
        if let trip, let state, let live = state.live, let twin = state.twin {
            VStack(alignment: .leading, spacing: 24) {
                switch mode {
                case .live:
                    liveContent(trip: trip, state: state, live: live, twin: twin)
                case .whatIf:
                    whatIfContent(trip: trip, state: state, live: live, twin: twin)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.88), value: mode)
        } else if case .failed(let message) = state?.phase {
            ConnectionBanner(message: message) {
                guard let trip else { return }
                Task { await twinStore.refresh(trip, force: true) }
            }
        } else {
            TwinLoadingCards(phase: state?.phase ?? .idle)
        }
    }

    private func section<Content: View>(_ title: String, caption: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: title, caption: caption)
                .padding(.horizontal, 4)
            content()
        }
    }

    // MARK: Live

    /// The answer first, then what's behind it: the weather now, what it does
    /// to the plan, what's been chosen about it, and only then the forecast
    /// detail and the ground reports it was built from.
    @ViewBuilder
    private func liveContent(trip: Trip, state: WeatherTwinStore.TripState, live: TwinResult, twin: TripTwin) -> some View {
        VStack(spacing: 12) {
            if let destination = state.weather["dest"] {
                TwinNowCard(place: destination)
            }
            TwinImpactCard(result: live, twin: twin, currencyCode: trip.currencyCode, onFocus: focus)
        }

        if !live.notable.isEmpty {
            section("At risk", caption: live.notable.count.pluralised("booking")) {
                TwinBookingList(
                    outcomes: live.notable,
                    twin: twin,
                    selection: selection,
                    actions: Dictionary(uniqueKeysWithValues: live.notable.map { ($0.id, twinStore.actions.actions(for: $0.id, in: trip.id)) }),
                    canRun: { canRun($0, on: trip) },
                    onToggle: { twinStore.actions.toggleQueued($0) },
                    onRun: { run($0, on: trip) },
                    onFocus: focus,
                    onEdit: { node in editing = store.trip(tripID)?.items.first { $0.id == node.id } },
                    canEdit: { trip.youCanEdit($0.item) }
                )
            }
        }

        let planB = twinStore.actions.planB(for: trip.id)
        if !planB.isEmpty {
            section("Plan B", caption: "Nothing changes until you finish one") {
                PlanBTray(
                    actions: planB,
                    canRun: { canRun($0, on: trip) },
                    onRun: { run($0, on: trip) },
                    onRemove: { twinStore.actions.set(.suggested, for: $0) }
                )
            }
        }

        if let destination = state.weather["dest"] {
            let hours = destination.upcomingHours(24)
            if hours.count >= 8, trip.phase != .past {
                section("Next 24 hours") {
                    TwinHourlyCard(hours: hours, bookings: twin.nodes)
                }
            }
            let days = tripDays(destination, trip: trip)
            if !days.isEmpty {
                section("Trip days", caption: basisCaption(live.basis)) {
                    TwinDaysCard(days: days, riskByDay: riskByDay(live, twin: twin))
                }
            }
        }

        section("On the ground", caption: "last 3 days") {
            SocialPulseCard(digest: state.digest, places: twin.placeNames)
        }

        TwinSourcesCard(
            weather: Array(state.weather.values),
            destination: state.weather["dest"],
            calibrationCount: twinStore.learning.calibration.observationCount,
            updatedAt: state.updatedAt
        )
    }

    // MARK: What-if

    /// Cause, then effect, then the fine print of the cause: pick a weather
    /// and the answer is directly under it; the timing and the dials come
    /// after for anyone who wants to shape it, with the header carrying the
    /// answer while they do.
    @ViewBuilder
    private func whatIfContent(trip: Trip, state: WeatherTwinStore.TripState, live: TwinResult, twin: TripTwin) -> some View {
        section("Choose the weather") {
            VStack(spacing: 12) {
                ScenarioPresetGrid(scenario: $scenario)
                ScenarioSkyCard(scenario: scenario)
            }
        }

        // The dials are for building your own weather; a preset is already
        // a complete answer, and four dials under it were noise. Straight under
        // the picker, because choosing "Your own" is what brings them in.
        if scenario.preset == nil {
            section("How strong", caption: "each dial starts at the forecast") {
                ScenarioStrengthCard(
                    scenario: $scenario,
                    forecastHigh: state.weather["dest"].flatMap { tripDays($0, trip: trip).map(\.high).max() }
                )
            }
        }

        if let whatIf {
            TwinImpactCard(result: whatIf, baseline: live, twin: twin, currencyCode: trip.currencyCode, onFocus: focus)
                .onScrollVisibilityChange(threshold: 0.35) { impactVisible = $0 }
        }

        section("When it hits") {
            ScenarioTimingCard(
                scenario: $scenario,
                days: tripDayDates(trip),
                places: twin.weatherPlaces,
                markers: timingMarkers(twin, result: whatIf)
            )
        }

        if let whatIf, !whatIf.notable.isEmpty {
            let planned = Dictionary(
                grouping: twinStore.actions.resolved(twinStore.plan(for: whatIf, trip: trip)).filter { $0.status != .dismissed },
                by: \.itemID
            )
            section("Bookings it hits", caption: whatIf.notable.count.pluralised("booking")) {
                TwinBookingList(
                    outcomes: whatIf.notable,
                    twin: twin,
                    selection: selection,
                    actions: planned,
                    canRun: { canRun($0, on: trip) },
                    onToggle: { twinStore.actions.toggleQueued($0) },
                    onRun: { run($0, on: trip) },
                    onFocus: focus,
                    onEdit: { node in editing = store.trip(tripID)?.items.first { $0.id == node.id } },
                    canEdit: { trip.youCanEdit($0.item) }
                )
            }
        }
    }

    // MARK: - Selection callout

    /// A booking's callout, or a tapped alert's — the map allows one at a time.
    private var activeCallout: AnyView? {
        if let selection { return callout(for: selection) }
        guard let place = signalSelection, let digest = state?.digest else { return nil }
        let signals = digest.signals.filter { $0.place.lowercased() == place }
        guard !signals.isEmpty else { return nil }
        return AnyView(SignalAlertCallout(signals: signals) { signalSelection = nil })
    }

    private func callout(for id: UUID) -> AnyView? {
        guard let node = state?.twin?.node(id) else { return nil }
        let outcome = displayed?.outcomes[id]
        let hour = trip.flatMap { twinStore.hour(for: node.item, in: $0.id) }

        return AnyView(
            HStack(spacing: 12) {
                SymbolBadge(symbol: node.item.symbol, tint: node.item.kind.tint, size: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.item.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let hour {
                            Image(systemName: hour.condition.symbol())
                                .symbolRenderingMode(.multicolor)
                            Text("\(TwinFormat.temperature(hour.temperature)) · \(TwinFormat.rain(hour.precipitation)) mm")
                                .fixedSize()
                        }
                        Text(node.place.isApproximate ? "Approximate spot" : (node.place.locality ?? node.place.name))
                            .lineLimit(1)
                    }
                    .lineLimit(1)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                }
                Spacer(minLength: 6)
                if let outcome {
                    RiskPill(risk: outcome.risk, probability: outcome.pAffected)
                }
                Button {
                    selection = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .frame(width: 26, height: 26)
                        .background(AppTheme.cardStroke.opacity(0.06), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(12)
            // The tint in the glass's own shape: a plain background drew
            // square corners out past the rounded glass.
            .glassEffect(.regular.tint(AppTheme.card.opacity(0.7)), in: .rect(cornerRadius: 22, style: .continuous))
        )
    }

    // MARK: - Placeholder

    private var placeholder: some View {
        ZStack {
            WeatherSky(condition: .partlyCloudy)
                .ignoresSafeArea()
            VStack(spacing: 10) {
                ProgressView().controlSize(.large).tint(.white)
                Text(state?.phase.label.isEmpty == false ? state!.phase.label : "Building the twin")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(22)
            .background(.black.opacity(0.25), in: .rect(cornerRadius: 20, style: .continuous))
            .offset(y: -120)
        }
    }

    // MARK: - Simulation

    private func scheduleSimulation() {
        pending?.cancel()
        pending = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            guard !Task.isCancelled else { return }
            runSimulation()
        }
    }

    private func runSimulation() {
        guard let trip else { return }
        // A short ease rather than a spring: the figures roll and the rows
        // settle, without a half-second of layout animation on every dial tick.
        let next = twinStore.simulate(scenario, for: trip)
        withAnimation(.easeOut(duration: 0.22)) { whatIf = next }
    }

    // MARK: - Actions

    private func canRun(_ action: TwinAction, on trip: Trip) -> Bool {
        twinStore.actions.canExecute(action) || TwinAgentJobs.canRun(action, on: trip)
    }

    private func run(_ action: TwinAction, on trip: Trip) {
        if TwinAgentJobs.kinds.contains(action.kind) {
            runWithEqui(action, on: trip)
            return
        }
        Task {
            guard let presentation = await twinStore.actions.execute(action, on: trip) else { return }
            switch presentation {
            case .chat(let draft): chat = ChatDraft(text: draft)
            case .booking: break
            }
        }
    }

    /// Hands the screen to Equi for an action it can carry out itself. The
    /// answer lands here as a toast, not in the Equi tab — this is the screen
    /// that asked, and the tab bar is under this cover.
    private func runWithEqui(_ action: TwinAction, on trip: Trip) {
        let agent = EquiAgent.shared
        guard !agent.isRunning else {
            GlassToastCenter.shared.show(.init(symbol: "hourglass", tint: AppTheme.inkSecondary, title: "Equi is busy", subtitle: "It's still finishing the last job."))
            return
        }
        let twin = state?.twin
        guard let task = TwinAgentJobs.task(
            for: action,
            trip: trip,
            spot: twin?.node(action.itemID)?.place,
            city: twin?.destination.name ?? trip.destination,
            store: store,
            screen: .init(raisePanel: {
                guard !pane.isWide, detent == .peek else { return }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { detent = .half }
            })
        ) else { return }

        twinStore.actions.set(.running, for: action)
        agent.start(task) { outcome, chat in
            twinStore.actions.set(outcome?.changedTrip == true ? .done : .queued, for: action)
            GlassToastCenter.shared.show(.init(
                symbol: outcome == nil ? "exclamationmark.triangle.fill" : action.kind.symbol,
                tint: outcome == nil ? AppTheme.danger : action.kind.tint,
                title: outcome?.title ?? "Equi stopped",
                subtitle: chat,
                duration: .seconds(6)
            ))
            if outcome?.changedTrip == true { refreshAfterEdit() }
        }
    }

    /// The twin notices an edited booking on its next refresh; this is that
    /// refresh, once the store has the new version.
    private func refreshAfterEdit() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard let fresh = store.trip(tripID) else { return }
            await twinStore.refresh(fresh)
        }
    }

    // MARK: - Map framing

    private func focus(on node: TwinNode) {
        signalSelection = nil
        selection = node.id
        // Phone: nudged south so the pin clears the sheet. iPad: west, so it
        // clears the column.
        let nudge = pane.isWide ? node.place.point.offset(km: 1.4, bearing: 270) : node.place.point.offset(km: 1.2, bearing: 180)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            camera = .region(MKCoordinateRegion(
                center: nudge.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            ))
        }
    }

    /// The destination's cluster, not the whole route — a trip's outbound
    /// flight from another city would otherwise shrink the place itself to a
    /// dot. The centre is nudged south so the pins sit above the panel.
    private func frameMap() {
        guard let twin = state?.twin else { return }
        let nearby: (GeoPoint) -> Bool = { showsWholeRoute || $0.distance(to: twin.destination.point) < 150 }
        var points = [twin.destination.point] + (state?.weather.values.map(\.point) ?? []).filter(nearby)
        points += twin.nodes.map(\.place.point).filter(nearby)
        let lats = points.map(\.latitude), lons = points.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else { return }
        let span = max(maxLat - minLat, maxLon - minLon, 0.05) * 1.5
        let panelShift = pane.isWide ? 0 : span * 0.32
        // On a wide window the column covers the map's left side: move the
        // centre west by half of what it covers, so the pins sit in the rest.
        let columnShare = pane.isWide ? pane.twinColumnFootprint / max(pane.width, 1) : 0
        let lonShift = span * columnShare / max(1 - columnShare, 0.3) * 0.5
        withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
            camera = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2 - panelShift, longitude: (minLon + maxLon) / 2 - lonShift),
                span: MKCoordinateSpan(latitudeDelta: span * 1.3, longitudeDelta: span)
            ))
        }
    }

    // MARK: - Helpers

    /// Bookings with a start time, placed on the what-if timing track and
    /// coloured by what the what-if does to them.
    private func timingMarkers(_ twin: TripTwin, result: TwinResult?) -> [ScenarioTimingCard.Marker] {
        twin.nodes.compactMap { node in
            guard let time = node.item.time else { return nil }
            if let result, result.outcomes[node.id] == nil { return nil }
            let clock = Calendar.current.dateComponents([.hour, .minute], from: time)
            return ScenarioTimingCard.Marker(
                id: node.id,
                title: node.item.title,
                day: node.item.day,
                hour: Double(clock.hour ?? 0) + Double(clock.minute ?? 0) / 60,
                symbol: node.item.symbol,
                risk: result?.outcomes[node.id]?.risk
            )
        }
    }

    private func tripDays(_ place: PlaceWeather, trip: Trip) -> [WeatherDay] {
        let start = Calendar.current.startOfDay(for: trip.startDate)
        let end = Calendar.current.startOfDay(for: trip.endDate)
        return place.days.filter { $0.date >= start && $0.date <= end }
    }

    private func tripDayDates(_ trip: Trip) -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        return (0..<min(trip.dayCount, 21)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func riskByDay(_ result: TwinResult, twin: TripTwin) -> [Date: RiskLevel] {
        var map: [Date: RiskLevel] = [:]
        for outcome in result.outcomes.values {
            guard let node = twin.node(outcome.id) else { continue }
            map[node.item.day] = max(map[node.item.day] ?? .calm, outcome.risk)
        }
        return map
    }

    private func basisCaption(_ basis: WeatherHour.Basis?) -> String? {
        switch basis {
        case .seasonal: "from last year's weather"
        case .observed: "as observed"
        default: nil
        }
    }
}

/// The panel while the twin is still being built: the shapes of the cards
/// to come, so nothing jumps when they arrive.
struct TwinLoadingCards: View {
    let phase: WeatherTwinStore.Phase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .frame(height: 150)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .frame(height: 170)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .frame(height: 200)
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                ProgressView()
                Text(phase.label.isEmpty ? "Starting the twin" : phase.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .padding(.top, 80)
        }
        .redacted(reason: .placeholder)
    }
}
