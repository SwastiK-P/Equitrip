//
//  LeaveTripSheet.swift
//  Equitrip
//

import SwiftUI

/// Leaving a trip that's already running.
///
/// The whole sheet is one argument: here is every booking you're carrying,
/// here is what happens to each of them, here is the single number that comes
/// out the other end, and here is what it does to everybody else. Nothing is
/// committed until somebody on the other side agrees — the button says
/// "Ask to leave", not "Leave", because that's what it does.
///
/// It's a review before it's a form. The one input that matters is the date,
/// and it sits at the top because moving it re-sorts every line underneath
/// between "already happened" and "hasn't yet". Everything else on screen is
/// the consequence of that one field, recomputed live.
struct LeaveTripSheet: View {
    @Environment(\.tripStore) private var store
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let traveller: Traveller

    @State private var plan: DeparturePlan
    @State private var appeared = false
    @State private var showConfirm = false

    init(trip: Trip, traveller: Traveller) {
        self.trip = trip
        self.traveller = traveller
        _plan = State(initialValue: DeparturePlan(trip: trip, traveller: traveller))
    }

    private var currency: String { trip.currencyCode }
    private var isSelf: Bool { traveller.id == Traveller.you.id }
    private var subject: String { isSelf ? "You" : traveller.name }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let block = plan.block {
                blocked(block)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dateCard.staggered(0, appeared)
                        outcome.staggered(1, appeared)

                        if plan.affectsOthers {
                            impact.staggered(2, appeared)
                        }

                        bookings.staggered(3, appeared)

                        if !plan.paidForOthers.isEmpty {
                            owedBack.staggered(4, appeared)
                        }

                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                footer
            }
        }
        .onAppear { withAnimation { appeared = true } }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
        .alert("Ask to leave \(trip.title)?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Ask to leave") { propose() }
        } message: {
            Text(confirmMessage)
        }
    }

    private var confirmMessage: String {
        let who = trip.organisers.filter { $0.id != traveller.id && !trip.hasLeft($0.id) }
        let names = who.map(\.name).joined(separator: " or ")
        let reviewer = names.isEmpty ? "the group" : names

        return "Nothing changes until \(reviewer) confirms it. Your share of everything up to \(dayLabel) stays exactly as it is."
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isSelf ? "Leave this trip" : "Take \(traveller.name) off")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(trip.title)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    // MARK: - Date

    private var dayLabel: String {
        if let day = plan.previewTrip.departureDayIndex(traveller.id) { return "day \(day)" }
        return DateFormatter.cached("d MMM").string(from: plan.leftAt)
    }

    /// The one thing being decided, and the thing every figure below hangs
    /// off. Bounded by the trip's own dates — leaving before it starts is a
    /// cancellation, and leaving after it ends is nothing at all.
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LAST DAY ON THE TRIP")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            DatePicker(
                "",
                selection: Binding(
                    get: { plan.leftAt },
                    set: { day in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            plan.setLeftAt(day)
                        }
                    }
                ),
                in: trip.startDate...trip.endDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Text("Everything on or before this day stays \(isSelf ? "yours" : "theirs"). Nothing after it does, unless it's already been paid for.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface(corner: 22)
    }

    // MARK: - Outcome

    /// The number the sheet exists to produce.
    private var outcome: some View {
        let balance = plan.finalBalance
        let settled = plan.isClean

        return VStack(alignment: .leading, spacing: 0) {
            Text(settled ? "NOTHING OUTSTANDING" : (balance > 0 ? "THE GROUP OWES \(subject.uppercased())" : "\(subject.uppercased()) STILL \(isSelf ? "OWE" : "OWES")"))
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(Money.format(abs(balance).rounded(), code: currency))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(settled ? AppTheme.ink : (balance > 0 ? AppTheme.moneyIn : AppTheme.moneyOut))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: balance)
                .padding(.top, 2)

            Text(settled
                 ? "Everything is square. Leaving costs nothing either way."
                 : "After leaving on \(dayLabel), settled up from the Settle tab as usual.")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)

            Hairline().padding(.vertical, 14)

            HStack(spacing: 9) {
                tile(
                    label: "Still carrying",
                    value: plan.carriedTotal,
                    symbol: "lock.fill",
                    tint: AppTheme.inkSecondary
                )
                tile(
                    label: "Not charged",
                    value: plan.droppedTotal,
                    symbol: "minus.circle",
                    tint: AppTheme.positive
                )
            }
        }
        .padding(18)
        .cardSurface(corner: 26, shadow: 14)
    }

    private func tile(label: String, value: Double, symbol: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.13), in: .circle)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                Text(Money.format(value.rounded(), code: currency))
                    .font(.system(size: 16.5, weight: .bold, design: .rounded))
                    .foregroundStyle(value > 0 ? AppTheme.ink : AppTheme.inkTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.canvasBottom.opacity(0.45), in: .rect(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Impact on everyone else

    /// The warning that makes "no extra charge to anyone" checkable rather
    /// than a promise.
    ///
    /// It only appears when somebody else's share actually moves, which
    /// happens for exactly one reason: a cost that doesn't shrink with the
    /// headcount — a villa, a hired car — being divided across fewer people.
    /// A per-head cost drops out with the person and this card never shows.
    private var impact: some View {
        let each = plan.groupImpactEach
        let others = trip.activeTravellers.filter { $0.id != traveller.id }

        return HStack(alignment: .top, spacing: 12) {
            SymbolBadge(
                symbol: each > 0 ? "exclamationmark.triangle.fill" : "arrow.down.circle.fill",
                tint: each > 0 ? Palette.amber : AppTheme.positive,
                size: 32
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(each > 0
                     ? "This adds \(Money.format(abs(each).rounded(), code: currency)) each for the others"
                     : "This takes \(Money.format(abs(each).rounded(), code: currency)) off everyone else")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(each > 0
                     ? "Some bookings cost the same whoever turns up, so \(others.count.pluralised("person", "people")) split them instead of \(others.count + 1). Switch those back on below if that's not what you want."
                     : "Bookings that cost less with one fewer person have come down in price.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (each > 0 ? Palette.amber : AppTheme.positive).opacity(0.1),
            in: .rect(cornerRadius: 20, style: .continuous)
        )
    }

    // MARK: - Bookings

    /// Every booking, in two groups, in the order they happen.
    ///
    /// Grouped by outcome rather than by date because the question people
    /// actually have is "what am I still paying for", not "what happened on
    /// Tuesday" — and the two groups are the answer to it and its opposite.
    private var bookings: some View {
        let lines = plan.lines
        let carried = lines.filter(\.isBorne)
        let dropped = lines.filter { !$0.isBorne }

        return VStack(alignment: .leading, spacing: 14) {
            if lines.isEmpty {
                Text("\(subject) \(isSelf ? "aren't" : "isn't") on any priced booking, so there's nothing to work out.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface(corner: 22)
            }

            if !carried.isEmpty {
                group(
                    title: isSelf ? "You still pay for" : "\(traveller.name) still pays for",
                    caption: Money.format(plan.carriedTotal.rounded(), code: currency),
                    lines: carried
                )
            }

            if !dropped.isEmpty {
                group(
                    title: "Not charged",
                    caption: Money.format(plan.droppedTotal.rounded(), code: currency),
                    lines: dropped
                )
            }
        }
    }

    private func group(title: String, caption: String, lines: [DeparturePlan.Line]) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionHeader(title: title, caption: caption)

            VStack(spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                    DepartureLineRow(
                        line: line,
                        currency: currency,
                        onToggle: line.isChoosable ? { toggle(line) } : nil
                    )

                    if index < lines.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 24)
        }
    }

    private func toggle(_ line: DeparturePlan.Line) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            // Only ever between the two answers that are actually available.
            // `.consumed` isn't one of them — a booking that already happened
            // has no switch, and `isChoosable` has already excluded it — so
            // switching a line back on always means `.keeps`, whether the
            // reason is "it's already paid for" or "I'll still chip in".
            plan.dispositions[line.item.id] = line.isBorne ? .dropped : .keeps
        }
    }

    // MARK: - Money owed back

    /// The half people forget. Leaving usually means owing; sometimes it means
    /// being owed, and a person walking away from bookings they paid for
    /// should see that before they walk.
    private var owedBack: some View {
        let total = plan.paidForOthers.reduce(0) { $0 + $1.cost }

        return HStack(alignment: .top, spacing: 12) {
            SymbolBadge(symbol: "creditcard.fill", tint: AppTheme.moneyIn, size: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(subject) paid for \(plan.paidForOthers.count.pluralised("booking"))")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)

                Text("\(Money.format(total.rounded(), code: currency)) went out of \(isSelf ? "your" : "their") account for the group. Leaving doesn't write that off — it's in the figure above.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.moneyIn.opacity(0.1), in: .rect(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Blocked

    /// The two states where leaving isn't a thing the app can let happen, each
    /// with the one action that unblocks it.
    private func blocked(_ block: DeparturePlan.Block) -> some View {
        VStack(spacing: 13) {
            IconTile(symbol: "exclamationmark.triangle.fill", tint: Palette.amber, size: 54, corner: 18)

            Text(block.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(block.detail)
                .font(.system(size: 13.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button("Close") { dismiss() }
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 4)
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: isSelf ? "Ask to leave" : "Propose this",
                systemImage: "arrow.right"
            ) {
                showConfirm = true
            }

            Text("Nothing changes until somebody else confirms it.")
                .font(.system(size: 11.5))
                .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(.ultraThinMaterial)
    }

    private func propose() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        store.proposeDeparture(plan)
        dismiss()
    }
}

// MARK: - One booking

/// A booking and what happens to it, with the switch where there's a choice.
///
/// The switch is a tap on the whole row rather than a control off to one side:
/// there are only two positions, the row already says which one it's in, and a
/// list of toggles reads as a settings screen rather than as a decision.
private struct DepartureLineRow: View {
    let line: DeparturePlan.Line
    let currency: String
    /// Nil for a booking that already happened — nothing to decide.
    var onToggle: (() -> Void)?

    private var item: ItineraryItem { line.item }

    var body: some View {
        Button {
            onToggle?()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)
                    .opacity(line.isBorne ? 1 : 0.45)
                    .saturation(line.isBorne ? 1 : 0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title.isEmpty ? item.kind.label : item.title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)

                    HStack(spacing: 5) {
                        Image(systemName: line.disposition.symbol)
                            .font(.system(size: 9, weight: .bold))
                        Text(line.reason)
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundStyle(line.disposition.tint)

                    Text(DateFormatter.cached("EEE d MMM").string(from: item.date))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.inkTertiary)

                    // Only when it costs someone else something. A row that
                    // says "+₹0 for everyone else" is noise on every booking
                    // that behaves normally.
                    if !line.isBorne, line.othersDelta > 0 {
                        Text("+\(Money.format(line.othersDelta.rounded(), code: currency)) each for the others")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Palette.amber)
                            .padding(.top, 1)
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(Money.format(line.amount.rounded(), code: currency))
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundStyle(line.isBorne ? AppTheme.ink : AppTheme.inkTertiary)
                        .strikethrough(!line.isBorne, color: AppTheme.inkTertiary)
                        .lineLimit(1)

                    if onToggle != nil {
                        Text(line.isBorne ? "Charged" : "Dropped")
                            .font(.system(size: 9.5, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(line.isBorne ? AppTheme.inkSecondary : AppTheme.positive)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                (line.isBorne ? AppTheme.cardStroke.opacity(0.1) : AppTheme.positive.opacity(0.14)),
                                in: .capsule
                            )
                    }
                }
                .fixedSize()
            }
            .padding(14)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(onToggle == nil)
    }
}
