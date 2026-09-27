//
//  ExpenseDraftSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The confirmation card for a spoken expense, which can be corrected where
/// it stands: tap who paid, tap how it's split, then Log.
///
/// The old card could only be accepted or cancelled, so "no, Priya paid" meant
/// starting the sentence again — and the payer and split are exactly the two
/// things people leave out when they speak. Now the card is the correction.
///
/// The amount is not on it as a control. It comes from the person's words and
/// only from them — no model reads, rounds or nudges it — and a wrong amount
/// is cancelled and said again, not stepped into shape on a card.
struct ExpenseDraftSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Expense Confirmation Card"

    @Parameter(title: "Draft")
    var draftID: String

    init() {}

    init(draftID: UUID) {
        self.draftID = draftID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        guard let id = UUID(uuidString: draftID), let draft = ExpenseDraftBook.shared.draft(id) else {
            throw IntentFailure.notSaved("The expense went stale. Try logging it again.")
        }
        let store = try await IntentStores.store(fresh: false)
        guard let trip = store.trip(draft.tripID) else { throw IntentFailure.tripNotFound }

        return .result(view: ExpenseDraftSnippetView(model: await ExpenseDraftModel.make(draft, on: trip)))
    }
}

/// A spoken expense between the question and the answer: everything Siri has
/// been told, plus whatever's been tapped on the card since.
struct ExpenseDraft {
    let id = UUID()
    /// Fixed when the draft is opened, so the row written is the row the card
    /// described — and the one a follow-up save of the category updates.
    let itemID = UUID()
    let tripID: UUID
    let title: String
    let amount: Double
    var payerID: UUID
    var split: ExpenseSplit
    let opened = Date()

    /// The same booking the quick-add sheet would make from the same answers.
    @MainActor
    func item(on trip: Trip, at now: Date = Date()) -> ItineraryItem {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: trip.startDate)
        let end = calendar.startOfDay(for: trip.endDate)
        let today = calendar.startOfDay(for: now)
        // Today when today is on the trip; otherwise the trip's first day, as
        // Home's quick add files it.
        let day = (start...max(start, end)).contains(today) ? today : start
        let parts = calendar.dateComponents([.hour, .minute], from: now)

        return ItineraryItem(
            id: itemID,
            title: title,
            kind: .activity,
            date: day,
            time: .at(parts.hour ?? 12, parts.minute ?? 0, on: day),
            cost: amount,
            split: split == .everyone ? .equal : .individual,
            participantIDs: split == .everyone ? Set(trip.travellers.map(\.id)) : [payerID],
            paidByID: payerID,
            paymentMethod: AppSettings.defaultPaymentMethod,
            createdByID: Traveller.you.id
        )
    }
}

/// Drafts waiting on a confirmation card.
///
/// In memory, because the only reader is this process while the card is up —
/// Siri keeps the app alive for exactly that long — and a draft that outlived
/// its card would be an expense nobody confirmed.
@MainActor
final class ExpenseDraftBook {
    static let shared = ExpenseDraftBook()

    private var drafts: [UUID: ExpenseDraft] = [:]
    private static let lifetime: TimeInterval = 10 * 60

    private init() {}

    func open(_ draft: ExpenseDraft) {
        drafts = drafts.filter { Date().timeIntervalSince($0.value.opened) < Self.lifetime }
        drafts[draft.id] = draft
    }

    func draft(_ id: UUID) -> ExpenseDraft? {
        drafts[id]
    }

    func update(_ id: UUID, _ change: (inout ExpenseDraft) -> Void) {
        guard var draft = drafts[id] else { return }
        change(&draft)
        drafts[id] = draft
    }

    /// The draft as confirmed, removed so it can't be logged twice.
    func close(_ id: UUID) -> ExpenseDraft? {
        drafts.removeValue(forKey: id)
    }
}

// MARK: - The card's buttons

/// A payer chip on the confirmation card.
struct SetDraftPayerIntent: AppIntent {
    static let title: LocalizedStringResource = "Change Who Paid"
    static let isDiscoverable = false

    @Parameter(title: "Draft") var draftID: String
    @Parameter(title: "Traveller") var travellerID: String

    init() {}

    init(draftID: UUID, travellerID: UUID) {
        self.draftID = draftID.uuidString
        self.travellerID = travellerID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: draftID), let payer = UUID(uuidString: travellerID) else { return .result() }
        ExpenseDraftBook.shared.update(id) { $0.payerID = payer }
        return .result()
    }
}

/// The split switch on the confirmation card.
struct SetDraftSplitIntent: AppIntent {
    static let title: LocalizedStringResource = "Change Split"
    static let isDiscoverable = false

    @Parameter(title: "Draft") var draftID: String
    @Parameter(title: "Split") var split: ExpenseSplit

    init() {}

    init(draftID: UUID, split: ExpenseSplit) {
        self.draftID = draftID.uuidString
        self.split = split
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: draftID) else { return .result() }
        ExpenseDraftBook.shared.update(id) { $0.split = split }
        return .result()
    }
}

// MARK: - Model and view

struct ExpenseDraftModel {
    struct Person: Identifiable {
        let id: UUID
        let name: String
        let asset: String
    }

    var draftID: UUID
    var look: SnippetLook
    var tripTitle: String
    var tripStyle: TripTitleStyle
    var amount: String
    var title: String
    var people: [Person]
    var payerID: UUID
    var split: ExpenseSplit
    var everyoneCount: Int
    var payerName: String
    /// "₹600 each", or who carries it alone.
    var outcome: String

    /// Up to four people to pick from — you first, then the trip's order — and
    /// the current payer always among them, so a chip never vanishes the
    /// moment it's picked.
    @MainActor
    static func make(_ draft: ExpenseDraft, on trip: Trip) async -> ExpenseDraftModel {
        let eligible = trip.travellers.filter { !trip.invitedIDs.contains($0.id) }
        let you = eligible.filter { $0.id == Traveller.you.id }
        var shown = Array((you + eligible.filter { $0.id != Traveller.you.id }).prefix(4))
        if !shown.contains(where: { $0.id == draft.payerID }), let payer = trip.traveller(draft.payerID) {
            if shown.count == 4 { shown.removeLast() }
            shown.append(payer)
        }

        let heads = trip.bearers(of: draft.item(on: trip)).count
        var shared = draft
        shared.split = .everyone
        let everyoneCount = trip.bearers(of: shared.item(on: trip)).count

        let payer = trip.traveller(draft.payerID)
        let payerName = draft.payerID == Traveller.you.id ? "You" : (payer?.name.firstName ?? "Someone")

        let outcome: String
        if heads > 1 {
            outcome = "\(Money.format(Money.wholeShare(of: draft.amount, heads: heads), code: trip.currencyCode)) each"
        } else {
            outcome = draft.payerID == Traveller.you.id ? "Yours alone" : "\(payerName)'s alone"
        }

        return ExpenseDraftModel(
            draftID: draft.id,
            look: await SnippetArtwork.look(for: trip),
            tripTitle: trip.title,
            tripStyle: trip.titleStyle,
            amount: Money.format(draft.amount, code: trip.currencyCode),
            title: draft.title,
            people: shown.map { Person(id: $0.id, name: $0.id == Traveller.you.id ? "You" : $0.name.firstName, asset: $0.asset) },
            payerID: draft.payerID,
            split: draft.split,
            everyoneCount: everyoneCount,
            payerName: payerName,
            outcome: outcome
        )
    }
}

/// The confirmation card. The system puts Cancel and Log under it.
///
/// Siri sets a card's text larger than the app does, so the controls here
/// use fixed sizes and the people who didn't pay show as faces only — the
/// first version gave every chip a name and at Siri's size they all read
/// "Swa…". The one who paid keeps their name, which is the answer the row
/// is asking for.
struct ExpenseDraftSnippetView: View {
    let model: ExpenseDraftModel

    var body: some View {
        SnippetCard(look: model.look) {
            HStack(alignment: .center, spacing: 12) {
                Text(model.tripTitle)
                    .tripTitle(model.tripStyle, size: 19)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                if let photo = model.look.photo {
                    SnippetThumbnail(photo: photo, size: 40)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                SnippetFigure(text: model.amount)
                Text(model.title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(SnippetInk.secondary)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                SnippetEyebrow(text: "Paid by")
                HStack(spacing: 6) {
                    ForEach(model.people) { person in
                        let selected = person.id == model.payerID
                        Button(intent: SetDraftPayerIntent(draftID: model.draftID, travellerID: person.id)) {
                            HStack(spacing: 6) {
                                SnippetAvatar(asset: person.asset, size: 24)
                                if selected {
                                    Text(person.name)
                                        .lineLimit(1)
                                        .transition(.blurReplace)
                                }
                            }
                        }
                        .buttonStyle(SnippetChipStyle(isSelected: selected, tint: model.look.tint, iconOnly: !selected))
                        .accessibilityLabel(person.name)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                    Spacer(minLength: 0)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    SnippetEyebrow(text: "Split")
                    Spacer(minLength: 8)
                    Text(model.outcome)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SnippetInk.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .contentTransition(.numericText())
                }
                HStack(spacing: 6) {
                    Button(intent: SetDraftSplitIntent(draftID: model.draftID, split: .everyone)) {
                        Text("Everyone · \(model.everyoneCount)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SnippetChipStyle(isSelected: model.split == .everyone, tint: model.look.tint))

                    Button(intent: SetDraftSplitIntent(draftID: model.draftID, split: .payerOnly)) {
                        Text(model.payerName == "You" ? "Just me" : "Just \(model.payerName)")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SnippetChipStyle(isSelected: model.split == .payerOnly, tint: model.look.tint))
                }
            }
        }
    }
}

#Preview(traits: .fixedLayout(width: 360, height: 400)) {
    let you = UUID()
    ExpenseDraftSnippetView(model: ExpenseDraftModel(
        draftID: UUID(),
        look: SnippetLook(tint: SnippetTint.readable(Color(red: 0.2, green: 0.7, blue: 0.6)), photo: nil),
        tripTitle: "Goa with the gang",
        tripStyle: .poster,
        amount: "₹2,400",
        title: "Dinner at Thalassa",
        people: [
            .init(id: you, name: "You", asset: "Avatar03"),
            .init(id: UUID(), name: "Priya", asset: "Avatar01"),
            .init(id: UUID(), name: "Ed", asset: "Avatar02"),
            .init(id: UUID(), name: "Kim", asset: "Avatar14")
        ],
        payerID: you,
        split: .everyone,
        everyoneCount: 4,
        payerName: "You",
        outcome: "₹600 each"
    ))
    .padding()
}
