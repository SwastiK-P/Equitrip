//
//  ToastCenter.swift
//  Equitrip
//

import SwiftUI

/// Settlement updates, the only toasts nobody asked for.
///
/// Nothing else in the app pushes anything to screen uninvited — every other
/// surface waits for you to pull it up (the bell, the ledger, the Settle tab).
/// A settlement someone else just confirmed or declined is different: it's the
/// one event that changes a number you might be looking at *right now*, on a
/// screen that has no reason to be polling for it. `GlassToastCenter` is the
/// general-purpose toast; this one only adds the settlement-specific parts.
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

    /// Set by whoever owns the app-level sheet — see `RootTabView`. Kept as a
    /// closure rather than routing the toast through the environment as
    /// state, because presenting from a tap has to happen at the root, above
    /// whichever tab is on screen when it arrives.
    var onTap: ((Toast) -> Void)?

    /// Drawn by `GlassToastCenter`, like every other toast, so a settlement
    /// update drips out of the Dynamic Island and stays above a sheet
    /// rather than being covered by one. This type decides only what a
    /// settlement toast says, how it feels, and where tapping it goes.
    func show(_ toast: Toast) {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(toast.kind == .declined ? .warning : .success)

        GlassToastCenter.shared.show(.init(
            symbol: Self.symbol(for: toast.kind),
            tint: Self.tint(for: toast.kind),
            title: toast.title,
            subtitle: toast.subtitle,
            onTap: { [weak self] in self?.onTap?(toast) }
        ))
    }

    private static func symbol(for kind: Toast.Kind) -> String {
        switch kind {
        case .requested: "arrow.left.arrow.right.circle.fill"
        case .confirmed: "checkmark.seal.fill"
        case .declined: "xmark.seal.fill"
        }
    }

    private static func tint(for kind: Toast.Kind) -> Color {
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
