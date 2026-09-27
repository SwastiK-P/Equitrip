//
//  StepRail.swift
//  Equitrip
//

import SwiftUI

/// Where the creation flow is, drawn as the questions themselves rather than as
/// a bar.
///
/// The thin four-cell track it replaces said "two of four" and nothing about
/// what the four were — and the header's title said the current question a
/// second time right above it. Here each step is its own glyph, the current
/// one opens out to say its name, and the ones behind turn into ticks, so the
/// header answers "what's left" in the same place it answers "where am I".
struct StepRail: View {
    struct Step: Hashable {
        let symbol: String
        let label: String
    }

    let steps: [Step]
    /// One-based, to match how the flow counts.
    let current: Int

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                cell(step, number: index + 1)
            }
        }
        .padding(4)
        .glassEffect(.regular, in: .capsule)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(steps.count), \(steps[max(0, min(current, steps.count) - 1)].label)")
    }

    private func cell(_ step: Step, number: Int) -> some View {
        let isCurrent = number == current
        let isDone = number < current

        return HStack(spacing: 6) {
            Image(systemName: isDone ? "checkmark" : step.symbol)
                .font(.system(size: isDone ? 11.5 : 13, weight: .bold))
                .contentTransition(.symbolEffect(.replace))

            if isCurrent {
                Text(step.label)
                    .font(.system(size: 13.5, weight: .semibold))
                    .fixedSize()
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
        .foregroundStyle(
            isCurrent ? AppTheme.ctaLabel : isDone ? AppTheme.accent : AppTheme.inkTertiary
        )
        .padding(.horizontal, isCurrent ? 13 : 9)
        .frame(minWidth: 32)
        .frame(height: 32)
        .background {
            if isCurrent {
                Capsule()
                    .fill(AppTheme.accent)
                    .matchedGeometryEffect(id: "current", in: namespace)
            }
        }
    }
}

extension StepRail.Step {
    static let place = Self(symbol: "mappin.and.ellipse", label: "Where")
    static let dates = Self(symbol: "calendar", label: "When")
    static let people = Self(symbol: "person.2.fill", label: "Who")
    static let read = Self(symbol: "doc.text.viewfinder", label: "Read")
    static let review = Self(symbol: "checkmark.seal.fill", label: "Check")
}
