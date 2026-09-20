//
//  TripDatesStage.swift
//  Equitrip
//

import SwiftUI

/// Step two: when.
///
/// A whole screen for one question, because it is one question with two
/// answers and the old form treated it as two questions with one answer each —
/// two grey date pills stacked in the middle of a scroll, and the length of
/// the trip left for the reader to work out. Here the calendar is the screen:
/// the span is drawn across it, the count is in the sentence at the top, and
/// the four lengths most trips actually are are one tap away.
struct TripDatesStage: View {
    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var isPicking = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headline
                .staggered(0, appeared)

            lengths
                .staggered(1, appeared)

            DateRangeCalendar(
                start: $draft.startDate,
                end: $draft.endDate,
                isPicking: $isPicking
            )
            .staggered(2, appeared)
        }
        .padding(.top, 10)
        .safeAreaInset(edge: .bottom) { continueBar }
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isPicking ? "And back on?" : "When are you going?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .contentTransition(.opacity)

            Text(DateSpan.caption(start: draft.startDate, end: draft.endDate, isPicking: isPicking))
                .font(.system(size: 14.5, weight: .medium))
                .foregroundStyle(isPicking ? AppTheme.accent : AppTheme.inkSecondary)
                .contentTransition(.opacity)
        }
        .animation(.easeOut(duration: 0.22), value: isPicking)
        .padding(.horizontal, 20)
    }

    /// The four trip lengths people actually pick, measured from the first day
    /// already chosen. Anything unusual still goes through the calendar.
    private var lengths: some View {
        HStack(spacing: 8) {
            ForEach(Self.durations, id: \.days) { option in
                let on = !isPicking && draft.dayCount == option.days

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isPicking = false
                        draft.endDate = Calendar.current.date(
                            byAdding: .day,
                            value: option.days - 1,
                            to: draft.startDate
                        ) ?? draft.startDate
                    }
                } label: {
                    Text(option.label)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(.clear))
                        }
                        .overlay {
                            Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.09))
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private static let durations: [(label: String, days: Int)] = [
        ("Weekend", 2), ("5 days", 5), ("A week", 7), ("2 weeks", 14)
    ]

    // MARK: - Continue

    /// Held back while a span is half-chosen. One tap into a new range, the
    /// trip is momentarily one day long, and letting that through is how
    /// somebody ends up with a fortnight booked as a Tuesday.
    private var continueBar: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onContinue()
        } label: {
            HStack(spacing: 7) {
                Text(isPicking ? "Pick the last day" : "Continue")
                    .font(.system(size: 16, weight: .semibold))
                if !isPicking {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(isPicking)
        .opacity(isPicking ? 0.55 : 1)
        .animation(.easeOut(duration: 0.2), value: isPicking)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}
