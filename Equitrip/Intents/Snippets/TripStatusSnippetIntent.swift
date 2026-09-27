//
//  TripStatusSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The trip as a place and a date: its photograph across the whole card, how
/// long until it starts or how far in you are, as dots.
///
/// The one card set on the photo rather than its colour, because it's the one
/// that's about *where*, not about money or a booking.
struct TripStatusSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Trip Card"

    @Parameter(title: "Trip")
    var trip: TripEntity

    init() {}

    init(trip: TripEntity) {
        self.trip = trip
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = try await IntentStores.store(fresh: false)
        guard let found = store.trip(trip.id) else { throw IntentFailure.tripNotFound }
        return .result(view: TripStatusSnippetView(model: await TripStatusModel.make(for: found)))
    }
}

struct TripStatusModel {
    var look: SnippetLook
    var tripID: UUID
    var title: String
    var titleStyle: TripTitleStyle
    var subtitle: String
    var eyebrow: String
    var figure: String
    var caption: String
    /// Days as dots — to go, or so far — capped at five weeks' worth.
    var dots: (total: Int, filled: Int, marked: Int?)?
    var footnote: String?

    /// Whole days from today until the trip's first day.
    @MainActor
    static func daysUntil(_ trip: Trip, from now: Date = Date()) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: trip.startDate)).day ?? 0
    }

    @MainActor
    static func make(for trip: Trip) async -> TripStatusModel {
        let look = await SnippetArtwork.look(for: trip)
        let subtitle = [trip.destination, trip.dateRange].filter { !$0.isEmpty }.joined(separator: " · ")

        switch trip.phase {
        case .upcoming:
            let days = daysUntil(trip)
            let next = trip.items.sorted(by: Trip.chronological).first
            return TripStatusModel(
                look: look, tripID: trip.id, title: trip.title, titleStyle: trip.titleStyle, subtitle: subtitle,
                eyebrow: "Countdown",
                figure: days == 1 ? "Tomorrow" : "\(days) days",
                caption: days == 1 ? "you're off" : "to go",
                // A dot per day to go, while that still fits on the card.
                dots: days <= 35 ? (total: days, filled: days, marked: days - 1) : nil,
                footnote: next.map { "First up: \($0.title)" } ?? trip.progressLabel
            )

        case .live:
            let elapsed = min(trip.dayCount, max(1, -daysUntil(trip) + 1))
            let today = trip.items
                .filter { Calendar.current.isDateInToday($0.date) }
                .sorted(by: Trip.chronological)
            let next = today.first { ($0.time ?? $0.date.endOfDay) >= Date() }
            return TripStatusModel(
                look: look, tripID: trip.id, title: trip.title, titleStyle: trip.titleStyle, subtitle: subtitle,
                eyebrow: "Under way",
                figure: "Day \(elapsed)",
                caption: "of \(trip.dayCount)",
                dots: trip.dayCount <= 35 ? (total: trip.dayCount, filled: elapsed, marked: elapsed - 1) : nil,
                footnote: next.map { item in
                    "Next: \(item.title)\(item.time.map { " at \(SnippetWhen.time($0))" } ?? "")"
                } ?? (today.isEmpty ? "Nothing booked today" : "That's everything for today")
            )

        case .past:
            let net = trip.remainingBalance(for: Traveller.you.id)
            return TripStatusModel(
                look: look, tripID: trip.id, title: trip.title, titleStyle: trip.titleStyle, subtitle: subtitle,
                eyebrow: "Wrapped up",
                figure: trip.projectedLabel,
                caption: "spent together",
                dots: nil,
                footnote: net == 0
                    ? "Everyone's square"
                    : net > 0
                        ? "\(Money.format(net, code: trip.currencyCode)) still owed to you"
                        : "You still owe \(Money.format(-net, code: trip.currencyCode))"
            )
        }
    }
}

struct TripStatusSnippetView: View {
    let model: TripStatusModel

    var body: some View {
        SnippetCard(look: model.look, fullBleedPhoto: true) {
            HStack(alignment: .firstTextBaseline) {
                SnippetEyebrow(text: model.eyebrow)
                    .foregroundStyle(SnippetInk.secondary)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    // Beside the figure when it fits, under it when a long
                    // amount would push the words onto two lines.
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            SnippetFigure(text: model.figure, size: 44)
                                .fixedSize()
                            caption
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            SnippetFigure(text: model.figure, size: 44)
                            caption
                        }
                    }
                    if let footnote = model.footnote {
                        Text(footnote)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SnippetInk.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
                if let dots = model.dots, dots.total > 0 {
                    SnippetDotGrid(total: dots.total, filled: dots.filled, marked: dots.marked, dot: dots.total > 21 ? 7 : 9)
                }
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .tripTitle(model.titleStyle, size: 26)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(model.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SnippetInk.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 18)

            Button(intent: OpenFromSnippetIntent(.trip, tripID: model.tripID)) {
                Text("Open trip")
            }
            .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint))
        }
    }

    private var caption: some View {
        Text(model.caption)
            .font(.title3.weight(.semibold))
            .foregroundStyle(SnippetInk.secondary)
            .lineLimit(1)
            .fixedSize()
    }
}

#Preview(traits: .fixedLayout(width: 360, height: 360)) {
    TripStatusSnippetView(model: TripStatusModel(
        look: SnippetLook(tint: SnippetTint.readable(Color(red: 0.55, green: 0.45, blue: 0.85)), photo: nil),
        tripID: UUID(),
        title: "Paris escape",
        titleStyle: .classic,
        subtitle: "Paris, France · 12–21 Sep",
        eyebrow: "Countdown",
        figure: "12 days",
        caption: "to go",
        dots: (total: 12, filled: 12, marked: 11),
        footnote: "First up: Airport transfer"
    ))
    .padding()
}
