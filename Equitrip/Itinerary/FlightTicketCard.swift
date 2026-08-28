//
//  FlightTicketCard.swift
//  Equitrip
//

import SwiftUI

/// A flight, drawn as the thing it is: a ticket.
///
/// The route reads left-to-right across a dashed path, the way it does on a
/// boarding pass, and the stub below the notch carries the two facts you
/// actually stand up for — which terminal, and how long you've got.
struct FlightTicketCard: View {
    let flight: FlightDetails
    /// Falls back to the booking's own time when the airline gave us none.
    var fallbackDeparture: Date?
    /// The timeline shows the ticket for its shape, not as a live board —
    /// a status that was true when the lookup ran goes stale sitting in a
    /// plan, so only the editor (where you just refreshed it) shows one.
    var showsStatus: Bool = true

    private var status: FlightDetails.Status { flight.status ?? .unknown }

    var body: some View {
        VStack(spacing: 0) {
            main
            perforation
            stub
        }
        .background(AppTheme.card, in: TicketShape())
        .overlay {
            TicketShape().stroke(AppTheme.cardStroke.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 10, y: 4)
    }

    // MARK: - Main

    private var main: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                SymbolBadge(symbol: "airplane", tint: ItineraryKind.flight.tint, size: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(FlightLookupService.display(flight.number))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(flight.displayAirline)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if showsStatus { statusChip }
            }

            route
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 16)
    }

    private var statusChip: some View {
        Text(statusLabel.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(status.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(status.tint.opacity(0.14), in: .capsule)
            .fixedSize()
    }

    /// "On time" is worth saying out loud; a delay is worth quantifying.
    private var statusLabel: String {
        if let delay = flight.departureDelay, delay > 0 {
            return "\(delay)m late"
        }
        if status == .scheduled || status == .active {
            return "On time"
        }
        return status.label
    }

    // MARK: - Route

    private var route: some View {
        HStack(alignment: .top, spacing: 10) {
            endpoint(
                code: flight.departureAirport,
                place: flight.departureCity ?? flight.departureAirportName,
                time: flight.scheduledDeparture ?? fallbackDeparture,
                alignment: .leading
            )

            path
                .padding(.top, 8)

            endpoint(
                code: flight.arrivalAirport,
                place: flight.arrivalCity ?? flight.arrivalAirportName,
                time: flight.scheduledArrival,
                alignment: .trailing
            )
        }
    }

    private var path: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppTheme.inkTertiary.opacity(0.5))
                .frame(width: 5, height: 5)

            Line()
                .stroke(
                    AppTheme.inkTertiary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
                .frame(height: 1)
                .overlay {
                    Image(systemName: "airplane")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ItineraryKind.flight.tint)
                        .background(AppTheme.card)
                }

            Circle()
                .fill(AppTheme.inkTertiary.opacity(0.5))
                .frame(width: 5, height: 5)
        }
        .frame(minWidth: 54)
    }

    private func endpoint(
        code: String?,
        place: String?,
        time: Date?,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(code ?? "—")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(subtitle(place: place, time: time))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .lineLimit(1)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func subtitle(place: String?, time: Date?) -> String {
        let clock = time.map { DateFormatter.cached("h:mm a").string(from: $0) }
        return [place, clock].compactMap { $0 }.joined(separator: " · ")
    }

    // MARK: - Stub

    private var perforation: some View {
        Line()
            .stroke(
                AppTheme.cardStroke.opacity(0.16),
                style: StrokeStyle(lineWidth: 1, dash: [5, 4])
            )
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private var stub: some View {
        HStack(spacing: 0) {
            stubCell(label: "Terminal", value: flight.departureTerminal ?? "—")

            if let gate = flight.departureGate, !gate.isEmpty {
                stubCell(label: "Gate", value: gate)
            }

            stubCell(
                label: "Departs in",
                value: flight.departsIn(from: Date()) ?? relativeDay
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    /// When the countdown is too far out to be useful, say which day instead.
    private var relativeDay: String {
        guard let departure = flight.scheduledDeparture ?? fallbackDeparture else { return "—" }
        if departure < Date() { return "Departed" }
        return DateFormatter.cached("d MMM").string(from: departure)
    }

    private func stubCell(label: String, value: String) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)

            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(AppTheme.cardStroke.opacity(0.07), in: .capsule)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Shapes

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A rounded rectangle with a bite taken out of each side, where a real ticket
/// would be torn. The notch sits on the perforation line.
private struct TicketShape: Shape {
    var corner: CGFloat = 20
    var notchRadius: CGFloat = 9
    /// Distance from the bottom to the tear — matches the stub's height.
    var stubHeight: CGFloat = 46

    func path(in rect: CGRect) -> Path {
        let notchY = rect.maxY - stubHeight
        var path = Path(roundedRect: rect, cornerRadius: corner, style: .continuous)

        for centre in [CGPoint(x: rect.minX, y: notchY), CGPoint(x: rect.maxX, y: notchY)] {
            path = path.subtracting(
                Path(ellipseIn: CGRect(
                    x: centre.x - notchRadius,
                    y: centre.y - notchRadius,
                    width: notchRadius * 2,
                    height: notchRadius * 2
                ))
            )
        }

        return path
    }
}
