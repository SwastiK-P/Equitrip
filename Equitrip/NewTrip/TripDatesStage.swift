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
/// the trip left for the reader to work out. Here the answer is a ticket at
/// the top — out, home, and how long between — that moves as the calendar
/// under it is tapped, and the four lengths most trips actually are sit one
/// tap away in between.
struct TripDatesStage: View {
    @Binding var draft: TripDraft
    var onContinue: () -> Void

    @State private var isPicking = false
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headline
                .staggered(0, appeared)

            TripSpanTicket(start: draft.startDate, end: draft.endDate, isPicking: isPicking)
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.36, dampingFraction: 0.86), value: isPicking)
                .staggered(1, appeared)

            lengths
                .staggered(2, appeared)

            DateRangeCalendar(
                start: $draft.startDate,
                end: $draft.endDate,
                isPicking: $isPicking
            )
            .padding(.top, 14)
            // The calendar sits on a sheet that runs off the bottom of the
            // screen, under the button — the ticket above is the answer, this
            // is where it's worked out. Only the sheet ignores the safe area;
            // the scroll inside still stops above the button.
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                    .fill(AppTheme.card.opacity(0.72))
                    .overlay {
                        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                            .strokeBorder(AppTheme.cardStroke.opacity(0.05))
                    }
                    .ignoresSafeArea(edges: .bottom)
            }
            .staggered(3, appeared)
        }
        .padding(.top, 10)
        .safeAreaInset(edge: .bottom) { continueBar }
        .onAppear { withAnimation { appeared = true } }
    }

    // MARK: - Headline

    private var headline: some View {
        Text(isPicking ? "And back on?" : "When are you going?")
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .contentTransition(.opacity)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(on ? AppTheme.ctaLabel : AppTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            Capsule().fill(on ? AnyShapeStyle(AppTheme.cta) : AnyShapeStyle(AppTheme.card.opacity(0.7)))
                        }
                        .overlay {
                            Capsule().strokeBorder(AppTheme.cardStroke.opacity(on ? 0 : 0.07))
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(PressableButtonStyle())
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
        StageActionBar(
            title: isPicking ? "Pick the last day" : "Continue",
            symbol: isPicking ? nil : "arrow.right",
            isEnabled: !isPicking
        ) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onContinue()
        }
    }
}
