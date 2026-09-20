//
//  AgendaPage.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// What's next on the trip in view, a day at a time.
///
/// The very next booking is lifted out as a card of its own — time, name,
/// what it costs you — because on a wrist that is nearly always the whole
/// question. Everything after it reads down one compact row each, and the
/// crown scrolls the lot.
struct AgendaPage: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        let days = groupedByDay(store.events)

        Group {
            if days.isEmpty {
                WatchNotice(
                    symbol: "calendar",
                    title: "Nothing booked ahead",
                    detail: "Bookings you add on your iPhone show up here."
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(days.enumerated()), id: \.element.date) { index, day in
                            DayHeader(title: header(for: day.date))
                                .padding(.top, index == 0 ? 0 : 8)

                            ForEach(Array(day.events.enumerated()), id: \.element.id) { position, event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    if index == 0 && position == 0 {
                                        NextCard(event: event)
                                    } else {
                                        EventRow(event: event)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        StaleFooter()
                            .padding(.top, 4)
                    }
                }
            }
        }
        .navigationTitle(store.trip?.destination.components(separatedBy: ",").first ?? "Up next")
        .watchPageTint(Brand.accent)
    }

    // MARK: Days

    private struct Day {
        let date: Date
        let events: [EquitripSnapshot.Event]
    }

    private func groupedByDay(_ events: [EquitripSnapshot.Event]) -> [Day] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted().map { Day(date: $0, events: grouped[$0] ?? []) }
    }

    /// "Day 1 · Sat 12 Sep", counted from the trip's first day — the same
    /// numbering as the phone's timeline. "Today" wins when it's true.
    private func header(for date: Date) -> String {
        let calendar = Calendar.current
        let label = date.tripDayLabel

        if let start = store.trip?.startDate,
           let offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: date).day,
           offset >= 0 {
            // "Today" is worth more than the day's number, and the date is
            // still there for anyone counting.
            return calendar.isDateInToday(date) ? "Today · \(label)" : "Day \(offset + 1) · \(label)"
        }
        if calendar.isDateInToday(date) { return "Today · \(label)" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow · \(label)" }
        return label
    }
}

// MARK: - Day header

private struct DayHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Brand.inkSecondary)
            .padding(.horizontal, 2)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Next card

/// The one booking that's actually next, given room: when, what, and what it
/// costs you against what it costs everyone.
private struct NextCard: View {
    let event: EquitripSnapshot.Event

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Eyebrow(text: "Next")
                if let time = event.timeLabel {
                    Text("· \(time)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Brand.accent)
                }
                Spacer(minLength: 4)
                Image(systemName: event.symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(event.tint)
            }
            .lineLimit(1)

            Text(event.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.ink)
                .lineLimit(2)
                .padding(.top, 3)

            if let detail = event.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)
                    .lineLimit(1)
            }

            if event.shareAmountLabel != nil || event.costLabel != nil {
                money
                    .padding(.top, 7)
            }
        }
        .watchCard(padding: 11, fill: Brand.accent.opacity(0.22))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Next booking")
    }

    /// "₹800 your share — of ₹3,200". The total drops to its own line once
    /// the text is large: three things on one line at an accessibility size
    /// is three truncations.
    @ViewBuilder
    private var money: some View {
        let figure = event.shareAmountLabel ?? event.costLabel
        let caption = event.shareAmountLabel == nil ? "total" : "your share"
        let total = event.shareAmountLabel == nil ? nil : event.costLabel

        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(figure ?? "")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Brand.ink)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(Brand.inkSecondary)

                if let total, total != figure, !typeSize.isAccessibilitySize {
                    Spacer(minLength: 4)
                    Text("of \(total)")
                        .font(.caption2)
                        .foregroundStyle(Brand.inkTertiary)
                }
            }

            if let total, total != figure, typeSize.isAccessibilitySize {
                Text("of \(total)")
                    .font(.caption2)
                    .foregroundStyle(Brand.inkTertiary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Row

private struct EventRow: View {
    let event: EquitripSnapshot.Event

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ClockStack(value: event.clockValue, meridiem: event.clockMeridiem)
                .padding(.top, 1)

            // The name gets the whole width and two lines — booking names come
            // out of PDFs at full length, and a column squeezed between a
            // badge and a price breaks them mid-word. The badge and the figure
            // move to the line underneath, where they're read second anyway.
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(2)

                HStack(spacing: 5) {
                    SymbolBadge(symbol: event.symbol, tint: event.tint, style: .caption2)

                    Text(event.detail ?? "")
                        .font(.caption2)
                        .foregroundStyle(Brand.inkSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let cost = event.costCompactLabel {
                        Text(cost)
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(Brand.inkSecondary)
                            .fixedSize()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.leading, 4)
        .padding(.trailing, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.watchCard, in: .rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

extension EquitripSnapshot.Event {
    /// `6:30 AM`, or nil for an all-day booking.
    var timeLabel: String? {
        guard let clockValue else { return nil }
        return [clockValue, clockMeridiem].compactMap { $0 }.joined(separator: " ")
    }
}

#Preview {
    NavigationStack { AgendaPage() }
        .environment(WatchStore(preview: .placeholder))
}
