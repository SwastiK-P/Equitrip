//
//  ExpenseLoggedSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The card after a spoken expense is saved: what went on the ledger, what it
/// did to your balance on the trip, and a way to take it back.
///
/// "Undo" because a voice entry is the one kind most likely to be a mistake —
/// the wrong trip, a misheard figure — and the moment it's on screen is when
/// it's noticed. Removing it goes through `TripStore.removeItem`, so the audit
/// trail files the removal as a new entry beside the one that added it.
struct ExpenseLoggedSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Logged Expense Card"

    @Parameter(title: "Trip") var tripID: String
    @Parameter(title: "Expense") var itemID: String

    init() {}

    init(tripID: UUID, itemID: UUID) {
        self.tripID = tripID.uuidString
        self.itemID = itemID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        guard let tripUUID = UUID(uuidString: tripID), let itemUUID = UUID(uuidString: itemID) else {
            throw IntentFailure.bookingNotFound
        }
        let store = try await IntentStores.store(fresh: false)
        guard let trip = store.trip(tripUUID) else { throw IntentFailure.tripNotFound }
        return .result(view: ExpenseLoggedSnippetView(model: await ExpenseLoggedModel.make(itemUUID, on: trip)))
    }
}

/// "Undo" on the logged-expense card.
struct UndoLoggedExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Undo Logged Expense"
    static let isDiscoverable = false

    @Parameter(title: "Trip") var tripID: String
    @Parameter(title: "Expense") var itemID: String

    init() {}

    init(tripID: UUID, itemID: UUID) {
        self.tripID = tripID.uuidString
        self.itemID = itemID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let tripUUID = UUID(uuidString: tripID), let itemUUID = UUID(uuidString: itemID) else {
            throw IntentFailure.bookingNotFound
        }
        let store = try await IntentStores.store(fresh: false)
        guard let item = store.trip(tripUUID)?.items.first(where: { $0.id == itemUUID }) else {
            // Already gone — a second tap, or removed in the app meanwhile.
            return .result()
        }
        // Undo takes back your own entry, nobody else's.
        guard item.createdByID == Traveller.you.id else { throw IntentFailure.notYours }

        store.clearWriteFailure()
        store.removeItem(itemUUID, in: tripUUID)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }
        return .result()
    }
}

struct ExpenseLoggedModel {
    var look: SnippetLook
    var tripID: UUID
    var itemID: UUID
    var tripTitle: String
    var tripStyle: TripTitleStyle
    /// False once the expense has been undone — the card says so and stops
    /// offering to undo it again.
    var isLogged: Bool
    var symbol: String
    var amount: String
    var title: String
    var detail: String
    /// "You're now owed ₹3,400 on Goa."
    var standing: String
    var canUndo: Bool

    @MainActor
    static func make(_ itemID: UUID, on trip: Trip) async -> ExpenseLoggedModel {
        let look = await SnippetArtwork.look(for: trip)
        let net = trip.remainingBalance(for: Traveller.you.id)
        let standing = net > 0
            ? "You're owed \(Money.format(net, code: trip.currencyCode)) on this trip now."
            : net < 0
                ? "You owe \(Money.format(-net, code: trip.currencyCode)) on this trip now."
                : "You're all square on this trip."

        guard let item = trip.items.first(where: { $0.id == itemID }) else {
            return ExpenseLoggedModel(
                look: look, tripID: trip.id, itemID: itemID, tripTitle: trip.title, tripStyle: trip.titleStyle,
                isLogged: false, symbol: "arrow.uturn.backward", amount: "Removed", title: "Taken off the ledger",
                detail: "", standing: standing, canUndo: false
            )
        }

        let heads = trip.bearers(of: item).count
        let payer = item.paidByID.flatMap(trip.traveller)
        let paidBy = item.paidByID == Traveller.you.id ? "You paid" : "\(payer?.name.firstName ?? "Someone") paid"
        let detail = heads > 1
            ? "\(paidBy) · \(Money.format(Money.wholeShare(of: item.cost, heads: heads), code: trip.currencyCode)) each"
            : "\(paidBy) · not split"

        return ExpenseLoggedModel(
            look: look,
            tripID: trip.id,
            itemID: item.id,
            tripTitle: trip.title,
            tripStyle: trip.titleStyle,
            isLogged: true,
            symbol: item.symbol,
            amount: Money.format(item.cost, code: trip.currencyCode),
            title: item.title,
            detail: detail,
            standing: standing,
            canUndo: item.createdByID == Traveller.you.id
        )
    }
}

struct ExpenseLoggedSnippetView: View {
    let model: ExpenseLoggedModel

    var body: some View {
        SnippetCard(look: model.look) {
            HStack(spacing: 8) {
                Image(systemName: model.isLogged ? "checkmark.circle.fill" : "arrow.uturn.backward.circle.fill")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(model.isLogged ? "Logged" : "Undone")
                    .font(.headline)
                Spacer(minLength: 8)
                Text(model.tripTitle)
                    .tripTitle(model.tripStyle, size: 15)
                    .foregroundStyle(SnippetInk.secondary)
                    .lineLimit(1)
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    SnippetFigure(text: model.amount)
                    Text(model.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(SnippetInk.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: model.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .background(SnippetInk.wash, in: .circle)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 2) {
                if !model.detail.isEmpty {
                    Text(model.detail)
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                }
                Text(model.standing)
                    .font(.subheadline)
                    .foregroundStyle(SnippetInk.secondary)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 10) {
                if model.canUndo {
                    Button(intent: UndoLoggedExpenseIntent(tripID: model.tripID, itemID: model.itemID)) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .buttonStyle(SnippetButtonStyle(weight: .secondary, tint: model.look.tint))
                }
                Button(intent: model.isLogged
                    ? OpenFromSnippetIntent(.booking, tripID: model.tripID, itemID: model.itemID)
                    : OpenFromSnippetIntent(.trip, tripID: model.tripID)
                ) {
                    Text(model.isLogged ? "Open" : "Open trip")
                }
                .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint))
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 360, height: 360)) {
    ExpenseLoggedSnippetView(model: ExpenseLoggedModel(
        look: SnippetLook(tint: SnippetTint.readable(Color(red: 0.2, green: 0.7, blue: 0.6)), photo: nil),
        tripID: UUID(),
        itemID: UUID(),
        tripTitle: "Goa with the gang",
        tripStyle: .poster,
        isLogged: true,
        symbol: "fork.knife",
        amount: "₹2,400",
        title: "Dinner at Thalassa",
        detail: "You paid · ₹600 each",
        standing: "You're owed ₹3,400 on this trip now.",
        canUndo: true
    ))
    .padding()
}
