//
//  TrainTicketCard.swift
//  Equitrip
//

import SwiftUI

/// A train booking as a compact ticket: the train, the two stations on a
/// stretch of track, and whether the group's seats are confirmed.
///
/// Not `FlightTicketCard`'s notched stub: squeezed into it, long station names
/// and berths became "Hazrat Nizamuddin…" and "C3-…". Names wrap here instead.
/// Each passenger's coach and berth, and the live position, only show on the
/// detail screen; on the timeline they made one booking taller than a day.
struct TrainTicketCard: View {
    let train: TrainDetails
    var fallbackDeparture: Date?
    /// The timeline's form. A live position read when the lookup ran goes
    /// stale sitting in a plan, so only the detail screen shows it.
    var compact: Bool = false

    private let tint = ItineraryKind.train.tint

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            divider
            journey
            // Seats are the detail screen's business: on the timeline they
            // made one booking taller than a whole day's worth of others.
            if !compact {
                divider
                passengers
                if let live = train.live {
                    divider
                    liveStrip(live)
                }
            }
        }
        .background(AppTheme.card, in: .rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.cardStroke.opacity(0.06), lineWidth: 1)
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 10, y: 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            SymbolBadge(symbol: "tram.fill", tint: tint, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(train.displayName)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(headerLine)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            chip(train.overallStanding.label, tint: train.overallStanding.tint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// Train number, PNR and day on one line.
    private var headerLine: String {
        var parts = [train.trainNumber, "PNR \(TrainDetails.displayPNR(train.pnr))"].compactMap { $0 }
        if let date = departureDate {
            var when = DateFormatter.cached("EEE d MMM").string(from: date)
            if let time = fallbackDeparture { when += ", " + DateFormatter.cached("h:mm a").string(from: time) }
            parts.append(when)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Journey

    private var departureDate: Date? { train.journeyDate ?? fallbackDeparture }

    /// Stations either side of a stretch of track. Names wrap under their
    /// codes rather than truncating — Indian station names run long.
    private var journey: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                station(train.from, alignment: .leading)
                track.padding(.top, 9)
                station(train.to, alignment: .trailing)
            }
            facts
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func station(_ station: TrainDetails.Station?, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(station?.code ?? "—")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            if let name = station?.name {
                Text(name.capitalized)
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    /// Two rails with sleepers — the one thing that says "train" without words.
    private var track: some View {
        ZStack {
            VStack(spacing: 3) {
                Rectangle().frame(height: 1.2)
                Rectangle().frame(height: 1.2)
            }
            .foregroundStyle(tint.opacity(0.45))
            HStack(spacing: 4) {
                ForEach(0..<9, id: \.self) { _ in
                    Rectangle().frame(width: 1.5, height: 8)
                }
            }
            .foregroundStyle(tint.opacity(0.28))
        }
        .frame(width: 52)
    }

    // MARK: - Passengers

    private var passengers: some View {
        VStack(alignment: .leading, spacing: 8) {
            if train.passengers.isEmpty {
                Text("No passengers listed for this PNR.")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.inkTertiary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 104), spacing: 6, alignment: .top)],
                    alignment: .leading,
                    spacing: 6
                ) {
                    ForEach(train.passengers, id: \.number) { coachTile($0) }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// One passenger as a coach: a status bar where the stripe would be, the
    /// seat in big type, and in words what kind of berth it is.
    private func coachTile(_ p: TrainDetails.Passenger) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(p.standing.tint).frame(width: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("""
                    \(Text(seat(p)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(AppTheme.ink))\
                    \(Text(berthName(p.berthCode).map { " \($0)" } ?? "").font(.system(size: 11)).foregroundStyle(AppTheme.inkSecondary))
                    """)
                    .fixedSize(horizontal: false, vertical: true)
                Text(standingLine(p))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(p.standing.tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Spacer(minLength: 0)
        }
        .background(AppTheme.cardStroke.opacity(0.045))
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
    }

    private func seat(_ p: TrainDetails.Passenger) -> String {
        if let coach = p.coach, !coach.isEmpty, let berth = p.berth, berth > 0 {
            return "\(coach) · \(berth)"
        }
        return p.currentStatus ?? p.bookingStatus ?? "—"
    }

    /// "Confirmed · was WL 4": a waitlist that cleared is worth saying.
    private func standingLine(_ p: TrainDetails.Passenger) -> String {
        guard let booked = p.bookingStatus, booked != p.currentStatus,
              !booked.hasPrefix("CNF") else { return p.standing.label }
        let short = booked.split(separator: "/").prefix(2).joined(separator: " ")
        return "\(p.standing.label) · was \(short)"
    }

    /// Indian Railways' berth codes, in words — "SU" means nothing to a guest.
    private func berthName(_ code: String?) -> String? {
        switch code?.uppercased() {
        case "LB": "Lower"
        case "MB": "Middle"
        case "UB": "Upper"
        case "SL": "Side lower"
        case "SU", "SUB": "Side upper"
        case "WS": "Window"
        case "MS": "Middle"
        case "AS": "Aisle"
        case "CB": "Cabin"
        case "CP": "Coupe"
        case let other?: other.isEmpty ? nil : other
        case nil: nil
        }
    }

    /// One quiet line instead of a row of pills: class, quota, chart.
    private var facts: some View {
        let parts = [
            train.travelClass.map(className),
            train.quota.map { "\($0) quota" },
            train.chartPrepared.map { $0 ? "Chart prepared" : "Chart pending" },
        ].compactMap { $0 }
        return Text(parts.joined(separator: " · "))
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppTheme.inkTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func className(_ code: String) -> String {
        let names = ["1A": "First AC", "2A": "AC 2-tier", "3A": "AC 3-tier", "3E": "AC 3 economy",
                     "CC": "AC Chair Car", "EC": "Executive Chair", "EA": "Executive Anubhuti",
                     "SL": "Sleeper", "2S": "Second sitting", "FC": "First class"]
        return names[code.uppercased()].map { "\($0) · \(code)" } ?? code
    }

    // MARK: - Live

    private func liveStrip(_ live: TrainDetails.Live) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(live.status.tint).frame(width: 7, height: 7)
                Text("LIVE")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(AppTheme.inkTertiary)
                Spacer()
                chip(delayLabel(live), tint: delayTint(live))
            }

            if let from = live.previousStation, let to = live.nextStation, live.status == .running {
                HStack(spacing: 8) {
                    Text(from.code).font(.system(size: 12, weight: .semibold, design: .rounded))
                    progressBar(live.segmentProgress ?? 0)
                    Text(to.code).font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.ink)

                Text(runningLine(live, next: to))
                    .font(.system(size: 11.5))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(live.status.label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func progressBar(_ progress: Double) -> some View {
        GeometryReader { proxy in
            let x = proxy.size.width * min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.cardStroke.opacity(0.1)).frame(height: 4)
                Capsule().fill(tint).frame(width: x, height: 4)
                Image(systemName: "tram.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(tint, in: .circle)
                    .offset(x: max(0, x - 10))
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 20)
    }

    private func runningLine(_ live: TrainDetails.Live, next: TrainDetails.Station) -> String {
        var parts = ["Next: \(next.name?.capitalized ?? next.code)"]
        if let speed = live.speedKmh, speed > 0 { parts.append("\(Int(speed)) km/h") }
        if let updated = live.updatedAt {
            parts.append("updated \(DateFormatter.cached("h:mm a").string(from: updated))")
        }
        return parts.joined(separator: " · ")
    }

    private func delayLabel(_ live: TrainDetails.Live) -> String {
        guard live.status == .running || live.status == .completed else { return live.status.label }
        guard let delay = live.delayMinutes, delay > 0 else { return "On time" }
        return delay >= 60 ? "\(delay / 60)h \(delay % 60)m late" : "\(delay)m late"
    }

    private func delayTint(_ live: TrainDetails.Live) -> Color {
        if live.status == .cancelled { return AppTheme.danger }
        guard let delay = live.delayMinutes, delay > 0 else { return live.status.tint }
        return delay > 30 ? AppTheme.danger : Palette.amber
    }

    // MARK: - Bits

    private func chip(_ text: String, tint: Color) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: .capsule)
            .fixedSize()
    }
}
