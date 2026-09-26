//
//  BalanceSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The card under "What do I owe?": where you stand, who pays whom, and the
/// one thing you can do about it from here.
///
/// A snippet intent, not a view handed back once: the system runs this again
/// after any of the card's buttons, so confirming a payment from the card
/// redraws the balance with the payment counted. Everything is read off the
/// store each time — Siri keeps the app alive while the card is up, so that's
/// memory, not the network.
struct BalanceSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Balance Card"

    /// Nil answers for every trip at once.
    @Parameter(title: "Trip")
    var trip: TripEntity?

    init() {}

    init(trip: TripEntity?) {
        self.trip = trip
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = try await IntentStores.store(fresh: false)
        let model = await BalanceSnippetModel.make(tripID: trip?.id, in: store)
        return .result(view: BalanceSnippetView(model: model))
    }
}

/// Everything the balance card draws, worked out before it's drawn so the
/// view is plain values — and previewable, and reusable by Equi.
struct BalanceSnippetModel {

    struct Transfer: Identifiable {
        let id: String
        let name: String
        let asset: String
        let amount: String
        let youPay: Bool
    }

    /// Somebody says they paid you and is waiting on your answer.
    struct Claim {
        let settlementID: UUID
        let tripID: UUID
        let name: String
        let asset: String
        let amount: String
        let method: String
    }

    /// One trip's line on the every-trip card.
    struct TripLine: Identifiable {
        let id: UUID
        let title: String
        let style: TripTitleStyle
        let figure: String
        let caption: String
    }

    var look: SnippetLook
    var title: String
    /// Nil sets the title in the system face — the every-trip card has no
    /// one trip's typeface to borrow.
    var titleStyle: TripTitleStyle?
    var subtitle: String?
    var figure: String
    var caption: String
    var transfers: [Transfer] = []
    var trips: [TripLine] = []
    var claim: Claim?
    /// Claims beyond the one shown, so the card can say there are more.
    var moreClaims = 0
    /// Set when you owe somebody on this trip: the card offers "Settle up".
    var settleTripID: UUID?
    var tripID: UUID?

    @MainActor
    static func make(tripID: UUID?, in store: TripStore) async -> BalanceSnippetModel {
        if let tripID, let trip = store.trip(tripID) {
            return await make(for: trip)
        }
        return await portfolio(store)
    }

    /// One trip: what's left after confirmed transfers, and who pays whom.
    @MainActor
    static func make(for trip: Trip) async -> BalanceSnippetModel {
        let you = Traveller.you.id
        let net = trip.remainingBalance(for: you)
        let transfers = trip.suggestedTransfers
            .filter { $0.from == you || $0.to == you }
            .map { transfer in
                let other = trip.traveller(transfer.from == you ? transfer.to : transfer.from)
                return Transfer(
                    id: "\(transfer.from)-\(transfer.to)",
                    name: other?.name.firstName ?? "Someone",
                    asset: other?.asset ?? "",
                    amount: Money.format(transfer.amount, code: trip.currencyCode),
                    youPay: transfer.from == you
                )
            }

        let waiting = trip.pendingSettlements
            .filter(\.youAreRecipient)
            .sorted { $0.createdAt > $1.createdAt }
        let claim = waiting.first.map { settlement in
            let payer = trip.traveller(settlement.fromID)
            return Claim(
                settlementID: settlement.id,
                tripID: trip.id,
                name: payer?.name.firstName ?? "Someone",
                asset: payer?.asset ?? "",
                amount: Money.format(settlement.amount, code: settlement.currencyCode),
                method: settlement.method.label
            )
        }

        return BalanceSnippetModel(
            look: await SnippetArtwork.look(for: trip),
            title: trip.title,
            titleStyle: trip.titleStyle,
            subtitle: trip.phase == .live ? trip.progressLabel : trip.dateRange,
            figure: net == 0 ? "All square" : Money.format(abs(net), code: trip.currencyCode),
            caption: net > 0 ? "coming back to you" : net < 0 ? "you owe" : "Nobody owes anybody",
            transfers: transfers,
            claim: claim,
            moreClaims: max(0, waiting.count - 1),
            settleTripID: transfers.contains(where: \.youPay) ? trip.id : nil,
            tripID: trip.id
        )
    }

    /// Every trip at once, in the currency most of them use. Read from what's
    /// *left* on each trip, as the single-trip card is — the store's portfolio
    /// totals count what was ever owed, confirmed payments included, and
    /// answered "you owe ₹4,000" to somebody who'd paid it.
    @MainActor
    static func portfolio(_ store: TripStore) async -> BalanceSnippetModel {
        let code = store.primaryCurrency
        let you = Traveller.you.id
        let open = TripMatcher.byRelevance(store.trips)
            .filter { $0.currencyCode == code && $0.remainingBalance(for: you) != 0 }
        let net = open.reduce(0) { $0 + $1.remainingBalance(for: you) }
        let others = store.trips.filter { $0.currencyCode != code && $0.remainingBalance(for: you) != 0 }.count

        let lines = open.prefix(3).map { trip in
            let balance = trip.remainingBalance(for: you)
            return TripLine(
                id: trip.id,
                title: trip.title,
                style: trip.titleStyle,
                figure: Money.format(abs(balance), code: code),
                caption: balance > 0 ? "owed to you" : "you owe"
            )
        }

        let subtitle: String = switch (open.count, others) {
        case (0, 0): "Across your trips"
        case (_, 0): "Across \(open.count.pluralised("trip"))"
        default: "Plus \(others.pluralised("trip")) in other currencies"
        }

        return BalanceSnippetModel(
            look: .brand,
            title: "All trips",
            titleStyle: nil,
            subtitle: subtitle,
            figure: net == 0 ? "All square" : Money.format(abs(net), code: code),
            caption: net > 0 ? "coming back to you" : net < 0 ? "you owe overall" : "Nobody owes anybody",
            trips: Array(lines)
        )
    }
}

/// The balance card.
struct BalanceSnippetView: View {
    let model: BalanceSnippetModel

    var body: some View {
        SnippetCard(look: model.look) {
            header

            VStack(alignment: .leading, spacing: 0) {
                SnippetFigure(text: model.figure)
                Text(model.caption)
                    .font(.headline)
                    .foregroundStyle(SnippetInk.secondary)
            }
            .accessibilityElement(children: .combine)

            if !model.trips.isEmpty {
                VStack(spacing: 8) {
                    ForEach(model.trips) { line in
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(line.title)
                                    .tripTitle(line.style, size: 16)
                                    .lineLimit(1)
                                Text(line.caption)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(SnippetInk.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(line.figure)
                                .font(.system(size: 17, weight: .semibold))
                                .monospacedDigit()
                                .layoutPriority(1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            if !model.transfers.isEmpty {
                VStack(spacing: 8) {
                    ForEach(model.transfers.prefix(transferRows)) { transfer in
                        HStack(spacing: 10) {
                            SnippetAvatar(asset: transfer.asset, size: 30)
                            // The name may be long — an address someone signed
                            // up with — so it truncates on its own line and the
                            // direction underneath never does.
                            VStack(alignment: .leading, spacing: 0) {
                                Text(transfer.name)
                                    .font(.body.weight(.semibold))
                                    .lineLimit(1)
                                Text(transfer.youPay ? "you pay them" : "pays you")
                                    .font(.footnote)
                                    .foregroundStyle(SnippetInk.secondary)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: transfer.youPay ? "arrow.up.right" : "arrow.down.left")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(SnippetInk.tertiary)
                            Text(transfer.amount)
                                .font(.body.weight(.semibold))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .layoutPriority(1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }

            if let claim = model.claim {
                claimStrip(claim)
            }

            if let settleTripID = model.settleTripID {
                Button(intent: OpenFromSnippetIntent(.settle, tripID: settleTripID)) {
                    Label("Settle up", systemImage: "arrow.left.arrow.right")
                }
                .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint))
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let style = model.titleStyle {
            SnippetTripHeader(title: model.title, style: style, subtitle: model.subtitle, photo: model.look.photo)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(.title3.weight(.bold))
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SnippetInk.secondary)
                }
            }
        }
    }

    /// Room is shared: a waiting claim and a Settle up button each take a
    /// row's worth, and the card stays inside Apple's height.
    private var transferRows: Int {
        max(1, 3 - (model.claim == nil ? 0 : 1) - (model.settleTripID == nil ? 0 : 1))
    }

    private func claimStrip(_ claim: BalanceSnippetModel.Claim) -> some View {
        HStack(spacing: 10) {
            SnippetAvatar(asset: claim.asset, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(claim.name) says they paid")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(model.moreClaims > 0 ? "\(claim.amount) · \(model.moreClaims) more waiting" : "\(claim.amount) · \(claim.method)")
                    .font(.footnote)
                    .foregroundStyle(SnippetInk.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button(intent: RespondToSettlementIntent(settlementID: claim.settlementID, tripID: claim.tripID)) {
                Text("Confirm")
            }
            .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint, compact: true))
        }
        .padding(10)
        .background(SnippetInk.wash, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Trip", traits: .fixedLayout(width: 360, height: 420)) {
    BalanceSnippetView(model: BalanceSnippetModel(
        look: SnippetLook(tint: SnippetTint.readable(Color(red: 0.93, green: 0.55, blue: 0.24)), photo: nil),
        title: "Goa with the gang",
        titleStyle: .poster,
        subtitle: "Day 3 of 6",
        figure: "₹3,400",
        caption: "coming back to you",
        transfers: [
            .init(id: "1", name: "Priya", asset: "Avatar01", amount: "₹2,200", youPay: false),
            .init(id: "2", name: "Ed", asset: "Avatar02", amount: "₹1,200", youPay: false)
        ],
        claim: .init(settlementID: UUID(), tripID: UUID(), name: "Krishna", asset: "Avatar05", amount: "₹800", method: "UPI")
    ))
    .padding()
}

#Preview("All trips", traits: .fixedLayout(width: 360, height: 380)) {
    BalanceSnippetView(model: BalanceSnippetModel(
        look: .brand,
        title: "All trips",
        titleStyle: nil,
        subtitle: "Across 2 trips",
        figure: "₹1,150",
        caption: "you owe overall",
        trips: [
            .init(id: UUID(), title: "Goa with the gang", style: .poster, figure: "₹3,400", caption: "owed to you"),
            .init(id: UUID(), title: "Paris escape", style: .classic, figure: "₹4,550", caption: "you owe")
        ]
    ))
    .padding()
}
