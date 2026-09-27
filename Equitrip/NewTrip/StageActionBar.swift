//
//  StageActionBar.swift
//  Equitrip
//

import SwiftUI

/// The one button at the foot of every step of the creation flow.
///
/// Each step used to build its own — the same glass capsule four times with
/// four slightly different paddings, and a status line above it on one screen
/// that none of the others had room for. One bar means the thumb finds it in
/// the same place on every step, and a step with something to say before you
/// go on says it in the same spot.
struct StageActionBar: View {
    let title: String
    var symbol: String? = "arrow.right"
    /// A short line above the button: what's still missing, or what the tap
    /// will commit to.
    var caption: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            if let caption {
                Text(caption)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .contentTransition(.numericText())
                    .transition(.opacity)
            }

            Button {
                guard isEnabled else {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    return
                }
                action()
            } label: {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .contentTransition(.opacity)
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.glassProminent)
            // Muted rather than `.disabled`: a disabled prominent glass button
            // goes see-through, and on the dates step that put a calendar's
            // worth of numbers behind the words "Pick the last day".
            .tint(isEnabled ? AppTheme.accent : AppTheme.inkTertiary)
        }
        .animation(.easeOut(duration: 0.2), value: isEnabled)
        .animation(.easeOut(duration: 0.2), value: caption)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
