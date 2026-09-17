//
//  GlassToast.swift
//  Equitrip
//

import SwiftUI

/// One reusable liquid-glass toast, queued and auto-dismissed.
///
/// Distinct from `ToastCenter`, which is deliberately scoped to settlement
/// events only — see its own header comment. This one is the general-purpose
/// version: any feature that needs to say something transient on top of
/// whatever's on screen, sheets included, reaches for this instead of
/// growing its own banner. `GlobalOverlayWindow` is what actually gets it
/// above a presented `.sheet` — a plain in-hierarchy `.overlay` would be
/// covered by one the instant it appears.
@MainActor
@Observable
final class GlassToastCenter {
    static let shared = GlassToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        var symbol: String
        var tint: Color
        var title: String
        var subtitle: String
        /// Nil means it sits until something dismisses it explicitly —
        /// every caller so far wants an auto-dismiss, but a future one
        /// might not.
        var duration: Duration? = .seconds(4.5)
        /// Runs when the toast itself is tapped, dismissing either way.
        var onTap: (() -> Void)?

        static func == (lhs: Toast, rhs: Toast) -> Bool { lhs.id == rhs.id }
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ toast: Toast) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            current = toast
        }

        guard let duration = toast.duration else { return }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
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

    func tap() {
        guard let current else { return }
        current.onTap?()
        dismiss()
    }
}

// MARK: - Overlay

/// The card itself, driven entirely by `GlassToastCenter`. Hosted inside
/// `GlobalOverlayWindow` rather than as a plain view `.overlay`, so it's the
/// one piece of chrome in the app that renders above a presented sheet.
struct GlassToastOverlay: View {
    @Environment(\.pane) private var pane

    @State private var center = GlassToastCenter.shared

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
            }

            Spacer(minLength: 0)
        }
        .allowsHitTesting(center.current != nil)
        .ignoresSafeArea()
    }

    private func card(_ toast: GlassToastCenter.Toast) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            center.tap()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: toast.symbol, tint: toast.tint, size: 38)

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
                        .lineLimit(3)
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
        // Liquid glass rather than a material fill — this is the one card in
        // the app meant to look like it's floating above everything else,
        // including a sheet, so it gets the treatment that actually reads as
        // "above", not just "on".
        .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .gesture(
            // A flick up dismisses without acting — the same gesture Control
            // Center and every system banner already trained people to use.
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -14 { center.dismiss() }
                }
        )
    }
}
