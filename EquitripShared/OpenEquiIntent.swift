//
//  OpenEquiIntent.swift
//  EquitripShared
//

import AppIntents
import Foundation

/// Opens the app on Equi.
///
/// Lives beside [AddExpenseIntent] in the shared sources, and for the same
/// non-obvious reason: `openAppWhenRun` re-runs `perform()` inside the app, so
/// the app binary — not just the widget extension — has to carry the intent in
/// its `Metadata.appintents`, or the press resolves to nothing at all.
///
/// Where the expense control exists because logging a payment at the table is
/// slow, this one exists because a question about the trip arrives with no
/// screen attached to it — "when does the Rome train go", "how much am I down"
/// — and the four taps to Equi are four taps spent before the question can
/// even be asked.
struct OpenEquiIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Equi"
    static let description = IntentDescription(
        "Opens Equitrip on Equi, ready for a question about your trip."
    )

    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedStore.post(.equi)
        return .result()
    }
}
