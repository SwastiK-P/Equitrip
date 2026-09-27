//
//  EquiAgentActivityController.swift
//  Equitrip
//

import ActivityKit
import Foundation

/// Starts, moves and ends the Live Activity for a run of `EquiAgent`.
///
/// Started with every run, not only when the app goes to the background: the
/// system keeps an app's own activity out of the Dynamic Island while the app
/// is in front, so it costs nothing on screen, and it's already there the
/// moment the phone is locked or the app swiped away — which is exactly when
/// it's needed and too late to start one.
@MainActor
enum EquiAgentActivityController {
    private static var activity: Activity<EquiAgentAttributes>?
    /// A job that finished out of sight, left up as "done" until you're back.
    private static var finished: Activity<EquiAgentAttributes>?
    /// The last state sent, so a step that changes nothing isn't sent twice —
    /// the system budgets how often an activity may change.
    private static var lastState: EquiAgentAttributes.ContentState?

    static func start(runID: String, title: String, symbol: String, totalSteps: Int, state: EquiAgentAttributes.ContentState) {
        endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = EquiAgentAttributes(runID: runID, title: title, symbol: symbol, totalSteps: totalSteps, startedAt: Date())
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil, relevanceScore: 100),
                pushType: nil
            )
            lastState = state
        } catch {
            activity = nil
        }
    }

    /// `alert` lights the Dynamic Island up and plays a sound — for a question
    /// asked while the app is out of sight, which nobody would otherwise see.
    static func update(_ state: EquiAgentAttributes.ContentState, alert: Bool = false) {
        guard let activity, state != lastState || alert else { return }
        lastState = state
        let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
        Task {
            if alert {
                await activity.update(content, alertConfiguration: AlertConfiguration(
                    title: "Equi needs you",
                    body: LocalizedStringResource(stringLiteral: state.question ?? state.step.text),
                    sound: .default
                ))
            } else {
                await activity.update(content)
            }
        }
    }

    /// Puts the activity on its final state.
    ///
    /// On screen, the chat already says it, so the activity ends at once.
    /// Out of sight, it is *updated*, not ended: an ended activity leaves the
    /// Dynamic Island straight away, and a job that finished with the phone in
    /// a pocket should sit there as done — the thing to glance at — until the
    /// app is opened again (`dismissFinished`).
    static func finish(_ state: EquiAgentAttributes.ContentState, onScreen: Bool) {
        guard let activity else { return }
        self.activity = nil
        lastState = nil
        let content = ActivityContent(state: state, staleDate: nil, relevanceScore: 100)
        if onScreen {
            Task { await activity.end(content, dismissalPolicy: .immediate) }
        } else {
            finished = activity
            Task { await activity.update(content) }
        }
    }

    /// Ends a finished job's activity, now that the app is in front.
    static func dismissFinished() {
        guard let finished else { return }
        self.finished = nil
        Task { await finished.end(nil, dismissalPolicy: .immediate) }
    }

    /// Ends every Equi activity still up but the running one — at launch,
    /// where one left behind belongs to a run that died with its process, and
    /// before a new run, which replaces a finished one.
    static func endAll() {
        finished = nil
        for stale in Activity<EquiAgentAttributes>.activities where stale.id != activity?.id {
            Task {
                var state = stale.content.state
                if !state.phase.isOver {
                    state.phase = .stopped
                    state.question = nil
                    state.options = []
                    state.outcomeTitle = "Stopped"
                    state.outcome = "Equi was closed"
                    state.outcomeDetail = "It stopped before it finished."
                }
                await stale.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
    }
}
