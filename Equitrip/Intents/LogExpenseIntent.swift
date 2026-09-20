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
    func perform() async throws -> some ReturnsValue<BookingEntity> & ProvidesDialog {
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

        let item = compose(title: trimmed, payer: paidBy, on: target)
        let amountLabel = Money.format(amount, code: target.currencyCode)
        let each = eachLabel(for: item, on: target)

        try await requestConfirmation(
            actionName: .log,
            dialog: "Log \(amountLabel) for \(trimmed) on \(target.title)?"
        ) {
            SiriExpenseSnippet(
                title: trimmed,
                amount: amount,
                currencyCode: target.currencyCode,
                tripTitle: target.title,
                payerName: paidBy.id == Traveller.you.id ? "You" : paidBy.name,
                splitLabel: split == .everyone ? "Everyone (\(target.bearers(of: item).count))" : "Just \(paidBy.id == Traveller.you.id ? "you" : paidBy.name)",
                eachLabel: each
            )
        }

        // Confirmed: the write, and nothing that can restart after it.
        store.clearWriteFailure()
        store.addItem(item, to: target.id)
        if let failure = await store.settleWrites() {
            throw IntentFailure.notSaved(failure)
        }

        // The category, as the quick-add sheet infers it: after the row exists,
        // as a second save of the same id, so a slow guess never holds up the
        // record and a failed one leaves it be.
        var classified = item
        classified.kind = await ActivityIconSuggester.kind(for: item.title)
        classified.suggestedSymbol = await ActivityIconSuggester.symbol(for: item.title, kind: classified.kind)
        if classified.kind != item.kind || classified.suggestedSymbol != item.suggestedSymbol {
            store.addItem(classified, to: target.id)
            _ = await store.settleWrites()
        }

        let saved = store.trip(target.id) ?? target
        let dialog: IntentDialog = each.map {
            "Logged \(amountLabel) for \(trimmed) on \(target.title). That's \($0) each."
        } ?? "Logged \(amountLabel) for \(trimmed) on \(target.title)."

        return .result(value: BookingEntity(classified, in: saved), dialog: dialog)
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

    /// The same booking the quick-add sheet would make from the same answers.
    @MainActor
    private func compose(title: String, payer: Traveller, on trip: Trip) -> ItineraryItem {
        let now = Date()
        let start = Calendar.current.startOfDay(for: trip.startDate)
        let end = Calendar.current.startOfDay(for: trip.endDate)
        let today = Calendar.current.startOfDay(for: now)
        // Today when today is on the trip; otherwise the trip's first day, as
        // Home's quick add files it.
        let day = (start...end).contains(today) ? today : start
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)

        return ItineraryItem(
            title: title,
            kind: .activity,
            date: day,
            time: .at(parts.hour ?? 12, parts.minute ?? 0, on: day),
            cost: amount,
            split: split == .everyone ? .equal : .individual,
            participantIDs: split == .everyone ? Set(trip.travellers.map(\.id)) : [payer.id],
            paidByID: payer.id,
            paymentMethod: AppSettings.defaultPaymentMethod,
            createdByID: Traveller.you.id
        )
    }

    /// "₹600" when the cost is shared, nil when one person carries it.
    @MainActor
    private func eachLabel(for item: ItineraryItem, on trip: Trip) -> String? {
        let heads = trip.bearers(of: item).count
        guard heads > 1 else { return nil }
        return Money.format(Money.wholeShare(of: amount, heads: heads), code: trip.currencyCode)
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
