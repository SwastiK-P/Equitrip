//
//  EquitripShortcuts.swift
//  Equitrip
//

import AppIntents

/// Publishes "Add expense" as an App Shortcut.
///
/// The Control Centre button and this are not the same thing, which is easy to
/// miss: a `ControlWidget` only ever appears in the controls gallery, and an
/// intent that no `AppShortcutsProvider` names is invisible everywhere else —
/// no entry under a long press on the app icon, nothing in Spotlight, nothing
/// to say to Siri. The build says so out loud ("No AppShortcuts found") and it
/// is the reason the quick action was missing from every surface except the
/// one the control put it on.
///
/// Declared in the app rather than the extension because these are the app's
/// shortcuts; the intent itself is shared with the widget target so that
/// `openAppWhenRun` can re-run it inside the app — see [AddExpenseIntent].
struct EquitripShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                // Every phrase has to contain the app name token, and these
                // are the three ways a person actually says it out loud.
                "Add an expense in \(.applicationName)",
                "Log an expense in \(.applicationName)",
                "Split a bill in \(.applicationName)"
            ],
            shortTitle: "Add expense",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: OpenEquiIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Open Equi in \(.applicationName)",
                "Ask Equi in \(.applicationName)"
            ],
            shortTitle: "Ask Equi",
            // Siri and Spotlight take a system name only, so the app's own
            // glyph cannot travel here — this is the nearest system symbol
            // for "the assistant".
            systemImageName: "sparkles"
        )
    }
}
