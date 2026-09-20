//
//  TripRecapCards.swift
//  Equitrip
//

import SwiftUI

// The cards `TripRecapView` is built from. Each one answers one question about
// a finished trip, and each takes the lens so the group's answer and yours sit
// in the same place on the screen.

// MARK: - Frame

/// The shared shell: a small uppercase eyebrow, a title, then the card's body.
private struct RecapCard<Content: View>: View {
    @Environment(\.pane) private var pane

    let eyebrow: String
    let title: String
    var trailing: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 10.5, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(title)
                        .font(.system(size: pane.isRegular ? 21 : 19, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }

                Spacer(minLength: 8)

                if let trailing {
                    Text(trailing)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                }
            }

            content
        }
        .padding(pane.isRegular ? 22 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(corner: pane.corner(26))
    }
}

// MARK: - Rolling figure

/// A money figure that counts up to its value instead of appearing whole.
///
/// Animatable rather than `numericText`: the content transition only rolls
/// the digits that change, so going from nothing to ₹48,200 is one swap, not a
/// count. Interpolating the number itself is what makes it feel like a tally.
private struct RollingAmount: View, Animatable {
    var value: Double
    let code: String
    var signed = false

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(Money.format(value.rounded(), code: code, signed: signed))
            .monospacedDigit()
    }
}

// MARK: - Headline

struct RecapHeadlineCard: View {
    @Environment(\.pane) private var pane

    let recap: TripRecap
    let lens: TripRecap.Lens
    let appeared: Bool

    private var trip: Trip { recap.trip }
    private var code: String { trip.currencyCode }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            figure
            Hairline()
            stats
        }
        .padding(pane.isRegular ? 26 : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                AppTheme.card
                RadialGradient(
                    colors: [trip.tint.opacity(0.16), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: pane.isRegular ? 420 : 260
                )
            }
        }
        .clipShape(.rect(cornerRadius: pane.corner(28), style: .continuous))
        .cardSurface(corner: pane.corner(28))
    }

    @ViewBuilder
    private var figure: some View {
        switch lens {
        case .group: groupFigure
        case .you: yourFigure
        }
    }

    private var stats: some View {
        HStack(spacing: 0) {
            switch lens {
            case .group:
                stat(Money.format(recap.perDay.rounded(), code: code), "a day")
                divider
                stat(Money.format(recap.perPerson.rounded(), code: code), "each, on average")
                divider
                stat("\(trip.items.count)", trip.items.count == 1 ? "booking" : "bookings")
            case .you:
                stat(Money.format(recap.yourPaid.rounded(), code: code), "you paid out")
                divider
                stat("\(recap.yourDays)", recap.yourDays == 1 ? "day there" : "days there")
                divider
                netStat
            }
        }
    }

    private var groupFigure: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TOGETHER YOU SPENT")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.inkTertiary)

            RollingAmount(value: appeared ? recap.total(.group) : 0, code: code)
                .font(.system(size: pane.isRegular ? 54 : 46, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .animation(.easeOut(duration: 1.1), value: appeared)

            Text("across \(trip.dayCount.pluralised("day")) in \(placeName)")
                .font(.system(size: pane.isRegular ? 15 : 14, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
        }
        .transition(.blurReplace)
    }

    /// On a phone the ring leads and the figure sits beside it. On iPad the
    /// figure takes the same place and size as the group total — so flipping
    /// the lens swaps the number without the card changing shape — and the
    /// ring moves to the right, where the group card's gradient has room.
    private var yourFigure: some View {
        HStack(spacing: pane.isRegular ? 24 : 18) {
            if !pane.isRegular { ring }

            VStack(alignment: .leading, spacing: 6) {
                Text("YOUR SHARE")
                    .font(.system(size: 10.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.inkTertiary)

                RollingAmount(value: recap.total(.you), code: code)
                    .font(.system(size: pane.isRegular ? 54 : 36, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text("of the group's \(Money.format(recap.total(.group).rounded(), code: code))")
                    .font(.system(size: pane.isRegular ? 15 : 13.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if pane.isRegular {
                Spacer(minLength: 0)
                ring
            }
        }
        .transition(.blurReplace)
    }

    private var ring: some View {
        let diameter: CGFloat = pane.isRegular ? 124 : 92
        return ShareRing(fraction: appeared ? recap.yourFraction : 0, tint: AppTheme.accent, diameter: diameter)
            .frame(width: diameter, height: diameter)
            .animation(.spring(response: 1.0, dampingFraction: 0.85), value: appeared)
            .animation(.spring(response: 0.8, dampingFraction: 0.85), value: lens)
    }

    /// "Goa, India" becomes "Goa" — a caption, not an address.
    private var placeName: String {
        trip.destination.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? trip.title
    }

    @ViewBuilder
    private var netStat: some View {
        if !trip.showsBalance {
            stat("—", "nothing recorded")
        } else {
            let remaining = recap.yourRemaining
            if abs(remaining) < SettlementEngine.epsilon {
                stat("Square", "all settled", tint: AppTheme.positive)
            } else {
                stat(
                    Money.format(abs(remaining).rounded(), code: code),
                    remaining > 0 ? "still to get back" : "still to pay",
                    tint: remaining > 0 ? AppTheme.moneyIn : AppTheme.moneyOut
                )
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.12))
            .frame(width: 1, height: pane.isRegular ? 36 : 30)
            .padding(.horizontal, pane.isRegular ? 16 : 10)
    }

    private func stat(_ value: String, _ caption: String, tint: Color = AppTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: pane.isRegular ? 19 : 16.5, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            Text(caption)
                .font(.system(size: pane.isRegular ? 12.5 : 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Your slice of the trip, as a ring with the percentage inside it.
private struct ShareRing: View {
    var fraction: Double
    let tint: Color
    /// The stroke and the type inside scale with it, so a larger ring on
    /// iPad doesn't end up a thin hoop around a small number.
    var diameter: CGFloat = 92

    private var scale: CGFloat { diameter / 92 }
    private var lineWidth: CGFloat { 11 * scale }

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, fraction))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.55), tint],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * max(0.001, fraction))
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: -1) {
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 20 * scale, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.numericText(value: fraction))
                Text("of it")
                    .font(.system(size: 10 * scale, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(Int((fraction * 100).rounded())) percent of the trip")
    }
}

// MARK: - Where it went

struct RecapBreakdownCard: View {
    let recap: TripRecap
    let slices: [TripRecap.Slice]
    let lens: TripRecap.Lens
    let appeared: Bool

    private var total: Double { slices.reduce(0) { $0 + $1.amount } }
    private var code: String { recap.trip.currencyCode }

    var body: some View {
        RecapCard(
            eyebrow: lens == .group ? "The money" : "Your money",
            title: "Where it went",
            trailing: slices.first.map { "Mostly \($0.kind.label.lowercased())" }
        ) {
            bar

            VStack(spacing: 12) {
                ForEach(slices) { slice in
                    row(slice)
                }
            }
        }
    }

    /// Every category as one continuous strip, in proportion. Drawn to grow
    /// from the left on arrival so the eye follows the order the rows list.
    private var bar: some View {
        GeometryReader { proxy in
            let gaps = CGFloat(max(0, slices.count - 1)) * 3
            let usable = max(0, proxy.size.width - gaps)

            HStack(spacing: 3) {
                ForEach(slices) { slice in
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(slice.kind.tint.gradient)
                        .frame(width: max(4, usable * slice.amount / max(total, 1)))
                }
            }
            .frame(width: proxy.size.width, alignment: .leading)
            .scaleEffect(x: appeared ? 1 : 0.02, anchor: .leading)
            .animation(.spring(response: 0.9, dampingFraction: 0.86).delay(0.15), value: appeared)
        }
        .frame(height: 16)
        .clipShape(.capsule)
    }

    private func row(_ slice: TripRecap.Slice) -> some View {
        let fraction = total > 0 ? slice.amount / total : 0

        return HStack(spacing: 12) {
            SymbolBadge(symbol: slice.kind.symbol, tint: slice.kind.tint, size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(slice.kind.label)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text(slice.count.pluralised("booking"))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.inkTertiary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(Money.format(slice.amount.rounded(), code: code))
                    .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.numericText())
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(slice.kind.tint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Day by day

struct RecapDaysCard: View {
    let recap: TripRecap
    let days: [TripRecap.DaySpend]
    let lens: TripRecap.Lens
    let appeared: Bool
    /// How many days fit across before the chart scrolls instead.
    var fits = 10

    @Environment(\.pane) private var pane

    private var chartHeight: CGFloat { pane.isRegular ? 140 : 112 }
    private var code: String { recap.trip.currencyCode }
    private var peak: TripRecap.DaySpend? { days.max { $0.amount < $1.amount } }
    private var maxAmount: Double { max(peak?.amount ?? 0, 1) }

    /// A week fits across a phone; a fortnight doesn't, so longer trips scroll
    /// sideways at a fixed bar width rather than shrinking into slivers.
    private var scrolls: Bool { days.count > fits }

    var body: some View {
        RecapCard(eyebrow: "Pace", title: "Day by day", trailing: peakCaption) {
            if scrolls {
                ScrollView(.horizontal) {
                    bars.padding(.horizontal, 2)
                }
                .scrollIndicators(.hidden)
                .defaultScrollAnchor(.leading)
            } else {
                bars
            }
        }
    }

    private var peakCaption: String? {
        guard let peak, peak.amount > 0 else { return nil }
        return "Biggest · \(DateFormatter.cached("EEE d").string(from: peak.date))"
    }

    private var bars: some View {
        HStack(alignment: .bottom, spacing: scrolls ? 10 : 6) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                column(day, index: index)
                    .frame(width: scrolls ? 26 : nil)
                    .frame(maxWidth: scrolls ? nil : .infinity)
            }
        }
    }

    private func column(_ day: TripRecap.DaySpend, index: Int) -> some View {
        let isPeak = day.id == peak?.id && day.amount > 0
        let height = day.amount > 0 ? max(8, chartHeight * day.amount / maxAmount) : 6
        let tint: Color = day.isOutside ? Palette.stone : AppTheme.accent

        return VStack(spacing: 7) {
            ZStack(alignment: .bottom) {
                Color.clear.frame(height: chartHeight + 22)

                VStack(spacing: 5) {
                    if isPeak {
                        Text(Money.format(day.amount.rounded(), code: code))
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                            .fixedSize()
                            .opacity(appeared ? 1 : 0)
                    }

                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isPeak ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(day.amount > 0 ? 0.24 : 0.1)))
                        .frame(height: appeared ? height : 6)
                }
            }
            .animation(
                .spring(response: 0.7, dampingFraction: 0.78).delay(0.2 + Double(index) * 0.035),
                value: appeared
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: lens)

            VStack(spacing: 0) {
                Text(DateFormatter.cached("EEEEE").string(from: day.date))
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(AppTheme.inkTertiary)
                Text(DateFormatter.cached("d").string(from: day.date))
                    .font(.system(size: 12, weight: isPeak ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isPeak ? AppTheme.ink : AppTheme.inkSecondary)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(DateFormatter.cached("EEEE d MMMM").string(from: day.date)), \(Money.format(day.amount.rounded(), code: code))")
    }
}

// MARK: - Who fronted it

struct RecapPayersCard: View {
    let recap: TripRecap
    let appeared: Bool

    private var code: String { recap.trip.currencyCode }
    private var people: [TripRecap.Contributor] { recap.contributors }
    private var top: Double { max(people.first?.paid ?? 0, 1) }

    var body: some View {
        RecapCard(eyebrow: "The people", title: "Who fronted it", trailing: "paid vs. share") {
            VStack(spacing: 16) {
                ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                    row(person, index: index)
                }
            }
        }
    }

    private func row(_ person: TripRecap.Contributor, index: Int) -> some View {
        let isDeparted = recap.trip.departedIDs.contains(person.id)
        let isTop = index == 0 && person.paid > 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TravellerAvatar(traveller: person.traveller, size: 38, isDimmed: isDeparted)
                    .overlay(alignment: .topTrailing) {
                        if isTop {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Palette.amber, in: .circle)
                                .overlay { Circle().strokeBorder(AppTheme.card, lineWidth: 1.5) }
                                .offset(x: 5, y: -5)
                        }
                    }

                VStack(alignment: .leading, spacing: 1) {
                    Text(person.isYou ? "You" : person.traveller.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(person.presence ?? subtitle(person))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(Money.format(person.paid.rounded(), code: code))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(person.paid > 0 ? AppTheme.ink : AppTheme.inkTertiary)
                    Text("share \(Money.format(person.share.rounded(), code: code))")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.cardStroke.opacity(0.06))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isTop ? [Palette.amber, Palette.amberDeep] : [AppTheme.accent.opacity(0.55), AppTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: appeared ? max(person.paid > 0 ? 6 : 0, proxy.size.width * person.paid / top) : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.25 + Double(index) * 0.06), value: appeared)
                }
            }
            .frame(height: 6)
            .padding(.leading, 50)
        }
        .accessibilityElement(children: .combine)
    }

    private func subtitle(_ person: TripRecap.Contributor) -> String {
        person.paidCount == 0 ? "Didn't pay for anything" : "Paid for \(person.paidCount.pluralised("booking"))"
    }
}

// MARK: - What you picked up

struct RecapYourPaymentsCard: View {
    let recap: TripRecap

    private static let cap = 4
    private var code: String { recap.trip.currencyCode }
    private var payments: [ItineraryItem] { recap.yourPayments }

    var body: some View {
        RecapCard(
            eyebrow: "On your card",
            title: "What you picked up",
            trailing: payments.count.pluralised("booking")
        ) {
            VStack(spacing: 0) {
                ForEach(Array(payments.prefix(Self.cap).enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Hairline(inset: 46).padding(.vertical, 10) }

                    HStack(spacing: 12) {
                        SymbolBadge(symbol: item.symbol, tint: item.kind.tint, size: 34)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title)
                                .font(.system(size: 14.5, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                            Text(DateFormatter.cached("EEE d MMM").string(from: item.date))
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.inkTertiary)
                        }

                        Spacer(minLength: 8)

                        Text(Money.format(item.cost.rounded(), code: code))
                            .font(.system(size: 14.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                    }
                }

                if payments.count > Self.cap {
                    let rest = payments.dropFirst(Self.cap)
                    Text("+ \(rest.count) more · \(Money.format(rest.reduce(0) { $0 + $1.cost }.rounded(), code: code))")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.leading, 46)
                }
            }
        }
    }
}

// MARK: - Highlights

struct RecapHighlightsGrid: View {
    let highlights: [TripRecap.Highlight]
    var columns = 2
    /// Matched to the gap between the cards around the grid.
    var spacing: CGFloat = 14

    @Environment(\.pane) private var pane

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(highlights) { tile in
                VStack(alignment: .leading, spacing: 0) {
                    SymbolBadge(symbol: tile.symbol, tint: tile.tint, size: 32)

                    Spacer(minLength: 14)

                    Text(tile.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(tile.value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                        .padding(.top, 1)

                    Text(tile.detail ?? " ")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .lineLimit(1)
                        .padding(.top, 1)
                }
                .padding(pane.isRegular ? 18 : 15)
                .frame(maxWidth: .infinity, minHeight: pane.isRegular ? 150 : 138, alignment: .topLeading)
                .background {
                    LinearGradient(
                        colors: [tile.tint.opacity(0.09), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                    .clipShape(.rect(cornerRadius: pane.corner(22), style: .continuous))
                }
                .cardSurface(corner: pane.corner(22), shadow: 8)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Squaring up

struct RecapSquaringCard: View {
    @Environment(\.pane) private var pane

    let recap: TripRecap
    let lens: TripRecap.Lens

    @State private var celebrate = false

    private var trip: Trip { recap.trip }
    private var code: String { trip.currencyCode }

    var body: some View {
        switch recap.squaring(lens) {
        case .nothingRecorded:
            quiet
        case .square(let moved, let transfers):
            square(moved: moved, transfers: transfers)
        case .open(let transfers, let pending):
            open(transfers: transfers, pending: pending)
        }
    }

    private var quiet: some View {
        HStack(spacing: 14) {
            SymbolBadge(symbol: "banknote", tint: AppTheme.inkSecondary, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("No payments recorded")
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text("Nobody logged who paid, so there was nothing to settle.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.inkSecondary)
            }
        }
        .padding(pane.isRegular ? 22 : 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(corner: pane.corner(26))
    }

    private func square(moved: Double, transfers: Int) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white, AppTheme.positive)
                .symbolRenderingMode(.palette)
                .symbolEffect(.bounce, options: .nonRepeating, value: celebrate)
                .shadow(color: AppTheme.positive.opacity(0.35), radius: 12, y: 6)

            Text(lens == .group ? "Everyone's square" : "You're all square")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(
                transfers == 0
                    ? "The bills split so evenly nobody owed anybody."
                    : "\(Money.format(moved.rounded(), code: code)) changed hands in \(transfers.pluralised("transfer")) to close it out."
            )
            .font(.system(size: 13.5))
            .foregroundStyle(AppTheme.inkSecondary)
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                AppTheme.card
                RadialGradient(
                    colors: [AppTheme.positive.opacity(0.16), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 240
                )
            }
            .clipShape(.rect(cornerRadius: pane.corner(26), style: .continuous))
        }
        .cardSurface(corner: pane.corner(26))
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(700))
                celebrate.toggle()
            }
        }
    }

    private func open(transfers: [SettlementEngine.Transfer], pending: [Settlement]) -> some View {
        RecapCard(
            eyebrow: "Settling up",
            title: headline,
            trailing: transfers.isEmpty ? nil : transfers.count.pluralised("transfer")
        ) {
            VStack(spacing: 12) {
                ForEach(transfers) { transfer in
                    transferRow(from: transfer.from, to: transfer.to, amount: transfer.amount, waiting: false)
                }
                ForEach(pending) { claim in
                    transferRow(from: claim.fromID, to: claim.toID, amount: claim.amount, waiting: true)
                }
            }
        }
    }

    private var headline: String {
        guard lens == .you else { return "Almost square" }
        let remaining = recap.yourRemaining
        if remaining > SettlementEngine.epsilon { return "You're owed \(Money.format(remaining.rounded(), code: code))" }
        if remaining < -SettlementEngine.epsilon { return "You owe \(Money.format((-remaining).rounded(), code: code))" }
        return "Waiting on a confirmation"
    }

    private func name(_ id: UUID) -> String {
        id == Traveller.you.id ? "You" : trip.traveller(id)?.name ?? "Someone"
    }

    private func transferRow(from: UUID, to: UUID, amount: Double, waiting: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                if let payer = trip.traveller(from) { TravellerAvatar(traveller: payer, size: 32) }
                if let payee = trip.traveller(to) { TravellerAvatar(traveller: payee, size: 32) }
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(name(from))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(name(to))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)

                if waiting {
                    Label("Sent · waiting on \(name(to))", systemImage: "clock.fill")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Palette.amberDeep)
                        .labelStyle(.titleAndIcon)
                } else {
                    Text("Open in Settle to pay")
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }

            Spacer(minLength: 8)

            Text(Money.format(amount.rounded(), code: code))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tone(from: from, to: to))
        }
        .padding(12)
        .background(AppTheme.canvasTop, in: .rect(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.cardStroke.opacity(0.05))
        }
        .accessibilityElement(children: .combine)
    }

    private func tone(from: UUID, to: UUID) -> Color {
        if from == Traveller.you.id { return AppTheme.moneyOut }
        if to == Traveller.you.id { return AppTheme.moneyIn }
        return AppTheme.ink
    }
}
