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
    static let canvasTop = Brand.canvasTop
    static let canvasBottom = Brand.canvasBottom

    static let card = Brand.card
    static let cardStroke = Brand.cardStroke

    // MARK: - Content

    static let ink = Brand.ink
    static let inkSecondary = Brand.inkSecondary
    static let inkTertiary = Brand.inkTertiary

    // MARK: - Accent

    /// Indigo, not green — it separates cleanly from the peach canvas without
    /// sitting in the same hue family, and keeps money colour semantic-free.
    static let accent = Brand.accent
    static let accentDeep = Brand.accentDeep

    static let cta = Brand.cta
    static let ctaLabel = Brand.ctaLabel

    static let danger = Brand.danger

    // MARK: - Money

    /// Direction, not sentiment: owed-to-you rides the accent, owed-by-you the
    /// danger red. Anything square is deliberately neutral.
    static var moneyIn: Color { accent }
    static var moneyOut: Color { danger }
    static var moneyFlat: Color { inkSecondary }

    static let positive = Brand.positive

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
        Brand.display(size, weight: weight)
    }

    // MARK: - Helpers

    /// Kept as the app-side spelling of `Brand.dynamic` — the avatar
    /// palettes below and a handful of one-off tints still build colours that
    /// have no business being brand tokens.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Brand.dynamic(light: light, dark: dark)
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
    static let blue = Brand.blue
    static let teal = Brand.teal
    static let indigo = Brand.indigo
    static let violet = Brand.violet
    static let green = Brand.green
    static let amber = Brand.amber
    static let stone = Brand.stone

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


