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

    var body: some View {
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

// MARK: - Timeline row

/// One booking on the rail: the clock in the gutter, a dot on the line, and
/// the card itself.
struct TimelineRow: View {
    let item: ItineraryItem
    let trip: Trip
    var isLast: Bool = false

    private var participants: [Traveller] { trip.participants(of: item) }

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

            // Runs the full height of the row so consecutive items read as one
            // continuous line rather than a column of dashes.
            Rectangle()
                .fill(AppTheme.cardStroke.opacity(0.14))
                .frame(width: 1.5)
                .frame(maxHeight: .infinity)
                .opacity(isLast ? 0 : 1)
        }
        .frame(width: 34)
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
        .cardSurface(corner: 20)
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

                if !item.vendor.isEmpty {
                    Text(item.vendor)
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
            AvatarStack(travellers: participants, size: 24, max: 4)

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
            guard let each = trip.shares(of: item).first?.amount else { return item.split.label }
            return "\(Money.format(each, code: trip.currencyCode)) each"
        }
    }
}
