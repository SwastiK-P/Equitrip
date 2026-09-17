//
//  EquiSidebar.swift
//  Equitrip
//

import SwiftUI

/// Equi's conversations as a floating, full-height column beside the thread,
/// on a wide iPad.
///
/// On a phone the history is a sheet behind a clock glyph because the thread
/// needs the whole screen. At 1000pt and up a single centred transcript left
/// two bands of empty aurora either side of it, and switching threads still
/// meant opening a sheet, picking one and waiting for it to close — Messages'
/// own answer to both is a list you can see while you read, so this is that.
///
/// Shaped like the system's own floating sidebar: a glass panel starting
/// level with the top of the floating tab bar and stopping the same distance
/// from the bottom of the window as from its side. Its title row is the header
/// the thread column would otherwise need, and which would have collided with
/// the tabs floating over it.
struct EquiSidebar: View {
    let history: EquiHistoryStore
    var isThinking: Bool
    /// Whether there's a thread on screen to put away. With none, starting a
    /// new conversation would do nothing, so the button says so by dimming.
    var hasConversation: Bool
    var onNewConversation: () -> Void
    var onOpen: (EquiConversationSummary) -> Void

    /// The panel's distance from the window's side and bottom edges.
    static let inset: CGFloat = 10
    private static let titleRow: CGFloat = 44
    private static let padding: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleRow
                .padding(.horizontal, Self.padding)
                .padding(.top, Self.padding)
                .padding(.bottom, 14)

            if let failure = history.failure {
                Text(failure)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.danger)
                    .padding(.horizontal, Self.padding + 4)
                    .padding(.bottom, 8)
            }

            ScrollView {
                EquiConversationList(
                    history: history,
                    selectedID: history.conversationID,
                    onOpen: onOpen
                )
                .padding(.horizontal, Self.padding)
                .padding(.bottom, Self.padding)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .refreshable { await history.loadConversations() }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .glassEffect(.regular.tint(AppTheme.accent.opacity(0.04)), in: .rect(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 0.75)
        }
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Equi")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(isThinking ? "Thinking…" : "Your trip assistant")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .contentTransition(.opacity)
            }
            .padding(.leading, 4)

            Spacer(minLength: 0)

            // A solid disc rather than `CircleGlyphButton`'s glass: glass on
            // the panel's own glass reads as a hole in it.
            Button(action: onNewConversation) {
                Image(systemName: "plus.bubble")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(hasConversation ? .white : AppTheme.accent)
                    .frame(width: Self.titleRow, height: Self.titleRow)
                    .background {
                        Circle().fill(
                            hasConversation
                                ? AnyShapeStyle(LinearGradient(colors: [AppTheme.accent, AppTheme.accentDeep], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(AppTheme.accent.opacity(0.12))
                        )
                    }
                    .shadow(color: AppTheme.accent.opacity(hasConversation ? 0.3 : 0), radius: 8, y: 3)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!hasConversation)
            .accessibilityLabel("New conversation")
            .animation(.easeInOut(duration: 0.2), value: hasConversation)
        }
        .frame(height: Self.titleRow)
    }
}
