//
//  EquiAgentOverlay.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// The layer Equi works in: its own window above the app — sheets included —
/// holding the edge glow, the cursor, the HUD and any question it asks.
///
/// A window rather than an overlay on the root view for the reason
/// `GlobalOverlayWindow` gives: a sheet the run opens would cover anything
/// drawn in the app's own hierarchy. It sits just under the toast window, so
/// the screen's own "Expense logged" still lands on top.
///
/// While a run is up, the window takes every touch: Equi has the controls,
/// and a finger landing mid-step would race the cursor. The HUD's Stop and the
/// question card are the ways in. Hidden between runs, so it costs nothing.
@MainActor
enum EquiAgentOverlay {
    private static var window: UIWindow?

    static func show() {
        if window == nil {
            guard let scene = EquiAgentTargets.mainWindow?.windowScene else { return }
            let hosting = UIHostingController(rootView: EquiAgentStage())
            hosting.view.backgroundColor = .clear

            let overlay = AgentWindow(windowScene: scene)
            overlay.rootViewController = hosting
            overlay.backgroundColor = .clear
            overlay.windowLevel = .alert
            window = overlay
        }
        window?.isHidden = false
    }

    static func hide() {
        window?.isHidden = true
    }
}

/// Swallows touches while a run is up and passes every one through otherwise.
private final class AgentWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard EquiAgent.shared.isRunning else { return nil }
        return super.hitTest(point, with: event)
    }
}

/// Everything the window draws, straight off `EquiAgent`.
private struct EquiAgentStage: View {
    private let agent = EquiAgent.shared

    var body: some View {
        ZStack {
            // Screen coordinates: the cursor and ripples are placed at the
            // points the targets reported, which are the window's own.
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.001)
                    .contentShape(.rect)
                    .allowsHitTesting(agent.isRunning)

                EquiEdgeGlow(
                    reach: agent.reach,
                    mood: agent.mood,
                    pressCount: agent.pressCount,
                    cornerRadius: Self.cornerRadius
                )

                if let ripple = agent.ripple {
                    EquiAgentRipple()
                        .id(ripple.id)
                        .position(ripple.point)
                }

                if let cursor = agent.cursor {
                    EquiAgentCursor(isPressing: agent.isPressing, isTyping: agent.isTyping)
                        .opacity(agent.cursorVisible ? 1 : 0)
                        .scaleEffect(agent.cursorVisible ? 1 : 0.6, anchor: .topLeading)
                        // The cursor's frame starts at its tip; `position`
                        // centres a frame, so shift by half of it.
                        .position(x: cursor.x + 70, y: cursor.y + 30)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if agent.isRunning && agent.reach > 0.4 {
                    // Capped so it stays a capsule on an iPad, not a banner.
                    EquiAgentHUD(agent: agent)
                        .frame(maxWidth: 520)
                        .padding(.horizontal, 14)
                        .padding(.top, 2)
                        .transition(.scale(scale: 0.5, anchor: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)

                if let question = agent.question {
                    EquiAgentQuestionCard(
                        question: question,
                        onAnswer: { agent.respond($0) },
                        onStop: { agent.stop() }
                    )
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: agent.reach > 0.4)
            .animation(.spring(response: 0.45, dampingFraction: 0.84), value: agent.question)
        }
    }

    /// The display's own corner, near enough for light that's blurred by
    /// thirty points anyway: a phone's screen is far rounder than an iPad's.
    private static var cornerRadius: CGFloat {
        let width = EquiAgentTargets.mainWindow?.bounds.width ?? 402
        return width < 600 ? 60 : 20
    }
}
