//
//  DateRangeSheet.swift
//  Equitrip
//

import SwiftUI

/// `DateRangeCalendar` as a sheet, for the screens that already exist and only
/// need the dates corrected — the review step, where the span is one row of
/// many rather than the question being asked.
struct DateRangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var start: Date
    @Binding var end: Date

    @State private var isPicking = false

    var body: some View {
        VStack(spacing: 0) {
            header
            DateRangeCalendar(start: $start, end: $end, isPicking: $isPicking)
        }
        .safeAreaInset(edge: .bottom) { doneBar }
        .presentationDragIndicator(.hidden)
        .presentationBackground { CanvasBackground() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("When?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(DateSpan.caption(start: start, end: end, isPicking: isPicking))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(isPicking ? AppTheme.accent : AppTheme.inkTertiary)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 8)

            CircleGlyphButton(symbol: "xmark", size: 34) { dismiss() }
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private var doneBar: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            Text("Done")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(AppTheme.accent)
        .disabled(isPicking)
        .opacity(isPicking ? 0.5 : 1)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Shared phrasing

/// How a span is written wherever one is being chosen, so the sheet and the
/// creation step say the same thing in the same words.
enum DateSpan {
    static func caption(start: Date, end: Date, isPicking: Bool) -> String {
        guard !isPicking else { return "Now pick the day you come home" }

        let format = DateFormatter.cached("EEE d MMM")
        let days = max(1, (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        let length = days == 1 ? "day trip" : (days - 1).pluralised("night")
        return "\(format.string(from: start)) → \(format.string(from: end)) · \(length)"
    }
}
