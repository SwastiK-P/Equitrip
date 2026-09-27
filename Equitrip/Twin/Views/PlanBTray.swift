//
//  PlanBTray.swift
//  Equitrip
//

import SwiftUI

/// The actions people have chosen for this trip, and where each one stands.
///
/// Only drawn once something is in it — an empty tray explaining itself sat
/// on every calm trip. Queued actions wait here for the executors that carry
/// them out; the ones that can already run ("Ask the group") run from here
/// too. Nothing in the tray changes the trip until a person finishes it on
/// the screen it opens — or, for the ones Equi does (`TwinAgentJobs`),
/// picks the place or confirms the clash it stops to ask about.
struct PlanBTray: View {
    let actions: [TwinAction]
    var canRun: (TwinAction) -> Bool
    var onRun: (TwinAction) -> Void
    var onRemove: (TwinAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                row(action)
                if index < actions.count - 1 { Hairline(inset: 42) }
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
    }

    private func row(_ action: TwinAction) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: action.kind.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(action.kind.tint)
                .frame(width: 30, height: 30)
                .background(action.kind.tint.opacity(0.12), in: .rect(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(action.kind.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(action.title)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                Text(status(action))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(action.status == .done ? AppTheme.positive : AppTheme.inkTertiary)
            }

            Spacer(minLength: 6)

            if canRun(action), action.status != .done {
                Button(TwinAgentJobs.kinds.contains(action.kind) ? "Do it" : "Open") { onRun(action) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.ctaLabel)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.cta, in: .capsule)
                    .buttonStyle(PressableButtonStyle())
            }

            Button { onRemove(action) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.cardStroke.opacity(0.06), in: .circle)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Remove from Plan B")
        }
        .padding(.vertical, 12)
    }

    private func status(_ action: TwinAction) -> String {
        var parts = [action.status == .queued ? "Waiting" : action.status.label]
        if let deadline = action.deadline, deadline > Date(), action.status != .done {
            let calendar = Calendar.current
            let format = calendar.isDateInToday(deadline) ? "h:mm a" : "EEE h a"
            parts.append("act before \(DateFormatter.cached(format).string(from: deadline))")
        }
        return parts.joined(separator: " · ")
    }
}
