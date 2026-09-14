//
//  EquiIntelligence.swift
//  Equitrip
//

import Foundation
import FoundationModels

/// The on-device Apple Intelligence model behind Equi's chat tab.
///
/// A fresh `LanguageModelSession` is created for every question rather than
/// reused turn over turn. That trades away the *model's own* memory of the
/// exchange — recent turns are folded back in as plain text instead, see
/// `Turn` — for the thing that matters more here: every answer is generated
/// from the trip data as it stands right now, never from a briefing that was
/// accurate when the conversation started but has since drifted, because an
/// expense got logged or a settlement got confirmed mid-chat.
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
    /// carrying the much larger trip briefing forward turn after turn.
    struct Turn {
        let isUser: Bool
        let text: String
    }

    /// A snapshot of the answer as it's being generated: what to say so far,
    /// and the card to draw under it once the model has committed to one.
    struct Reply: Equatable {
        var text: String
        var card: EquiCard?
    }

    /// Streams a reply to `question`. Each element is the *cumulative* text
    /// generated so far — assign it straight to the bubble that's rendering
    /// it, don't append. Never throws: a failure that survives the retry
    /// below arrives as one last yielded chunk explaining what went wrong,
    /// in plain words, so the view never has to know this can fail.
    @MainActor
    static func streamReply(
        to question: String,
        recent turns: [Turn],
        store: TripStore
    ) -> AsyncThrowingStream<Reply, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await run(question: question, turns: turns, store: store, compact: false, into: continuation)
                } catch is CancellationError {
                    // Nothing to say — the view already tore down for its
                    // own reason (a new question, leaving the tab).
                } catch {
                    // The likeliest cause of a first-pass failure is the
                    // on-device model's small context window — a trip with
                    // enough bookings can still overflow it even after
                    // `EquiContext`'s caps. One retry with the sharply
                    // trimmed `compact` briefing and no chat history covers
                    // that; anything else, this was going to fail either way.
                    do {
                        try await run(question: question, turns: [], store: store, compact: true, into: continuation)
                    } catch {
                        continuation.yield(Reply(text: friendlyMessage(for: error), card: nil))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    @MainActor
    private static func run(
        question: String,
        turns: [Turn],
        store: TripStore,
        compact: Bool,
        into continuation: AsyncThrowingStream<Reply, Error>.Continuation
    ) async throws {
        let instructions = EquiContext.build(store: store, compact: compact)
        let session = LanguageModelSession(instructions: instructions)

        var prompt = ""
        if !turns.isEmpty {
            prompt += "Recent conversation, for context only — answer the question below, don't re-answer these:\n"
            for turn in turns.suffix(6) {
                prompt += "\(turn.isUser ? "User" : "Equi"): \(turn.text)\n"
            }
            prompt += "\n"
        }
        prompt += "User: \(question)"

        // Structured rather than free text: the model fills in a reply *and*
        // picks a card, and constrained decoding means the card is always one
        // this app knows how to draw. See `EquiAnswer`.
        let stream = session.streamResponse(to: prompt, generating: EquiAnswer.self)
        for try await snapshot in stream {
            try Task.checkCancellation()

            let partial = snapshot.content
            var card: EquiCard?
            if let kind = partial.card, kind != .text, let trip = resolveTrip(partial.tripTitle, store: store) {
                card = EquiCard(kind: kind, tripID: trip.id)
            }

            continuation.yield(Reply(text: partial.reply ?? "", card: card))
        }
    }

    /// Matches the trip the model named against the real ones.
    ///
    /// It's given exact titles in the briefing and usually copies one back,
    /// but "the Goa one" and a half-remembered title both need to land
    /// somewhere sensible — hence the widening passes, and the fall back to
    /// whichever trip the rest of the app currently considers current. A card
    /// about the wrong trip is a bug; a card about no trip at all is a blank
    /// space where an answer should be.
    @MainActor
    private static func resolveTrip(_ title: String?, store: TripStore) -> Trip? {
        let query = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !query.isEmpty {
            if let exact = store.trips.first(where: { $0.title.lowercased() == query }) { return exact }
            if let partial = store.trips.first(where: {
                let title = $0.title.lowercased()
                return title.contains(query) || query.contains(title) || $0.destination.lowercased().contains(query)
            }) { return partial }
        }

        return store.selectedTrip ?? store.currentTrip ?? store.trips.first
    }

    /// Plain-language stand-ins for the model's own error cases — most of
    /// which describe something a user has no way to act on ("guardrail
    /// violation", "decoding failure").
    private static func friendlyMessage(for error: Error) -> String {
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return "Something went wrong answering that — try again?"
        }

        switch generationError {
        case .exceededContextWindowSize:
            return "That's a lot of trip to hold in one go — try asking about something more specific."
        case .guardrailViolation, .refusal:
            return "I can't help with that one."
        case .rateLimited, .concurrentRequests:
            return "Still catching up on the last question — give me a moment and try again."
        case .unsupportedLanguageOrLocale:
            return "I can only reply in a language my on-device model supports."
        default:
            return generationError.errorDescription ?? "Something went wrong answering that — try again?"
        }
    }
}
