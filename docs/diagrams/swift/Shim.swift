// Render-only stand-in for the app's DesignSystem (light mode), so the
// component file compiles unchanged on macOS. Not shipped.

import SwiftUI

enum AppTheme {
    static let canvasTop = hex(0xFFF9F5)
    static let canvasBottom = hex(0xF8E4D5)
    static let card = hex(0xFFFFFF)
    static let cardStroke = hex(0x2A1810)
    static let ink = hex(0x1A1109)
    static let inkSecondary = hex(0x6B5B50)
    static let inkTertiary = hex(0x9C8B7F)
    static let accent = hex(0x4B45C6)
    static let cta = hex(0x21150D)
    static let ctaLabel = hex(0xFFFFFF)
    static let positive = hex(0x1E7A55)
    static let danger = hex(0xC5442E)

    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func softShadow() -> Color {
        Color(red: 0.35, green: 0.20, blue: 0.10).opacity(0.11)
    }

    static func hex(_ rgb: UInt32) -> Color {
        Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

enum Palette {
    static let blue = AppTheme.hex(0x2F6FED)
    static let stone = AppTheme.hex(0x6B5B50)
    static let violet = AppTheme.hex(0x7C4DE0)
    static let amber = AppTheme.hex(0xD97706)
    static let green = AppTheme.hex(0x1E7A55)
    static let indigo = AppTheme.hex(0x4B45C6)
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label }
}

struct CardSurface: ViewModifier {
    var corner: CGFloat = 20
    var shadow: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(AppTheme.card, in: .rect(cornerRadius: corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(AppTheme.cardStroke.opacity(0.045))
            }
            .shadow(color: AppTheme.softShadow(), radius: shadow, y: shadow * 0.35)
    }
}

extension View {
    func cardSurface(corner: CGFloat = 20, shadow: CGFloat = 10) -> some View {
        modifier(CardSurface(corner: corner, shadow: shadow))
    }
}

struct Hairline: View {
    var inset: CGFloat = 0
    var body: some View {
        Rectangle()
            .fill(AppTheme.cardStroke.opacity(0.07))
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

struct TagChip: View {
    let title: String
    var tint: Color = AppTheme.accent
    var symbol: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(tint.opacity(0.13), in: .capsule)
    }
}
