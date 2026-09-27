//
//  EquiAgentActivity.swift
//  EquitripShared
//

#if os(iOS)
import ActivityKit
import AppIntents
import Foundation

/// Equi working through the app on your behalf, as the Lock Screen and the
/// Dynamic Island show it.
///
/// Shared because both ends need the one type: the app starts and updates the
/// activity as each step lands, the widget extension draws it. Pre-formatted
/// strings only, for the same reason `EquitripSnapshot` is — the extension
/// never signs in and has no trips to format from.
///
/// iOS only: the watch compiles this folder too and has no ActivityKit to
/// start one with (a phone's activity reaches the wrist's Smart Stack on its own).
nonisolated struct EquiAgentAttributes: ActivityAttributes {
    /// Ties a button press on the activity to the run that drew it, so an
    /// answer tapped on a stale activity can't steer a newer run.
    var runID: String
    /// The job, as a line: "Logging an expense".
    var title: String
    var symbol: String
    var totalSteps: Int
    /// When the run began — the Lock Screen counts up from it.
    var startedAt: Date

    struct ContentState: Codable, Hashable {
        var phase: Phase
        /// The trip being worked on, once it's known — "Goa · 4 people".
        var context: String
        var completed: Int
        /// What's happening right now.
        var step: Step
        /// The last few steps that finished, oldest first.
        var trail: [Step]
        var question: String?
        var options: [Option]
        /// What the run came to, when it has stopped: a title ("Expense
        /// logged"), the thing ("Auto rickshaw"), its figure ("₹250") and a
        /// line under them.
        var outcomeTitle: String?
        var outcome: String?
        var outcomeValue: String?
        var outcomeDetail: String?
    }

    enum Phase: String, Codable, Hashable {
        case working, asking, done, stopped, failed

        var isOver: Bool { self == .done || self == .stopped || self == .failed }
    }

    struct Step: Codable, Hashable {
        var text: String
        var symbol: String
    }

    struct Option: Codable, Hashable, Identifiable {
        var id: String
        var label: String
    }
}

/// An answer to Equi's question, tapped on the Lock Screen or in the Dynamic
/// Island — or "Stop", which is an answer too.
///
/// A `LiveActivityIntent`, so the system runs it in the app's own process
/// (waking it in the background if it has to), where the run that asked is
/// waiting. Also written to the app group: which process serves a press is
/// the system's call, and the run polls for its answer as well as listening.
struct EquiAgentAnswerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Answer Equi"
    static let isDiscoverable = false

    @Parameter(title: "Run") var runID: String
    @Parameter(title: "Answer") var optionID: String

    init() {}

    init(runID: String, optionID: String) {
        self.runID = runID
        self.optionID = optionID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        EquiAgentRemote.post(runID: runID, optionID: optionID)
        return .result()
    }
}

/// The wire between an activity's buttons and the run in the app.
@MainActor
enum EquiAgentRemote {
    /// The option id "Stop" sends.
    static let stopID = "equi.stop"
    static let answeredNotification = Notification.Name("com.swastik.Equitrip.equiAgentAnswered")
    private static let darwinName = "com.swastik.Equitrip.equiAgentAnswered"
    private static let answerKey = "equiAgent.answer"

    static func post(runID: String, optionID: String) {
        SharedStore.defaults?.set("\(runID)|\(optionID)", forKey: answerKey)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(darwinName as CFString),
            nil, nil, true
        )
        NotificationCenter.default.post(name: answeredNotification, object: nil)
    }

    /// Reads and clears the answer left for `runID`, if there is one.
    static func takeAnswer(for runID: String) -> String? {
        guard let raw = SharedStore.defaults?.string(forKey: answerKey) else { return nil }
        let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, parts[0] == runID else { return nil }
        SharedStore.defaults?.removeObject(forKey: answerKey)
        return parts[1]
    }

    static func clear() {
        SharedStore.defaults?.removeObject(forKey: answerKey)
    }
}
#endif
