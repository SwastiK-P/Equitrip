//
//  TwinActionQueue.swift
//  Equitrip
//

import Foundation
import Observation

/// Carries out one kind of `TwinAction`.
///
/// The seam the next step plugs into. An executor that changes the trip must
/// do it through `TripStore` — the same writes, audit rows and outbox a person
/// editing by hand produces — never by writing Postgres itself.
@MainActor
protocol TwinActionExecutor {
    var kinds: Set<TwinAction.Kind> { get }
    func execute(_ action: TwinAction, on trip: Trip) async throws -> TwinActionOutcome
}

enum TwinActionOutcome: Hashable {
    /// Finished; the string is what the Plan B row says afterwards.
    case completed(String)
    /// Needs a screen: the host presents it (the chat with a draft, the
    /// booking editor with a proposed time).
    case needsPresentation(TwinActionPresentation)
}

/// What a host screen should put in front of the person to finish an action.
enum TwinActionPresentation: Hashable, Identifiable {
    case chat(draft: String)
    case booking(UUID)

    var id: String {
        switch self {
        case .chat(let draft): "chat|\(draft)"
        case .booking(let id): "booking|\(id)"
        }
    }
}

/// The only executor this release ships: putting the question to the group.
/// Everything else queues, visibly, for the executors that come next.
struct DiscussExecutor: TwinActionExecutor {
    var kinds: Set<TwinAction.Kind> { [.discussWithGroup] }

    func execute(_ action: TwinAction, on trip: Trip) async throws -> TwinActionOutcome {
        .needsPresentation(.chat(draft: action.payload.draft ?? "What should we do about \(action.title)?"))
    }
}

/// Plan B: the actions people have chosen, per trip, and where each one is.
///
/// Suggestions are recomputed with every simulation, live or what-if. What a
/// person has done to one — queued it, dismissed it, finished it — is kept
/// as a copy of the action under its stable id, so it survives the
/// recompute, shows in Plan B even when it came from a what-if that's since
/// been closed, and outlives a relaunch (UserDefaults). Only choices are
/// stored; the trip's data never is.
@MainActor
@Observable
final class TwinActionQueue {
    private(set) var suggestions: [UUID: [TwinAction]] = [:]
    /// Every action a person has touched, keyed "trip|action".
    private var chosen: [String: TwinAction]
    private var executors: [any TwinActionExecutor] = [DiscussExecutor()]

    private static let key = "twin.planB.v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let map = try? JSONDecoder().decode([String: TwinAction].self, from: data) {
            chosen = map
        } else {
            chosen = [:]
        }
    }

    /// Registers the executors a later step adds.
    func register(_ executor: any TwinActionExecutor) {
        executors.append(executor)
    }

    func update(_ actions: [TwinAction], for tripID: UUID) {
        suggestions[tripID] = actions
    }

    /// Fresh suggestions with any person-given status applied.
    func resolved(_ actions: [TwinAction]) -> [TwinAction] {
        actions.map { action in
            var copy = action
            copy.status = chosen[key(action)]?.status ?? .suggested
            return copy
        }
    }

    /// The live suggestions for one booking, minus anything dismissed.
    func actions(for itemID: UUID, in tripID: UUID) -> [TwinAction] {
        resolved(suggestions[tripID] ?? []).filter { $0.itemID == itemID && $0.status != .dismissed }
    }

    /// What people have put in Plan B, most urgent first.
    func planB(for tripID: UUID) -> [TwinAction] {
        chosen.values
            .filter { $0.tripID == tripID && [.queued, .running, .done].contains($0.status) }
            .sorted { ($0.urgency, $1.createdAt) > ($1.urgency, $0.createdAt) }
    }

    func canExecute(_ action: TwinAction) -> Bool {
        executors.contains { $0.kinds.contains(action.kind) }
    }

    func set(_ status: TwinAction.Status, for action: TwinAction) {
        var copy = action
        copy.status = status
        if status == .suggested {
            chosen[key(action)] = nil
        } else {
            chosen[key(action)] = copy
        }
        persist()
    }

    func toggleQueued(_ action: TwinAction) {
        let current = chosen[key(action)]?.status ?? .suggested
        set(current == .queued ? .suggested : .queued, for: action)
    }

    /// Runs an action if an executor claims it. Returns what the host needs
    /// to show, if anything.
    func execute(_ action: TwinAction, on trip: Trip) async -> TwinActionPresentation? {
        guard let executor = executors.first(where: { $0.kinds.contains(action.kind) }) else { return nil }
        set(.running, for: action)
        do {
            switch try await executor.execute(action, on: trip) {
            case .completed:
                set(.done, for: action)
                return nil
            case .needsPresentation(let presentation):
                set(.done, for: action)
                return presentation
            }
        } catch {
            set(.queued, for: action)
            return nil
        }
    }

    private func key(_ action: TwinAction) -> String { "\(action.tripID)|\(action.id)" }

    private func persist() {
        if let data = try? JSONEncoder().encode(chosen) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
