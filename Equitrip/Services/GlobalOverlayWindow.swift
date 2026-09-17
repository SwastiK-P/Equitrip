//
//  GlobalOverlayWindow.swift
//  Equitrip
//

import SwiftUI
import UIKit

/// Puts `GlassToastOverlay` above everything else on screen, sheets and full
/// screen covers included.
///
/// A SwiftUI `.overlay` only ever draws inside the view hierarchy it's
/// attached to, and a presented `.sheet` is a separate `UIViewController`
/// stacked on top of that hierarchy — so an overlay pinned to the root view
/// gets covered by the very next sheet somebody presents. The fix is the
/// same one any UIKit app uses for a toast that has to survive a modal: a
/// second, transparent `UIWindow` above the key window, high enough on the
/// window level that nothing else in the app can end up over it.
@MainActor
enum GlobalOverlayWindow {
    private static var window: PassthroughWindow?

    /// Call once, as soon as a window scene exists. Safe to call again —
    /// it's a no-op once the window is up.
    static func install() {
        guard window == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
            as? UIWindowScene
        else { return }

        // Its own `PaneReader`, because this window is outside the app's
        // view hierarchy and inherits nothing from it — including the pane
        // the toast needs in order to know it shouldn't be 1200pt wide.
        let hosting = UIHostingController(rootView: PaneReader { GlassToastOverlay() })
        hosting.view.backgroundColor = .clear

        let overlayWindow = PassthroughWindow(windowScene: scene)
        overlayWindow.rootViewController = hosting
        overlayWindow.backgroundColor = .clear
        // One above `.alert` — high enough that a `.sheet`, a
        // `.fullScreenCover`, and even a system alert all sit under it.
        overlayWindow.windowLevel = .alert + 1
        overlayWindow.isHidden = false

        window = overlayWindow
    }
}

/// A window that only accepts touches where its SwiftUI content actually
/// drew something tappable.
///
/// Without this override, the window's own root view — which SwiftUI sizes
/// to fill the whole screen so it can position the toast anywhere in it —
/// would swallow every touch in the app the moment it existed, toast visible
/// or not. Returning `nil` for a hit that lands on that bare root view lets
/// the touch fall through to whatever's actually underneath; only a hit on
/// real content (the toast card itself) is claimed.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        return hit == rootViewController?.view ? nil : hit
    }
}
