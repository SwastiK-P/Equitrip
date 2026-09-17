//
//  ToastCenter.swift
//  Equitrip
//

import SwiftUI

/// One live-update banner, queued and auto-dismissed.
///
/// Nothing else in the app pushes anything to screen uninvited — every other
/// surface waits for you to pull it up (the bell, the ledger, the Settle tab).
/// A settlement someone else just confirmed or declined is different: it's the
/// one event that changes a number you might be looking at *right now*, on a
/// screen that has no reason to be polling for it. That's what this is for,
/// and only for — it is not a general-purpose toast bus, because nothing else
/// in the product needs one yet.
@MainActor
@Observable
final class ToastCenter {
    struct Toast: Identifiable, Equatable {
        enum Kind { case requested, confirmed, declined }

        let id = UUID()
        let kind: Kind
        let title: String
        let subtitle: String
        /// The settlement to open if this is tapped.
        var settlement: Settlement?

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    private(set) var current: Toast?
    /// Set by whoever owns the app-level sheet — see `RootTabView`. Kept as a
    /// closure rather than routing the toast through the environment as
    /// state, because presenting from a tap has to happen at the root, above
    /// whichever tab is on screen when it arrives.
    var onTap: ((Toast) -> Void)?

    private var dismissTask: Task<Void, Never>?

    /// How long a toast sits before it clears itself. Long enough to read two
    /// short lines without rushing, short enough that a second one arriving
    /// soon after doesn't queue up behind a stale one.
    private static let visibleDuration: Duration = .seconds(4.5)

    func show(_ toast: Toast) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            current = toast
        }

        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(toast.kind == .declined ? .warning : .success)

        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: Self.visibleDuration)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.dismiss() }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
            current = nil
        }
    }

    /// Tapped rather than swiped away: reads as "take me there", not "make it
    /// go away". Both act, then clear.
    func tap() {
        guard let current else { return }
        onTap?(current)
        dismiss()
    }
}

// MARK: - Overlay

/// The card itself, pinned to the top and driven entirely by `ToastCenter`.
struct ToastOverlay: View {
    @Environment(\.pane) private var pane

    @Environment(\.toastCenter) private var center

    var body: some View {
        VStack {
            if let toast = center.current {
                card(toast)
                    .padding(.horizontal, 16)
                    // A toast is one sentence about one thing. Left to fill a
                    // landscape iPad it becomes a banner across the top of the
                    // screen, and the extra inset clears the floating tab bar
                    // that lives up there on iPad rather than at the bottom.
                    .frame(maxWidth: pane.isRegular ? 460 : .infinity)
                    .frame(maxWidth: .infinity)
                    .padding(.top, ScreenInsets.top + (pane.isRegular ? 64 : 6))
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                    .zIndex(1)
            }

            Spacer(minLength: 0)
        }
        .allowsHitTesting(center.current != nil)
        .ignoresSafeArea(edges: .top)
    }

    private func card(_ toast: ToastCenter.Toast) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            center.tap()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: symbol(for: toast.kind), tint: tint(for: toast.kind), size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(toast.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    Text(toast.subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .padding(.top, 3)
            }
            .padding(14)
        }
        .buttonStyle(PressableButtonStyle())
        .background(.regularMaterial, in: .rect(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.08))
        }
        .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
        .gesture(
            // A flick up dismisses without acting — the same gesture Control
            // Center and every system banner already trained people to use.
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -14 { center.dismiss() }
                }
        )
    }

    private func symbol(for kind: ToastCenter.Toast.Kind) -> String {
        switch kind {
        case .requested: "arrow.left.arrow.right.circle.fill"
        case .confirmed: "checkmark.seal.fill"
        case .declined: "xmark.seal.fill"
        }
    }

    private func tint(for kind: ToastCenter.Toast.Kind) -> Color {
        switch kind {
        case .requested: AppTheme.accent
        case .confirmed: AppTheme.positive
        case .declined: AppTheme.danger
        }
    }
}

extension EnvironmentValues {
    @Entry var toastCenter = ToastCenter()
}
