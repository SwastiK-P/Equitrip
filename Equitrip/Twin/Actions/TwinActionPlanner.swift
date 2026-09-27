//
//  TwinActionPlanner.swift
//  Equitrip
//

import Foundation

/// Turns a simulation into proposals: for each booking at risk, the few
/// things that would actually help, most useful first.
///
/// Rules, not a model: which actions make sense follows from how a booking
/// is exposed (a ferry can move, a flight can be rebooked, a taxi can leave
/// earlier) and how it's threatened (its own weather, or something upstream).
/// The one search it does is for a drier slot — the same place's forecast,
/// scanned across the trip's remaining daytime hours — so "move it" comes
/// with a when, and the numbers to compare.
enum TwinActionPlanner {

    static func plan(result: TwinResult, twin: TripTwin, trip: Trip, weather: [String: PlaceWeather]) -> [TwinAction] {
        var actions: [TwinAction] = []
        let now = Date()

        for outcome in result.notable {
            guard let node = twin.node(outcome.id), node.window.end > now || trip.phase == .past else { continue }
            let item = node.item
            let deadline = item.time ?? node.window.start
            let percent = Int((outcome.pAffected * 100).rounded())

            func add(_ kind: TwinAction.Kind, _ rationale: String, payload: TwinAction.Payload = .init(), urgency: RiskLevel? = nil, deadline override: Date? = nil) {
                actions.append(TwinAction(
                    kind: kind,
                    tripID: trip.id,
                    itemID: item.id,
                    title: item.title,
                    rationale: rationale,
                    urgency: urgency ?? outcome.risk,
                    deadline: override ?? deadline,
                    payload: payload,
                    status: .suggested,
                    createdAt: now
                ))
            }

            // Knock-on: the fix is upstream, so the useful thing here is to
            // talk about it — the cause gets its own actions.
            if outcome.order > 1, let cause = outcome.causedBy.flatMap(twin.node) {
                add(.discussWithGroup,
                    "\(percent)% chance it's missed if \(cause.item.title) runs late.",
                    payload: .init(draft: "Heads up: if \(cause.item.title) is held up by the weather we could miss \(item.title). Worth a backup plan?"))
                continue
            }

            switch node.exposure {
            case .outdoor, .marine:
                if let slot = drierSlot(for: node, outcome: outcome, trip: trip, weather: weather) {
                    add(.reschedule,
                        "\(slot.label) looks drier — \(format(slot.rain)) mm/h against \(format(outcome.features.rainRate)).",
                        payload: .init(suggestedStart: slot.start, suggestedRain: slot.rain, currentRain: outcome.features.rainRate))
                }
                if node.exposure == .outdoor {
                    add(.swapIndoor, "Keep the time, lose the weather: something under a roof near \(node.place.locality ?? node.place.name).")
                }
                if item.cost > 0 {
                    add(.checkRefund, "\(percent)% likely to be called off. Worth knowing the terms before it is.")
                }

            case .road:
                let feedsDeparture = twin.outgoing(item.id).contains { edge in
                    twin.node(edge.to).map { $0.item.kind == .flight || $0.item.kind == .train } ?? false
                }
                let buffer = Int((max(outcome.typicalDelay, 20) + 30).rounded() / 15) * 15
                add(.addBuffer,
                    feedsDeparture
                        ? "Roads may run \(Int(outcome.typicalDelay.rounded())) min slow on the way to your departure."
                        : "Expect around \(Int(outcome.typicalDelay.rounded())) min of delay on the road.",
                    payload: .init(bufferMinutes: buffer),
                    urgency: feedsDeparture ? max(outcome.risk, .warning) : outcome.risk,
                    deadline: deadline.addingTimeInterval(-Double(buffer) * 60))

            case .air, .rail:
                add(.rebookTransport, "\(percent)% chance of disruption — alternatives are easiest before others start looking.")
                if item.id == twin.homeboundID, let night = result.extraNight {
                    add(.extendStay,
                        "If this falls through, one more night at \(night.stayTitle) is \(Money.format(night.nightly, code: trip.currencyCode)) at its own rate.",
                        payload: .init(stayID: night.stayID, nightly: night.nightly))
                }
                add(.monitor, "The twin re-checks as new forecasts and reports arrive.", urgency: .watch)

            case .shelter, .indoor:
                add(.monitor, "Under a roof, but the way there may not be.", urgency: .watch)
            }
        }

        // One group message for the whole picture, anchored on the worst booking.
        if let worst = result.notable.first, let node = twin.node(worst.id) {
            let names = result.notable.prefix(3).compactMap { twin.node($0.id)?.item.title }
            actions.append(TwinAction(
                kind: .discussWithGroup,
                tripID: trip.id,
                itemID: node.id,
                title: "The weather and our plan",
                rationale: "\(result.notable.count.pluralised("booking")) look exposed. Decide together while there are options.",
                urgency: result.risk,
                deadline: node.item.time ?? node.window.start,
                payload: .init(draft: "The weather twin flags \(names.joined(separator: ", ")) as at risk. Should we move anything?"),
                status: .suggested,
                createdAt: Date()
            ))
        }

        var seen = Set<String>()
        return actions
            .filter { seen.insert($0.id).inserted }
            .sorted { ($0.urgency, $1.deadline ?? .distantFuture) > ($1.urgency, $0.deadline ?? .distantFuture) }
    }

    // MARK: - Drier slot

    private struct Slot {
        let start: Date
        let rain: Double
        var label: String {
            let calendar = Calendar.current
            let day = calendar.isDateInToday(start) ? "Today" : calendar.isDateInTomorrow(start) ? "Tomorrow" : DateFormatter.cached("EEE").string(from: start)
            return "\(day) \(DateFormatter.cached("h a").string(from: start))"
        }
    }

    /// The daytime start, on a day of the trip still ahead, with the least
    /// rain across the booking's own length — and meaningfully less than now.
    private static func drierSlot(for node: TwinNode, outcome: NodeOutcome, trip: Trip, weather: [String: PlaceWeather]) -> Slot? {
        guard let place = weather[node.weatherPlaceID] ?? weather["dest"] else { return nil }
        let duration = node.window.duration
        let calendar = Calendar.current
        let now = Date()
        let firstDay = calendar.startOfDay(for: trip.startDate)
        let lastDay = calendar.startOfDay(for: trip.endDate)

        var best: Slot?
        for hour in place.hours where hour.basis == .forecast {
            let local = calendar.component(.hour, from: hour.time)
            // Inside the trip: a drier morning before anyone has arrived is
            // no slot at all, and Equi will now actually move it there.
            guard (8...17).contains(local), hour.time > now.addingTimeInterval(3600),
                  (firstDay...lastDay).contains(calendar.startOfDay(for: hour.time)),
                  abs(hour.time.timeIntervalSince(node.window.start)) > 2 * 3600 else { continue }
            let span = place.hours(in: DateInterval(start: hour.time, duration: duration))
            let rain = span.map(\.precipitation).max() ?? 0
            if best == nil || rain < best!.rain { best = Slot(start: hour.time, rain: rain) }
        }
        guard let best, best.rain < outcome.features.rainRate * 0.5 || (outcome.features.rainRate > 2 && best.rain < 1) else { return nil }
        return best
    }

    private static func format(_ value: Double) -> String {
        value < 1 ? String(format: "%.1f", value) : String(format: "%.0f", value)
    }
}
