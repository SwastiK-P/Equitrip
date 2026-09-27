//
//  LogExpenseIntent.swift
//  Equitrip
//

import AppIntents
import Foundation
import SwiftUI

/// "Log ₹2,400 for dinner on the Goa trip" — an expense, by voice.
///
/// This reverses a decision `AddExpenseIntent` records ("nothing about an
/// expense can be captured without a keypad"), and the reversal is narrow on
/// purpose. What made a spoken expense a bad row was the half-filled one: an
/// amount with no payer and no split, left for somebody to fix. So this one is
/// never half-filled — payer defaults to you, the split to the whole trip, and
/// Siri asks for anything missing — and it is never unseen: every figure is on
/// a confirmation card before a byte is written.
///
/// The amount comes from exactly one place, the person's own words. No model
/// reads, rounds or suggests it — the invariant the receipt and mail readers
/// keep, kept here too. The category *is* inferred, afterwards, the same way
/// the quick-add sheet does it, because a wrong category costs nobody money.
///
/// Anyone on a trip can log an expense on it, as from Home's quick add;
/// changing the itinerary itself is for organisers (`AddBookingIntent`).
struct LogExpenseIntent: AppIntent {

    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription(
        "Records something that was paid for on a trip. Shows you the amount, who paid and how it's split before saving.",
        categoryName: "Expenses"
    )
    static var supportedModes: IntentModes { .background }

    @Parameter(title: "Amount", requestValueDialog: "How much was it?")
    var amount: Double

    @Parameter(title: "For", requestValueDialog: "What was it for?")
    var purpose: String

    @Parameter(title: "Trip")
    var trip: TripEntity?

    @Parameter(title: "Paid By")
    var payer: TravellerEntity?

    @Parameter(title: "Split", default: .everyone)
    var split: ExpenseSplit

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$purpose) on \(\.$trip)") {
            \.$payer
            \.$split
        }
    }

    init() {}

    /// For donations from the quick-add sheet, which already knows everything.
    init(amount: Double, purpose: String, trip: TripEntity, payer: TravellerEntity?, split: ExpenseSplit) {
        self.amount = amount
        self.purpose = purpose
        self.trip = trip
        self.payer = payer
        self.split = split
    }

    @MainActor
    func perform() async throws -> some ReturnsValue<BookingEntity> & ProvidesDialog & ShowsSnippetIntent {
        // Everything that can send Siri back to ask a question happens first.
        // A value request restarts `perform()` from the top, and nothing may
        // have been written by then.
        let trimmed = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw $purpose.needsValueError("What was it for?") }
        guard amount > 0, amount.isFinite else { throw $amount.needsValueError("How much was it? It needs to be more than zero.") }

        let store = try await IntentStores.store()
        let target = try resolveTrip(in: store)

        let payerID = payer?.id ?? Traveller.you.id
        guard let paidBy = target.traveller(payerID) else {
            throw IntentFailure.notOnTrip(payer?.name ?? "You")
        }
        guard !target.invitedIDs.contains(paidBy.id) else {
            throw IntentFailure.notOnTrip(paidBy.name)
        }

        // The card can change who paid and how it's split before anything is
        // written, so what's confirmed is read back from the draft afterwards
        // — not from the parameters Siri started with.
        let draft = ExpenseDraft(tripID: target.id, title: trimmed, amount: amount, payerID: paidBy.id, split: split)
        ExpenseDraftBook.shared.open(draft)
        let amountLabel = Money.format(amount, code: target.currencyCode)

        try await requestConfirmation(
            actionName: .log,
            dialog: IntentDialog(
                full: "Log \(amountLabel) for \(trimmed) on \(target.title), \(Self.spokenTerms(of: draft, on: target))?",
                supporting: "Log this on \(target.title)?"
            ),
            snippetIntent: ExpenseDraftSnippetIntent(draftID: draft.id)
        )

        // Confirmed: the write, and nothing that can restart after it.
        guard let confirmed = ExpenseDraftBook.shared.close(draft.id) else {
            throw IntentFailure.notSaved("It was already logged.")
        }
        let trip = store.trip(target.id) ?? target
        guard let finalPayer = trip.traveller(confirmed.payerID), !trip.invitedIDs.contains(finalPayer.id) else {
            throw IntentFailure.notOnTrip(trip.traveller(confirmed.payerID)?.name ?? "They")
        }
        let item = confirmed.item(on: trip)

        store.clearWriteFailure()
        store.addItem(item, to: trip.id)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }

        Self.classifyAfterwards(item, on: trip.id, in: store)

        let saved = store.trip(trip.id) ?? trip
        let heads = saved.bearers(of: item).count
        let dialog: IntentDialog = heads > 1
            ? "Logged \(amountLabel) for \(trimmed) on \(saved.title). That's \(Money.format(Money.wholeShare(of: item.cost, heads: heads), code: saved.currencyCode)) each."
            : "Logged \(amountLabel) for \(trimmed) on \(saved.title)."

        return .result(
            value: BookingEntity(item, in: saved),
            dialog: dialog,
            snippetIntent: ExpenseLoggedSnippetIntent(tripID: saved.id, itemID: item.id)
        )
    }

    // MARK: - Pieces

    /// The trip named, or the one under way. With neither, Siri asks — a
    /// guess at which trip money belongs to is exactly the wrong row.
    @MainActor
    private func resolveTrip(in store: TripStore) throws -> Trip {
        if let trip {
            guard let found = store.trip(trip.id) else { throw IntentFailure.tripNotFound }
            return found
        }
        guard !store.trips.isEmpty else { throw IntentFailure.noTrips }
        let live = store.trips.filter { $0.phase == .live }
        if live.count == 1 { return live[0] }
        throw $trip.needsValueError("Which trip was it for?")
    }

    /// "paid by you, split 4 ways" — the terms said out loud, for when there's
    /// no card to check them on.
    @MainActor
    private static func spokenTerms(of draft: ExpenseDraft, on trip: Trip) -> String {
        let payer = draft.payerID == Traveller.you.id ? "you" : (trip.traveller(draft.payerID)?.name ?? "them")
        let heads = trip.bearers(of: draft.item(on: trip)).count
        return heads > 1 ? "paid by \(payer), split \(heads) ways" : "paid by \(payer), not split"
    }

    /// The category, as the quick-add sheet infers it: after the row exists,
    /// as a second save of the same id, so a slow guess never holds up the
    /// record — or, now, Siri's answer. It used to run before the reply, and a
    /// model call on a cold launch was seconds of silence after "Log".
    @MainActor
    private static func classifyAfterwards(_ item: ItineraryItem, on tripID: UUID, in store: TripStore) {
        Task {
            var classified = item
            classified.kind = await ActivityIconSuggester.kind(for: item.title)
            classified.suggestedSymbol = await ActivityIconSuggester.symbol(for: item.title, kind: classified.kind)
            guard classified.kind != item.kind || classified.suggestedSymbol != item.suggestedSymbol else { return }
            // Undone from the card meanwhile: an upsert now would put it back.
            guard store.trip(tripID)?.items.contains(where: { $0.id == item.id }) == true else { return }
            store.addItem(classified, to: tripID)
            _ = await store.settleWrites()
        }
    }
}

/// How a spoken expense is shared. Two ways, because those are the two a
/// sentence can carry — "split it" and "that one's mine". Anything finer
/// (some of us, exact amounts) needs the people on screen, and belongs in the
/// quick-add sheet.
///
/// Raw values are stored in saved shortcuts: append, never rename.
enum ExpenseSplit: String, AppEnum {
    case everyone
    case payerOnly

    nonisolated static let typeDisplayRepresentation: TypeDisplayRepresentation = "Split"
    nonisolated static let caseDisplayRepresentations: [ExpenseSplit: DisplayRepresentation] = [
        .everyone: DisplayRepresentation(title: "Everyone", subtitle: "Divided equally across the trip"),
        .payerOnly: DisplayRepresentation(title: "Just the payer", subtitle: "Kept on the ledger, owed by nobody else")
    ]
}
