//
//  EventDetailView.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// One booking — the phone's detail sheet at wrist scale.
///
/// The same sections in the same spirit: what and when, the pass for a
/// flight, what it costs you and how that was worked out, who paid, who it's
/// shared with. What's left behind is what a wrist can't use — editing, the
/// receipt photograph, the per-person arithmetic under an uneven split, and
/// who added it.
///
/// The hero is centred rather than leading like the phone's: on a round-
/// cornered screen a badge in the top-left corner sits under the clock and
/// the curve, and a centred mark is how watchOS opens a detail screen.
struct EventDetailView: View {
    let event: EquitripSnapshot.Event

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Hero(event: event)
                    .padding(.bottom, 2)

                if event.routeLabel != nil || event.flightNumber != nil {
                    FlightPass(event: event)
                }

                if event.costLabel != nil {
                    DetailSection(title: "Cost") { CostCard(event: event) }
                    DetailSection(title: "Paid by") { PaidByCard(event: event) }
                }

                if event.isDisputed == true {
                    DisputeBanner()
                }

                if let people = event.participants, !people.isEmpty {
                    DetailSection(title: "Who's on this · \(people.count)") { WhoCard(people: people) }
                }
            }
        }
        .navigationTitle(event.kindLabel ?? "Booking")
        // Pushed over the pages, so the navigation container's.
        .watchPageTint(event.tint, intensity: 0.4, placement: .navigation)
    }
}

// MARK: - Hero

/// The booking's mark large and centred, the name under it, and when as a
/// single capsule — date and time are one fact on a wrist, not two rows.
private struct Hero: View {
    let event: EquitripSnapshot.Event

    @ScaledMetric(relativeTo: .title2) private var mark: CGFloat = 56

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: event.symbol)
                .font(.title2.weight(.semibold))
                .foregroundStyle(event.tint)
                .frame(width: mark, height: mark)
                .background(event.tint.opacity(0.2), in: .circle)
                .overlay {
                    Circle().strokeBorder(event.tint.opacity(0.35), lineWidth: 1)
                }
                .padding(.bottom, 2)
                .accessibilityHidden(true)

            Text(event.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let vendor = event.vendor, vendor != event.title {
                Text(vendor)
                    .font(.footnote)
                    .foregroundStyle(Brand.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            HStack(spacing: 5) {
                Image(systemName: "calendar")
                    .foregroundStyle(event.tint)
                Text(when)
                    .foregroundStyle(Brand.ink)
            }
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .glassEffect(.regular, in: .capsule)
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// "Today · 4:30 PM", "Tomorrow · All day", "Sat 12 Sep · 8:00 PM".
    private var when: String {
        let calendar = Calendar.current
        let day = if calendar.isDateInToday(event.date) {
            "Today"
        } else if calendar.isDateInTomorrow(event.date) {
            "Tomorrow"
        } else {
            event.date.tripDayLabel
        }
        return "\(day) · \(event.timeLabel ?? "All day")"
    }
}

// MARK: - Section

/// A caption over a card — the phone's `sectionLabel`.
private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.inkSecondary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Flight

/// The phone's ticket card: airline and number, the two airports with their
/// cities and times either side of the plane, then terminal and gate.
private struct FlightPass: View {
    let event: EquitripSnapshot.Event

    /// `BOM → GOI`, split back into its ends.
    private var ends: (from: String, to: String)? {
        guard let parts = event.routeLabel?.components(separatedBy: " → "), parts.count == 2 else { return nil }
        return (parts[0], parts[1])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 4) {
                Text([event.airline, event.flightNumber].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let status = event.flightStatus {
                    Text(status)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(statusTint(status))
                        .lineLimit(1)
                }
            }

            if let ends {
                HStack(alignment: .top, spacing: 4) {
                    airport(ends.from, city: event.departureCity, time: event.departureTimeLabel, alignment: .leading)
                    Spacer(minLength: 2)
                    Image(systemName: "airplane")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(event.tint)
                        .padding(.top, 6)
                        .accessibilityHidden(true)
                    Spacer(minLength: 2)
                    airport(ends.to, city: event.arrivalCity, time: event.arrivalTimeLabel, alignment: .trailing)
                }
            }

            if event.terminal != nil || event.gate != nil {
                HStack(spacing: 6) {
                    if let terminal = event.terminal { chip("Terminal", terminal) }
                    if let gate = event.gate { chip("Gate", gate) }
                }
            }
        }
        .watchCard(padding: 11)
    }

    private func airport(_ code: String, city: String?, time: String?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(code)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Brand.ink)
            if let city {
                Text(city)
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)
            }
            if let time {
                Text(time)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.inkSecondary)
                    .padding(.top, 2)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .accessibilityElement(children: .combine)
    }

    private func chip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.inkTertiary)
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(Brand.ink)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: .rect(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// The phone's `FlightDetails.Status.tint`, keyed by the label the
    /// snapshot carries.
    private func statusTint(_ status: String) -> Color {
        switch status {
        case "In the air": Brand.blue
        case "Landed": Brand.positive
        case "Delayed": Brand.amber
        case "Cancelled": Brand.danger
        default: Brand.inkSecondary
        }
    }
}

// MARK: - Cost

/// Your share first and largest — the figure people open a booking to check
/// — against the total, then the rule that got there.
private struct CostCard: View {
    let event: EquitripSnapshot.Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let share = event.shareAmountLabel {
                Text("Your share")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        figure(share)
                        Spacer(minLength: 4)
                        total
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        figure(share)
                        total
                    }
                }
            } else {
                Text("Total")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)
                Text(event.costLabel ?? "")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Text("Not shared with you")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)
            }

            if let rule = event.splitLabel {
                Divider()
                    .padding(.vertical, 8)

                HStack(spacing: 8) {
                    Image(systemName: event.splitSymbol ?? "equal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.accent)
                        .frame(width: 18)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(rule)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Brand.ink)
                        if let each = event.eachLabel {
                            Text(each)
                                .font(.caption2)
                                .foregroundStyle(Brand.inkSecondary)
                        }
                    }
                }
            }
        }
        .watchCard(padding: 11)
        .accessibilityElement(children: .combine)
    }

    private func figure(_ share: String) -> some View {
        Text(share)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(Brand.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    @ViewBuilder
    private var total: some View {
        if let total = event.costLabel, total != event.shareAmountLabel {
            Text("of \(total)")
                .font(.caption2)
                .foregroundStyle(Brand.inkTertiary)
                .lineLimit(1)
        }
    }
}

// MARK: - Paid by

/// Whose money it was — or that it isn't anybody's yet, which on the phone
/// is a button and here is the instruction to go there.
private struct PaidByCard: View {
    let event: EquitripSnapshot.Event

    @ScaledMetric(relativeTo: .footnote) private var face: CGFloat = 30

    var body: some View {
        HStack(spacing: 9) {
            if let payer = event.paidBy {
                WatchAvatar(person: payer, size: face)

                VStack(alignment: .leading, spacing: 0) {
                    Text(payer.name == "You" ? "You paid" : "\(payer.name) paid")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.ink)
                    Text(event.paymentMethodLabel ?? "Method not recorded")
                        .font(.caption2)
                        .foregroundStyle(Brand.inkSecondary)
                }
                .lineLimit(1)

                Spacer(minLength: 4)

                if let cost = event.costLabel {
                    Text(cost)
                        .font(.system(.footnote, design: .rounded, weight: .bold))
                        .foregroundStyle(Brand.ink)
                        .lineLimit(1)
                        .fixedSize()
                }
            } else {
                Image(systemName: "creditcard")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.accent)
                    .frame(width: face, height: face)
                    .background(Brand.accent.opacity(0.2), in: .circle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Nobody's paid yet")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.ink)
                    Text("Record it on your iPhone")
                        .font(.caption2)
                        .foregroundStyle(Brand.inkSecondary)
                }

                Spacer(minLength: 0)
            }
        }
        .watchCard(padding: 10)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Dispute

private struct DisputeBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Brand.danger)
            VStack(alignment: .leading, spacing: 0) {
                Text("Payment disputed")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text("Sort it out on your iPhone")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)
            }
        }
        .watchCard(padding: 10, fill: Brand.danger.opacity(0.2))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Who

/// Faces, then names — the phone's `AvatarStack` over the sentence it
/// stands for. The overlapping faces say "how many" at a glance, and the line
/// says who.
private struct WhoCard: View {
    let people: [EquitripSnapshot.Person]

    @ScaledMetric(relativeTo: .footnote) private var face: CGFloat = 28

    private let shown = 4

    /// Beside the faces when the names fit there — one or two people is a
    /// row, not a stack — and under them once they don't.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                faces
                names(lineLimit: 1)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 7) {
                faces
                names(lineLimit: nil)
            }
        }
        .watchCard(padding: 10)
    }

    private var faces: some View {
        HStack(spacing: -face * 0.3) {
            ForEach(Array(people.prefix(shown).enumerated()), id: \.offset) { slot, person in
                WatchAvatar(person: person, size: face)
                    .zIndex(Double(shown - slot))
            }
            if people.count > shown {
                Text("+\(people.count - shown)")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(Brand.inkSecondary)
                    .minimumScaleFactor(0.7)
                    .frame(width: face, height: face)
                    .background(Brand.inkTertiary.opacity(0.35), in: .circle)
                    .overlay { Circle().strokeBorder(Color.watchCard, lineWidth: 1.5) }
            }
        }
        .fixedSize()
        .accessibilityHidden(true)
    }

    private func names(lineLimit: Int?) -> some View {
        Text(sentence)
            .font(.footnote)
            .foregroundStyle(Brand.ink)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: lineLimit != nil, vertical: true)
    }

    /// "You, Priya, Rohan and Ananya".
    private var sentence: String {
        let names = people.map(\.name)
        guard names.count > 1 else { return names.first ?? "" }
        return names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }
}

#Preview {
    NavigationStack { EventDetailView(event: EquitripSnapshot.placeholder.upNext[0]) }
}
