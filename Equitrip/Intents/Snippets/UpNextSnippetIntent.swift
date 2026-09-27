//
//  UpNextSnippetIntent.swift
//  Equitrip
//

import AppIntents
import SwiftUI

/// The card under "What's next?": the next booking, large, in the app's
/// dashed timeline block, with how to get there and what follows it.
///
/// Laid out like a calendar's next-event card rather than a list, because the
/// question is almost always about one thing — when's the train, which gate —
/// and a list of three at the same size made the answer the third thing
/// anyone read.
struct UpNextSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "What's Next Card"

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
        return .result(view: UpNextSnippetView(model: await UpNextSnippetModel.make(for: found)))
    }
}

struct UpNextSnippetModel {

    struct Event: Identifiable {
        let id: UUID
        let symbol: String
        let title: String
        /// "Tomorrow", "Sat 14 Sep" — shown only when it isn't the card's day.
        let day: String
        let time: String
        /// "10:15 AM – 12:15 PM", or the time alone when nothing says how long.
        let span: String
        /// Flight number, terminal and gate; otherwise where it is.
        let detail: String?
        let status: String?
        let statusIsAlert: Bool
    }

    var look: SnippetLook
    var tripID: UUID
    var title: String
    var titleStyle: TripTitleStyle
    var day: String
    var first: Event?
    var then: [Event] = []
    /// What Maps should look for — the first booking's place, in the trip's
    /// destination.
    var directions: String?

    /// Next three from now: anything still to come, and anything untimed on a
    /// day that hasn't ended.
    @MainActor
    static func upcoming(on trip: Trip, from now: Date = Date()) -> [ItineraryItem] {
        Array(
            trip.items
                .filter { ($0.time ?? $0.date.endOfDay) >= now }
                .sorted(by: Trip.chronological)
                .prefix(3)
        )
    }

    @MainActor
    static func make(for trip: Trip) async -> UpNextSnippetModel {
        let ahead = upcoming(on: trip)
        let first = ahead.first

        return UpNextSnippetModel(
            look: await SnippetArtwork.look(for: trip),
            tripID: trip.id,
            title: trip.title,
            titleStyle: trip.titleStyle,
            day: first.map { SnippetWhen.day($0.date) } ?? "Nothing booked",
            first: first.map(event),
            then: ahead.dropFirst().map(event),
            directions: first.flatMap { place(of: $0, on: trip) }
        )
    }

    /// Where to send Maps: a flight's departure airport as it's named, or a
    /// booking's venue in the trip's destination so "Taj" means the one in
    /// Goa. Nil when the booking names nowhere.
    @MainActor
    private static func place(of item: ItineraryItem, on trip: Trip) -> String? {
        if let flight = item.flight {
            return flight.departureAirportName ?? flight.departureAirport.map { "\($0) airport" }
        }
        return item.vendorName.map { [$0, trip.destination].joined(separator: ", ") }
    }

    @MainActor
    private static func event(_ item: ItineraryItem) -> Event {
        let start = item.time
        let end = item.flight?.scheduledArrival
        let span: String = switch (start, end) {
        case (let start?, let end?) where end > start: "\(SnippetWhen.time(start)) – \(SnippetWhen.time(end))"
        case (let start?, _): SnippetWhen.time(start)
        default: "All day"
        }

        var detail: String?
        var status: String?
        var alert = false
        if let flight = item.flight {
            detail = [
                flight.number,
                flight.departureTerminal.map { "T\($0)" },
                flight.departureGate.map { "Gate \($0)" }
            ].compactMap { $0 }.joined(separator: " · ")
            if let state = flight.status, state != .unknown, state != .scheduled {
                if state == .delayed, let minutes = flight.departureDelay, minutes > 0 {
                    status = "Delayed \(minutes)m"
                } else {
                    status = state.label
                }
                alert = state == .delayed || state == .cancelled
            }
        } else {
            detail = item.vendorName
        }

        return Event(
            id: item.id,
            symbol: item.symbol,
            title: item.title,
            day: SnippetWhen.day(item.date),
            time: start.map(SnippetWhen.time) ?? "All day",
            span: span,
            detail: detail,
            status: status,
            statusIsAlert: alert
        )
    }
}

/// The what's-next card.
struct UpNextSnippetView: View {
    let model: UpNextSnippetModel

    var body: some View {
        SnippetCard(look: model.look) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.day)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(model.title)
                        .tripTitle(model.titleStyle, size: 15)
                        .foregroundStyle(SnippetInk.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if let photo = model.look.photo {
                    SnippetThumbnail(photo: photo, size: 44)
                }
            }

            if let first = model.first {
                SnippetEventBlock {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: first.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(SnippetInk.wash, in: .circle)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(first.title)
                                .font(.title3.weight(.semibold))
                                .lineLimit(2)
                            Text(first.span)
                                .font(.body.weight(.medium))
                                .foregroundStyle(SnippetInk.secondary)
                                .monospacedDigit()
                            if first.detail != nil || first.status != nil {
                                HStack(spacing: 8) {
                                    if let detail = first.detail, !detail.isEmpty {
                                        Text(detail)
                                            .font(.subheadline)
                                            .foregroundStyle(SnippetInk.secondary)
                                            .lineLimit(1)
                                    }
                                    if let status = first.status {
                                        Text(status)
                                            .font(.caption.weight(.bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .foregroundStyle(first.statusIsAlert ? model.look.tint : SnippetInk.primary)
                                            .background(first.statusIsAlert ? Color.white : SnippetInk.wash, in: .capsule)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }

                if !model.then.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(model.then) { event in
                            HStack(spacing: 10) {
                                Text(event.day == model.day ? event.time : "\(event.day), \(event.time)")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(SnippetInk.secondary)
                                    .lineLimit(1)
                                    .layoutPriority(1)
                                Text(event.title)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    if let directions = model.directions {
                        Button(intent: OpenInMapsIntent(place: directions)) {
                            Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        }
                        .buttonStyle(SnippetButtonStyle(weight: .secondary, tint: model.look.tint))
                    }
                    Button(intent: OpenFromSnippetIntent(.booking, tripID: model.tripID, itemID: first.id)) {
                        Text("Open")
                    }
                    .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint))
                }
            } else {
                Text("Nothing else is booked on this trip.")
                    .font(.body)
                    .foregroundStyle(SnippetInk.secondary)
                Button(intent: OpenFromSnippetIntent(.trip, tripID: model.tripID)) {
                    Text("Open trip")
                }
                .buttonStyle(SnippetButtonStyle(weight: .primary, tint: model.look.tint))
            }
        }
    }
}

#Preview("Flight", traits: .fixedLayout(width: 360, height: 400)) {
    UpNextSnippetView(model: UpNextSnippetModel(
        look: SnippetLook(tint: SnippetTint.readable(Color(red: 0.35, green: 0.6, blue: 0.95)), photo: nil),
        tripID: UUID(),
        title: "Paris escape",
        titleStyle: .classic,
        day: "Tomorrow",
        first: .init(
            id: UUID(), symbol: "airplane", title: "Flight to Paris", day: "Tomorrow", time: "10:15 AM",
            span: "10:15 AM – 3:40 PM", detail: "AI 143 · T2 · Gate 14", status: "Delayed 20m", statusIsAlert: true
        ),
        then: [
            .init(id: UUID(), symbol: "car.fill", title: "Airport transfer", day: "Tomorrow", time: "6:00 PM",
                  span: "6:00 PM", detail: nil, status: nil, statusIsAlert: false),
            .init(id: UUID(), symbol: "bed.double.fill", title: "Hôtel des Arts", day: "Sun 15 Sep", time: "All day",
                  span: "All day", detail: nil, status: nil, statusIsAlert: false)
        ],
        directions: "Chhatrapati Shivaji Airport, Mumbai"
    ))
    .padding()
}
