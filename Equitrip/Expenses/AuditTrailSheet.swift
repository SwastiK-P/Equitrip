//
//  AuditTrailSheet.swift
//  Equitrip
//

import SwiftUI

// MARK: - The ledger's entry point

/// The card at the foot of the ledger that opens the trail.
///
/// Placed below the expenses rather than beside the totals because it answers
/// the question that comes *after* the numbers, not instead of them: you read
/// what something costs, you disagree with it, and then you want to know who
/// made it that. It leads with the most recent change for the same reason —
/// nine times out of ten that's the one being asked about.
struct AuditTrailButton: View {
    @Environment(\.auditTrail) private var audit

    let trip: Trip
    let action: () -> Void

    private var events: [AuditEvent] { audit.events(for: trip.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: "Audit trail", caption: caption)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            } label: {
                HStack(spacing: 13) {
                    IconTile(symbol: "list.bullet.rectangle.portrait", size: 40, corner: 12)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Every change on this trip")
                            .font(.system(size: 14.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)

                        Text(subtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(corner: 22)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Audit trail, \(events.count) recorded changes")
        }
        // Loaded here rather than inside the sheet so the card can say how
        // many there are before anybody taps it — "22 changes recorded" is
        // itself the reason somebody opens this.
        .task(id: trip.id) { await audit.load(trip.id) }
    }

    private var caption: String? {
        events.isEmpty ? nil : events.count.pluralised("entry", "entries")
    }

    private var subtitle: String {
        guard let latest = audit.latest(for: trip.id) else {
            return audit.hasLoaded(trip.id) ? "Amounts, splits, payments, disputes" : "Reading the record…"
        }
        return "Last change \(latest.relative) · \(latest.actorLabel)"
    }
}

// MARK: - The trail

/// Every recorded change to one trip, searchable and grouped by day.
///
/// Append-only by construction — see `0015_audit_trail.sql`. There is nothing
/// on this screen that edits or removes an entry, and there is deliberately no
/// server-side policy that would let one be added.
struct AuditTrailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.auditTrail) private var audit

    let trip: Trip

    @State private var searchText = ""
    @State private var category: AuditEvent.Category?
    /// Only entries you filed. The single most-asked question of a trail after
    /// "what changed" is "was that me", and it's a tap rather than a search
    /// because your own name isn't what you'd type.
    @State private var minesOnly = false
    @State private var expanded: Set<UUID> = []
    /// Which day's card currently sits at the top of the scroll view — see
    /// `content`. Drives the fixed day label, which lives outside the
    /// `ScrollView` entirely so it truly never moves, rather than a pinned
    /// `Section` header sliding and clipping against the card underneath it.
    @State private var topDayID: Date?

    private var all: [AuditEvent] { audit.events(for: trip.id) }

    private var visible: [AuditEvent] {
        Self.apply(category: category, minesOnly: minesOnly, search: searchText, to: all)
    }

    private var days: [AuditDay] {
        Dictionary(grouping: visible, by: \.day)
            .map { AuditDay(date: $0.key, events: $0.value.sorted { $0.at > $1.at }) }
            .sorted { $0.date > $1.date }
    }

    static func apply(
        category: AuditEvent.Category?,
        minesOnly: Bool,
        search: String,
        to events: [AuditEvent]
    ) -> [AuditEvent] {
        var filtered = events
        if let category { filtered = filtered.filter { $0.kind.category == category } }
        if minesOnly { filtered = filtered.filter(\.isYours) }

        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty { filtered = filtered.filter { $0.matches(query) } }

        return filtered.sorted { $0.at > $1.at }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            LedgerSearchField(text: $searchText, placeholder: "Search by name, amount or date")
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

            filters
                .padding(.bottom, 2)

            content
        }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .task { await audit.load(trip.id) }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audit trail")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(trip.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }

                Spacer(minLength: 8)

                CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                    .accessibilityLabel("Close")
            }

            summary
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    /// Three facts, and the third one is the point: the record cannot be
    /// edited. Saying so on the screen is what makes it worth pointing at.
    private var summary: some View {
        HStack(spacing: 0) {
            stat(all.count.formatted(), "recorded")
            divider
            stat(disputeCount.formatted(), disputeCount == 1 ? "dispute" : "disputes")
            divider
            stat(spanLabel, "covered")
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .panelSurface(corner: 18)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.10))
            .frame(width: 1, height: 26)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var disputeCount: Int {
        all.filter { $0.kind.category == .disputes }.count
    }

    private var spanLabel: String {
        guard let oldest = all.last?.at, let newest = all.first?.at else { return "—" }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: oldest),
            to: Calendar.current.startOfDay(for: newest)
        ).day ?? 0
        return days == 0 ? "1 day" : "\(days + 1) days"
    }

    // MARK: Filters

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                LedgerFilterChip(
                    label: "All",
                    count: Self.apply(category: nil, minesOnly: minesOnly, search: searchText, to: all).count,
                    isOn: category == nil
                ) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { category = nil }
                }

                // Empty categories are hidden rather than shown at zero. A
                // "Disputes 0" chip on a clean trip reads as though something
                // is wrong with it.
                ForEach(presentCategories) { option in
                    LedgerFilterChip(
                        label: option.label,
                        count: Self.apply(category: option, minesOnly: minesOnly, search: searchText, to: all).count,
                        isOn: category == option
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { category = option }
                    }
                }

                Rectangle()
                    .fill(AppTheme.cardStroke.opacity(0.12))
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 2)

                LedgerFilterChip(
                    label: "By you",
                    count: Self.apply(category: category, minesOnly: true, search: searchText, to: all).count,
                    isOn: minesOnly
                ) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { minesOnly.toggle() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var presentCategories: [AuditEvent.Category] {
        let present = Set(all.map { $0.kind.category })
        return AuditEvent.Category.allCases.filter { present.contains($0) }
    }

    // MARK: List

    /// The day whose label the fixed bar shows — whichever day's card has
    /// scrolled up to (or past) the top of the visible list, falling back to
    /// the first day before anything has been measured yet.
    private var topDay: AuditDay? {
        days.first { $0.id == topDayID } ?? days.first
    }

    @ViewBuilder
    private var content: some View {
        if visible.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                // Outside the `ScrollView`, not a pinned `Section` header —
                // a pinned header still slides during the handoff between
                // one day's header and the next's, and clips against
                // whatever card happens to be mid-scroll behind it. This
                // never moves and never overlaps anything, because it isn't
                // part of the same view that scrolls.
                if let topDay {
                    AuditDayHeader(day: topDay)
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22) {
                        ForEach(days) { day in
                            VStack(spacing: 0) {
                                ForEach(Array(day.events.enumerated()), id: \.element.id) { index, event in
                                    AuditRow(
                                        event: event,
                                        isExpanded: expanded.contains(event.id),
                                        isLast: index == day.events.count - 1
                                    ) {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                            if expanded.contains(event.id) {
                                                expanded.remove(event.id)
                                            } else {
                                                expanded.insert(event.id)
                                            }
                                        }
                                    }
                                }
                            }
                            // Square on top only while this is the day
                            // sitting under the fixed header — matched to
                            // its flat bottom edge so the two read as one
                            // surface. Every other day's card stays fully
                            // rounded; only the currently-attached one gives
                            // up its top corners.
                            .cardSurface(corner: 24, topCorner: day.id == (topDayID ?? days.first?.id) ? 0 : 24)
                            .padding(.horizontal, 20)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: AuditDayOffsetKey.self,
                                        value: [day.id: proxy.frame(in: .named(Self.scrollSpace)).minY]
                                    )
                                }
                            }
                        }

                        footnote
                    }
                }
                .coordinateSpace(name: Self.scrollSpace)
                .onPreferenceChange(AuditDayOffsetKey.self) { offsets in
                    // The lowest (most recently scrolled-to) day whose card
                    // has already reached the top edge — the same rule a
                    // pinned header uses, just computed by hand so the
                    // result can drive a view that sits still.
                    let passed = days.filter { (offsets[$0.id] ?? .infinity) <= 1 }
                    topDayID = passed.map(\.id).max() ?? days.first?.id
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private static let scrollSpace = "auditTrailScroll"

    private var footnote: some View {
        Text("Entries can't be edited or deleted, by anyone. A correction is a new entry.")
            .font(.system(size: 11.5))
            .foregroundStyle(AppTheme.inkTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            .padding(.top, 6)
            .padding(.bottom, 28)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 30)

            Image(systemName: audit.isLoading(trip.id) ? "clock.arrow.circlepath" : "text.magnifyingglass")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            Text(emptyTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(emptyLine)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyTitle: String {
        if audit.isLoading(trip.id) && all.isEmpty { return "Reading the record" }
        if all.isEmpty { return "Nothing recorded yet" }
        return "No matches"
    }

    private var emptyLine: String {
        if audit.isLoading(trip.id) && all.isEmpty { return "One moment." }
        if all.isEmpty {
            return "Every price, split, payment, dispute and settle-up from here on gets written down with a name and a timestamp."
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty { return "Nothing in the trail matches “\(query)”." }
        if minesOnly { return "None of these were recorded by you." }
        return "Nothing under \(category?.label ?? "this filter") yet."
    }
}

// MARK: - Day header

/// Reports where each day's card sits relative to the scroll view's own top
/// edge, so `AuditTrailSheet` can tell which one to show in the fixed bar
/// without a pinned `Section` header's sliding handoff between sections.
private struct AuditDayOffsetKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date: CGFloat], nextValue: () -> [Date: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// The fixed "which day is this" label — outside the scrolling list, so it
/// sits in exactly one place regardless of how far anything below it has
/// scrolled, sitting flush on top of whichever card is currently the top
/// one (that card gives up its own top corners to match — see `content`).
private struct AuditDayHeader: View {
    let day: AuditDay

    /// Rounded on top only, at the same radius as the card underneath, and
    /// flat along the bottom edge where the two meet — the pairing that
    /// makes them read as one surface with a header on it, rather than two
    /// shapes sitting apart.
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: .init(topLeading: 24, bottomLeading: 0, bottomTrailing: 0, topTrailing: 24),
            style: .continuous
        )
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(day.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(day.caption)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Solid, the same fill the card below it uses — not a glass
        // material. This is the card's own header, fixed rather than
        // pinned, so it never needs to slide or re-clip against anything.
        .background(AppTheme.card, in: shape)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Row

/// One entry, collapsed to its sentence and expandable to its evidence.
///
/// Collapsed shows what happened, who did it and when — enough to scroll past.
/// Expanded shows the field-level diff and the timestamp to the second, which
/// is what somebody reconciling against a bank statement actually needs and
/// what nobody needs on twenty rows at once.
private struct AuditRow: View {
    let event: AuditEvent
    let isExpanded: Bool
    let isLast: Bool
    let toggle: () -> Void

    /// Two lines of diff collapsed. Enough to see the number that moved
    /// without the row becoming a paragraph.
    private static let collapsedChanges = 2

    private var shownChanges: [AuditChange] {
        isExpanded ? event.changes : Array(event.changes.prefix(Self.collapsedChanges))
    }

    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 12) {
                rail

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(event.summary)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 4)

                        if let amount = event.amountLabel {
                            Text(amount)
                                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)
                                .monospacedDigit()
                        }
                    }

                    meta

                    if !shownChanges.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(shownChanges) { change in
                                changeLine(change)
                            }

                            if !isExpanded, event.changes.count > Self.collapsedChanges {
                                Text("+\(event.changes.count - Self.collapsedChanges) more")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(.top, 1)
                    }

                    if isExpanded { receipt }
                }
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .overlay(alignment: .bottom) {
            if !isLast { Hairline(inset: 52) }
        }
    }

    /// The glyph, and the thread running down through the entries under it —
    /// the thing that makes a list of edits read as a sequence of events.
    private var rail: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(event.kind.tint.opacity(0.14))
                    .frame(width: 30, height: 30)

                Image(systemName: event.kind.symbol)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(event.kind.tint)
            }

            if !isLast {
                Rectangle()
                    .fill(AppTheme.cardStroke.opacity(0.14))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
                    .padding(.top, 4)
            }
        }
        .frame(width: 30)
    }

    private var meta: some View {
        HStack(spacing: 5) {
            Text(event.actorLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(event.isYours ? AppTheme.accent : AppTheme.inkSecondary)

            Text("·")
                .foregroundStyle(AppTheme.inkTertiary)

            Text(isExpanded ? event.timestamp : "\(event.clock) · \(event.relative)")
                .font(.system(size: 11.5))
                .foregroundStyle(AppTheme.inkTertiary)
                .monospacedDigit()

            Text("·")
                .foregroundStyle(AppTheme.inkTertiary)

            Text(event.kind.label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            Spacer(minLength: 0)
        }
        .lineLimit(1)
    }

    private func changeLine(_ change: AuditChange) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(change.field)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(AppTheme.inkSecondary)

            Text(change.line)
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // A tint of the row's own stroke colour, not the card's own
            // fill — the row already sits on `AppTheme.card`, so a
            // translucent copy of that same colour disappeared into it
            // instead of reading as a distinct strip underneath the text.
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(AppTheme.cardStroke.opacity(0.07))
        }
    }

    /// The part that only matters when somebody is actually checking: what it
    /// was about, and the entry's own identifier, so two people looking at two
    /// phones can be certain they're discussing the same record.
    private var receipt: some View {
        VStack(alignment: .leading, spacing: 3) {
            if !event.subject.isEmpty {
                Text("On \(event.subject)")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }

            Text("Entry \(event.id.uuidString.prefix(8).lowercased()) · recorded by \(event.actorName)")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(AppTheme.inkTertiary)
                .textSelection(.enabled)
        }
        .padding(.top, 3)
    }
}
