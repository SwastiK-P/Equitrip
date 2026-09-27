//
//  EquiAgent.swift
//  Equitrip
//

import Observation
import SwiftUI
import UIKit

/// Equi with its hands on the app: runs an `EquiAgentTask`, moving a cursor to
/// each control and pressing it, typing into fields, and stopping to ask when
/// the request left something open.
///
/// One run at a time, app-wide — a singleton like `AppNavigator`, because the
/// overlay window, the Live Activity's buttons and the screens being driven
/// all need the same one, and none of them are under the chat that started it.
///
/// **With the screen off.** A run that loses the foreground — the phone
/// locked, the app swiped away mid-job — can't present sheets or move a
/// cursor anyone can see, so it goes *headless* for the rest of the run: each
/// step is still announced (the Live Activity is the screen now), and the
/// commit goes straight to the store through the task's own fallback instead
/// of the button. Headless is sticky for the run; switching back to the
/// screen halfway would drive a UI whose earlier steps never happened. The
/// same fallback catches a control that never turned up, so a job that can
/// be done is done even when the choreography can't finish.
@MainActor
@Observable
final class EquiAgent {
    static let shared = EquiAgent()

    enum Mood: Equatable {
        case working, asking, done, stopped, failed
    }

    struct Ripple: Equatable, Identifiable {
        let id = UUID()
        let point: CGPoint
    }

    // MARK: What the overlay draws

    /// The glow is up. True from the start of a run until the glow has
    /// drawn back into the island.
    private(set) var isRunning = false
    /// 0 — the glow tucked into the Dynamic Island; 1 — all the way round.
    private(set) var reach: Double = 0
    private(set) var mood: Mood = .working
    private(set) var title = ""
    private(set) var symbol = "sparkles"
    private(set) var context = ""
    private(set) var step = EquiAgentAttributes.Step(text: "", symbol: "sparkles")
    private(set) var completed = 0
    private(set) var totalSteps = 1
    private(set) var question: EquiAgentQuestion?
    /// The run has lost the screen — see the type's notes.
    private(set) var isHeadless = false

    private(set) var cursor: CGPoint?
    private(set) var cursorVisible = false
    private(set) var isPressing = false
    private(set) var isTyping = false
    private(set) var ripple: Ripple?
    /// Bumped on every press, so the glow can flare in time with it.
    private(set) var pressCount = 0

    /// What the finished job is called — "Expense logged" — for the HUD.
    private(set) var doneTitle = "Done"

    /// The trip the current run is about. Home's quick add reads it to know
    /// which trip Equi is filing against.
    private(set) var tripID: UUID?

    var progress: Double {
        mood == .done ? 1 : min(0.95, Double(completed) / Double(max(totalSteps, 1)))
    }

    // MARK: Run state

    private var runID = ""
    private var runTask: Task<Void, Never>?
    private var trail: [EquiAgentAttributes.Step] = []
    private var cleanup: [String] = []
    private var committed = false
    private var returnsToChat = true
    private var answer: CheckedContinuation<String, Error>?
    private var answerPoll: Task<Void, Never>?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var observers: [NSObjectProtocol] = []

    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.loseScreen() }
        })
        observers.append(center.addObserver(forName: EquiAgentRemote.answeredNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.collectRemoteAnswer() }
        })
        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.collectRemoteAnswer()
                self?.tidyAfterHeadlessRun()
                // A job that finished out of sight stayed in the Dynamic
                // Island as "done"; you're back, and the chat says it now.
                if self?.isRunning == false { EquiAgentActivityController.dismissFinished() }
            }
        })
    }

    // MARK: - Running

    /// Takes the screen and runs `task`. `onFinish` gets the outcome — nil when
    /// the run was stopped — after the glow has handed back to the chat.
    func start(_ task: EquiAgentTask, onFinish: @escaping (EquiAgentOutcome?, String) -> Void) {
        guard !isRunning else { return }

        runID = UUID().uuidString
        title = task.title
        symbol = task.symbol
        context = ""
        tripID = task.tripID
        totalSteps = max(task.steps, 1)
        completed = 0
        trail = []
        cleanup = task.cleanup
        returnsToChat = task.returnsToChat
        committed = false
        question = nil
        doneTitle = "Done"
        mood = .working
        step = .init(text: "Getting started", symbol: "sparkles")
        isHeadless = UIApplication.shared.applicationState == .background
        isRunning = true
        reach = 0
        cursor = nil
        cursorVisible = false
        EquiAgentRemote.clear()

        EquiAgentOverlay.show()
        beginBackgroundTime()
        EquiAgentActivityController.start(
            runID: runID,
            title: task.title,
            symbol: task.symbol,
            totalSteps: totalSteps,
            state: activityState
        )

        runTask = Task { [weak self] in
            guard let self else { return }
            var outcome: EquiAgentOutcome?
            var failure: String?
            do {
                await self.enter()
                outcome = try await task.script(self)
            } catch is CancellationError {
                // Stopped — by the HUD, or from the Lock Screen.
            } catch let error as EquiAgentError {
                failure = error.message
            } catch {
                failure = "Something went wrong partway through, so I stopped."
            }
            // A task of its own: a stopped run's task is cancelled, and every
            // pause in the hand-back would return at once — the glow would
            // vanish instead of drawing back into the island.
            let (finalOutcome, finalFailure) = (outcome, failure)
            Task { await self.finish(outcome: finalOutcome, failure: finalFailure, onFinish: onFinish) }
        }
    }

    /// Stops the run where it stands. Whatever the screen shows stays shown —
    /// you have the controls back.
    func stop() {
        guard isRunning, mood != .done else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        runTask?.cancel()
        answer?.resume(throwing: CancellationError())
        answer = nil
    }

    /// An answer tapped on the in-app card.
    func respond(_ option: EquiAgentQuestion.Option) {
        deliver(option.id)
    }

    // MARK: - Verbs

    /// Sets what the job is about, once the trip is known — "Goa · 4 people".
    func setContext(_ text: String, tripID: UUID?) {
        context = text
        if let tripID { self.tripID = tripID }
        pushActivity()
    }

    /// A step with nothing to press: something being worked out.
    func note(_ text: String, symbol: String) async throws {
        try Task.checkCancellation()
        begin(text, symbol: symbol)
        await pause(0.55)
        end()
    }

    /// Moves to the control and presses it.
    func tap(_ id: String, _ text: String, symbol: String, settle: Double = 0.45) async throws {
        try Task.checkCancellation()
        begin(text, symbol: symbol)

        if !isHeadless, let target = await locate(id) {
            let point = CGPoint(x: target.frame.midX, y: target.frame.midY)
            await moveCursor(to: point)
            try Task.checkCancellation()
            await press(at: point)
            target.handlers.perform?()
            await pause(settle)
        } else {
            goHeadless()
            await pause(0.6)
        }
        end()
    }

    /// Clicks into the field and types `text` into it.
    func type(_ text: String, into id: String, _ caption: String, symbol: String = "keyboard") async throws {
        try Task.checkCancellation()
        begin(caption, symbol: symbol)

        if !isHeadless, let target = await locate(id) {
            // Aimed at the start of the field, where the caret goes, rather
            // than at its middle.
            let point = CGPoint(x: min(target.frame.minX + 60, target.frame.midX), y: target.frame.midY)
            await moveCursor(to: point)
            await press(at: point)
            isTyping = true
            var typed = ""
            for character in text {
                try Task.checkCancellation()
                typed.append(character)
                target.handlers.setText?(typed)
                if character != " " { UISelectionFeedbackGenerator().selectionChanged() }
                await pause(Double.random(in: 0.045...0.085))
            }
            isTyping = false
            await pause(0.25)
        } else {
            goHeadless()
            await pause(0.6)
        }
        end()
    }

    /// Clicks on a date or time picker and sets it to `date`.
    func pick(_ date: Date, in id: String, _ text: String, symbol: String) async throws {
        try Task.checkCancellation()
        begin(text, symbol: symbol)

        if !isHeadless, let target = await locate(id), let set = target.handlers.setDate {
            // The value sits at the trailing end of a picker row.
            let point = CGPoint(x: max(target.frame.maxX - 70, target.frame.midX), y: target.frame.midY)
            await moveCursor(to: point)
            try Task.checkCancellation()
            await press(at: point)
            withAnimation(.snappy) { set(date) }
            UISelectionFeedbackGenerator().selectionChanged()
            await pause(0.45)
        } else {
            goHeadless()
            await pause(0.6)
        }
        end()
    }

    /// Scrolls a container until the view with `viewID` is in sight.
    func reveal(_ viewID: String, in scroller: String) async {
        guard !isHeadless, let target = EquiAgentTargets.shared.resolve(scroller) else { return }
        withAnimation(.smooth(duration: 0.5)) { target.handlers.reveal?(viewID) }
        await pause(0.55)
    }

    /// The step that makes the change. Pressed on screen like any other, so
    /// the screen's own save runs; `fallback` does the same write through the
    /// store when there's no screen to press it on.
    func commit(_ id: String, _ text: String, symbol: String, fallback: () -> Void) async throws {
        try Task.checkCancellation()
        begin(text, symbol: symbol)

        if !isHeadless, let target = await locate(id), let perform = target.handlers.perform {
            let point = CGPoint(x: target.frame.midX, y: target.frame.midY)
            await moveCursor(to: point)
            try Task.checkCancellation()
            await press(at: point)
            perform()
        } else {
            goHeadless()
            fallback()
        }
        committed = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        await pause(0.7)
        end()
    }

    /// Stops and asks. Answered from the card on screen, or from the Lock
    /// Screen and Dynamic Island when the app is out of sight — which is also
    /// where the question is announced, with a sound, if it's asked then.
    func ask(_ question: EquiAgentQuestion) async throws -> EquiAgentQuestion.Option {
        try Task.checkCancellation()
        begin(question.text, symbol: "questionmark.bubble")

        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            self.question = question
            mood = .asking
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        EquiAgentActivityController.update(activityState, alert: isHeadless || UIApplication.shared.applicationState != .active)

        let chosen: String = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Stopped before the wait began: the cancellation handler has
                // already run, found nothing to resume, and won't run again.
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                answer = continuation
                startPollingForAnswer()
            }
        } onCancel: {
            Task { @MainActor in
                self.answer?.resume(throwing: CancellationError())
                self.answer = nil
            }
        }

        answerPoll?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            self.question = nil
            mood = .working
        }
        guard chosen != EquiAgentRemote.stopID,
              let option = question.options.first(where: { $0.id == chosen })
        else { throw CancellationError() }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // Logged as the answer rather than the question: "who paid?" in the
        // trail says nothing about what happened next.
        step = .init(text: "You said “\(option.label)”", symbol: "checkmark.bubble")
        end()
        return option
    }

    // MARK: - Steps

    private func begin(_ text: String, symbol: String) {
        withAnimation(.snappy) {
            step = .init(text: text, symbol: symbol)
        }
        pushActivity()
    }

    private func end() {
        completed += 1
        trail.append(step)
        if trail.count > 3 { trail.removeFirst(trail.count - 3) }
        pushActivity()
    }

    private var activityState: EquiAgentAttributes.ContentState {
        let phase: EquiAgentAttributes.Phase = switch mood {
        case .working: .working
        case .asking: .asking
        case .done: .done
        case .stopped: .stopped
        case .failed: .failed
        }
        return .init(
            phase: phase,
            context: context,
            completed: min(completed, totalSteps),
            step: step,
            trail: trail,
            question: question?.text,
            options: (question?.options ?? []).prefix(4).map { .init(id: $0.id, label: $0.label) },
            outcomeTitle: nil,
            outcome: nil,
            outcomeValue: nil,
            outcomeDetail: nil
        )
    }

    private func pushActivity() {
        EquiAgentActivityController.update(activityState)
    }

    // MARK: - Cursor

    /// Waits for a control to be on screen and to have stopped moving — a
    /// sheet's buttons are there from the first frame of its slide.
    private func locate(_ id: String) async -> (frame: CGRect, handlers: EquiAgentTargets.Handlers)? {
        let deadline = Date().addingTimeInterval(3.5)
        var last: CGRect?
        while Date() < deadline {
            if Task.isCancelled || isHeadless { return nil }
            if let found = EquiAgentTargets.shared.resolve(id) {
                if let last, abs(last.minX - found.frame.minX) < 0.5, abs(last.minY - found.frame.minY) < 0.5 {
                    return found
                }
                last = found.frame
            }
            await pause(0.08)
        }
        return nil
    }

    private func moveCursor(to point: CGPoint) async {
        let from = cursor ?? Self.restingPoint
        if cursor == nil { cursor = from }
        if !cursorVisible {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { cursorVisible = true }
        }
        let distance = hypot(point.x - from.x, point.y - from.y)
        let duration = min(0.9, max(0.35, 0.25 + distance / 1100))
        withAnimation(.timingCurve(0.32, 0.02, 0.18, 1, duration: duration)) { cursor = point }
        await pause(duration + 0.06)
    }

    private func press(at point: CGPoint) async {
        withAnimation(.spring(response: 0.16, dampingFraction: 0.6)) { isPressing = true }
        ripple = Ripple(point: point)
        pressCount += 1
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.9)
        await pause(0.13)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { isPressing = false }
        await pause(0.08)
    }

    /// Where the cursor first appears: rising out of the chat's composer.
    private static var restingPoint: CGPoint {
        let bounds = EquiAgentTargets.mainWindow?.bounds ?? CGRect(x: 0, y: 0, width: 402, height: 874)
        return CGPoint(x: bounds.midX + 60, y: bounds.maxY - 150)
    }

    // MARK: - Arrival and departure

    private func enter() async {
        guard !isHeadless else {
            reach = 1
            return
        }
        withAnimation(.easeOut(duration: 1.0)) { reach = 1 }
        cursor = Self.restingPoint
        await pause(0.35)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { cursorVisible = true }
        await pause(0.45)
    }

    private func finish(outcome: EquiAgentOutcome?, failure: String?, onFinish: @escaping (EquiAgentOutcome?, String) -> Void) async {
        answerPoll?.cancel()
        question = nil
        isTyping = false

        let chat: String
        var final = activityState
        if let outcome {
            mood = .done
            step = .init(text: "\(outcome.headline) · \(outcome.value)", symbol: "checkmark")
            doneTitle = outcome.title
            chat = outcome.chat
            final = activityState
            final.phase = .done
            final.outcomeTitle = outcome.title
            final.outcome = outcome.headline
            final.outcomeValue = outcome.value
            final.outcomeDetail = outcome.detail
        } else if let failure {
            mood = .failed
            step = .init(text: "Couldn't finish", symbol: "exclamationmark.triangle")
            chat = failure
            final = activityState
            final.phase = .failed
            final.outcomeTitle = "Couldn't finish"
            final.outcomeDetail = failure
        } else {
            mood = .stopped
            step = .init(text: "Stopped", symbol: "hand.raised")
            chat = committed
                ? "Stopped — though the change had already gone through."
                : "Stopped. Nothing was saved — the screen is yours."
            final = activityState
            final.phase = .stopped
            final.outcomeTitle = "Stopped"
            final.outcome = committed ? "Already saved" : "Nothing was saved"
            final.outcomeDetail = committed ? "The change had gone through before you stopped it." : "You have the controls back."
        }
        final.completed = mood == .done ? totalSteps : final.completed

        let onScreen = UIApplication.shared.applicationState == .active && !isHeadless
        EquiAgentActivityController.finish(final, onScreen: onScreen)

        if onScreen {
            // Back to the chat the job came from, the way a person would go:
            // over to the Equi tab. A stopped run leaves you where you are.
            await pause(mood == .done ? 0.35 : 0.6)
            if mood != .stopped, returnsToChat, let target = await locate("tab.equi") {
                let point = CGPoint(x: target.frame.midX, y: target.frame.midY)
                await moveCursor(to: point)
                await press(at: point)
                target.handlers.perform?()
                await pause(0.3)
            }
            withAnimation(.easeOut(duration: 0.25)) { cursorVisible = false }
            onFinish(outcome, chat)
            await pause(0.5)
        } else {
            // Nobody's watching: go straight back to the chat, so it's where
            // the app opens with the answer already in it.
            if returnsToChat { EquiAgentTargets.shared.handlers("tab.equi")?.perform?() }
            cursorVisible = false
            onFinish(outcome, chat)
        }

        withAnimation(.easeInOut(duration: 0.8)) { reach = 0 }
        await pause(0.85)
        isRunning = false
        cursor = nil
        runTask = nil
        endBackgroundTime()
        EquiAgentOverlay.hide()
        if !onScreen, UIApplication.shared.applicationState == .active { tidyAfterHeadlessRun() }
    }

    // MARK: - Losing the screen

    private func loseScreen() {
        guard isRunning, !isHeadless else { return }
        goHeadless()
    }

    private func goHeadless() {
        guard !isHeadless else { return }
        isHeadless = true
        isTyping = false
        withAnimation(.easeOut(duration: 0.2)) { cursorVisible = false }
    }

    /// Closes what a headless run left open, once the app is back on screen.
    private func tidyAfterHeadlessRun() {
        guard !isRunning, !cleanup.isEmpty else { return }
        for id in cleanup { EquiAgentTargets.shared.handlers(id)?.perform?() }
        cleanup = []
    }

    private func beginBackgroundTime() {
        endBackgroundTime()
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Equi") { [weak self] in
            MainActor.assumeIsolated { self?.endBackgroundTime() }
        }
    }

    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - Answers

    private func deliver(_ optionID: String) {
        guard let answer else { return }
        self.answer = nil
        answer.resume(returning: optionID)
    }

    private func collectRemoteAnswer() {
        guard answer != nil, let optionID = EquiAgentRemote.takeAnswer(for: runID) else { return }
        deliver(optionID)
    }

    /// The Lock Screen's buttons write to the app group as well as posting,
    /// and a post can arrive while nothing's listening; checking the group
    /// too means a tapped answer is never the one that went missing.
    private func startPollingForAnswer() {
        answerPoll?.cancel()
        answerPoll = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(400))
                self?.collectRemoteAnswer()
            }
        }
        // A question can outlast the background time a run was given; asking
        // for more keeps the wait alive while the Lock Screen is the only way in.
        if UIApplication.shared.applicationState != .active { beginBackgroundTime() }
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}
