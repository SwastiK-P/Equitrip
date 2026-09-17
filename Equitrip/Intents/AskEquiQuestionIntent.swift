//
//  AskEquiQuestionIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// "Ask Equitrip who paid for the villa" — Equi's answer, spoken by Siri,
/// without the app coming forward.
///
/// Where `OpenEquiIntent` opens the tab and waits for a question, this one
/// arrives *with* the question and answers it in place. It is the same Equi:
/// the same briefing (`EquiContext`), the same on-device model, the same
/// structured answer — so a card the model picks is drawn under Siri's reply
/// exactly as it would be in the thread, live off the store, and the model
/// never gets to restate a figure it could get wrong.
///
/// Background by default. When the model can't run on this device there is no
/// answer to give without the app, so it says why rather than opening a tab
/// that would say the same thing.
struct AskEquiQuestionIntent: AppIntent {

    static let title: LocalizedStringResource = "Ask Equi a Question"
    static let description = IntentDescription(
        "Asks Equi, Equitrip's trip assistant, about your trips — plans, bookings, who paid and who owes — and reads out the answer.",
        categoryName: "Equi"
    )
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Question", requestValueDialog: "What would you like to know?")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Ask Equi \(\.$question)")
    }

    init() {}

    init(question: String) {
        self.question = question
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog & ShowsSnippetView {
        let asked = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !asked.isEmpty else { throw $question.needsValueError("What would you like to know?") }

        if case .unavailable(let reason) = EquiIntelligence.availability {
            throw IntentFailure.modelUnavailable(reason)
        }

        let store = try await IntentStores.store()

        // The stream is how the tab draws a reply as it arrives; Siri speaks
        // once, so it only needs where the stream ended up.
        var reply = EquiIntelligence.Reply(text: "", card: nil)
        for try await chunk in EquiIntelligence.streamReply(to: asked, recent: [], store: store) {
            reply = chunk
        }

        let text = reply.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let spoken = text.isEmpty ? "I couldn't find an answer to that in your trips." : text

        return .result(
            value: spoken,
            dialog: IntentDialog(full: "\(spoken)", supporting: "\(spoken)"),
            view: EquiSiriAnswer(card: reply.card).environment(\.tripStore, store)
        )
    }
}

/// The card under Siri's reply, when Equi picked one; nothing when the answer
/// was only words.
private struct EquiSiriAnswer: View {
    let card: EquiCard?

    var body: some View {
        if let card {
            EquiCardView(card: card)
                .padding()
        }
    }
}
