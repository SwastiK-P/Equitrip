//
//  SwipeToDelete.swift
//  Equitrip
//

import SwiftUI

/// Swipe a card row left to delete it.
///
/// `List`'s `.swipeActions` isn't available here: the rows this wraps are
/// cards in a `LazyVStack` on the app's own canvas, and putting them in a
/// `List` to buy one gesture would cost the surface, the spacing and the
/// insertion animations. So the gesture is built directly — it behaves the
/// way the system one does, because that's what a thumb expects: a short
/// swipe rests the row open next to a delete button, a long one commits, and
/// either way the row itself decides what deleting means.
///
/// It only reports the intent. Confirmation and the actual write belong to
/// the caller, so a full swipe here is never the last word on its own.
struct SwipeToDelete<Content: View>: View {
    var corner: CGFloat = 16
    let onDelete: () -> Void
    @ViewBuilder var content: Content

    /// How far the row rests open — wide enough for a 44pt target plus the
    /// gap that keeps the button from touching the card.
    private let reveal: CGFloat = 78

    /// A swipe past this commits without waiting for the button. Comfortably
    /// wider than `reveal`, so resting the row open is not a near-miss of
    /// deleting it.
    private let commit: CGFloat = 150

    @State private var offset: CGFloat = 0
    @State private var isOpen = false
    @State private var armed = false

    var body: some View {
        ZStack(alignment: .trailing) {
            button

            content
                .overlay {
                    // While the row is open, a tap anywhere on it closes
                    // instead of opening what it points at — the same rule
                    // the system's rows follow, and the reason a stray swipe
                    // never costs anything.
                    if isOpen {
                        Color.clear
                            .contentShape(.rect)
                            .onTapGesture { close() }
                    }
                }
                .offset(x: offset)
        }
        // High priority, because the row this wraps is itself a button: with
        // a plain `.gesture` the button's own recognizer swallows the drag and
        // the row never moves. The 14pt minimum keeps taps working.
        .highPriorityGesture(swipe)
        .accessibilityAction(named: "Delete") { onDelete() }
    }

    /// Tracks the drag rather than appearing at the end, so the gesture
    /// explains itself the first time someone tries it by accident.
    private var button: some View {
        let progress = min(1, -offset / reveal)

        return Button {
            close()
            onDelete()
        } label: {
            Image(systemName: "trash.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 44)
                .background(AppTheme.danger, in: .rect(cornerRadius: corner, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .scaleEffect(0.7 + 0.3 * progress)
        .opacity(progress)
        .accessibilityLabel("Delete")
        .allowsHitTesting(isOpen)
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 14, coordinateSpace: .local)
            .onChanged { value in
                // Vertical intent belongs to the scroll view, always.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }

                let raw = value.translation.width + (isOpen ? -reveal : 0)
                // Rubber-banding in both directions: pulling right from a
                // closed row, or past the commit point, keeps answering the
                // finger without sliding the card off its own screen.
                offset = raw > 0 ? raw * 0.18 : max(raw, -commit - (-raw - commit) * 0.3)

                if -offset >= commit, !armed {
                    armed = true
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else if -offset < commit, armed {
                    armed = false
                }
            }
            .onEnded { _ in
                if armed {
                    armed = false
                    close()
                    onDelete()
                } else if -offset > reveal * 0.5 {
                    open()
                } else {
                    close()
                }
            }
    }

    private func open() {
        isOpen = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { offset = -reveal }
    }

    private func close() {
        isOpen = false
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) { offset = 0 }
    }
}
