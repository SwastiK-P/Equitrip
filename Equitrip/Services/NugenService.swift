//
//  NugenService.swift
//  Equitrip
//

import Foundation
import Supabase

/// The booking reader's line to Nugen: the `nugen-reader` Supabase function,
/// which holds the API key and the instructions the model was aligned on.
///
/// The app never talks to api.nugen.in itself. A key in the binary can be
/// read by anyone with the IPA and every call is billed, so the function
/// spends it only for a signed-in user, only on this account's own deployed
/// aligned models, and only with the day-reading prompt. What comes back is
/// the model's text and Nugen's confidence in it; turning that into bookings,
/// and checking every title and time against the document, stays in Swift
/// (`TripExtractor.validate`).
enum NugenService {

    nonisolated struct Model: Decodable, Hashable, Identifiable {
        let id: String
        let name: String
        let base: String
    }

    /// One entry as the model wrote it. Everything optional: a model that
    /// drops a field has still told us something about the row.
    nonisolated struct Item: Decodable {
        var title: String?
        var time: String?
        var kind: String?
    }

    struct DayReading {
        var items: [Item]
        /// Nugen's 0–100 confidence in this answer, nil when it didn't send one.
        var confidence: Double?
    }

    enum Failure: LocalizedError {
        case unreadable

        var errorDescription: String? { "Nugen's answer wasn't a list of bookings." }
    }

    private nonisolated struct Plan: Decodable { let items: [Item] }
    private nonisolated struct ModelsResponse: Decodable { let models: [Model] }
    private nonisolated struct ReadResponse: Decodable {
        let content: String
        let confidence: Double?
    }
    private nonisolated struct Request: Encodable {
        let action: String
        var model: String?
        var day: String?
    }

    /// The deployed slug. The function is named `nugen-reader` in the
    /// dashboard, but it was first deployed as `nudge-reader`, and renaming a
    /// function doesn't change its URL.
    private static let function = "nudge-reader"

    /// This account's deployed aligned models, for the Settings picker.
    static func models() async throws -> [Model] {
        let response: ModelsResponse = try await AuthService.shared.client.functions.invoke(
            function,
            options: FunctionInvokeOptions(body: Request(action: "models"))
        )
        return response.models
    }

    /// Reads one day of an itinerary — the same prompt `TripExtractor` gives
    /// Apple Intelligence — with the chosen aligned model.
    static func readDay(_ prompt: String, model: String) async throws -> DayReading {
        let response: ReadResponse = try await AuthService.shared.client.functions.invoke(
            function,
            options: FunctionInvokeOptions(body: Request(action: "read_day", model: model, day: prompt))
        )
        guard let items = parse(response.content) else { throw Failure.unreadable }
        return DayReading(items: items, confidence: response.confidence)
    }

    /// Why a call failed, in words Settings can show. "Couldn't reach Nugen"
    /// alone hid whether the function was undeployed, missing its key, or
    /// refusing the session — three different fixes.
    nonisolated static func reason(for error: Error) -> String {
        guard case FunctionsError.httpError(let code, let data) = error else {
            return "No connection to Equitrip's server."
        }
        let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message
        switch code {
        case 401: return "Sign in again to use Nugen."
        case 404 where message == nil: return "The booking reader function isn't deployed."
        default: return message.map { "\($0) (\(code))" } ?? "Equitrip's server answered \(code)."
        }
    }

    private nonisolated struct ErrorBody: Decodable {
        struct Detail: Decodable { let message: String }
        let error: Detail
    }

    /// The JSON inside a reply, however it was wrapped.
    ///
    /// Small models asked for "one JSON object and nothing else" still
    /// sometimes think out loud first, or fence the object in ```json, so
    /// this takes the outermost object rather than trusting the whole reply.
    nonisolated static func parse(_ content: String) -> [Item]? {
        var text = content
        if let end = text.range(of: "</think>") { text = String(text[end.upperBound...]) }
        guard let open = text.firstIndex(of: "{"), let close = text.lastIndex(of: "}"), open < close,
              let data = String(text[open...close]).data(using: .utf8)
        else { return nil }
        return (try? JSONDecoder().decode(Plan.self, from: data))?.items
    }

    /// The model's word for a kind, as the extractor's enum.
    nonisolated static func kind(_ word: String?) -> ExtractedKind {
        switch word?.lowercased().trimmingCharacters(in: .whitespaces) {
        case "flight": .flight
        case "train": .train
        case "transfer": .transfer
        case "stay": .stay
        case "activity": .activity
        case "meal", "food": .meal
        default: .other
        }
    }
}
