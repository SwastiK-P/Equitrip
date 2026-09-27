//
//  SignalAlertCallout.swift
//  Equitrip
//

import SwiftUI

/// What opens when a ground-report pin on the Weather Twin map is tapped: the
/// reports about that place, strongest first, each with who said it and a
/// link back.
///
/// Built like the booking callout it replaces on the map — the same glass
/// card, badge and close button — so tapping an alert and tapping a booking
/// feel like the same gesture. An earlier version glowed red round the rim
/// and nested each report in its own card; it read as a banner ad sitting on
/// top of the app rather than part of it. The colour is in the badge and the
/// eyebrow only.
struct SignalAlertCallout: View {
    let signals: [SocialSignal]
    var onClose: () -> Void

    @Environment(\.openURL) private var openURL

    private var sorted: [SocialSignal] { signals.sorted { $0.strength > $1.strength } }
    private var lead: SocialSignal { sorted[0] }
    private var official: Bool { signals.contains { $0.source.isOfficial } }
    private var tint: Color { official ? AppTheme.danger : lead.category.tint }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ForEach(Array(sorted.prefix(2).enumerated()), id: \.element.id) { index, signal in
                if index > 0 { Hairline(inset: 0) }
                report(signal)
            }
            if signals.count > 2 {
                Text("+\(signals.count - 2) more under On the ground")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
            }
        }
        .padding(12)
        .glassEffect(.regular.tint(AppTheme.card.opacity(0.7)), in: .rect(cornerRadius: 22, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            SymbolBadge(
                symbol: official ? "exclamationmark.shield.fill" : lead.category.symbol,
                tint: tint,
                size: 38
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("\(lead.category.label) · \(lead.place.capitalized)")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Text(official ? "Official alert" : "Ground reports")
                        .foregroundStyle(tint)
                    Text("·")
                    Text(signals.count == 1 ? "1 report" : "\(signals.count) reports")
                }
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(AppTheme.inkSecondary)
            }

            Spacer(minLength: 6)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .frame(width: 26, height: 26)
                    .background(AppTheme.cardStroke.opacity(0.06), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private func report(_ signal: SocialSignal) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(cleaned(signal.text))
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(byline(signal))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let url = signal.url {
                    Button {
                        openURL(url)
                    } label: {
                        HStack(spacing: 3) {
                            Text("Open")
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(AppTheme.inkTertiary)
        }
        .padding(.leading, 50)
    }

    /// Feeds pad their titles ("… 24 Sep 2026 .") — tidy the ends.
    private func cleaned(_ text: String) -> String {
        var t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        while t.hasSuffix(" .") { t = String(t.dropLast(2)) + "." }
        return t
    }

    /// "GDACS · Orange · 4d": the source once, even when the feed repeats it
    /// as the author.
    private func byline(_ signal: SocialSignal) -> String {
        var parts: [String] = []
        for part in [signal.source.label] + signal.author.components(separatedBy: " · ") + [signal.age]
        where !part.isEmpty && !parts.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
            parts.append(part)
        }
        return parts.joined(separator: " · ")
    }
}
