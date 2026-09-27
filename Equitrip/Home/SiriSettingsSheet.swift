//
//  SiriSettingsSheet.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// What you can say to Siri about your trips, and what Siri shows back.
///
/// Everything here already works without setting anything up — the App
/// Shortcuts phrases are registered on install. The sheet exists because none
/// of that is visible: a voice feature nobody has heard of is a feature nobody
/// uses.
///
/// Two rules the first version broke. Every phrase listed is one that's
/// actually registered, word for word — it used to promise "Ask Equitrip who
/// paid for the villa", which a shortcut phrase can't hold, so Siri asked the
/// question back. And the things only Siri with Apple Intelligence
/// understands (bookings and group messages, in your own words) are kept in a
/// group of their own, rather than sitting beside phrases that work on every
/// phone as if they were the same.
///
/// The cards at the top are the real ones — the same views Siri draws, built
/// from your own trip — shown here with their buttons switched off.
struct SiriSettingsSheet: View {
    @Environment(\.tripStore) private var store

    private struct Example: Identifiable {
        let id = UUID()
        let symbol: String
        let phrase: String
        let detail: String
    }

    private struct Preview: Identifiable {
        let id: String
        let phrase: String
        let card: AnyView
    }

    @State private var previews: [Preview] = []

    /// The trip the examples name — the one under way, or next.
    private var trip: Trip? {
        TripMatcher.byRelevance(store.trips).first { $0.phase != .past } ?? store.trips.first
    }

    private var tripName: String { trip?.title ?? "Goa" }

    private var sections: [(section: String, note: String?, items: [Example])] {
        [
            ("Money", nil, [
                Example(symbol: "plus.circle", phrase: "“Log an expense in Equitrip”", detail: "Siri asks how much and what for, then shows a card where you can change who paid and how it's split."),
                Example(symbol: "arrow.left.arrow.right", phrase: "“What do I owe in Equitrip?”", detail: "Your balance and who pays whom. Confirm a payment right from the card."),
                Example(symbol: "checkmark.seal", phrase: "“Did anyone pay me in Equitrip?”", detail: "Payments waiting on you, one tap each to confirm."),
            ]),
            ("The plan", nil, [
                Example(symbol: "calendar.day.timeline.left", phrase: "“What's next in Equitrip?”", detail: "The next booking with its time, gate and directions."),
                Example(symbol: "hourglass", phrase: "“How long until \(tripName) in Equitrip?”", detail: "Days to go, or which day of the trip you're on."),
                Example(symbol: "sparkles", phrase: "“Ask Equitrip”", detail: "Then ask anything — who paid for the villa, what's on Saturday."),
            ]),
            ("With Apple Intelligence", "On iPhones with Apple Intelligence, Siri also understands these in your own words.", [
                Example(symbol: "calendar.badge.plus", phrase: "“Add a cooking class at 11 on Saturday to my \(tripName) trip”", detail: "Organisers can add, move and cancel bookings."),
                Example(symbol: "bubble.left.and.bubble.right", phrase: "“Tell the \(tripName) group I'm running late”", detail: "Siri reads it back before it sends."),
                Example(symbol: "hand.point.up.left", phrase: "“Add this to the trip”", detail: "Siri knows which trip, booking or chat is on screen."),
            ]),
        ]
    }

    var body: some View {
        SettingsSheetScaffold(
            title: "Siri",
            caption: "Ask about your trips, log what you paid and confirm payments, hands-free. Nothing to set up."
        ) {
            if !previews.isEmpty {
                previewCarousel
            }

            SiriTipView(intent: LogExpenseIntent())
                .siriTipViewStyle(.automatic)

            ForEach(sections, id: \.section) { group in
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.section.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.9)
                        .foregroundStyle(AppTheme.inkTertiary)
                    if let note = group.note {
                        Text(note)
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.leading, 2)
                .padding(.top, 6)

                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, example in
                        HStack(alignment: .top, spacing: 12) {
                            IconTile(symbol: example.symbol, size: 32, corner: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(example.phrase)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(example.detail)
                                    .font(.system(size: 12.5))
                                    .foregroundStyle(AppTheme.inkTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if index < group.items.count - 1 { Hairline(inset: 16) }
                    }
                }
                .cardSurface(corner: 22)
            }

            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
        .task(id: trip?.id) { previews = await buildPreviews() }
    }

    /// What Siri shows, one card per page, each under the words that bring it
    /// up.
    private var previewCarousel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHAT SIRI SHOWS")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.leading, 2)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(previews) { preview in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preview.phrase)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.inkSecondary)
                                .lineLimit(1)
                                .padding(.leading, 4)
                            preview.card
                                .containerShape(.rect(cornerRadius: 30, style: .continuous))
                                // A preview, not a remote: its buttons would
                                // otherwise really confirm payments.
                                .allowsHitTesting(false)
                                .accessibilityHint("Example of what Siri shows")
                        }
                        .containerRelativeFrame(.horizontal) { width, _ in width * 0.88 }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func buildPreviews() async -> [Preview] {
        guard let trip else { return [] }
        var built: [Preview] = []

        let balance = await BalanceSnippetModel.make(for: trip)
        built.append(Preview(id: "balance", phrase: "“What do I owe in Equitrip?”", card: AnyView(BalanceSnippetView(model: balance))))

        if trip.phase != .past, !UpNextSnippetModel.upcoming(on: trip).isEmpty {
            let upNext = await UpNextSnippetModel.make(for: trip)
            built.append(Preview(id: "next", phrase: "“What's next in Equitrip?”", card: AnyView(UpNextSnippetView(model: upNext))))
        }

        let status = await TripStatusModel.make(for: trip)
        built.append(Preview(id: "trip", phrase: "“How long until \(trip.title) in Equitrip?”", card: AnyView(TripStatusSnippetView(model: status))))

        if !store.settlementsAwaitingYou.isEmpty {
            let payments = await SettleRequestsModel.make(store)
            built.append(Preview(id: "payments", phrase: "“Did anyone pay me in Equitrip?”", card: AnyView(SettleRequestsSnippetView(model: payments))))
        }
        return built
    }
}
