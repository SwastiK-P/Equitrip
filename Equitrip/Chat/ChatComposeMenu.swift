//
//  ChatComposeMenu.swift
//  Equitrip
//

import SwiftUI

/// The stack of glass pills that grows out of the composer's `+`.
///
/// Drawn by the thread, not the composer: it sits above the composer's frame,
/// and a view drawn outside its parent's bounds doesn't get the taps — they
/// fell through to the tap-to-dismiss layer and closed the menu instead.
///
/// It replaced a tray that took the keyboard's place. Seven tools never sat
/// evenly in a grid, and the thread jumped a keyboard's height to show seven
/// words; a menu over the thread leaves the conversation where it was.
struct ChatComposeMenu: View {
    var onTool: (ChatComposeTool) -> Void

    var body: some View {
        // Container spacing under the stack's own, so neighbouring pills
        // stay separate shapes instead of melting into one column.
        GlassEffectContainer(spacing: 2) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(ChatComposeTool.allCases) { tool in
                    pill(tool)
                }
            }
        }
    }

    private func pill(_ tool: ChatComposeTool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTool(tool)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tool.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(tool.tint.gradient, in: .circle)

                Text(tool.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(.leading, 6)
            .padding(.trailing, 18)
            .frame(height: 44)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        // Untinted: a card-coloured tint made the pills read as flat white
        // buttons. The thread's veil behind the menu keeps labels legible.
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}
