//
//  Brand.swift
//  Equitrip
//

import SwiftUI

/// The palette, in the one place both the app and its widgets can read it.
///
/// `AppTheme` used to hold these literals directly, which was fine while the
/// app was the only thing drawing them. A widget runs in a separate process
/// built from a separate target, so it either shares this file or keeps a
/// second copy of every hex value — and a second copy is a palette that drifts
/// the first time somebody warms the peach by two points and only remembers
/// the screen they were looking at. `AppTheme` now aliases these, so nothing
/// on the app side changes name or meaning.
enum Brand {

    // MARK: Surfaces

    /// A single peach hue carried top-to-bottom — the gradient is the same
    /// colour deepening, never a second hue blended in.
    static let canvasTop = dynamic(light: 0xFFF9F5, dark: 0x100D0B)
    static let canvasBottom = dynamic(light: 0xF8E4D5, dark: 0x1B1512)

    static let card = dynamic(light: 0xFFFFFF, dark: 0x221B17)
    static let cardStroke = dynamic(light: 0x2A1810, dark: 0xFFFFFF)

    // MARK: Content

    static let ink = dynamic(light: 0x1A1109, dark: 0xF7F3F0)
    static let inkSecondary = dynamic(light: 0x6B5B50, dark: 0xB0A49B)
    static let inkTertiary = dynamic(light: 0x9C8B7F, dark: 0x7D7169)

    // MARK: Accent

    /// Indigo, not green — it separates cleanly from the peach canvas without
    /// sitting in the same hue family, and keeps money colour semantic-free.
    static let accent = dynamic(light: 0x4B45C6, dark: 0x9A93FF)
    static let accentDeep = dynamic(light: 0x3A34A8, dark: 0x7C74F0)

    static let cta = dynamic(light: 0x21150D, dark: 0xF7F3F0)
    static let ctaLabel = dynamic(light: 0xFFFFFF, dark: 0x21150D)

    static let danger = dynamic(light: 0xC5442E, dark: 0xF08A72)
    static let positive = dynamic(light: 0x1E7A55, dark: 0x66D2A4)

    // MARK: Category tints

    static let blue = dynamic(light: 0x2F6FED, dark: 0x5E9BFF)
    static let teal = dynamic(light: 0x0E7490, dark: 0x3FB6CE)
    static let indigo = dynamic(light: 0x4B45C6, dark: 0x9A93FF)
    static let violet = dynamic(light: 0x7C4DE0, dark: 0xA98BF5)
    static let green = dynamic(light: 0x1E7A55, dark: 0x66D2A4)
    static let amber = dynamic(light: 0xD97706, dark: 0xF0A93C)
    static let stone = dynamic(light: 0x6B5B50, dark: 0xB0A49B)

    // MARK: Type

    /// The display face, used only for names of places and trips.
    ///
    /// One serif against an otherwise all-sans interface, so a trip title
    /// reads as the name of somewhere rather than another label. Everything
    /// around it — regions, counts, money — stays in the system sans, which is
    /// what makes the contrast do any work.
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    // MARK: Helpers

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(watchOS)
        // watchOS has no dynamic-provider `UIColor` and no light appearance
        // to provide for — the watch face is always dark, so the dark value
        // is the only one that can ever be right.
        Color(uiColor: UIColor(brandRGB: dark))
        #else
        Color(uiColor: UIColor { trait in
            UIColor(brandRGB: trait.userInterfaceStyle == .dark ? dark : light)
        })
        #endif
    }
}

private extension UIColor {
    convenience init(brandRGB rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
