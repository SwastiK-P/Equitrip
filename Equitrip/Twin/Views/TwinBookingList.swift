//
//  TwinBookingList.swift
//  Equitrip
//

import SwiftUI

/// The bookings the weather threatens, as one list: what, when, how likely,
/// and why — with the fixes one tap away.
///
/// It replaced a cascade of tiered cards, each with a coloured spine, a
/// probability bar, driver chips and a row of action pills that scrolled off
/// the right edge. Every one of those said the same thing a second time. A
/// row now carries the verdict in words and the chance as a number; the
/// knock-on relationship the tiers existed for is said on the row itself
/// ("if the airport transfer runs late"), which is where it's needed.
/// Tapping a row opens the why and the Plan B options, and puts the booking
/// on the map.
struct TwinBookingList: View {
    let outcomes: [NodeOutcome]
    let twin: TripTwin
    var selection: UUID?
    var actions: [UUID: [TwinAction]] = [:]
    var canRun: (TwinAction) -> Bool = { _ in false }
    var onToggle: (TwinAction) -> Void = { _ in }
    var onRun: (TwinAction) -> Void = { _ in }
    var onFocus: (TwinNode) -> Void = { _ in }
    /// Opens the booking's editor. Nil hides the link.
    var onEdit: ((TwinNode) -> Void)?
    /// Whether you may edit this booking — the rule the itinerary uses.
    var canEdit: (TwinNode) -> Bool = { _ in false }

    @State private var expanded: UUID?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(outcomes.enumerated()), id: \.element.id) { index, outcome in
                if let node = twin.node(outcome.id) {
                    TwinBookingRow(
                        node: node,
                        outcome: outcome,
                        cause: outcome.causedBy.flatMap(twin.node),
                        actions: actions[node.id] ?? [],
                        isExpanded: expanded == node.id,
                        canRun: canRun,
                        onToggle: onToggle,
                        onRun: onRun,
                        onEdit: canEdit(node) ? onEdit.map { edit in { edit(node) } } : nil,
                        canEdit: canEdit(node)
                    ) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                            expanded = expanded == node.id ? nil : node.id
                        }
                        onFocus(node)
                    }
                    .id("twin-row-\(node.id)")
                    if index < outcomes.count - 1 { Hairline(inset: 48) }
                }
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: outcomes.map(\.id))
        .onChange(of: selection) { _, id in
            // A pin tapped on the map opens its row here too.
            guard let id, outcomes.contains(where: { $0.id == id }) else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) { expanded = id }
        }
    }
}

/// One threatened booking.
struct TwinBookingRow: View {
    let node: TwinNode
    let outcome: NodeOutcome
    var cause: TwinNode?
    var actions: [TwinAction]
    var isExpanded: Bool
    var canRun: (TwinAction) -> Bool
    var onToggle: (TwinAction) -> Void
    var onRun: (TwinAction) -> Void
    var onEdit: (() -> Void)?
    var canEdit = true
    var onTap: () -> Void

    private var tint: Color { outcome.risk.tint }
    private var isKnockOn: Bool { outcome.order > 1 && cause != nil }
    private var isCancellation: Bool { outcome.pCancelled > outcome.pAffected / 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                summary
                    .padding(.vertical, 14)
                    .contentShape(.rect)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint(isExpanded ? "Hides the details" : "Shows why, and what could be done")
            // Equi opens a row, never closes one: a toggle would shut the
            // row it was about to work in if someone had already opened it.
            .agentTarget("twin.row.\(node.id)") { if !isExpanded { onTap() } }

            if isExpanded {
                details
                    .padding(.leading, 48)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Summary

    private var summary: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadge(symbol: node.item.symbol, tint: node.item.kind.tint, size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(node.item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(when)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Image(systemName: verdictSymbol)
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(tint)
                    Text(verdict)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 3)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 1) {
                Text(TwinFormat.percent(outcome.pAffected))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: outcome.pAffected))
                Text(outcome.risk.short)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(tint)
            .animation(.snappy, value: outcome.pAffected)
        }
    }

    private var when: String {
        let day = DateFormatter.cached("EEE d MMM").string(from: node.item.date)
        return [day, node.item.timeLabel, node.exposure.label].compactMap { $0 }.joined(separator: " · ")
    }

    private var verdictSymbol: String {
        if isKnockOn { return "arrow.turn.down.right" }
        return isCancellation ? "xmark.circle.fill" : "clock.fill"
    }

    private var verdict: String {
        if isKnockOn, let cause {
            return "Could be missed if \(cause.item.title) runs late"
        }
        let head: String
        if isCancellation {
            head = node.exposure == .marine ? "May not sail" : "May not go ahead"
        } else {
            let minutes = Int(outcome.typicalDelay.rounded())
            head = minutes > 0 ? "About \(minutes) min late" : "Likely affected"
        }
        guard let driver = outcome.drivers.first else { return head }
        return "\(head) — \(driver.label.lowercased()) \(driver.value)"
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !outcome.drivers.isEmpty, !isKnockOn {
                VStack(alignment: .leading, spacing: 8) {
                    caption("Why")
                    ForEach(outcome.drivers.prefix(4)) { driver in
                        HStack(spacing: 8) {
                            Text(driver.label)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            Text(driver.value)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                            Capsule()
                                .fill(tint.opacity(0.75))
                                .frame(width: max(4, 40 * driver.weight), height: 4)
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                }
            }

            Text(footnote)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkTertiary)
                .fixedSize(horizontal: false, vertical: true)

            if let onEdit {
                Button(action: onEdit) {
                    Label("Edit booking", systemImage: "square.and.pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(PressableButtonStyle())
                .agentTarget("twin.edit.\(node.id)", perform: onEdit)
                .id("twin-edit-\(node.id)")
            }

            if !actions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    caption("Plan B")
                    ForEach(actions) { action in
                        TwinActionRow(
                            action: action,
                            canRun: canRun(action),
                            isLocked: !canEdit && TwinAgentJobs.kinds.contains(action.kind),
                            onToggle: { onToggle(action) },
                            onRun: { onRun(action) }
                        )
                    }
                }
            }
        }
    }

    private var footnote: String {
        var parts: [String] = []
        let low = Int((outcome.spread.lowerBound * 100).rounded())
        let high = Int((outcome.spread.upperBound * 100).rounded())
        if high > low + 4, !isKnockOn { parts.append("Somewhere between \(low)% and \(high)% across the forecast's possible futures.") }
        parts.append(node.place.isApproximate
                     ? "Placed at \(node.place.name) — its exact spot wasn't found."
                     : "At \(node.place.name)\(node.place.locality.map { ", \($0)" } ?? "").")
        switch outcome.basis {
        case .seasonal: parts.append("Beyond the forecast, so this uses the same week last year.")
        case .observed: parts.append("Replayed from the weather that happened.")
        default: break
        }
        return parts.joined(separator: " ")
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.inkTertiary)
    }
}

/// One Plan B option under a booking: add it (or take it out), or open it
/// when it can already run.
struct TwinActionRow: View {
    let action: TwinAction
    var canRun: Bool
    /// Equi could do it, but you can't edit this booking — so neither can
    /// it. Said on the row, rather than the option quietly losing its play
    /// affordance.
    var isLocked = false
    var onToggle: () -> Void
    var onRun: () -> Void

    private var isQueued: Bool { action.status == .queued || action.status == .done }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            canRun ? onRun() : onToggle()
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: action.kind.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(action.kind.tint)
                    .frame(width: 28, height: 28)
                    .background(action.kind.tint.opacity(0.12), in: .rect(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.kind.label)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(action.rationale)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if isLocked {
                        Label("Only the organiser or whoever added it can change this", systemImage: "lock.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .labelStyle(.titleAndIcon)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 6)

                Image(systemName: canRun ? (byEqui ? "cursorarrow.click.2" : "arrow.up.right.circle.fill") : isQueued ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(canRun || isQueued ? action.kind.tint : AppTheme.inkTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(10)
            .background(AppTheme.canvasTop.opacity(isQueued ? 1 : 0.6), in: .rect(cornerRadius: 14, style: .continuous))
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(canRun ? (byEqui ? "Equi does it on screen" : "Opens now") : isQueued ? "Removes it from Plan B" : "Adds it to Plan B")
        .animation(.snappy, value: isQueued)
    }

    /// Equi carries it out on screen rather than opening something.
    private var byEqui: Bool { TwinAgentJobs.kinds.contains(action.kind) }
}
