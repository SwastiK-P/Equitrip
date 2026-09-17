//
//  HomeCards.swift
//  Equitrip
//

import SwiftUI

// MARK: - Current trip card

/// The one trip Home leads with.
///
/// It used to be three stacked bands — a photo strip, a progress row and a
/// balance row — separated by hairlines, which made the most personal thing
/// on Home look like a settings table with a picture on top. The photograph
/// is the whole card now: the trip's name sits on it in the display face, and
/// the two numbers that matter (how far in, where you stand) share one glass
/// panel along its foot, so the card reads as a place first and a ledger
/// second without dropping anything it used to say.
///
/// A progressive blur rather than a flat gradient under the type, because
/// half of these covers are skies and a gradient left the trip's own name the
/// least legible text on the card.
struct CurrentTripCard: View {
    @Environment(\.tripStore) private var store
    @Environment(\.pane) private var pane
    let trip: Trip

    private let corner: CGFloat = 28

    var body: some View {
        DestinationImage(
            query: trip.destination,
            photo: trip.cover,
            fallbackSymbol: trip.symbol,
            fallbackTint: trip.tint,
            onResolve: { store.setCover($0, for: trip.id) }
        )
        // Taller as the card widens, so a wide column doesn't letterbox the
        // one thing on the card that says which trip it is.
        .frame(height: pane.scaled(300, wide: 340, regular: 360))
        .frame(maxWidth: .infinity)
        .overlay { ProgressiveBlur(edge: .bottom, begins: 0.34, scrim: 0.55) }
        .overlay(alignment: .top) { topRow }
        .overlay(alignment: .bottom) { foot }
        .clipShape(.rect(cornerRadius: corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 18, y: 8)
    }

    // MARK: Top

    /// Who's going, up where a glance lands first. The phase only shows for a
    /// trip that isn't running — a live one already sits under "Happening
    /// now", and a second "In progress" here was repeating it.
    private var topRow: some View {
        HStack {
            if trip.phase != .live { phaseChip }
            Spacer(minLength: 8)
            AvatarStack(travellers: trip.travellers, size: 28, max: 4, departedIDs: trip.departedIDs)
        }
        .padding(14)
    }

    private var phaseChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(trip.phase.tint)
                .frame(width: 5, height: 5)

            Text(trip.phase.label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(.black.opacity(0.2)), in: .capsule)
    }

    // MARK: Foot

    private var foot: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(trip.title)
                    .font(AppTheme.display(30))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("\(trip.dateRange) · \(trip.bookingCount.pluralised("booking")) · \(trip.projectedLabel)")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
            .shadow(color: .black.opacity(0.25), radius: 8, y: 1)
            .padding(.horizontal, 6)

            panel
        }
        .padding(10)
    }

    /// How far in on the left, where you stand on the right — the reason to
    /// open the app at all, so it gets the largest figure on the card.
    private var panel: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 9) {
                Text(trip.progressLabel)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                ProgressTrack(
                    value: trip.progress,
                    tint: .white,
                    cells: trip.dayCount,
                    empty: .white.opacity(0.22)
                )
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(width: 1, height: 34)

            // Before the trip starts there is no balance to report — see
            // `Trip.showsBalance`. What it'll cost you is the figure that
            // means something at that point.
            VStack(alignment: .trailing, spacing: 2) {
                Text(trip.showsBalance ? trip.netLabel : Money.format(trip.yourShare, code: trip.currencyCode))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    // Direction survives on dark glass as a dot; the brand
                    // indigo as a text colour didn't.
                    if trip.showsBalance {
                        Circle()
                            .fill(trip.netTone)
                            .frame(width: 5, height: 5)
                    }
                    Text(trip.showsBalance ? trip.netCaption : "your share")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .lineLimit(1)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular.tint(.black.opacity(0.22)), in: .rect(cornerRadius: corner - 10, style: .continuous))
    }
}

/// The affordance that stops an empty or short trip list from being a dead end.
struct NewTripCard: View {
    @Environment(\.pane) private var pane
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 52, height: 52)
                    .contentShape(.circle)
                    // See `quickActions` — interactive glass inside a button
                    // eats the button's tap.
                    .glassEffect(.regular, in: .circle)

                VStack(spacing: 2) {
                    Text("New trip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Import a PDF or\nadd it yourself")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            // A fixed 164pt on a phone, where it sits beside nothing and
            // shouldn't stretch to the full margin; the width of its column on
            // iPad, where a small dashed box floating in a wide empty lane
            // reads as a rendering fault rather than as an invitation.
            .frame(maxWidth: pane.isRegular ? .infinity : 164)
            .frame(maxHeight: .infinity)
            .padding(.vertical, pane.isRegular ? 34 : 24)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        AppTheme.cardStroke.opacity(0.16),
                        style: StrokeStyle(lineWidth: 1.5, dash: [7, 6])
                    )
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Segmented progress: equal-width capsules rather than one continuous fill.
///
/// One cell per day of the trip, so the bar and the "Day 2 of 5" label above
/// it are visibly counting the same thing — a continuous fill made you
/// estimate the same number the label states exactly. Kept local because the
/// only other bar in the app (the hero split) is a two-tone variant of a
/// different thing.
struct ProgressTrack: View {
    let value: Double
    let tint: Color
    /// Days on the trip. `dayCount` is already at least 1, but this clamps
    /// anyway rather than trusting a caller not to hand over an empty range.
    let cells: Int
    /// The unlit cells. Brown-on-canvas by default; a track on a photograph
    /// passes something light instead, or the empty days vanish.
    var empty: Color = AppTheme.cardStroke.opacity(0.08)

    private var count: Int { max(1, cells) }

    /// Rounded up: any progress at all lights the first cell, because a bar
    /// showing nothing on a trip that has started reads as broken.
    private var filled: Int {
        let clamped = min(1, max(0, value))
        guard clamped > 0 else { return 0 }
        return min(count, max(1, Int((Double(count) * clamped).rounded(.up))))
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index < filled ? tint : empty)
                    // Equal share of the row each, so the cells stay identical
                    // at any card width without measuring anything.
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: filled)
    }
}

// MARK: - Itinerary row

struct ItineraryRow: View {
    let item: ItineraryItem
    let trip: Trip?

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                if let clock = item.clock {
                    Text(clock.value)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text(clock.meridiem)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                } else {
                    Text("All\nday")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .fixedSize()
            .frame(width: 44)

            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
            .lineLimit(1)
            .layoutPriority(1)

            Spacer(minLength: 4)

            if let trip {
                // Who the cost actually lands on — see the note on the same
                // switch in `TimelineRow` — not just whoever was tagged when
                // the booking was made.
                AvatarStack(travellers: trip.bearers(of: item), size: 22, max: 3, departedIDs: trip.departedIDs)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// Vendor when there is one, otherwise how the cost is being shared —
    /// which is the next most useful thing to know about a booking.
    private var subtitle: String {
        let money = item.cost > 0 && trip != nil
            ? Money.format(item.cost, code: trip!.currencyCode)
            : nil

        let lead = item.vendor.isEmpty ? item.split.label : item.vendor
        guard let money else { return lead }
        return "\(lead) · \(money)"
    }
}

// MARK: - Activity row

struct ActivityRow: View {
    let item: AppNotification

    var body: some View {
        HStack(spacing: 12) {
            SymbolBadge(symbol: item.kind.symbol, tint: item.kind.tint, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 13.5, weight: item.isUnread ? .semibold : .regular))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.body.isEmpty ? item.time : "\(item.body) · \(item.time)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            if item.isUnread {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

// MARK: - Pending settlements

/// The card the brief calls "pops up at the top": somebody says they paid
/// you, and it's the first thing to see after your own name — ahead of the
/// balance it's about to change, because it's the one thing on this screen
/// that's actually asking you something.
struct PendingSettlementsCard: View {
    let entries: [(trip: Trip, settlement: Settlement)]
    var onOpen: (Settlement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 6) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.accent)

                Text(entries.count == 1 ? "Someone paid you" : "\(entries.count) payments to confirm")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.settlement.id) { index, entry in
                    Button { onOpen(entry.settlement) } label: {
                        row(entry)
                    }
                    .buttonStyle(PressableButtonStyle())

                    if index < entries.count - 1 { Hairline(inset: 16) }
                }
            }
            .cardSurface(corner: 20)
        }
    }

    private func row(_ entry: (trip: Trip, settlement: Settlement)) -> some View {
        let payer = entry.trip.traveller(entry.settlement.fromID)

        return HStack(spacing: 12) {
            if let payer {
                TravellerAvatar(traveller: payer, size: 38)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(payer?.name ?? "Someone") paid you \(Money.format(entry.settlement.amount, code: entry.settlement.currencyCode))")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(entry.trip.title) · \(entry.settlement.method.label)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text("Review")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(AppTheme.ctaLabel)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(AppTheme.cta, in: .capsule)
        }
        .padding(13)
    }
}

#Preview("Light") {
    RootTabView(userName: "Swastik Patil")
}

#Preview("Dark") {
    RootTabView(userName: "Swastik Patil")
        .preferredColorScheme(.dark)
}
