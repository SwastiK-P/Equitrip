//
//  BalancePage.swift
//  EquitripWatch Watch App
//

import SwiftUI

/// Home's hero, on the wrist: "am I up or down?" first and largest, with the
/// two sides of it underneath. The trip it's scoped to is the next page.
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

#Preview {
    NavigationStack { BalancePage() }
        .environment(WatchStore(preview: .placeholder))
}
