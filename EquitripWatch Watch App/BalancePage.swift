//
//  BalancePage.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// Home's hero, on the wrist: "am I up or down?" first and largest, the two
/// sides of it underneath, then the trip in view.
///
/// One screen, glanceable, no hierarchy to descend — what the watch HIG asks
/// a first screen to be. Everything is a Dynamic Type style, so the figure
/// that matters stays the biggest thing here at any text size.
struct BalancePage: View {
    @Environment(WatchStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let snapshot = store.snapshot ?? .empty

        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if snapshot.balanceIsMeaningful {
                    hero(snapshot)
                } else {
                    quietHero(snapshot)
                }

                if let trip = store.trip {
                    TripCard(trip: trip)
                }

                StaleFooter()
            }
        }
        .navigationTitle("Balance")
        .watchPageTint(MoneyTone.of(snapshot.net))
    }

    // MARK: Hero

    private func hero(_ snapshot: EquitripSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Net position")
                .font(.caption2)
                .foregroundStyle(Brand.inkTertiary)

            Text(snapshot.netLabel)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(MoneyTone.of(snapshot.net))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .accessibilityLabel("\(snapshot.netCaption), \(snapshot.netLabel.unsignedMoney)")

            // Home's own sentence, word for word.
            Text(snapshot.scopeCaption)
                .font(.footnote)
                .foregroundStyle(Brand.inkSecondary)

            SplitCells(fraction: snapshot.owedFraction)
                .padding(.top, 9)

            figures(snapshot)
                .padding(.top, 8)
        }
        .padding(.bottom, 4)
    }

    /// Side by side at normal sizes, stacked once the text is large enough
    /// that two columns would each be a word wide. The pair is a comparison;
    /// "You're / owed" over two lines stops being one.
    @ViewBuilder
    private func figures(_ snapshot: EquitripSnapshot) -> some View {
        let owed = DottedFigure(label: "You're owed", value: snapshot.owedToYouLabel, dot: Brand.accent)
        let owing = DottedFigure(label: "You owe", value: snapshot.youOweLabel, dot: Brand.danger)

        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 7) {
                owed
                Divider()
                owing
            }
        } else {
            HStack(spacing: 0) {
                owed

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1)
                    .padding(.trailing, 8)
                    .padding(.vertical, 2)

                owing
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Before anything has been paid for there is no position to report, and
    /// "Settled · all square" would be a lie on a trip that hasn't started.
    private func quietHero(_ snapshot: EquitripSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Nothing spent yet")
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(snapshot.scopeCaption)
                .font(.footnote)
                .foregroundStyle(Brand.inkSecondary)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Trip card

/// Home's current-trip card: the cover with the name set on it, then how far
/// in, then where you stand.
private struct TripCard: View {
    let trip: EquitripSnapshot.TripSummary

    /// Grows with the text on it, so the name still has room to sit over the
    /// photograph at the larger accessibility sizes.
    @ScaledMetric(relativeTo: .title3) private var coverHeight: CGFloat = 104

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cover

            VStack(alignment: .leading, spacing: 0) {
                Text(trip.progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.ink)

                DayTrack(progress: trip.progress, days: trip.dayCount ?? 1)
                    .padding(.top, 5)

                Divider()
                    .padding(.vertical, 8)

                standing
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: .rect(cornerRadius: 20, style: .continuous))
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// The photograph with the name on it, as on the phone's card: a scrim
    /// that deepens toward the bottom so white serif reads over any sky, and
    /// the phase as a chip in the corner rather than a line of its own.
    private var cover: some View {
        CoverImage(url: trip.coverURL, symbol: trip.symbol)
            .frame(height: coverHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.3),
                        .init(color: .black.opacity(0.7), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .topLeading) { phaseChip }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(trip.title)
                        .font(.display(.title3))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
                .padding(.horizontal, 10)
                .padding(.bottom, 7)
            }
    }

    /// On the photograph, over the system's own thin material: the HIG asks
    /// for materials to carry hierarchy, and a chip that keeps its contrast
    /// over a bright sky and a night street both.
    private var phaseChip: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(phaseTint)
                .frame(width: 5, height: 5)
            Text(phaseLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: .capsule)
        .environment(\.colorScheme, .dark)
        .padding(7)
    }

    /// Where you stand — the trip's own balance once it has one, what it will
    /// cost you before it does. The same switch the phone's card makes.
    private var standing: some View {
        let hasBalance = trip.phase != .upcoming

        return HStack(alignment: .firstTextBaseline) {
            Text(hasBalance ? trip.netCaption.capitalizedFirst : "Your share")
                .font(.caption2)
                .foregroundStyle(Brand.inkTertiary)

            Spacer(minLength: 4)

            Text(hasBalance ? trip.netLabel : (trip.yourShareLabel ?? "—"))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(hasBalance ? MoneyTone.of(trip.net) : Brand.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var subtitle: String {
        guard let count = trip.travellerCount else { return trip.dateRange }
        return "\(trip.dateRange) · \(count) \(count == 1 ? "traveller" : "travellers")"
    }

    private var phaseLabel: String {
        switch trip.phase {
        case .live: "Happening now"
        case .upcoming: "Upcoming"
        case .past: "Finished"
        }
    }

    private var phaseTint: Color {
        switch trip.phase {
        case .live: Brand.positive
        case .upcoming: Brand.accent
        case .past: Brand.inkTertiary
        }
    }
}

extension String {
    /// "you get back" → "You get back", for a caption standing on its own.
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

#Preview {
    NavigationStack { BalancePage() }
        .environment(WatchStore(preview: .placeholder))
}
