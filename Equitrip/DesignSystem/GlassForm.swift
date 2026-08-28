//
//  GlassForm.swift
//  Equitrip
//

import SwiftUI

// MARK: - Panel

/// The pane the creation flow's controls sit on.
///
/// Deliberately *not* Liquid Glass. Glass is a backdrop filter, and these
/// panels appear dozens at a time — one per field, one per chip, one per row
/// in a `ForEach` — which is exactly the case Apple warns against and which
/// made the split picker visibly stutter on every tap. Glass stays on the
/// navigation layer, where there are a handful of it: bars, floating buttons,
/// the tab bar. Here a flat translucent fill costs nothing and reads the same
/// against the canvas.
struct PanelSurface: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    var corner: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                AppTheme.card.opacity(scheme == .dark ? 0.55 : 0.7),
                in: .rect(cornerRadius: corner, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(scheme == .dark ? 0.10 : 0.06))
            }
    }
}

extension View {
    func panelSurface(corner: CGFloat = 20) -> some View {
        modifier(PanelSurface(corner: corner))
    }
}

// MARK: - Field

/// Labelled text field on glass. Deliberately quieter than `EquitripField`
/// from the auth screens — there the field is the whole page, here it's one
/// row of many.
struct GlassField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String

    var symbol: String?
    var keyboard: UIKeyboardType = .default
    var autocapitalisation: TextInputAutocapitalization = .words

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isFocused ? AppTheme.accent : AppTheme.inkSecondary)

            HStack(spacing: 10) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.inkTertiary)
                        .frame(width: 18)
                }

                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.ink)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalisation)
                    .focused($isFocused)
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .panelSurface(corner: 16)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppTheme.accent, lineWidth: isFocused ? 1.6 : 0)
            }
        }
        .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}

// MARK: - Rows

/// Read-out row that opens something — a picker, a sheet, a detail screen.
struct GlassRow<Trailing: View>: View {
    let label: String
    var symbol: String?
    var action: (() -> Void)?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        let content = HStack(spacing: 11) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.inkTertiary)
                    .frame(width: 18)
            }

            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.ink)

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .contentShape(.rect)

        if let action {
            Button(action: action) { content }
                .buttonStyle(PressableButtonStyle())
        } else {
            content
        }
    }
}

// MARK: - Segmented picker

/// Glass segmented control with a sliding selection. Used where the options
/// are few enough to show at once and the choice changes what's below it.
struct GlassSegments<Value: Hashable>: View {
    @Namespace private var namespace

    let options: [(value: Value, label: String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                let isSelected = option.value == selection

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                        selection = option.value
                    }
                } label: {
                    Text(option.label)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.ctaLabel : AppTheme.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppTheme.cta)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .panelSurface(corner: 22)
    }
}

// MARK: - Chips

/// Removable participant chip.
struct TravellerChip: View {
    let traveller: Traveller
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 7) {
            MemojiAvatar(traveller: traveller, size: 24)

            Text(traveller.name)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(AppTheme.ink)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppTheme.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 5)
        .padding(.trailing, onRemove == nil ? 11 : 9)
        .padding(.vertical, 5)
        .panelSurface(corner: 18)
    }
}

// MARK: - Flowing layout

/// Wraps children onto as many rows as they need. Participant chips and split
/// options are both variable-width and unpredictable in count, which is
/// exactly what `HStack` can't handle.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews, in: width)
        let height = rows.reduce(0) { $0 + $1.height } + rowSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in arrange(subviews, in: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width

            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
