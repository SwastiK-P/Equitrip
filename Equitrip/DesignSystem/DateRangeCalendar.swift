//
//  DateRangeCalendar.swift
//  Equitrip
//

import SwiftUI

/// A scrolling calendar that picks both ends of a trip at once.
///
/// It replaces the pair of single-date pickers the creation flow used to run
/// on — one for the first day, one for the last. Two controls for one decision
/// meant the length of the trip, which is the thing anybody is really
/// choosing, was never on screen while it was being chosen: you picked a day,
/// read a number somewhere else, went back and adjusted. Here the span is
/// drawn as a span and the count follows your thumb.
///
/// Days before today are dimmed but still selectable. A group settling up
/// after the fact is a trip this app is expected to hold, and a calendar that
/// refuses to admit last weekend happened is no use to them.
struct DateRangeCalendar: View {
    @Binding var start: Date
    @Binding var end: Date
    /// True between the first tap of a new span and the second, so the screen
    /// around this can say what it's waiting for instead of leaving the
    /// one-day trip that first tap produced looking like the answer.
    @Binding var isPicking: Bool

    @State private var anchor: Date?

    private let calendar = Calendar.current
    private let today: Date
    /// Built once, in `init`. Derived from `start` it would be rebuilt every
    /// time a tap moved the span, and the scroll position would jump with it.
    private let months: [Date]

    init(start: Binding<Date>, end: Binding<Date>, isPicking: Binding<Bool>) {
        _start = start
        _end = end
        _isPicking = isPicking

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        self.today = today

        // Three months of headroom behind whichever is earlier — today, or a
        // span that has already been set — so a trip being recorded late is
        // reachable by scrolling rather than not reachable at all.
        let earliest = min(today, calendar.startOfDay(for: start.wrappedValue))
        let firstOfThatMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliest)) ?? earliest
        let first = calendar.date(byAdding: .month, value: -3, to: firstOfThatMonth) ?? firstOfThatMonth
        months = (0..<27).compactMap { calendar.date(byAdding: .month, value: $0, to: first) }
    }

    /// The span as it stands, always in order.
    private var span: ClosedRange<Date> {
        let first = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        return first <= last ? first...last : last...first
    }

    var body: some View {
        VStack(spacing: 0) {
            weekdays
            Hairline()

            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 26) {
                        ForEach(months, id: \.self) { month in
                            MonthGrid(month: month, span: span, today: today, onPick: pick)
                                .id(month)
                        }

                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 16)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    reader.scrollTo(monthStart(of: span.lowerBound), anchor: .top)
                }
            }
        }
    }

    /// The locale's own short weekday names, rotated so the column order
    /// matches the calendar's first day rather than always starting on Sunday.
    private var weekdays: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 10)
        .accessibilityHidden(true)
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }

    /// One tap opens a new span, the next closes it.
    ///
    /// Written straight through to the bindings rather than held back until a
    /// Done button, so whatever is showing the dates moves with the calendar —
    /// the whole point of having both ends on screen is seeing what the choice
    /// does.
    private func pick(_ day: Date) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            if let anchor, day > anchor {
                start = anchor
                end = day
                self.anchor = nil
                isPicking = false
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } else {
                anchor = day
                start = day
                end = day
                isPicking = true
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
    }

    private func monthStart(of date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

// MARK: - One month

/// A month drawn as seven columns, with the selected span running through it
/// as a continuous bar rather than as a set of individually highlighted days —
/// the bar is what makes a fortnight read as a fortnight at a glance.
private struct MonthGrid: View {
    let month: Date
    let span: ClosedRange<Date>
    let today: Date
    let onPick: (Date) -> Void

    private let calendar = Calendar.current

    /// Leading blanks for the days of the previous month, then this month's
    /// days. Blanks rather than the neighbouring month's numbers: a grey 31st
    /// sitting at the top of October is a date people tap by mistake.
    private var cells: [Date?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: month),
            let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }

        return Array(repeating: nil, count: leading) + days.map { Optional($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(DateFormatter.cached("MMMM yyyy").string(from: month))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .padding(.leading, 8)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 0
            ) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        cell(day)
                    } else {
                        Color.clear.frame(height: 46)
                    }
                }
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let isStart = calendar.isDate(day, inSameDayAs: span.lowerBound)
        let isEnd = calendar.isDate(day, inSameDayAs: span.upperBound)
        let isEndpoint = isStart || isEnd
        let inSpan = day >= span.lowerBound && day <= span.upperBound
        let isToday = calendar.isDate(day, inSameDayAs: today)

        return ZStack {
            if inSpan, span.lowerBound != span.upperBound {
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: isStart ? 23 : 0,
                        bottomLeading: isStart ? 23 : 0,
                        bottomTrailing: isEnd ? 23 : 0,
                        topTrailing: isEnd ? 23 : 0
                    ),
                    style: .continuous
                )
                .fill(AppTheme.accent.opacity(0.13))
                .padding(.vertical, 3)
            }

            if isEndpoint {
                Circle()
                    .fill(AppTheme.cta)
                    .frame(width: 40, height: 40)
            }

            Text("\(calendar.component(.day, from: day))")
                .font(.system(size: 15, weight: isEndpoint ? .bold : .medium, design: .rounded))
                .foregroundStyle(label(isEndpoint: isEndpoint, isPast: day < today))
        }
        .frame(height: 46)
        .overlay(alignment: .bottom) {
            Circle()
                .fill(isEndpoint ? AppTheme.ctaLabel : AppTheme.accent)
                .frame(width: 3.5, height: 3.5)
                .padding(.bottom, 5)
                .opacity(isToday ? 1 : 0)
        }
        .contentShape(.rect)
        .onTapGesture { onPick(day) }
        .accessibilityElement()
        .accessibilityLabel(DateFormatter.cached("EEEE d MMMM").string(from: day))
        .accessibilityAddTraits(isEndpoint ? [.isButton, .isSelected] : .isButton)
    }

    private func label(isEndpoint: Bool, isPast: Bool) -> Color {
        if isEndpoint { return AppTheme.ctaLabel }
        return isPast ? AppTheme.inkTertiary.opacity(0.55) : AppTheme.ink
    }
}
