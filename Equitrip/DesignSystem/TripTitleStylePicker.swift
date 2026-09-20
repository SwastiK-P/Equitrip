//
//  TripTitleStylePicker.swift
//  Equitrip
//

import SwiftUI

/// Choosing the typeface a trip's name is set in.
///
/// Each option is drawn with the trip's own name rather than "Aa": whether a
/// face suits "Manali" is only answerable by looking at "Manali" in it.
struct TripTitleStylePicker: View {
    let title: String
    @Binding var selection: TripTitleStyle

    private var sample: String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Your trip" : trimmed
    }

    var body: some View {
        ScrollViewReader { reader in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(TripTitleStyle.allCases) { style in
                        tile(style)
                            .id(style)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .onAppear { reader.scrollTo(selection, anchor: .center) }
        }
    }

    private func tile(_ style: TripTitleStyle) -> some View {
        let on = style == selection

        return Button {
            guard !on else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { selection = style }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(sample)
                    .tripTitle(style, size: 24)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                HStack(spacing: 4) {
                    Text(style.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(on ? AppTheme.ink : AppTheme.inkTertiary)

                    Spacer(minLength: 0)

                    if on {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .frame(width: 148, height: 88)
            .background(AppTheme.card, in: .rect(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(on ? AppTheme.ink : AppTheme.cardStroke.opacity(0.08), lineWidth: on ? 1.5 : 1)
            }
            .contentShape(.rect(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(style.name) title style")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
