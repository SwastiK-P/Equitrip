//
//  TwinImpactCard.swift
//  Equitrip
//

import SwiftUI

/// The twin's answer: how worried to be, what's worst, and what it could
/// cost — in live mode against nothing, in what-if against the live trip.
///
/// One card for both modes because they ask the same question; what-if used
/// to show a comparison card *and* a summary card with the same three figures
/// in two layouts. Figures are read as sentences ("could reach ₹37,720"), not
/// as P10/P90, and a calm trip doesn't get a row of ₹0 tiles — it gets the
/// few bookings that came closest, which is the useful thing to know about a
/// calm trip.
struct TwinImpactCard: View {
    let result: TwinResult
    /// The live result, when `result` is a what-if.
    var baseline: TwinResult?
    let twin: TripTwin
    let currencyCode: String
    var onFocus: ((TwinNode) -> Void)?
    var youID: UUID = Traveller.you.id

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var showsFigures: Bool { baseline != nil || result.risk.isNotable }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: result.risk.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .symbolEffect(.pulse, options: .repeating, isActive: result.risk == .severe && !reduceMotion)
                    Text(result.risk.label)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer(minLength: 8)
                    if let baseline {
                        Text("Live: \(baseline.risk.label.lowercased())")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }
                }
                .foregroundStyle(result.risk.tint)

                Text(result.headline)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                if !result.detail.isEmpty {
                    Text(result.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if showsFigures {
                Hairline()
                figures
            } else if !closestCalls.isEmpty {
                Hairline()
                closest
            }

            if let night = result.extraNight, night.probability >= 0.05 {
                extraNight(night)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(corner: 22)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: result.risk)
    }

    // MARK: - Figures

    private var figures: some View {
        VStack(spacing: 12) {
            let hit = result.affected
            figure(
                "Bookings likely hit",
                value: "\(Int(hit.p50.rounded())) of \(result.outcomes.count)",
                notes: [
                    hit.p90.rounded() > hit.p10.rounded() ? "could be \(Int(hit.p10.rounded()))–\(Int(hit.p90.rounded()))" : nil,
                    baseline.map { "live \(Int($0.affected.p50.rounded()))" }
                ]
            )
            figure(
                "Value at risk",
                value: money(result.valueAtRisk.p50),
                notes: [
                    reach(result.valueAtRisk),
                    baseline.map { "live \(money($0.valueAtRisk.p50))" }
                ]
            )
            if let yours = result.share(for: youID) {
                figure(
                    "Your share of it",
                    value: money(yours.atRisk.p50),
                    notes: [
                        reach(yours.atRisk),
                        baseline?.share(for: youID).map { "live \(money($0.atRisk.p50))" }
                    ]
                )
            }
        }
    }

    private func figure(_ label: String, value: String, notes: [String?]) -> some View {
        let note = notes.compactMap { $0 }.joined(separator: " · ")
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                if !note.isEmpty {
                    Text(note)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .lineLimit(1)
        }
        .animation(.snappy, value: value)
    }

    /// The bad end of the range, only when it's meaningfully worse than the middle.
    private func reach(_ q: Quantiles) -> String? {
        q.p90 > q.p50 * 1.1 + 1 ? "could reach \(money(q.p90))" : nil
    }

    private func money(_ amount: Double) -> String {
        Money.format(amount, code: currencyCode)
    }

    // MARK: - Calm

    private var closestCalls: [(node: TwinNode, outcome: NodeOutcome)] {
        result.ranked.prefix(3).compactMap { outcome in
            twin.node(outcome.id).map { ($0, outcome) }
        }
    }

    private var closest: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Closest calls")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.inkTertiary)
                .padding(.bottom, 2)

            ForEach(closestCalls, id: \.node.id) { entry in
                Button {
                    onFocus?(entry.node)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: entry.node.item.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(entry.node.item.kind.tint)
                            .frame(width: 22)
                        Text(entry.node.item.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(DateFormatter.cached("EEE d").string(from: entry.node.item.date))
                            .font(.system(size: 12.5))
                            .foregroundStyle(AppTheme.inkTertiary)
                        Text(TwinFormat.percent(entry.outcome.pAffected))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.inkSecondary)
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    .contentShape(.rect)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityHint("Shows it on the map")
            }
        }
    }

    // MARK: - Stranded

    private func extraNight(_ night: ExtraNight) -> some View {
        let yours = result.share(for: youID)?.extraNight ?? 0
        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.inkSecondary)
                .frame(width: 20)
                .padding(.top, 1)
            Text("\(TwinFormat.percent(night.probability)) chance the way home falls through and you need another night at \(night.stayTitle) — \(money(night.nightly)) at its own rate, \(money(yours)) of it yours.")
                .font(.system(size: 12.5))
                .foregroundStyle(AppTheme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.canvasTop, in: .rect(cornerRadius: 14, style: .continuous))
    }
}
