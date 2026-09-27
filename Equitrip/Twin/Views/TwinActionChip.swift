//
//  TwinActionChip.swift
//  Equitrip
//

import SwiftUI

/// One suggested action: tap to put it in Plan B (or take it out); actions
/// that can already run show a play affordance instead.
struct TwinActionChip: View {
    let action: TwinAction
    var canRun = false
    var onToggle: () -> Void
    var onRun: () -> Void

    private var isQueued: Bool { action.status == .queued || action.status == .done }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            canRun ? onRun() : onToggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: isQueued ? "checkmark" : action.kind.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                Text(action.kind.label)
                    .font(.system(size: 12, weight: .semibold))
                if canRun {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .foregroundStyle(isQueued ? .white : action.kind.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background {
                Capsule().fill(isQueued ? AnyShapeStyle(action.kind.tint) : AnyShapeStyle(action.kind.tint.opacity(0.1)))
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(canRun ? "Opens now" : isQueued ? "Remove from Plan B" : "Add to Plan B")
        .animation(.snappy, value: isQueued)
    }
}
