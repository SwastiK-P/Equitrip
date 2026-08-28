//
//  AppTheme.swift
//  Equitrip
//

import SwiftUI

/// Central palette + elevation tokens so screens stay visually consistent.
enum AppTheme {

    // MARK: - Surfaces

    /// A single peach hue carried top-to-bottom — the gradient is the same
    /// colour deepening, never a second hue blended in.
    static let canvasTop = dynamic(light: 0xFFF9F5, dark: 0x100D0B)
    static let canvasBottom = dynamic(light: 0xF8E4D5, dark: 0x1B1512)

    static let card = dynamic(light: 0xFFFFFF, dark: 0x221B17)
    static let cardStroke = dynamic(light: 0x2A1810, dark: 0xFFFFFF)

    // MARK: - Content

    static let ink = dynamic(light: 0x1A1109, dark: 0xF7F3F0)
    static let inkSecondary = dynamic(light: 0x6B5B50, dark: 0xB0A49B)
    static let inkTertiary = dynamic(light: 0x9C8B7F, dark: 0x7D7169)

    // MARK: - Accent

    /// Indigo, not green — it separates cleanly from the peach canvas without
    /// sitting in the same hue family, and keeps money colour semantic-free.
    static let accent = dynamic(light: 0x4B45C6, dark: 0x9A93FF)
    static let accentDeep = dynamic(light: 0x3A34A8, dark: 0x7C74F0)

    static let cta = dynamic(light: 0x21150D, dark: 0xF7F3F0)
    static let ctaLabel = dynamic(light: 0xFFFFFF, dark: 0x21150D)

    static let danger = dynamic(light: 0xC5442E, dark: 0xF08A72)

    // MARK: - Money

    /// Direction, not sentiment: owed-to-you rides the accent, owed-by-you the
    /// danger red. Anything square is deliberately neutral.
    static var moneyIn: Color { accent }
    static var moneyOut: Color { danger }
    static var moneyFlat: Color { inkSecondary }

    static let positive = dynamic(light: 0x1E7A55, dark: 0x66D2A4)

    // MARK: - Elevation

    /// Warm-tinted rather than neutral grey, so shadows sit in the peach canvas
    /// instead of greying it out.
    static func softShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black.opacity(0.55) : Color(red: 0.35, green: 0.20, blue: 0.10).opacity(0.11)
    }

    // MARK: - Type

    /// The display face, used only for names of places and trips.
    ///
    /// One serif against an otherwise all-sans interface, so a trip title
    /// reads as the name of somewhere rather than another label. Everything
    /// around it — regions, counts, money — stays in the system sans, which is
    /// what makes the contrast do any work.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // MARK: - Helpers

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { trait in
            UIColor(rgb: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - Named palette

/// Every non-semantic colour in the app, allocated once.
///
/// This exists because `AppTheme.dynamic` builds a fresh
/// `UIColor(dynamicProvider:)` on each call. Reading one from a computed
/// `var tint: Color` therefore allocated a new colour for every chip on every
/// body pass — which both cost real time and defeated SwiftUI's equality
/// check, so views redrew that didn't need to. Hoisting them to `static let`
/// makes each one a single shared instance.
enum Palette {
    static let blue = AppTheme.dynamic(light: 0x2F6FED, dark: 0x5E9BFF)
    static let teal = AppTheme.dynamic(light: 0x0E7490, dark: 0x3FB6CE)
    static let indigo = AppTheme.dynamic(light: 0x4B45C6, dark: 0x9A93FF)
    static let violet = AppTheme.dynamic(light: 0x7C4DE0, dark: 0xA98BF5)
    static let green = AppTheme.dynamic(light: 0x1E7A55, dark: 0x66D2A4)
    static let amber = AppTheme.dynamic(light: 0xD97706, dark: 0xF0A93C)
    static let stone = AppTheme.dynamic(light: 0x6B5B50, dark: 0xB0A49B)

    /// Slightly muted variants, for solid tiles where the bright tone shouts.
    static let greenDeep = AppTheme.dynamic(light: 0x1E7A55, dark: 0x2E9C72)
    static let amberDeep = AppTheme.dynamic(light: 0xD97706, dark: 0xC98A2E)
    static let violetDeep = AppTheme.dynamic(light: 0x7C4DE0, dark: 0x6B45C0)
}

// MARK: - Avatar palettes

/// Pastel bubbles for participant avatars — deliberately varied so a group
/// cluster reads as distinct people rather than a repeated glyph.
struct AvatarPalette {
    let fill: Color
    let label: Color

    static let all: [AvatarPalette] = [
        .init(fill: AppTheme.dynamic(light: 0xD9F2E4, dark: 0x1E4438), label: AppTheme.dynamic(light: 0x0C6B49, dark: 0x7FE8C0)),
        .init(fill: AppTheme.dynamic(light: 0xE6E2FB, dark: 0x2B2650), label: AppTheme.dynamic(light: 0x4A3AA8, dark: 0xBDB3FF)),
        .init(fill: AppTheme.dynamic(light: 0xFCE3DC, dark: 0x4A2A22), label: AppTheme.dynamic(light: 0xB2472B, dark: 0xFFB39B)),
        .init(fill: AppTheme.dynamic(light: 0xD9EBFB, dark: 0x1D3550), label: AppTheme.dynamic(light: 0x1F5E96, dark: 0x93C7F5)),
        .init(fill: AppTheme.dynamic(light: 0xFBE0EC, dark: 0x47223A), label: AppTheme.dynamic(light: 0xA83C6D, dark: 0xF7A3C8)),
        .init(fill: AppTheme.dynamic(light: 0xF6EBD5, dark: 0x453820), label: AppTheme.dynamic(light: 0x8A6420, dark: 0xE7C382)),
        .init(fill: AppTheme.dynamic(light: 0xDFF0D8, dark: 0x27401F), label: AppTheme.dynamic(light: 0x4C7A32, dark: 0xAEDD96)),
        .init(fill: AppTheme.dynamic(light: 0xE2E8F0, dark: 0x2A3140), label: AppTheme.dynamic(light: 0x475569, dark: 0xC3CDDB))
    ]

    static func at(_ index: Int) -> AvatarPalette { all[index % all.count] }
}

// MARK: - UIColor hex

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
