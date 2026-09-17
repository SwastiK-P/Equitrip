//
//  DetectedExpensesCard.swift
//  Equitrip
//

import SwiftUI

/// Home's line into the detection queue.
///
/// Only ever on screen when there is something in it. A permanent card saying
/// "0 detected" would be a standing advertisement for a feature that is doing
/// its job precisely when it has nothing to say — and Home is already the
/// busiest screen in the app. So this appears when payments are waiting,
/// counts them, and disappears when the last one has been answered.
///
/// It sits above the balance hero rather than below it because it is the only
/// thing on the screen that changes what the balance will be. Reading "you're
/// owed ₹2,400" underneath three unadded payments is reading a number that is
/// known to be out of date.
struct DetectedExpensesCard: View {
    let count: Int
    let tripTitle: String
    var isReading: Bool
    var open: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            open()
        } label: {
            HStack(spacing: 13) {
                GmailMark()
                    .frame(width: 24, height: 18)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.card, in: .rect(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.08))
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.numericText())

                    Text(isReading ? "Reading your payment alerts…" : "Tap to name them and split them · \(tripTitle)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                if isReading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .cardSurface(corner: 20)
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .animation(.snappy, value: count)
    }

    private var headline: String {
        count == 1 ? "1 payment spotted in your mail" : "\(count) payments spotted in your mail"
    }
}
