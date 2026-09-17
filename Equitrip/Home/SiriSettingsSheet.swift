//
//  SiriSettingsSheet.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// What you can say to Siri about your trips.
///
/// Everything here already works without setting anything up — the App
/// Shortcuts phrases are registered on install, and the calendar and message
/// actions are understood by meaning. The sheet exists because none of that
/// is visible: a voice feature nobody has heard of is a feature nobody uses.
/// So it's examples, in the words that work, and the way into Shortcuts.
struct SiriSettingsSheet: View {

    private struct Example: Identifiable {
        let id = UUID()
        let symbol: String
        let phrase: String
        let detail: String
    }

    private let examples: [(section: String, items: [Example])] = [
        ("Money", [
            Example(symbol: "indianrupeesign.circle", phrase: "“Log an expense in Equitrip”", detail: "Siri asks what and how much, then shows you the split before saving."),
            Example(symbol: "arrow.left.arrow.right", phrase: "“Where do I stand on Goa in Equitrip?”", detail: "Who you owe and who owes you, read out."),
        ]),
        ("The plan", [
            Example(symbol: "calendar.day.timeline.left", phrase: "“What's next on my trip in Equitrip?”", detail: "The next few bookings, with gates and times."),
            Example(symbol: "plus.circle", phrase: "“Add a cooking class at 11 on Saturday to my Goa trip in Equitrip”", detail: "Organisers can add, move and cancel bookings."),
            Example(symbol: "sparkles", phrase: "“Ask Equitrip who paid for the villa”", detail: "Equi answers without opening the app."),
        ]),
        ("The group chat", [
            Example(symbol: "bubble.left.and.bubble.right", phrase: "“Tell the Goa group I'm running late in Equitrip”", detail: "Siri reads it back before it sends."),
            Example(symbol: "hand.point.up.left", phrase: "“Add this to the trip” · “Send this to the group”", detail: "Siri knows which trip, booking or chat is on screen."),
        ]),
    ]

    var body: some View {
        SettingsSheetScaffold(
            title: "Siri",
            caption: "Ask about your trips, log what you paid and message the group, hands-free. Nothing to set up."
        ) {
            SiriTipView(intent: TripBalanceIntent())
                .siriTipViewStyle(.automatic)

            ForEach(examples, id: \.section) { group in
                Text(group.section.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)
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
    }
}
