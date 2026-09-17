//
//  EquitripField.swift
//  Equitrip
//

import SwiftUI

// MARK: - Text field

/// Labelled field with an animated focus ring, matching the card surfaces.
struct EquitripField<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme

    let label: String
    let placeholder: String
    @Binding var text: String

    var isSecure: Bool = false
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .next

    /// Shared focus binding so the parent can drive field-to-field submission.
    @FocusState.Binding var focus: Value?
    let field: Value
    var onSubmit: () -> Void = {}

    @State private var isRevealed = false

    private var isFocused: Bool { focus == field }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(isFocused ? AppTheme.accent : AppTheme.inkSecondary)

            HStack(spacing: 11) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboard == .emailAddress)
                .focused($focus, equals: field)
                .submitLabel(submitLabel)
                .onSubmit(onSubmit)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.inkTertiary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15)
            .frame(height: 54)
            .background(AppTheme.card, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isFocused ? AppTheme.accent : AppTheme.cardStroke.opacity(scheme == .dark ? 0.12 : 0.07),
                        lineWidth: isFocused ? 1.6 : 1
                    )
            }
            .shadow(color: AppTheme.softShadow(scheme), radius: isFocused ? 12 : 6, y: isFocused ? 5 : 3)
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

// MARK: - Shake

/// Horizontal shake for rejected input. Driven by incrementing an integer, so
/// each failed attempt animates even when the error text is unchanged.
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 7
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

extension View {
    func shake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}
