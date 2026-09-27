//
//  TwinAgentJobs.swift
//  Equitrip
//

import Foundation

/// The Plan B actions Equi carries out with its hands on the app: swap an
/// outdoor plan for somewhere indoors, move it to a drier slot, leave earlier.
///
/// Each is the path a person would take from the Weather Twin — open the
/// booking's row, press Edit, change the fields, Save — so the change goes
/// through the editor's own save, toast and audit row like any other edit.
/// Equi decides only what it can check: the place comes from Apple Maps
/// (`IndoorScout`), the time from the forecast the planner already read. The
/// choice between places is the group's, asked mid-run; the cost is never
/// touched, since what the new place charges is something only a person knows.
@MainActor
enum TwinAgentJobs {

    static let kinds: Set<TwinAction.Kind> = [.swapIndoor, .reschedule, .addBuffer]

    /// What the twin's screen does for a run that Equi can't do by pressing.
    struct Screen {
        /// Brings the panel up far enough for the booking list to show.
        var raisePanel: () -> Void
    }

    static func canRun(_ action: TwinAction, on trip: Trip) -> Bool {
        // The same rule that offers a person the editor: Equi works it with
        // your hands, so it can't change what you couldn't.
        guard kinds.contains(action.kind), let item = trip.items.first(where: { $0.id == action.itemID }),
              trip.youCanEdit(item) else { return false }
        switch action.kind {
        case .swapIndoor: return true
        case .reschedule: return action.payload.suggestedStart != nil
        case .addBuffer: return action.payload.bufferMinutes != nil && item.time != nil
        default: return false
        }
    }

    static func task(
        for action: TwinAction,
        trip: Trip,
        spot: TwinGeocoder.Place?,
        city: String,
        store: TripStore,
        screen: Screen
    ) -> EquiAgentTask? {
        guard canRun(action, on: trip), let item = trip.items.first(where: { $0.id == action.itemID }) else { return nil }
        switch action.kind {
        case .swapIndoor:
            guard let spot else { return nil }
            return swapIndoor(item, trip: trip, spot: spot, city: city, store: store, screen: screen)
        case .reschedule:
            guard let start = action.payload.suggestedStart else { return nil }
            return reschedule(item, to: start, action: action, trip: trip, store: store, screen: screen)
        case .addBuffer:
            guard let time = item.time, let minutes = action.payload.bufferMinutes else { return nil }
            return leaveEarlier(item, by: minutes, from: time, trip: trip, store: store, screen: screen)
        default:
            return nil
        }
    }

    // MARK: - Swap indoors

    private static func swapIndoor(
        _ item: ItineraryItem,
        trip: Trip,
        spot: TwinGeocoder.Place,
        city: String,
        store: TripStore,
        screen: Screen
    ) -> EquiAgentTask {
        EquiAgentTask(
            title: "Finding somewhere indoors",
            symbol: "building.2.fill",
            steps: 11,
            opening: "",
            tripID: trip.id,
            cleanup: ["editor.close"],
            returnsToChat: false
        ) { agent in
            agent.setContext("\(EquiAgentJobs.short(trip)) · \(item.title)", tripID: trip.id)
            try await agent.note("Reading “\(item.title)” — \(when(item)), near \(spot.name)", symbol: "text.magnifyingglass")

            let found = try await IndoorScout.scout(for: item, at: spot, city: city, trip: trip) { @MainActor text, symbol in
                try? await agent.note(text, symbol: symbol)
            }
            guard !found.candidates.isEmpty else {
                throw EquiAgentError(message: "I couldn't find anywhere under a roof within 8 km of \(spot.name) on Apple Maps, so \(item.title) is unchanged.")
            }

            let keep = "keep"
            let option = try await agent.ask(EquiAgentQuestion(
                text: found.rankedByModel ? "Best fit first — swap “\(item.title)” for?" : "Closest first — swap “\(item.title)” for?",
                options: found.candidates.prefix(3).map { .init(id: $0.id, label: "\($0.name) · \($0.shortDistance)", symbol: $0.symbol) }
                    + [.init(id: keep, label: "Keep it as it is", symbol: "xmark")]
            ))
            guard option.id != keep, let pick = found.candidates.first(where: { $0.id == option.id }) else {
                return EquiAgentOutcome(
                    title: "Kept the plan",
                    headline: item.title,
                    value: "Unchanged",
                    detail: "Nothing on the trip changed.",
                    chat: "Left “\(item.title)” as it was.",
                    tripID: trip.id,
                    changedTrip: false
                )
            }

            let title = IndoorScout.title(for: pick, replacing: item)
            var updated = item
            updated.title = title
            updated.vendor = pick.name

            try await openEditor(for: item, agent: agent, screen: screen)
            try await agent.type(title, into: "editor.title", "Renaming it “\(title)”", symbol: "character.cursor.ibeam")
            try await agent.type(pick.name, into: "editor.vendor", "Placing it at \(pick.name)", symbol: "mappin.and.ellipse")
            try await agent.commit("editor.save", "Saving the swap", symbol: "checkmark.circle") {
                store.updateItem(updated, in: trip.id)
            }

            let cost = item.cost > 0 ? " Cost left at \(Money.format(item.cost, code: trip.currencyCode)) — change it if \(pick.name) charges differently." : ""
            return EquiAgentOutcome(
                title: "Swapped indoors",
                headline: pick.name,
                value: pick.shortDistance,
                detail: "Same slot, \(when(item)).\(cost)",
                chat: "“\(item.title)” is now \(title), \(pick.distanceLabel) away, same slot.\(cost)",
                tripID: trip.id
            )
        }
    }

    // MARK: - Drier slot

    private static func reschedule(
        _ item: ItineraryItem,
        to start: Date,
        action: TwinAction,
        trip: Trip,
        store: TripStore,
        screen: Screen
    ) -> EquiAgentTask {
        let label = slotLabel(start)
        return EquiAgentTask(
            title: "Moving to a drier slot",
            symbol: "calendar.badge.clock",
            steps: 7,
            opening: "",
            tripID: trip.id,
            cleanup: ["editor.close"],
            returnsToChat: false
        ) { agent in
            agent.setContext("\(EquiAgentJobs.short(trip)) · \(item.title)", tripID: trip.id)
            try await agent.note("Checking \(label) against the rest of the plan", symbol: "calendar")

            // Another booking already in that slot is the group's call.
            let window = WeatherExposure.of(item).window(for: item).duration
            if let clash = trip.items.first(where: { other in
                guard other.id != item.id, let time = other.time else { return false }
                return abs(time.timeIntervalSince(start)) < max(window, 3600)
            }) {
                let option = try await agent.ask(EquiAgentQuestion(
                    text: "“\(clash.title)” is at \(clash.timeLabel ?? "that time"), close to \(DateFormatter.cached("h:mm a").string(from: start)). Move “\(item.title)” anyway?",
                    options: [.init(id: "move", label: "Move it", symbol: "calendar.badge.clock"),
                              .init(id: "keep", label: "Leave it", symbol: "xmark")]
                ))
                guard option.id == "move" else {
                    return EquiAgentOutcome(
                        title: "Kept the plan",
                        headline: item.title,
                        value: "Unchanged",
                        detail: "It would have clashed with \(clash.title).",
                        chat: "Left “\(item.title)” where it was — \(clash.title) is in that slot.",
                        tripID: trip.id,
                        changedTrip: false
                    )
                }
            }

            try await openEditor(for: item, agent: agent, screen: screen)
            try await setStart(start, of: item, agent: agent)

            var updated = item
            updated.date = start
            updated.time = start
            try await agent.commit("editor.save", "Saving the new time", symbol: "checkmark.circle") {
                store.updateItem(updated, in: trip.id)
            }

            let rain = action.payload.suggestedRain.map { " — \(rainLabel($0)) mm/h forecast" } ?? ""
            let before = action.payload.currentRain.map { " against \(rainLabel($0))" } ?? ""
            return EquiAgentOutcome(
                title: "Moved to a drier slot",
                headline: item.title,
                value: label,
                detail: "\(label)\(rain)\(before)",
                chat: "“\(item.title)” now starts \(label)\(rain)\(before).",
                tripID: trip.id
            )
        }
    }

    // MARK: - Leave earlier

    private static func leaveEarlier(
        _ item: ItineraryItem,
        by minutes: Int,
        from time: Date,
        trip: Trip,
        store: TripStore,
        screen: Screen
    ) -> EquiAgentTask {
        let start = time.addingTimeInterval(-Double(minutes) * 60)
        let clock = DateFormatter.cached("h:mm a").string(from: start)
        return EquiAgentTask(
            title: "Leaving earlier",
            symbol: "clock.arrow.2.circlepath",
            steps: 6,
            opening: "",
            tripID: trip.id,
            cleanup: ["editor.close"],
            returnsToChat: false
        ) { agent in
            agent.setContext("\(EquiAgentJobs.short(trip)) · \(item.title)", tripID: trip.id)
            try await openEditor(for: item, agent: agent, screen: screen)
            try await setStart(start, of: item, agent: agent, caption: "Leaving at \(clock) — \(minutes) min earlier")

            var updated = item
            updated.date = start
            updated.time = start
            try await agent.commit("editor.save", "Saving the earlier start", symbol: "checkmark.circle") {
                store.updateItem(updated, in: trip.id)
            }
            return EquiAgentOutcome(
                title: "Leaving earlier",
                headline: item.title,
                value: clock,
                detail: "\(minutes) min earlier, for the roads",
                chat: "“\(item.title)” now leaves at \(clock), \(minutes) minutes earlier.",
                tripID: trip.id
            )
        }
    }

    // MARK: - Shared steps

    /// From the twin's panel into the booking's editor, the way a finger goes.
    private static func openEditor(for item: ItineraryItem, agent: EquiAgent, screen: Screen) async throws {
        screen.raisePanel()
        await agent.reveal("twin-row-\(item.id)", in: "twin.scroll")
        try await agent.tap("twin.row.\(item.id)", "Opening \(item.title)", symbol: "hand.point.up.left", settle: 0.5)
        await agent.reveal("twin-edit-\(item.id)", in: "twin.scroll")
        try await agent.tap("twin.edit.\(item.id)", "Opening the booking", symbol: "square.and.pencil", settle: 0.9)
    }

    private static func setStart(_ start: Date, of item: ItineraryItem, agent: EquiAgent, caption: String? = nil) async throws {
        if item.time == nil {
            try await agent.tap("editor.hasTime", "Giving it a start time", symbol: "clock", settle: 0.35)
        }
        if !Calendar.current.isDate(start, inSameDayAs: item.date) {
            try await agent.pick(start, in: "editor.day", "Moving it to \(DateFormatter.cached("EEE d MMM").string(from: start))", symbol: "calendar")
        }
        try await agent.pick(
            start,
            in: "editor.time",
            caption ?? "Starting at \(DateFormatter.cached("h:mm a").string(from: start))",
            symbol: "clock"
        )
    }

    private static func when(_ item: ItineraryItem) -> String {
        [DateFormatter.cached("EEE d MMM").string(from: item.date), item.timeLabel].compactMap { $0 }.joined(separator: ", ")
    }

    private static func slotLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.isDateInToday(date) ? "today" : calendar.isDateInTomorrow(date) ? "tomorrow" : DateFormatter.cached("EEE d MMM").string(from: date)
        return "\(day) at \(DateFormatter.cached("h:mm a").string(from: date))"
    }

    private static func rainLabel(_ value: Double) -> String {
        value < 1 ? String(format: "%.1f", value) : String(format: "%.0f", value)
    }
}
