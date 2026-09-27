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

    /// `EquiCardKind.storageKey`, the same name a saved transcript uses.
    @Parameter(title: "Card") var kind: String
    @Parameter(title: "Trip") var tripID: String

    init() {}

    init(card: EquiCard?) {
        kind = card?.kind.storageKey ?? EquiCardKind.text.storageKey
        tripID = card?.tripID.uuidString ?? ""
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        guard let id = UUID(uuidString: tripID), let kind = EquiCardKind(storageKey: kind) else {
            return .result(view: EquiAnswerSnippetView(content: .none))
        }
        let store = try await IntentStores.store(fresh: false)
        guard let trip = store.trip(id) else { return .result(view: EquiAnswerSnippetView(content: .none)) }

        let content: EquiAnswerSnippetView.Content = switch kind {
        case .balance: .balance(await BalanceSnippetModel.make(for: trip))
        case .itinerary: .upNext(await UpNextSnippetModel.make(for: trip))
        case .trip: .trip(await TripStatusModel.make(for: trip))
        case .spending, .people: .card(EquiCard(kind: kind, tripID: id), store)
        case .text: .none
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
