//
//  BookingChangeCard.swift
//  Equitrip
//

import SwiftUI

/// One booking change, told as the work the app is about to do for you.
///
/// Top to bottom: what the email says happened, the booking as it is beside
/// the booking as it will be, who it touches, and a short plan — read the
/// email, found the booking, change it, tell the others, post in the chat,
/// log it. The first two steps are already true when the card appears; the
/// rest wait for Confirm.
///
/// After Confirm, Equi's cursor walks the card: it looks at the new value,
/// then goes down the plan clicking each step off. The edit itself lands in a
/// few milliseconds, and a card that jumped straight from Confirm to Done
/// would leave the question every person asks of an agent — what did it
/// actually do? — answered by nothing. Watching a cursor tick each step is
/// how that gets read, and it's paced slowly enough to read.
struct BookingChangeCard: View {
    @Environment(\.tripStore) private var store
    @Environment(\.bookingChangeSync) private var sync

    let change: BookingChange
    /// Confirm without being asked — the "Apply changes automatically" setting.
    var runsAutomatically = false
    /// "Not now" when the card popped up by itself; "Ignore" in the list.
    var dismissTitle = "Not now"
    var apply: () -> Void
    var undo: () -> Void
    var dismissChange: () -> Void
    var choose: (BookingChange.Candidate) -> Void
    /// After the last step has ticked, or after Undo.
    var finished: () -> Void = {}

    private enum Phase: Equatable {
        case review
        case running
        case finished
        case undone
    }

    /// The booking as it stood when Confirm was pressed. After applying, the
    /// live booking *is* the "after", so the card draws from this instead.
    private struct Frozen {
        let item: ItineraryItem
        let trip: Trip
        let proposed: ItineraryItem?
    }

    @State private var phase: Phase = .review
    @State private var frozen: Frozen?
    /// Pending steps finished so far, and the one being worked on.
    @State private var completed = 0
    @State private var working: String?

    // The cursor.
    @State private var frames: [String: CGRect] = [:]
    @State private var cursorTarget: String?
    @State private var cursorPressed = false
    @State private var cursorVisible = false

    private static let ticketLabels: Set<String> = ["Day", "Time", "Cost"]
    private static let space = "bookingChangeCard"
    static let symbol = "exclamationmark.triangle"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let frozen {
                content(item: frozen.item, trip: frozen.trip, proposed: frozen.proposed)
            } else {
                switch BookingChangeApplier.standing(of: change, in: store) {
                case .ready(let item, let trip, let proposed):
                    content(item: item, trip: trip, proposed: proposed)
                        .task { await runIfAutomatic(item: item, trip: trip, proposed: proposed) }

                case .alreadyApplied(let item, _):
                    header(title: change.headline(for: item, tripCurrency: "INR"), subtitle: change.provenance)
                    note(symbol: "checkmark.circle.fill", tint: AppTheme.positive,
                         text: "\(item.title) already looks like this — someone on the trip applied it.")
                    secondaryButton("Done", action: dismissChange)

                case .bookingGone:
                    header(title: "A booking changed", subtitle: change.provenance)
                    note(symbol: "questionmark.circle", tint: AppTheme.inkTertiary,
                         text: "That booking is no longer on the trip.")
                    secondaryButton("Dismiss", action: dismissChange)

                case .needsChoice:
                    header(title: "A booking was \(change.kind == .cancelled ? "cancelled" : "changed")",
                           subtitle: change.provenance)
                    chooser
                }
            }
        }
        .padding(16)
        .coordinateSpace(.named(Self.space))
        .onPreferenceChange(FrameKey.self) { frames = $0 }
        .overlay(alignment: .topLeading) { cursor }
        .cardSurface(corner: 24)
        .animation(.snappy(duration: 0.35), value: phase)
    }

    // MARK: - The change

    @ViewBuilder
    private func content(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?) -> some View {
        let rows = BookingChangeApplier.rows(for: change, item: item, proposed: proposed, trip: trip)
        let plan = Self.plan(for: change, item: item, trip: trip, proposed: proposed, rows: rows,
                             postsToChat: sync?.postsToChat ?? true)

        header(title: change.headline(for: item, tripCurrency: trip.currencyCode),
               subtitle: [trip.title, change.provenance, change.dayText].joined(separator: " · "))

        tickets(rows.filter { Self.ticketLabels.contains($0.label) }, removed: proposed == nil, trip: trip)
        extraRows(rows.filter { !Self.ticketLabels.contains($0.label) && $0.label != "Your share" })

        affected(item: item, trip: trip, proposed: proposed)

        steps(plan)

        if change.confidence == .likely, phase == .review {
            Label("The match is on thinner evidence — worth a look before confirming", systemImage: "info.circle")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        actions(item: item, trip: trip, proposed: proposed, plan: plan)
    }

    private func header(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Badge(done: phase == .finished)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Before and after

    private func tickets(_ rows: [BookingDiffRow], removed: Bool, trip: Trip) -> some View {
        HStack(alignment: .center, spacing: 8) {
            ticket(title: "Before", rows: rows, side: .before, removed: false, trip: trip)

            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.inkTertiary)

            ticket(title: phase == .finished ? "Now" : "After", rows: rows, side: .after, removed: removed, trip: trip)
                .reportFrame("after")
        }
    }

    private enum Side { case before, after }

    private func ticket(title: String, rows: [BookingDiffRow], side: Side, removed: Bool, trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.inkTertiary)
                .contentTransition(.opacity)
                .padding(.bottom, 1)

            if removed {
                Text("Off the plan")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
                Text(change.refund.map { "\(Money.format($0, code: change.currencyCode ?? trip.currencyCode)) refund" }
                     ?? "No refund mentioned")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
            } else {
                ForEach(rows) { row in
                    let value = side == .before ? row.before : row.after
                    Text(value)
                        .font(.system(size: row.label == "Day" ? 13 : 14.5,
                                      weight: row.changed && side == .after ? .semibold : .medium,
                                      design: row.label == "Cost" ? .rounded : .default))
                        .strikethrough(row.changed && side == .before, color: AppTheme.inkTertiary)
                        .foregroundStyle(row.changed ? (side == .after ? AppTheme.accent : AppTheme.inkTertiary) : AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
        .padding(11)
        .background(
            side == .before ? AppTheme.card.opacity(0.6)
                : (removed ? AppTheme.danger.opacity(0.07) : AppTheme.accent.opacity(phase == .finished ? 0.1 : 0.06)),
            in: .rect(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(side == .after && !removed ? AppTheme.accent.opacity(0.25) : AppTheme.cardStroke.opacity(0.1),
                              style: StrokeStyle(lineWidth: 1, dash: side == .before ? [4, 3] : []))
        }
    }

    @ViewBuilder
    private func extraRows(_ rows: [BookingDiffRow]) -> some View {
        if !rows.isEmpty {
            VStack(spacing: 6) {
                ForEach(rows) { row in
                    HStack(spacing: 6) {
                        Text(row.label)
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkSecondary)
                        Spacer(minLength: 6)
                        if row.before != "—" {
                            Text(row.before)
                                .font(.system(size: 12.5, design: .rounded))
                                .strikethrough(row.changed, color: AppTheme.inkTertiary)
                                .foregroundStyle(AppTheme.inkTertiary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }
                        Text(row.after)
                            .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Who it touches

    /// Everyone on the booking, each with what it now means for them. Asked
    /// of the trip the normal way — share of the booking as it is, share of
    /// the booking as it would be — never worked out on the side.
    private func affected(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?) -> some View {
        let shares = trip.shares(of: item)
        let people = shares.isEmpty
            ? trip.travellers.filter { item.participantIDs.contains($0.id) }.map { (traveller: $0, amount: 0.0) }
            : shares

        let names = people.map { $0.traveller.id == Traveller.you.id ? "you" : String($0.traveller.name.split(separator: " ").first ?? "") }
        let list = names.count <= 2 ? names.joined(separator: " and ")
            : "\(names.dropLast().joined(separator: ", ")) and \(names.last!)"
        let yourBefore = trip.share(of: item, for: Traveller.you.id)
        let yourAfter = proposed.map { trip.share(of: $0, for: Traveller.you.id) } ?? 0
        let others = people.contains { $0.traveller.id != Traveller.you.id }

        // One compact row: faces, names, and what it means in money. The
        // per-person detail is the same for everyone on an even split, and
        // a list of identical rows was taking half the card.
        return HStack(spacing: 10) {
            AvatarStack(travellers: people.map(\.traveller), size: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text(list.prefix(1).uppercased() + list.dropFirst())
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(others ? (phase == .finished ? "Told about the change" : "Will be told") : "Only you")
                    .font(.system(size: 11.5))
                    .foregroundStyle(others && phase == .finished ? AppTheme.positive : AppTheme.inkTertiary)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 6)

            if yourBefore != yourAfter {
                HStack(spacing: 4) {
                    Text(Money.format(yourBefore, code: trip.currencyCode))
                        .strikethrough(color: AppTheme.inkTertiary)
                        .foregroundStyle(AppTheme.inkTertiary)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(Money.format(yourAfter, code: trip.currencyCode))
                        .fontWeight(.semibold).foregroundStyle(AppTheme.accent)
                }
                .font(.system(size: 12.5, design: .rounded))
            } else if yourBefore > 0 {
                Text("\(Money.format(yourBefore, code: trip.currencyCode)) your share")
                    .font(.system(size: 12.5, design: .rounded))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(AppTheme.card.opacity(0.55), in: .rect(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.07))
        }
    }

    private func sectionLabel(_ title: String, count: Int? = nil) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(AppTheme.inkTertiary)
            if let count {
                Text("\(count)")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(AppTheme.cardStroke.opacity(0.08), in: .capsule)
            }
        }
        .padding(.leading, 2)
    }

    // MARK: - The plan

    struct Step: Identifiable, Hashable {
        let id: String
        let symbol: String
        let title: String
        let detail: String
        /// True for what's already happened by the time the card is shown.
        let isGiven: Bool
    }

    /// What the app has done, and what it will do on Confirm — every one of
    /// them a real effect of `BookingChangeApplier.apply`, in the order it
    /// happens.
    static func plan(
        for change: BookingChange,
        item: ItineraryItem,
        trip: Trip,
        proposed: ItineraryItem?,
        rows: [BookingDiffRow],
        postsToChat: Bool
    ) -> [Step] {
        var steps: [Step] = []

        // Nothing is ticked before Confirm: every row is something that
        // happens when the person says yes. Where the change came from and
        // why this booking is in the header and the check step's detail.
        steps.append(.init(
            id: "verify", symbol: "checklist",
            title: "Check \(item.title) against the email",
            detail: change.reasons.isEmpty ? "You chose this booking" : change.reasons.joined(separator: " · "),
            isGiven: false
        ))

        let action: (title: String, detail: String)
        if proposed == nil {
            action = ("Take it off the plan", change.refund.map { "\(Money.format($0, code: change.currencyCode ?? trip.currencyCode)) is being refunded" } ?? "The email mentions no refund")
        } else if change.kind == .cancelled {
            action = ("Mark it cancelled", "Keep the \(rows.first { $0.label == "Cost" }?.after ?? "") that isn't refunded on the ledger")
        } else {
            let changed = rows.filter { $0.changed && Self.ticketLabels.contains($0.label) }
            action = (
                changed.map { "\($0.label == "Cost" ? "Change cost to" : "Move to") \($0.after)" }.joined(separator: ", ")
                    .capitalizedFirst,
                changed.map { "was \($0.before)" }.joined(separator: " · ")
            )
        }
        steps.append(.init(id: "apply", symbol: "square.and.pencil", title: action.title, detail: action.detail, isGiven: false))

        let shareMoves = rows.contains { $0.label == "Your share" && $0.changed }
        steps.append(.init(id: "shares", symbol: "arrow.triangle.2.circlepath",
                           title: shareMoves ? "Recalculate everyone's share" : "Recheck everyone's share",
                           detail: shareMoves ? "The cost changed, so the split moves" : "Nobody's share changes",
                           isGiven: false))

        let others = trip.travellers.filter { $0.id != Traveller.you.id && !trip.invitedIDs.contains($0.id) }
        if !others.isEmpty {
            let names = others.map { String($0.name.split(separator: " ").first ?? "") }
            let list = names.count <= 2 ? names.joined(separator: " and ") : "\(names.dropLast().joined(separator: ", ")) and \(names.last!)"
            steps.append(.init(id: "notify", symbol: "bell.badge", title: "Tell \(list)",
                               detail: "A notification with what changed", isGiven: false))
        }

        if postsToChat {
            steps.append(.init(id: "chat", symbol: "bubble.left.and.bubble.right", title: "Post in the \(trip.title) chat",
                               detail: "So the group sees it in the thread", isGiven: false))
        }

        steps.append(.init(id: "audit", symbol: "clock.arrow.circlepath", title: "Note it in the trip's history",
                           detail: "Undo puts everything back", isGiven: false))
        return steps
    }

    private enum StepState { case waiting, working, done }

    private func state(of step: Step, in plan: [Step]) -> StepState {
        if step.isGiven || phase == .finished { return .done }
        if phase == .undone { return .waiting }
        if working == step.id { return .working }
        let pending = plan.filter { !$0.isGiven }
        guard let index = pending.firstIndex(of: step) else { return .waiting }
        return index < completed ? .done : .waiting
    }

    /// One stack, rows divided by hairlines — the plan reads as a single
    /// list, and each row is still a place for the cursor to land.
    private func steps(_ plan: [Step]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(phase == .review ? "What Equi will do" : "What Equi did")
                .contentTransition(.opacity)

            VStack(spacing: 0) {
                ForEach(Array(plan.enumerated()), id: \.element.id) { index, step in
                    stepRow(step, state: state(of: step, in: plan))
                        .reportFrame(step.id)
                    if index < plan.count - 1 { Hairline(inset: 54) }
                }
            }
            .background(AppTheme.card.opacity(0.55), in: .rect(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.07))
            }
        }
    }

    private func stepRow(_ step: Step, state: StepState) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(state == .done ? AppTheme.positive.opacity(0.14) : AppTheme.cardStroke.opacity(0.06))
                switch state {
                case .done:
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.positive)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                case .working:
                    ProgressView()
                        .controlSize(.mini)
                        .transition(.opacity)
                case .waiting:
                    Image(systemName: step.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .transition(.opacity)
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(step.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(state == .waiting ? AppTheme.inkSecondary : AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(step.detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(state == .working ? AppTheme.accent.opacity(0.07) : .clear)
        .scaleEffect(state == .working && cursorPressed ? 0.985 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }

    // MARK: - The cursor

    @ViewBuilder
    private var cursor: some View {
        if cursorVisible, let target = cursorTarget, let frame = frames[target] {
            // Tip on the step's circle; on a ticket or a button, a little in.
            let point = ["after", "done"].contains(target)
                ? CGPoint(x: frame.midX - 10, y: frame.midY - 6)
                : CGPoint(x: frame.minX + 24, y: frame.midY + 2)

            EquiCursor(isPressed: cursorPressed)
                .offset(x: point.x, y: point.y)
                .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .topLeading)))
                .allowsHitTesting(false)
        }
    }

    private func move(to target: String) async {
        withAnimation(.spring(response: 0.62, dampingFraction: 0.82)) { cursorTarget = target }
        try? await Task.sleep(for: .milliseconds(640))
    }

    private func click() async {
        withAnimation(.easeOut(duration: 0.12)) { cursorPressed = true }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        try? await Task.sleep(for: .milliseconds(140))
        withAnimation(.easeOut(duration: 0.16)) { cursorPressed = false }
    }

    // MARK: - Actions

    @ViewBuilder
    private func actions(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?, plan: [Step]) -> some View {
        switch phase {
        case .review:
            HStack(spacing: 8) {
                secondaryButton(dismissTitle, symbol: "xmark", action: dismissChange)
                primaryButton(proposed == nil ? "Confirm removal" : "Confirm", symbol: "checkmark",
                              tint: change.kind == .cancelled ? AppTheme.danger : AppTheme.accent) {
                    confirm(item: item, trip: trip, proposed: proposed, plan: plan)
                }
                .reportFrame("confirm")
            }
            .transition(.opacity)

        case .running:
            HStack(spacing: 8) {
                EquiOrb(size: 18, isThinking: true, glyphSize: 8)
                Text(runsAutomatically ? "Equi is applying this automatically…" : "Equi is working through it…")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .transition(.opacity)

        case .finished:
            HStack(spacing: 8) {
                secondaryButton("Undo", symbol: "arrow.uturn.backward") {
                    undo()
                    completed = 0
                    phase = .undone
                    finished()
                }
                primaryButton("Done", symbol: nil, tint: AppTheme.accent, action: finished)
                    .reportFrame("done")
            }
            .transition(.opacity)

        case .undone:
            note(symbol: "arrow.uturn.backward.circle", tint: AppTheme.inkSecondary, text: "Put back as it was.")
        }
    }

    private func confirm(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?, plan: [Step]) {
        guard phase == .review else { return }
        frozen = Frozen(item: item, trip: trip, proposed: proposed)
        apply()

        let pending = plan.filter { !$0.isGiven }

        Task { @MainActor in
            // The cursor appears where the tap was.
            cursorTarget = "confirm"
            withAnimation(.snappy) {
                phase = .running
                cursorVisible = true
            }
            try? await Task.sleep(for: .milliseconds(350))

            // First, a look at what it's about to make true.
            await move(to: "after")
            try? await Task.sleep(for: .milliseconds(450))

            for (index, step) in pending.enumerated() {
                await move(to: step.id)
                await click()
                withAnimation(.snappy) { working = step.id }
                try? await Task.sleep(for: .milliseconds(520))
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    working = nil
                    completed = index + 1
                }
                try? await Task.sleep(for: .milliseconds(220))
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { phase = .finished }

            // Rest on Done, then step aside.
            try? await Task.sleep(for: .milliseconds(200))
            await move(to: "done")
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.3)) { cursorVisible = false }

            if runsAutomatically {
                try? await Task.sleep(for: .seconds(1.2))
                finished()
            }
        }
    }

    private func runIfAutomatic(item: ItineraryItem, trip: Trip, proposed: ItineraryItem?) async {
        guard runsAutomatically, phase == .review, change.confidence == .certain else { return }
        // Long enough to read what it's about to do.
        try? await Task.sleep(for: .milliseconds(1100))
        let rows = BookingChangeApplier.rows(for: change, item: item, proposed: proposed, trip: trip)
        confirm(item: item, trip: trip, proposed: proposed,
                plan: Self.plan(for: change, item: item, trip: trip, proposed: proposed, rows: rows,
                                postsToChat: sync?.postsToChat ?? true))
    }

    // MARK: - Choosing

    private var chooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("It fits more than one booking. Which is it?")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkSecondary)

            ForEach(change.alternatives) { candidate in
                let trip = store.trip(candidate.tripID)
                let item = trip?.items.first { $0.id == candidate.itemID }
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    choose(candidate)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item?.symbol ?? "questionmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(item?.kind.tint ?? AppTheme.inkTertiary)
                            .frame(width: 28, height: 28)
                            .background((item?.kind.tint ?? AppTheme.inkTertiary).opacity(0.12), in: .circle)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item?.title ?? "A booking")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            Text([trip?.title, item.map { DateFormatter.cached("EEE d MMM").string(from: $0.date) }, item?.timeLabel]
                                .compactMap { $0 }.joined(separator: " · "))
                                .font(.system(size: 11.5))
                                .foregroundStyle(AppTheme.inkTertiary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 4)

                        if let trip {
                            AvatarStack(travellers: Array(trip.travellers.prefix(4)), size: 22)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                    .padding(10)
                    .background(AppTheme.card.opacity(0.7), in: .rect(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
            }

            secondaryButton("None of these", action: dismissChange)
        }
    }

    // MARK: - Pieces

    private func note(symbol: String, tint: Color, text: String) -> some View {
        Label {
            Text(text).font(.system(size: 13)).foregroundStyle(AppTheme.inkSecondary)
        } icon: {
            Image(systemName: symbol).foregroundStyle(tint)
        }
    }

    private func secondaryButton(_ title: String, symbol: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            actionLabel(symbol: symbol, title: title, tint: AppTheme.inkSecondary)
                .background(AppTheme.card.opacity(0.7), in: .rect(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func primaryButton(_ title: String, symbol: String?, tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            actionLabel(symbol: symbol, title: title, tint: AppTheme.ctaLabel)
                .background(tint, in: .rect(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func actionLabel(symbol: String?, title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
            }
            Text(title)
                .font(.system(size: 13.5, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .contentShape(.rect(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Badge

extension BookingChangeCard {
    /// The warning, drawn like the Gmail tile beside it: a white tile, a
    /// yellow triangle, a black mark. Green check once it's been handled.
    struct Badge: View {
        var done = false

        var body: some View {
            Group {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, AppTheme.positive)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, Color(red: 1, green: 0.8, blue: 0.1))
                }
            }
            .font(.system(size: 20, weight: .semibold))
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 40, height: 40)
            .background(AppTheme.card, in: .rect(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.08))
            }
        }
    }
}

// MARK: - Equi's cursor

/// A pointer with Equi's name on it — the way a collaborator's cursor shows
/// up in a shared document, because that's what this is: someone else doing
/// the clicking, in plain view.
private struct EquiCursor: View {
    var isPressed: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Ink, not the accent: it has to read over the purple Done
            // button as well as over the cards.
            CursorArrow()
                .fill(AppTheme.ink)
                .overlay { CursorArrow().stroke(.white, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)) }
                .frame(width: 17, height: 22)
                .shadow(color: .black.opacity(0.22), radius: 3, y: 1.5)

            HStack(spacing: 5) {
                EquiOrb(size: 14, isThinking: false, glyphSize: 6)
                    .padding(1.5)
                    .background(.white, in: .circle)
                Text("Equi")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.leading, 3)
            .padding(.trailing, 9)
            .padding(.vertical, 3)
            .background(AppTheme.accent, in: .capsule)
            .shadow(color: AppTheme.accent.opacity(0.35), radius: 6, y: 2)
            .offset(x: 13, y: 19)
        }
        .scaleEffect(isPressed ? 0.84 : 1, anchor: .topLeading)
    }
}

/// The classic pointer, tip at the top-left corner.
private struct CursorArrow: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width / 13, h = rect.height / 20
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 17 * h))
        path.addLine(to: CGPoint(x: 4.3 * w, y: 13.2 * h))
        path.addLine(to: CGPoint(x: 7.2 * w, y: 19.6 * h))
        path.addLine(to: CGPoint(x: 9.9 * w, y: 18.4 * h))
        path.addLine(to: CGPoint(x: 7.1 * w, y: 12.2 * h))
        path.addLine(to: CGPoint(x: 13 * w, y: 12.2 * h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Frames

private struct FrameKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private extension View {
    /// Where this sits on the card, for the cursor to find.
    func reportFrame(_ id: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: FrameKey.self, value: [id: proxy.frame(in: .named("bookingChangeCard"))])
            }
        }
    }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
