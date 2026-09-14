//
//  SnapshotStyle.swift
//  EquitripShared
//

import SwiftUI

/// The colours a snapshot figure is drawn in, for every surface that draws
/// one without the app's model — the widgets and the watch.
///
/// Both used to be able to hold their own copy, and the moment there are two
/// copies of "which kind is blue" one of them is wrong. So they live here,
/// beside the snapshot they colour.

// MARK: - Money tone

/// Direction, not sentiment — the same rule `AppTheme` states for the app.
enum MoneyTone {
    static func of(_ amount: Double) -> Color {
        if amount > 0 { return Brand.accent }
        if amount < 0 { return Brand.danger }
        return Brand.inkSecondary
    }
}

// MARK: - Category tints

extension EquitripSnapshot.Event {
    /// The rail colour, matched to `ItineraryKind.tint` on the app side.
    ///
    /// Resolved from the raw string rather than shipped as a colour, because
    /// a `Color` has no honest `Codable` form that survives a change of
    /// appearance — encoding one would freeze the light-mode value into the
    /// shared container and hand the widget the wrong tint in the dark.
    var tint: Color {
        switch kind {
        case "flight": Brand.blue
        case "train": Brand.teal
        case "drive": Brand.indigo
        case "stay": Brand.violet
        case "activity": Brand.green
        case "meal": Brand.amber
        default: Brand.stone
        }
    }
}
