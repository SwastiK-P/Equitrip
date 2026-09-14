//
//  CodeSlotsField.swift
//  Equitrip
//

import SwiftUI

/// One box per character of an invite code.
///
/// A single text field can hold a code, but it can't tell you how long the
/// code is before you've typed it — six boxes and a dash say "six characters,
/// grouped like the card" at a glance, and each one that fills is a small
/// piece of progress. The real field is still a `TextField`: it's stretched
/// invisibly over the boxes so the system keyboard, caret placement, paste and
/// dictation all keep working, and the boxes are only a rendering of its text.
struct CodeSlotsField: View {
    @Binding var text: String

    /// Total characters, ignoring the grouping dash.
    var length: Int = 6
    /// Where the dash sits. `nil` for an ungrouped code.
    var groupAfter: Int? = 3
    var onSubmit: () -> Void = {}
    /// Owned by the caller so the surrounding flow can dismiss the keyboard
    /// (and re-focus after a failed lookup) without reaching inside.
    var isFocused: FocusState<Bool>.Binding

    private var focused: Bool { isFocused.wrappedValue }
    /// Drives the caret blink, started only while focused so an idle screen
    /// isn't animating.
    @State private var caretOn = true

    /// The typed characters, dash stripped — the boxes index into this.
    private var characters: [Character] { Array(text.filter { $0 != "-" }.prefix(length)) }

    private var cursor: Int { min(characters.count, length - 1) }

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { index in
                    slot(index)

                    if let groupAfter, index == groupAfter - 1 {
                        Rectangle()
                            .fill(AppTheme.inkTertiary.opacity(0.5))
                            .frame(width: 10, height: 2)
                            .padding(.horizontal, 2)
                    }
                }
            }
            .allowsHitTesting(false)

            // The actual input, invisible but live. Kept full-width so a tap
            // anywhere along the row focuses it.
            TextField("", text: $text)
                .font(.system(size: 1))
                .tint(.clear)
                .foregroundStyle(.clear)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textContentType(.oneTimeCode)
                .keyboardType(.asciiCapable)
                .submitLabel(.go)
                .onSubmit(onSubmit)
                .focused(isFocused)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .frame(height: 62)
        .contentShape(.rect)
        .onTapGesture { isFocused.wrappedValue = true }
        .onChange(of: characters.count) { old, new in
            // A light tick per character, and a firmer one when the last box
            // fills — the code is complete, and that's worth feeling.
            if new > old {
                UIImpactFeedbackGenerator(style: new == length ? .medium : .light)
                    .impactOccurred()
            }
        }
        .onChange(of: focused) { _, isFocused in
            caretOn = true
            guard isFocused else { return }
            withAnimation(.easeInOut(duration: 0.55).repeatForever()) { caretOn = false }
        }
    }

    // MARK: - Slot

    private func slot(_ index: Int) -> some View {
        let character = index < characters.count ? characters[index] : nil
        let isCursor = focused && index == cursor && characters.count < length
        let isFilledCursor = focused && characters.count == length && index == length - 1

        return ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card.opacity(character == nil ? 0.55 : 0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            isCursor || isFilledCursor
                                ? AppTheme.accent.opacity(0.85)
                                : AppTheme.cardStroke.opacity(character == nil ? 0.08 : 0.14),
                            lineWidth: isCursor || isFilledCursor ? 1.8 : 1
                        )
                }
                // The active box lifts slightly out of the row, so the eye
                // finds where the next character lands without reading.
                .shadow(
                    color: AppTheme.accent.opacity(isCursor ? 0.22 : 0),
                    radius: 10, y: 4
                )
                .scaleEffect(isCursor ? 1.04 : 1)

            if let character {
                Text(String(character))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .id(character)
                    // Dropped in from just above rather than blinking into
                    // place: typed characters arrive.
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.55)
                                .combined(with: .offset(y: -10))
                                .combined(with: .opacity),
                            removal: .scale(scale: 0.7)
                                .combined(with: .offset(y: 8))
                                .combined(with: .opacity)
                        )
                    )
            } else if isCursor {
                Capsule()
                    .fill(AppTheme.accent)
                    .frame(width: 2, height: 24)
                    .opacity(caretOn ? 1 : 0)
            }
        }
        .frame(width: 44, height: 54)
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: characters.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: focused)
    }
}
