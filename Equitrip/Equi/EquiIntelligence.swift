//
//  EquiIntelligence.swift
//  Equitrip
//

import Foundation
import FoundationModels

/// The on-device Apple Intelligence model behind Equi's chat tab, and the
/// order it's asked things in.
///
/// Three steps a question, where there used to be one:
///
/// 1. **Read** the question into an `EquiQuery` — which trips, what about
///    (`EquiQueryReader`: word rules plus a small classification pass).
/// 2. **Answer** it in Swift (`EquiFacts`): the figures, a card narrowed to
///    the question, a sentence that says it, and follow-ups to offer.
/// 3. **Say** it. For anything about the trips' own plan, people and money,
///    Swift's sentence *is* the reply. The model was tried as the writer:
///    given only the right figures, it still ranked ₹63,900 above ₹95,600
///    and said Kim paid the most while quoting what Kim owed — every number
///    real, the relationship between them invented, which no check on the
///    numbers can catch. The model writes only advice and small talk, from
///    general knowledge plus the trip's facts, and a reply naming a figure
///    the facts don't contain is replaced (`isGrounded`).
///
/// Without Apple Intelligence the rules read the question alone and every
/// answer about the trips still works.
///
/// A fresh `LanguageModelSession` is created for every question: every
/// answer comes from the trips as they are now, and earlier turns are folded
/// back in as plain text (`Turn`), carrying the trip each was about so a
/// follow-up that names none stays on it.
enum EquiIntelligence {

    enum Availability: Equatable {
        case ready
        case unavailable(String)
    }

    /// Whether this device can actually run the model, and why not when it
    /// can't — surfaced as a message bubble rather than a disabled composer,
    /// so "why doesn't this work" is answered inline instead of by a greyed
    /// out button.
    @MainActor
    static var availability: Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(.deviceNotEligible):
            return .unavailable("This device can't run Apple Intelligence, so I can't answer yet.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Turn on Apple Intelligence in Settings to chat with me.")
        case .unavailable(.modelNotReady):
            return .unavailable("My on-device model is still downloading — try again in a bit.")
        case .unavailable:
            return .unavailable("I'm not available on this device right now.")
        }
    }

    /// One prior turn, folded back into the next prompt so the model can
    /// resolve "that one" or "the other trip" without the session itself
    /// carrying anything forward.
    struct Turn {
        let isUser: Bool
        let text: String
        /// The trip that turn's answer was about.
        var tripID: UUID?
        var card: EquiCard?
    }

    /// A snapshot of the answer as it's being generated.
    struct Reply: Equatable {
        var text: String
        var card: EquiCard?
        /// Offered as chips once the reply is complete.
        var suggestions: [String] = []
        /// The trip this answer was about, card or not.
        var focusTripID: UUID?
    }

    /// Streams a reply to `question`. Each element is the *cumulative* reply
    /// so far — assign it straight to the bubble that's rendering it, don't
    /// append. The last element carries the suggestions. Never throws: a
    /// failure arrives as Swift's own answer to the question, which is always
    /// there to fall back on.
    @MainActor
    static func streamReply(
        to question: String,
        recent turns: [Turn],
        store: TripStore
    ) -> AsyncThrowingStream<Reply, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let canThink = availability == .ready
                let query = await EquiQueryReader.read(question, turns: turns, store: store, useModel: canThink)
                guard !Task.isCancelled else { return continuation.finish() }

                let facts = EquiFacts.answer(query, store: store)
                let asked = EquiQueryReader.Cues.normalise(question)
                var reply = Reply(
                    text: "",
                    card: facts.card,
                    suggestions: [],
                    focusTripID: facts.focusTripID
                )
                let suggestions = Array(facts.suggestions.filter { EquiQueryReader.Cues.normalise($0) != asked }.prefix(3))

                if facts.allowsGeneralKnowledge, availability == .ready {
                    do {
                        let written = try await write(question: question, turns: turns, facts: facts) { partial in
                            reply.text = partial
                            continuation.yield(reply)
                        }
                        let sources = facts.lines + [facts.headline, question] + turns.map(\.text)
                        reply.text = written.isEmpty || !isGrounded(written, in: sources) ? facts.headline : written
                    } catch {
                        guard !Task.isCancelled else { return continuation.finish() }
                        // The model's own failures — a guardrail, a full
                        // context — aren't the user's problem when Swift
                        // already has something to say.
                        reply.text = facts.headline
                    }
                } else if case .unavailable(let reason) = availability, query.topic == .advice {
                    reply.text = reason
                } else {
                    // Figures, and how they relate, are Swift's to say.
                    await reveal(facts.headline, into: &reply, continuation: continuation)
                    guard !Task.isCancelled else { return continuation.finish() }
                    reply.text = facts.headline
                }

                reply.suggestions = suggestions
                continuation.yield(reply)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Lays a finished answer down a few words at a time, so a reply Swift
    /// wrote arrives the way a written one does rather than in one jump.
    @MainActor
    private static func reveal(
        _ text: String,
        into reply: inout Reply,
        continuation: AsyncThrowingStream<Reply, Error>.Continuation
    ) async {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var shown = ""
        for (index, word) in words.enumerated() {
            shown += (index == 0 ? "" : " ") + word
            guard index % 2 == 1 || index == words.count - 1 else { continue }
            reply.text = shown
            continuation.yield(reply)
            try? await Task.sleep(for: .milliseconds(28))
            if Task.isCancelled { return }
        }
    }

    /// Streams the model's reply through `onPartial`, and returns where it
    /// ended up.
    @MainActor
    private static func write(
        question: String,
        turns: [Turn],
        facts: EquiFacts,
        onPartial: (String) -> Void
    ) async throws -> String {
        let session = LanguageModelSession(instructions: EquiContext.instructions(for: facts))

        var prompt = ""
        if !turns.isEmpty {
            prompt += "Earlier in this conversation, for context only — answer the latest question, don't re-answer these:\n"
            for turn in turns.suffix(4) {
                prompt += "\(turn.isUser ? "User" : "Equi"): \(turn.text.prefix(240))\n"
            }
            prompt += "\n"
        }
        prompt += "Latest question: \(question)"

        var text = ""
        let stream = session.streamResponse(to: prompt, options: GenerationOptions(temperature: 0.5))
        for try await snapshot in stream {
            try Task.checkCancellation()
            text = snapshot.content
            onPartial(text)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Grounding

    /// Whether every figure in a reply appears in what it was written from.
    ///
    /// The model is told to copy amounts and dates, and mostly does; this is
    /// for the time it doesn't. Money is always checked, and so is any number
    /// of 100 or more — days, counts and percentages below that pass, since
    /// "3 nights" is a fair reading of two dates and a wrong one is harmless.
    static func isGrounded(_ reply: String, in sources: [String]) -> Bool {
        let allowed = Set(sources.flatMap { figures(in: $0).map(\.value) })
        return figures(in: reply).allSatisfy { figure in
            allowed.contains(figure.value) || (!figure.isMoney && (Double(figure.value) ?? 0) < 100)
        }
    }

    private static let figurePattern = #/([₹$€£¥]\s?)?(\d[\d,]*(?:\.\d+)?)/#

    private static func figures(in text: String) -> [(value: String, isMoney: Bool)] {
        text.matches(of: figurePattern).map { match in
            var value = String(match.output.2).replacingOccurrences(of: ",", with: "")
            if value.contains(".") {
                while value.hasSuffix("0") { value.removeLast() }
                if value.hasSuffix(".") { value.removeLast() }
            }
            return (value, match.output.1 != nil)
        }
    }

    /// Plain-language stand-ins for the model's own error cases — most of
    /// which describe something a user has no way to act on ("guardrail
    /// violation", "decoding failure").
    ///
    /// iOS 27 throws `LanguageModelError` in place of the deprecated
    /// `GenerationError`. Matching only the old type left every failure on the
    /// generic apology — and Siri, which reads this aloud, saying it too.
    static func friendlyMessage(for error: Error) -> String {
        if case LanguageModelSession.Error.concurrentRequests = error {
            return "Still catching up on the last question — give me a moment and try again."
        }
        guard let modelError = error as? LanguageModelError else {
            return "Something went wrong answering that — try again?"
        }

        switch modelError {
        case .contextSizeExceeded:
            return "That's a lot of trip to hold in one go — try asking about something more specific."
        case .guardrailViolation, .refusal:
            return "I can't help with that one."
        case .rateLimited, .timeout:
            return "Still catching up on the last question — give me a moment and try again."
        case .unsupportedLanguageOrLocale:
            return "I can only reply in a language my on-device model supports."
        default:
            return modelError.errorDescription ?? "Something went wrong answering that — try again?"
        }
    }
}
