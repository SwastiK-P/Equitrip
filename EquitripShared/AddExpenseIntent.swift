//
//  AddExpenseIntent.swift
//  EquitripShared
//

import AppIntents
import Foundation

/// Opens the app on the quick-add sheet.
///
/// Lives in the shared sources, compiled into *both* the app and the widget
/// extension, and that is not tidiness — it is the thing that makes the
/// control work at all. `openAppWhenRun` does not simply launch the app: the
/// system launches it and re-runs `perform()` in the app's own process, so the
/// app binary has to carry this intent in its `Metadata.appintents`. Declared
/// only in the extension, the app extracts no intent symbols at build time,
/// the launch resolves to nothing, and the press does nothing at all — no
/// error, no app, no sheet.
///
/// It deliberately does not try to be a fill-in-the-blanks shortcut. Nothing
/// about an expense can be captured without a keypad, and an amount with no
/// payer and no split is a row somebody has to go and fix later — so the
/// intent's whole job is to get the app up on the right sheet, which is the
/// part that was slow.
struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add expense"
    static let description = IntentDescription(
        "Opens Equitrip ready to log an expense on the trip you're on."
    )

    /// The one thing that opens the app. Setting this *and* returning an
    /// `OpensIntent` from `perform()` is what broke the control before: the
    /// system is handed two different instructions for the same press and
    /// carries out neither, so the button flashed and nothing happened.
    static let openAppWhenRun = true

    /// Leaves the route where the app will find it, then gets out of the way
    /// and lets `openAppWhenRun` bring the app up.
    ///
    /// The write happens before the app is in front, so whichever way the app
    /// arrives — cold launch, unlock, or already on screen under Control
    /// Centre — the route is already sitting there to be read.
    @MainActor
    func perform() async throws -> some IntentResult {
        SharedStore.post(.addExpense)
        return .result()
    }
}
