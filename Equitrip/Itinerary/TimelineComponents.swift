//
//  TimelineComponents.swift
//  Equitrip
//

import SwiftUI

// MARK: - Day header

/// Pins to the top as its day scrolls past, so you always know which day
/// you're looking at. Glass, because it's chrome floating over content.
struct DayHeader: View {
    let day: TripDay
    /// Nil leaves the header static — used wherever a day is shown without a
    /// list under it to fold, so there's nothing to open or close.
    var isCollapsed: Bool = false
    var onToggle: (() -> Void)?

    var body: some View {
        Button {
            guard let onToggle else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onToggle()
        } label: {
            HStack(spacing: 9) {
                Text(day.title)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(day.subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)

                if day.isToday {
                    Text("TODAY")
                        .font(.system(size: 9.5, weight: .bold))
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.accent, in: .capsule)
                }

                Spacer(minLength: 0)

                // Points down while the day is open, right once it's closed —
                // the same disclosure convention as a folder, so it reads
                // without needing a label of its own.
                if onToggle != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(onToggle == nil)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

// MARK: - Departure marker

/// "Ravi left the trip", on the day it happened.
///
/// Deliberately the smallest thing that can carry the fact. A departure
/// changes what everybody owes, so it has to be visible — but it happens once
/// on a screen whose entire job is the bookings, and a card or a banner would
/// give a one-off event permanent weight it hasn't earned. So: one line, in
/// the rail's own gutter geometry, reading as a note on the timeline rather
/// than an entry in it. The detail lives in the Ledger, one tap away.
struct DepartureMarker: View {
    let travellers: [Traveller]
    /// Whether this is the very last thing on the timeline, in which case the
    /// rail stops here rather than carrying on to nothing.
    var isLast: Bool = false

    private var names: String {
        switch travellers.count {
        case 0: return ""
        case 1: return travellers[0].id == Traveller.you.id ? "You" : travellers[0].name
        case 2: return "\(travellers[0].name) and \(travellers[1].name)"
        default: return "\(travellers[0].name) and \(travellers.count - 1) others"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Matches `TimelineRow`'s clock gutter so the line starts where
            // every booking's card starts.
            Color.clear.frame(width: 42)

            VStack(spacing: 0) {
                Image(systemName: "arrow.right.to.line")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 14, height: 14)
                    .background(AppTheme.canvasTop, in: .circle)

                if !isLast {
                    Rectangle()
                        .fill(AppTheme.cardStroke.opacity(0.14))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 34)

            HStack(spacing: 7) {
                AvatarStack(
                    travellers: travellers,
                    size: 18,
                    max: 3,
                    departedIDs: Set(travellers.map(\.id))
                )

                Text("\(names) left the trip")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Timeline row

/// One booking on the rail: the clock in the gutter, a dot on the line, and
/// the card itself.
struct TimelineRow: View {
    let item: ItineraryItem
    let trip: Trip
    var isLast: Bool = false
    /// The last booking of its day, distinct from `isLast` — that one hides
    /// the rail outright at the very end of the whole timeline; this one is
    /// every day's last row, where the thread should read as closed rather
    /// than simply cut off before the next day's header.
    var closesDay: Bool = false

    /// Who the footer's faces are — the people the split actually lands the
    /// cost on, not just whoever was tagged when the booking was made.
    ///
    /// `Trip.participants(of:)` answers a different question: it's the raw
    /// tag list, which is what you edit from the picker and what stays frozen
    /// at whoever was on the trip the day the booking was added. For an equal
    /// split that's every current traveller regardless of the tag list — see
    /// `Trip.bearers(of:)` — so a booking made before somebody joined showed
    /// their avatar nowhere near it even after they'd paid for it. `bearers`
    /// is the set the "₹400 each" figure next to these faces is actually
    /// computed across, so it's the set that belongs here.
    private var participants: [Traveller] { trip.bearers(of: item) }

    /// Whether this was logged after the trip had already started, rather
    /// than planned ahead of time with the rest of the itinerary — a booking
    /// added mid-trip has no plan behind it, so the card says so instead of
    /// looking identical to one the group agreed on weeks earlier.
    private var isUnplanned: Bool { item.createdAt >= trip.startDate }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            clock
            rail
            card
        }
        .padding(.horizontal, 20)
    }

    // MARK: Gutter

    private var clock: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let clock = item.clock {
                Text(clock.value)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                Text(clock.meridiem)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                Text("All\nday")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(width: 42, alignment: .trailing)
        .padding(.top, 2)
    }

    private var rail: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(item.kind.tint)
                .frame(width: 10, height: 10)
                .overlay {
                    Circle().strokeBorder(AppTheme.canvasTop, lineWidth: 2.5)
                }
                .padding(.top, 5)

            if isLast {
                // The very end of the timeline — nothing follows, so the rail
                // simply stops.
                Color.clear
            } else if closesDay {
                dayCloser
            } else {
                // Runs the full height of the row so consecutive items read as
                // one continuous line rather than a column of dashes.
                Rectangle()
                    .fill(AppTheme.cardStroke.opacity(0.14))
                    .frame(width: 1.5)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 34)
    }

    /// Where a day's thread ends: a long taper rather than the line running
    /// the full row height and then just not being there for the next one.
    /// The next thing on screen is a new day's header, not another booking,
    /// and the rail reading as finished says that before the header does.
    private var dayCloser: some View {
        LinearGradient(
            colors: [AppTheme.cardStroke.opacity(0.14), AppTheme.cardStroke.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: 1.5)
        .frame(maxHeight: .infinity)
    }

    // MARK: Card

    // Stays used to carry a photograph here. It was searched from the hotel's
    // name, which returns whatever stock the provider has for that string
    // rather than the building the group is checking into — a picture of a
    // street in Montmartre above a booking at a different hotel entirely. It
    // also pushed the title, the price and who's on it down past the fold.
    @ViewBuilder
    private var card: some View {
        if let flight = item.flight, flight.isResolved {
            // A tracked flight has enough of its own structure to earn the
            // ticket treatment; an untracked one is just another booking.
            VStack(alignment: .leading, spacing: 10) {
                FlightTicketCard(flight: flight, fallbackDeparture: item.time, showsStatus: false)
                footer
            }
            .padding(.bottom, 14)
        } else {
            plainCard
        }
    }

    private var plainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            footer.padding(.top, 12)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(corner: 20, dashed: isUnplanned)
        .padding(.bottom, 14)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 11) {
            SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                if let vendor = item.vendorName {
                    Text(vendor)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }

                if let flight = item.flight, !flight.isResolved {
                    flightLine(flight)
                }
            }

            Spacer(minLength: 6)

            if item.cost > 0 {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(Money.format(item.cost, code: trip.currencyCode))
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("total")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .fixedSize()
            }
        }
    }

    /// The route when a lookup resolved one, otherwise just the number —
    /// either way, more useful on a timeline than the bare title alone.
    private func flightLine(_ flight: FlightDetails) -> some View {
        HStack(spacing: 5) {
            if let status = flight.status, flight.isResolved {
                Circle().fill(status.tint).frame(width: 5, height: 5)
            }

            Group {
                if let departure = flight.departureAirport, let arrival = flight.arrivalAirport {
                    Text("\(FlightLookupService.display(flight.number)) · \(departure) → \(arrival)")
                } else {
                    Text(FlightLookupService.display(flight.number))
                }
            }
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(flight.isResolved ? (flight.status?.tint ?? AppTheme.inkSecondary) : AppTheme.inkTertiary)
        }
        .lineLimit(1)
    }

    /// Who's on it, who paid, and what it works out to each — the three facts
    /// that decide what this booking does to anyone's balance.
    private var footer: some View {
        HStack(spacing: 8) {
            AvatarStack(travellers: participants, size: 24, max: 4, departedIDs: trip.departedIDs)

            if let payer = item.paidByID.flatMap(trip.traveller) {
                Text("\(payer.id == Traveller.you.id ? "You" : payer.name) paid")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                Image(systemName: item.split.symbol)
                    .font(.system(size: 9, weight: .bold))
                Text(splitLabel)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppTheme.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(AppTheme.cardStroke.opacity(0.06), in: .capsule)
        }
    }

    private var splitLabel: String {
        guard item.cost > 0 else { return item.split.label }

        // One booking is charged to one person under both of these, so "each"
        // would be a division by one dressed up as a split.
        switch item.split {
        case .organiser, .individual:
            return item.split.label
        default:
            let heads = trip.shares(of: item).count
            guard heads > 0 else { return item.split.label }
            let each = Money.wholeShare(of: item.cost, heads: heads)
            return "\(Money.format(each, code: trip.currencyCode)) each"
        }
    }
}
