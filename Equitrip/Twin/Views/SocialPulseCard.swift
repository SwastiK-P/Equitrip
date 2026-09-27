//
//  SocialPulseCard.swift
//  Equitrip
//

import SwiftUI

/// What people, newsrooms and disaster agencies are saying where the trip is.
///
/// Every report is attributed — author, network, age, place — and opens at
/// its source, because the twin weighs these when it scores bookings and a
/// traveller should be able to check what it weighed. Official alerts come
/// first. The category bar chart and the chips on every row were cut: one
/// line up top says what's being reported most and whether it's building,
/// and the rows are left to be read.
struct SocialPulseCard: View {
    let digest: SignalDigest
    let places: [String]

    @State private var showsAll = false
    @Environment(\.openURL) private var openURL

    private var ordered: [SocialSignal] {
        digest.officialAlerts + digest.signals.filter { !$0.source.isOfficial }
    }

    private var visible: [SocialSignal] {
        Array(ordered.prefix(showsAll ? 20 : 3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if digest.signals.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.bubble.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.positive)
                    Text("Nobody's reporting rain, flooding or disruption in \(places.prefix(2).joined(separator: " or ")) right now.")
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 14)
            } else {
                summary
                    .padding(.vertical, 12)

                ForEach(visible) { signal in
                    Hairline()
                    SignalRow(signal: signal) {
                        if let url = signal.url { openURL(url) }
                    }
                }

                if ordered.count > 3 {
                    Hairline()
                    Button {
                        withAnimation(.snappy) { showsAll.toggle() }
                    } label: {
                        Text(showsAll ? "Show fewer" : "Show all \(ordered.count) reports")
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .padding(.horizontal, 14)
        .cardSurface(corner: 22)
    }

    private var summary: some View {
        HStack(spacing: 8) {
            Image(systemName: digest.officialAlerts.isEmpty ? digest.trend.symbol : "exclamationmark.triangle.fill")
                .font(.system(size: 11, weight: .bold))
            Text(summaryText)
                .font(.system(size: 13, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(digest.trend == .building ? AppTheme.danger : AppTheme.inkSecondary)
    }

    /// "Quiet" above an official cyclone alert read as a contradiction, so
    /// alerts are counted first and the trend speaks only for the rest.
    private var summaryText: String {
        var parts: [String] = []
        let alerts = digest.officialAlerts.count
        if alerts > 0 { parts.append(alerts.pluralised("official alert")) }
        if digest.trend != .quiet || alerts == 0 { parts.append(digest.trend.label) }
        if let top = digest.dominant, digest.signals.count > alerts {
            parts.append("mostly \(top.category.label.lowercased())")
        }
        return parts.joined(separator: " · ")
    }
}

/// One report, credited.
struct SignalRow: View {
    let signal: SocialSignal
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: signal.source.symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(signal.source.tint)
                    .frame(width: 30, height: 30)
                    .background(signal.source.tint.opacity(0.12), in: .rect(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(signal.author)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(signal.age)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.inkTertiary)
                    }

                    Text(signal.text)
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Text([signal.source.label, signal.place, signal.category.label].joined(separator: " · "))
                        .font(.system(size: 11.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint(signal.url != nil ? "Opens the original at \(signal.source.label)" : "")
    }
}
