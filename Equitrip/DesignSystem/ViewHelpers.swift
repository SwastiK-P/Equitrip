//
//  ViewHelpers.swift
//  Equitrip
//

import SwiftUI

// MARK: - Entrance

extension View {
    /// Shared stagger so every screen enters with the same rhythm as onboarding.
    func staggered(_ index: Int, _ appeared: Bool, base: Double = 0.05) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.86).delay(base * Double(index)),
                value: appeared
            )
    }
}

// MARK: - Screen metrics

enum ScreenInsets {
    /// The status-bar / notch inset. Needed when a hero image has to run up
    /// behind a top bar that a `safeAreaInset` has already accounted for —
    /// SwiftUI has consumed the inset by then, so read it from the window.
    static var top: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        return scene?.windows.first { $0.isKeyWindow }?.safeAreaInsets.top
            ?? scene?.windows.first?.safeAreaInsets.top
            ?? 59
    }
}

// MARK: - Trip zoom transition

extension EnvironmentValues {
    /// The namespace the trip cards and the itinerary they push both draw on.
    ///
    /// It has to be shared across two files that never see each other — the
    /// card lives in the Trips list, the destination is declared on the
    /// `NavigationStack` in `RootTabView` — so it travels through the
    /// environment rather than being passed down by hand. Optional so a view
    /// used outside that stack (previews, the map) simply doesn't animate
    /// rather than needing a namespace it has no business owning.
    @Entry var tripZoomNamespace: Namespace.ID?
}

extension View {
    /// Marks this card as where the itinerary should appear to grow from.
    @ViewBuilder
    func tripZoomSource(_ id: UUID, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    /// The other half: the pushed screen zooms out of the matching card, and
    /// back into it on the way out — including interactively, so a
    /// swipe-to-go-back shrinks the page back onto the card under your thumb.
    @ViewBuilder
    func tripZoomDestination(_ id: UUID, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

// MARK: - Identifiable strings

/// Lets a plain code drive `sheet(item:)`, which needs identity rather than a
/// separate boolean plus a value that can drift out of sync with it.
extension String: @retroactive Identifiable {
    public var id: String { self }
}
