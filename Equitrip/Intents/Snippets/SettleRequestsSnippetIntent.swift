//
//  SettleRequestsSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The card of payments people say they've made to you, each confirmable
/// with one tap — the watch's "Settle requests" page, under Siri.
///
/// A confirmed row stays on the card, marked, rather than disappearing from
/// under the finger that confirmed it; it drops off the next time anyone asks.
struct SettleRequestsSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Payments Card"

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = try await IntentStores.store(fresh: false)
        return .result(view: SettleRequestsSnippetView(model: await SettleRequestsModel.make(store)))
    }
}

struct SettleRequestsModel {
    struct Row: Identifiable {
        let id: UUID
        let tripID: UUID
        let name: String
        let asset: String
        let amount: String
        let detail: String
        let isConfirmed: Bool
    }

    var look: SnippetLook
    var figure: String
    var caption: String
    var rows: [Row]
    var more: Int

    @MainActor
    static func make(_ store: TripStore) async -> SettleRequestsModel {
        let waiting = store.settlementsAwaitingYou
        let answered: [(trip: Trip, settlement: Settlement)] = SettlementAnswers.recent.reversed().compactMap { id in
            for trip in store.trips {
                if let settlement = trip.settlements.first(where: { $0.id == id && $0.status == .confirmed }) {
                    return (trip, settlement)
                }
            }
            return nil
        }
        let all = waiting + answered
        let rows = all.prefix(3).map { entry in
            let payer = entry.trip.traveller(entry.settlement.fromID)
            return Row(
                id: entry.settlement.id,
                tripID: entry.trip.id,
                name: payer?.name.firstName ?? "Someone",
                asset: payer?.asset ?? "",
                amount: Money.format(entry.settlement.amount, code: entry.settlement.currencyCode),
                detail: "\(entry.settlement.method.label) · \(entry.trip.title) · \(SnippetWhen.ago(entry.settlement.createdAt))",
                isConfirmed: entry.settlement.status == .confirmed
            )
        }

        // One trip's colour when every claim is from that trip; the app's own
        // when they span several.
        let trips = Set(all.map(\.trip.id))
        let look: SnippetLook = if trips.count == 1, let trip = all.first?.trip {
            await SnippetArtwork.look(for: trip)
        } else {
            .brand
        }

        let codes = Set(waiting.map(\.settlement.currencyCode))
        let total = waiting.reduce(0) { $0 + $1.settlement.amount }
        let figure: String
        let caption: String
        switch (waiting.count, answered.isEmpty) {
        case (0, true):
            figure = "All clear"
            caption = "Nobody's waiting on you"
        case (0, false):
            figure = "All confirmed"
            caption = "Those balances are settled"
        default:
            figure = codes.count == 1 ? Money.format(total, code: codes.first!) : waiting.count.pluralised("payment")
            caption = waiting.count == 1 ? "says they paid you" : "\(waiting.count) payments to confirm"
        }

        return SettleRequestsModel(look: look, figure: figure, caption: caption, rows: Array(rows), more: max(0, all.count - 3))
    }
}

struct SettleRequestsSnippetView: View {
    let model: SettleRequestsModel

    var body: some View {
        SnippetCard(look: model.look) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    SnippetEyebrow(text: "Payments to you")
                    SnippetFigure(text: model.figure, size: 40)
                    Text(model.caption)
                        .font(.headline)
                        .foregroundStyle(SnippetInk.secondary)
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                if model.rows.isEmpty {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(SnippetInk.secondary)
                        .accessibilityHidden(true)
                }
            }

            if !model.rows.isEmpty {
                VStack(spacing: 8) {
                    ForEach(model.rows) { row in
                        HStack(spacing: 10) {
                            SnippetAvatar(asset: row.asset, size: 32)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(row.name) · \(row.amount)")
                                    .font(.body.weight(.semibold))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                Text(row.detail)
                                    .font(.footnote)
                                    .foregroundStyle(SnippetInk.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            if row.isConfirmed {
                                Label("Confirmed", systemImage: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SnippetInk.secondary)
                                    .labelStyle(.titleAndIcon)
                                    .transition(.blurReplace)
                            } else {
                                Button(intent: RespondToSettlementIntent(settlementID: row.id, tripID: row.tripID)) {
                                    Text("Confirm")
                                }
                                .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint, compact: true))
                                .transition(.blurReplace)
                            }
                        }
                        .padding(10)
                        .background(SnippetInk.wash, in: .rect(cornerRadius: 16, style: .continuous))
                    }
                }
            }

            if !model.rows.isEmpty {
                Button(intent: OpenFromSnippetIntent(.settle, tripID: model.rows.first?.tripID, itemID: model.rows.first(where: { !$0.isConfirmed })?.id)) {
                    Text(model.more > 0 ? "Review all \(model.rows.count + model.more)" : "Review in Equitrip")
                }
                .buttonStyle(SnippetButtonStyle(weight: .secondary, tint: model.look.tint))
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 360, height: 400)) {
    SettleRequestsSnippetView(model: SettleRequestsModel(
        look: .brand,
        figure: "₹2,000",
        caption: "2 payments to confirm",
        rows: [
            .init(id: UUID(), tripID: UUID(), name: "Ed", asset: "Avatar02", amount: "₹1,200",
                  detail: "UPI · Goa · 2 hr. ago", isConfirmed: false),
            .init(id: UUID(), tripID: UUID(), name: "Priya", asset: "Avatar01", amount: "₹800",
                  detail: "Cash · Goa · 1 day ago", isConfirmed: true)
        ],
        more: 0
    ))
    .padding()
}
