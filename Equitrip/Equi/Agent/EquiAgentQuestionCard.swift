//
//  EquiAgentQuestionCard.swift
//  Equitrip
//

import SwiftUI

/// Equi, stopped mid-job, asking the one thing it couldn't work out.
///
/// Rises over the screen it's working on rather than sending you back to the
/// chat to answer: the form it's filling stays in view behind it, so "who
/// paid?" is asked next to the row it's about to fill. The same question and
/// answers are on the Lock Screen when the app isn't in front, and whichever
/// is answered first wins.
struct EquiAgentQuestionCard: View {
    let question: EquiAgentQuestion
    var onAnswer: (EquiAgentQuestion.Option) -> Void
    var onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 11) {
                EquiAgentBadge(mood: .asking, progress: 0, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Equi needs you")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                    Text(question.text)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Button("Stop", action: onStop)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSecondary)
                    .padding(.top, 2)
            }

            FlowLayout(spacing: 8, rowSpacing: 8) {
                ForEach(question.options) { option in
                    Button { onAnswer(option) } label: {
                        answerLabel(option)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 440, alignment: .leading)
        .glassEffect(.regular.tint(Palette.violet.opacity(0.06)), in: .rect(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(.white.opacity(0.4), lineWidth: 0.75)
        }
        .shadow(color: Palette.violet.opacity(0.2), radius: 24, y: 8)
    }

    private func answerLabel(_ option: EquiAgentQuestion.Option) -> some View {
        HStack(spacing: 7) {
            if let traveller = option.traveller {
                TravellerAvatar(traveller: traveller, size: 24)
            } else if let symbol = option.symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(option.label)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
        }
        .padding(.leading, option.traveller == nil ? 14 : 5)
        .padding(.trailing, 14)
        .padding(.vertical, option.traveller == nil ? 10 : 5)
        .background(AppTheme.card.opacity(0.85), in: .capsule)
        .overlay { Capsule().strokeBorder(AppTheme.cardStroke.opacity(0.08)) }
        .contentShape(.capsule)
    }
}
