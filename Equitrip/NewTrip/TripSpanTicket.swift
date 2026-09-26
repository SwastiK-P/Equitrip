//
//  TripSpanTicket.swift
//  Equitrip
//

import SwiftUI

/// A trip's span drawn as a ticket: the day out on the left, the day home on
/// the right, and how long that is across the tear-off strip.
///
/// Dates were a sentence — "Sun 20 Sep → Wed 23 Sep · 3 nights" — which is
/// correct and has to be read left to right to be understood. The two days
/// that matter are the two numbers people check, so they're the biggest thing
/// on the card, and the length sits between them where the eye crosses
/// anyway. The dates step and the review screen draw the same ticket, so the
/// span chosen on one is recognisably the span checked on the other.
struct TripSpanTicket: View {
    let start: Date
    let end: Date
    /// Between the two taps of a new span: the return half is a question, not
    /// the one-day trip the first tap momentarily made.
    var isPicking = false
    /// Makes the whole ticket a button, with "Change" on the strip.
    var action: (() -> Void)?

    private static let stripHeight: CGFloat = 44

    private var days: Int {
        max(1, (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
    }

    var body: some View {
        if let action {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                action()
            } label: {
                ticket
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityHint("Changes the dates")
        } else {
            ticket
        }
    }

    private var ticket: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                endpoint("Out", date: start, alignment: .leading)
                route
                if isPicking {
                    pendingReturn
                } else {
                    endpoint("Home", date: end, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)

            perforation

            strip
                .frame(height: Self.stripHeight)
        }
        .background(AppTheme.card, in: TicketShape(notchFromBottom: Self.stripHeight))
        .overlay {
            TicketShape(notchFromBottom: Self.stripHeight)
                .stroke(AppTheme.cardStroke.opacity(0.05))
        }
        .shadow(color: AppTheme.softShadow(.light), radius: 12, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DateSpan.caption(start: start, end: end, isPicking: isPicking))
    }

    // MARK: - Ends

    private func endpoint(_ label: String, date: Date, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(AppTheme.inkTertiary)

            Text(DateFormatter.cached("d").string(from: date))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.numericText())
                .monospacedDigit()

            Text(DateFormatter.cached("EEE, MMM").string(from: date))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
                .contentTransition(.opacity)
        }
        .frame(minWidth: 76, alignment: alignment == .leading ? .leading : .trailing)
    }

    private var pendingReturn: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("HOME")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(1)
                .foregroundStyle(AppTheme.accent)

            Circle()
                .strokeBorder(AppTheme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1.6, dash: [4, 4]))
                .frame(width: 46, height: 46)
                .overlay {
                    Image(systemName: "questionmark")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.vertical, 2)

            Text("Pick a day")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.accent)
        }
        .frame(minWidth: 76, alignment: .trailing)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    /// A dotted path with the plane on it — how far apart the two ends are,
    /// said with a line before it's said with a number.
    private var route: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.inkTertiary.opacity(0.5))
                .frame(width: 5, height: 5)
            dots
            Image(systemName: "airplane")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            dots
            Circle()
                .strokeBorder(AppTheme.inkTertiary.opacity(0.6), lineWidth: 1.4)
                .frame(width: 7, height: 7)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var dots: some View {
        Line()
            .stroke(AppTheme.inkTertiary.opacity(0.4), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [0.1, 4.5]))
            .frame(height: 2)
    }

    // MARK: - Strip

    private var perforation: some View {
        Line()
            .stroke(AppTheme.cardStroke.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private var strip: some View {
        HStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            Text(lengthLabel)
                .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.numericText())

            Spacer(minLength: 8)

            if action != nil {
                HStack(spacing: 3) {
                    Text("Change")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AppTheme.accent)
            } else {
                Text(DateFormatter.cached("yyyy").string(from: start))
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .padding(.horizontal, 20)
    }

    private var lengthLabel: String {
        if isPicking { return "Choosing…" }
        if days == 1 { return "Day trip" }
        return "\(days.pluralised("day")) · \((days - 1).pluralised("night"))"
    }
}

// MARK: - Shapes

/// A rounded card with a half-circle bitten out of each side, where the stub
/// tears off.
private struct TicketShape: Shape {
    var corner: CGFloat = 24
    var notch: CGFloat = 9
    var notchFromBottom: CGFloat

    func path(in rect: CGRect) -> Path {
        let body = RoundedRectangle(cornerRadius: corner, style: .continuous).path(in: rect)
        let y = rect.maxY - notchFromBottom
        var bites = Path()
        bites.addEllipse(in: CGRect(x: rect.minX - notch, y: y - notch, width: notch * 2, height: notch * 2))
        bites.addEllipse(in: CGRect(x: rect.maxX - notch, y: y - notch, width: notch * 2, height: notch * 2))
        return body.subtracting(bites)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
