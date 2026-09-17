//
//  AskEquiControl.swift
//  EquitripWidgets
//

import AppIntents
import SwiftUI
import WidgetKit

/// Equi in one press, from Control Centre, the Lock Screen, or the Action
/// button.
///
/// Kept as its own `ControlWidget` rather than folded into the expense one:
/// the controls gallery is a list of single-purpose buttons, and a control
/// that could mean two things is one a person has to stop and think about
/// before pressing — which is the entire cost this is meant to remove.
struct AskEquiControl: ControlWidget {
    static let kind = "EquitripAskEqui"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenEquiIntent()) {
                // Equi's own face, so the button in the controls gallery is
                // recognisably the same character the tab bar shows. The
                // extension cannot read the app's asset catalogue, so the
                // symbol is carried again in `WidgetAssets.xcassets`; it is an
                // SF Symbol template, which is what lets Control Centre tint
                // and scale it like any system glyph.
                Label("Ask Equi", image: "Equi")
            }
        }
        .displayName("Ask Equi")
        .description("Open Equi and ask about the trip you're on.")
    }
}
