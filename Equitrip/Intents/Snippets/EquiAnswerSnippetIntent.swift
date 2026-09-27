//
//  EquiAnswerSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The card under an answer from Equi, when Equi picked one.
///
/// A balance, a plan or a trip question gets the same card as asking Siri
/// for it directly — "who owes me?" through Equi and through "What do I owe"
/// shouldn't look like two different apps. The kinds Siri has no card of its
/// own for (spending, people) keep Equi's, on a white panel so the app's
/// light palette reads on Siri's dark glass. Prose-only answers have no card.
///
/// One intent for all of them because `perform()` can only return one kind of
/// snippet intent; the switch lives in the view instead.
struct EquiAnswerSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Equi Answer Card"

    /// `EquiCard.storageKey`, the same string a saved transcript uses — the
    /// kind plus what it's narrowed to.
    @Parameter(title: "Card") var kind: String
    @Parameter(title: "Trip") var tripID: String

    init() {}

    init(card: EquiCard?) {
        kind = card?.storageKey ?? "text"
        tripID = card?.tripID?.uuidString ?? ""
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        guard let card = EquiCard(storageKey: kind, tripID: UUID(uuidString: tripID)) else {
            return .result(view: EquiAnswerSnippetView(content: .none))
        }
        let store = try await IntentStores.store(fresh: false)
        guard card.kind != .trips else { return .result(view: EquiAnswerSnippetView(content: .card(card, store))) }
        guard let trip = store.trip(card.tripID) else { return .result(view: EquiAnswerSnippetView(content: .none)) }

        // Siri's own cards where they answer the same question; Equi's where
        // the answer was narrowed to something Siri's cards don't show.
        let content: EquiAnswerSnippetView.Content = switch card.kind {
        case .balance where card.personID == nil: .balance(await BalanceSnippetModel.make(for: trip))
        case .itinerary where card.day == nil: .upNext(await UpNextSnippetModel.make(for: trip))
        case .trip: .trip(await TripStatusModel.make(for: trip))
        default: .card(card, store)
        }
        return .result(view: EquiAnswerSnippetView(content: content))
    }
}

struct EquiAnswerSnippetView: View {
    enum Content {
        case balance(BalanceSnippetModel)
        case upNext(UpNextSnippetModel)
        case trip(TripStatusModel)
        case card(EquiCard, TripStore)
        case none
    }

    let content: Content

    var body: some View {
        switch content {
        case .balance(let model): BalanceSnippetView(model: model)
        case .upNext(let model): UpNextSnippetView(model: model)
        case .trip(let model): TripStatusSnippetView(model: model)
        case .card(let card, let store):
            EquiCardView(card: card)
                .environment(\.tripStore, store)
                .padding(12)
                .background(AppTheme.canvasTop, in: ContainerRelativeShape())
                .environment(\.colorScheme, .light)
        case .none:
            EmptyView()
        }
    }
}
