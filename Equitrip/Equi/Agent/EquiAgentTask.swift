//
//  EquiAgentTask.swift
//  Equitrip
//

import Foundation

/// A job Equi does by working the app itself — pressing the same buttons,
/// typing into the same fields — rather than by writing to the store behind
/// the screen's back.
///
/// The script is plain async Swift against `EquiAgent`'s verbs (`tap`, `type`,
/// `ask`, `commit`), so a job reads top to bottom as the path a person would
/// take, and can stop halfway to ask something and branch on the answer.
struct EquiAgentTask {
    /// The job as a line, for the HUD and the Live Activity: "Logging an expense".
    let title: String
    let symbol: String
    /// Roughly how many steps the script takes, for the progress bar. A guess
    /// is fine: the bar is capped, and it fills when the run ends.
    let steps: Int
    /// What Equi says in the chat before it takes the screen.
    let opening: String
    /// The trip the job is on, when the request already said.
    var tripID: UUID?
    /// Controls to press if the run finished while the app was in the
    /// background — closing a sheet the script had opened before the screen
    /// went dark, so coming back doesn't land on a half-filled form for a job
    /// that's already done.
    var cleanup: [String] = []
    /// Whether the cursor walks back to the Equi tab at the end. False for a
    /// job started from a screen of its own — the Weather Twin's Plan B — where
    /// the tab bar sits under a full-screen cover and the answer belongs on
    /// the screen that asked.
    var returnsToChat = true
    let script: @MainActor (EquiAgent) async throws -> EquiAgentOutcome
}

/// What a job came to, told for the Live Activity's done card and the chat.
struct EquiAgentOutcome {
    /// What happened, as a title: "Expense logged".
    var title: String
    /// The thing it happened to: "Auto rickshaw".
    var headline: String
    /// Its figure, copied from the job: "₹250".
    var value: String
    var detail: String
    var chat: String
    var tripID: UUID?
    var suggestions: [String] = []
    /// False when the job finished by deciding to leave things as they were
    /// ("keep the walk"), so whatever started it isn't marked done.
    var changedTrip = true
}

/// A question Equi stops to ask partway through a job — the one thing it can't
/// work out from the request or the trip.
struct EquiAgentQuestion: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var options: [Option]

    struct Option: Identifiable, Equatable {
        let id: String
        let label: String
        var symbol: String?
        /// Drawn as the person's face on the in-app card. The Live Activity
        /// can't load avatars and shows the label alone.
        var traveller: Traveller?
    }
}

/// A job that couldn't finish, with the reason as Equi would say it.
struct EquiAgentError: Error {
    let message: String
}
