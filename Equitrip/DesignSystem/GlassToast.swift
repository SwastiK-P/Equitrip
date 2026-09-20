//
//  GlassToast.swift
//  Equitrip
//

import SwiftUI

/// One reusable liquid-glass toast, queued and auto-dismissed.
///
/// Every transient message goes through this one, including settlement
/// updates, which `ToastCenter` forwards here. `GlobalOverlayWindow` is what
/// actually gets it above a presented `.sheet`: a plain in-hierarchy `.overlay`
/// would be covered as soon as a sheet appears. On an iPhone with a Dynamic
/// Island the toast drips out of the island and is pulled back into it
/// (`IslandToastView`). Everywhere else it slides down from the top.
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
    /// Set when the exit begins. `current` stays set until the exit
    /// animation finishes, so the toast is still there to animate out.
    private(set) var dismissedAt: Date?

    /// A toast that arrived while another was on screen. The first one
    /// goes back into the island before the next one comes out, instead of
    /// the card changing its text while it's still showing.
    private var queued: Toast?
    private var dismissTask: Task<Void, Never>?
    private var exitTask: Task<Void, Never>?

    private init() {}

    func show(_ toast: Toast) {
        guard current != nil else { return present(toast) }
        queued = toast
        beginExit()
    }

    func dismiss() {
        queued = nil
        beginExit()
    }

    func tap() {
        guard let current, dismissedAt == nil else { return }
        current.onTap?()
        dismiss()
    }

    private func present(_ toast: Toast) {
        current = toast
        dismissedAt = nil
        AccessibilityNotification.Announcement("\(toast.title). \(toast.subtitle)").post()

        dismissTask?.cancel()
        guard let duration = toast.duration else { return }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(ToastMotion.revealDelay) + duration)
            guard !Task.isCancelled else { return }
            self?.beginExit()
        }
    }

    private func beginExit() {
        guard current != nil, dismissedAt == nil else { return }
        dismissTask?.cancel()
        dismissedAt = .now

        exitTask = Task { [weak self] in
            try? await Task.sleep(for: ToastMotion.exitDuration)
            guard !Task.isCancelled, let self else { return }
            self.current = nil
            self.dismissedAt = nil
            if let next = self.queued {
                self.queued = nil
                self.present(next)
            }
        }
    }
}

// MARK: - Overlay

/// The toast itself, driven entirely by `GlassToastCenter`. Hosted inside
/// `GlobalOverlayWindow` rather than as a plain view `.overlay`, so it's the
/// one piece of chrome in the app that renders above a presented sheet.
struct GlassToastOverlay: View {
    @Environment(\.pane) private var pane
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var center = GlassToastCenter.shared
    @State private var drag = ToastMotion.Drag()
    /// The card's natural height at its width. It depends on how many
    /// lines the text wraps to, and the island geometry needs it before
    /// the card has been drawn.
    @State private var contentHeight: CGFloat = 64
    @State private var isWarm = false
    @State private var clock = ToastMotion.Clock()

    var body: some View {
        GeometryReader { proxy in
            if let toast = center.current {
                // From the app's own window: this overlay window reports no
                // safe area once its content ignores it.
                let topInset = ScreenInsets.top
                let island = reduceMotion ? nil : DynamicIslandMetrics.islandFrame(
                    width: proxy.size.width,
                    topInset: topInset
                )
                let cardWidth = island == nil
                    ? min(proxy.size.width - 32, pane.isRegular ? 460 : .infinity)
                    : DynamicIslandMetrics.cardWidth(for: proxy.size.width)

                TimelineView(.animation) { timeline in
                    let motion = clock.tick(timeline.date, toast: toast.id, isExiting: center.dismissedAt != nil)
                    let offset = drag.offset(at: timeline.date)

                    Group {
                        if let island {
                            IslandToastView(
                                motion: motion,
                                island: island,
                                containerWidth: proxy.size.width,
                                cardSize: CGSize(width: cardWidth, height: contentHeight),
                                dragOffset: offset
                            ) {
                                card(toast)
                            }
                        } else {
                            banner(toast, motion: motion, width: cardWidth, top: topInset, dragOffset: offset)
                        }
                    }
                    .gesture(dismissDrag)
                }
                .background(alignment: .topLeading) {
                    GlassToastContent(toast: toast)
                        .frame(width: cardWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                }
                .id(toast.id)
                .onAppear { drag = ToastMotion.Drag() }
            } else if !isWarm {
                warmUp(width: proxy.size.width)
            }
        }
        .allowsHitTesting(center.current != nil && center.dismissedAt == nil)
        .ignoresSafeArea()
    }

    /// Draws the glass and the goo filters once, invisibly, when the
    /// window is installed. The first time they're rendered, the frame
    /// stalls long enough that the first toast's clock-driven drip would
    /// already be over by the time anything appeared. It would show up fully
    /// formed instead.
    private func warmUp(width: CGFloat) -> some View {
        IslandToastView(
            motion: ToastMotion(drop: 0.5, expand: 0.5, reveal: 0.5, tint: 0.5, slide: 0.5),
            island: DynamicIslandMetrics.islandFrame(width: width, topInset: 62) ?? .zero,
            containerWidth: width,
            cardSize: CGSize(width: DynamicIslandMetrics.cardWidth(for: width), height: 64),
            dragOffset: 0
        ) {
            EmptyView()
        }
        .opacity(0.01)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: .seconds(1))
            isWarm = true
        }
    }

    private func card(_ toast: GlassToastCenter.Toast) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            center.tap()
        } label: {
            GlassToastContent(toast: toast)
        }
        .buttonStyle(PressableButtonStyle())
    }

    /// Where there's no island to drip from — iPad, landscape, older
    /// iPhones, Reduce Motion — the same glass card slides down instead.
    private func banner(
        _ toast: GlassToastCenter.Toast,
        motion: ToastMotion,
        width: CGFloat,
        top: CGFloat,
        dragOffset: Double
    ) -> some View {
        let travel = reduceMotion ? 0 : (1 - motion.slide) * -(top + contentHeight + 40)

        return VStack {
            card(toast)
                .frame(width: width)
                .glassEffect(.regular, in: .rect(cornerRadius: GlassToastContent.radius(forHeight: contentHeight), style: .continuous))
                .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
                .opacity(reduceMotion ? motion.slide : min(1, motion.slide * 1.6))
                .offset(y: travel + dragOffset)
                // The extra inset on iPad clears the floating tab bar that
                // lives up there rather than at the bottom.
                .padding(.top, top + (pane.isRegular ? 64 : 6))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    /// A flick up dismisses without acting — the same gesture every system
    /// banner already trained people to use.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag.track($0.translation.height) }
            .onEnded { value in
                if drag.translation < -18 || value.velocity.height < -420 {
                    // The drag stays where it was let go: the exit carries
                    // the card from there back into the island.
                    center.dismiss()
                } else {
                    drag.release(at: .now)
                }
            }
    }
}

/// The toast's text and badge, shared by the island and banner
/// presentations so they only differ in how they arrive.
struct GlassToastContent: View {
    let toast: GlassToastCenter.Toast

    /// A capsule while the card is one or two lines — concentric with the
    /// badge, like the island it came out of — and a rounded rect once the
    /// text makes it too tall for a capsule to look intentional.
    static func radius(forHeight height: CGFloat) -> CGFloat {
        height <= 76 ? height / 2 : 30
    }

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: toast.symbol, tint: toast.tint, size: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text(toast.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text(toast.subtitle)
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(3)
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Only a toast that goes somewhere promises to.
            if toast.onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 12)
        .padding(.trailing, 20)
        .contentShape(.rect)
    }
}
