//
//  TripTitleStyle.swift
//  EquitripShared
//

import SwiftUI

/// The typeface a trip's name is set in, chosen by whoever organises it.
///
/// A trip title is the one piece of type in the app that names a *place*
/// rather than labelling a control, and places have characters: a ski week
/// wants something different from a wedding in Udaipur. So the name gets a
/// wordmark, the way an artist page does, and everything around it stays in
/// the system sans.
///
/// Shared, not app-only: the watch draws the same trip name on its trip
/// page, and a title that changes typeface between the wrist and the phone
/// reads as a different trip.
///
/// Only faces that ship with iOS — nothing to bundle, license or download —
/// and each one carries its own size correction, tracking and case, because
/// "46pt" in Snell Roundhand and "46pt" in Futura Condensed are not the same
/// visual size, and a wide-tracked uppercase title needs less of it.
nonisolated enum TripTitleStyle: String, CaseIterable, Identifiable, Codable {
    case classic, bold, airy, poster, clean, script, typewriter

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Classic"
        case .bold: "Bold"
        case .airy: "Airy"
        case .poster: "Poster"
        case .clean: "Clean"
        case .script: "Script"
        case .typewriter: "Typewriter"
        }
    }

    /// Unknown or missing values — older rows, or a style since removed —
    /// read as the original serif.
    init(stored: String?) {
        self = stored.flatMap(Self.init(rawValue:)) ?? .classic
    }

    func font(_ size: CGFloat) -> Font {
        switch self {
        // `Brand.display` in every other word, spelled out here because this
        // enum is nonisolated and `Brand` is not.
        case .classic: .system(size: size, weight: .bold, design: .serif)
        case .bold: .system(size: size * 1.02, weight: .black).italic()
        case .airy: .system(size: size * 0.8, weight: .regular).width(.condensed)
        case .poster: .custom("Futura-CondensedExtraBold", fixedSize: size * 0.98)
        case .clean: .system(size: size * 0.96, weight: .bold)
        case .script: .custom("SnellRoundhand-Black", fixedSize: size * 1.08)
        case .typewriter: .custom("AmericanTypewriter-Semibold", fixedSize: size * 0.86)
        }
    }

    /// Tracking as a fraction of the point size, so it scales with the title.
    func tracking(_ size: CGFloat) -> CGFloat {
        switch self {
        case .bold: -size * 0.035
        case .airy: size * 0.22
        case .poster: size * 0.01
        default: 0
        }
    }

    var isUppercased: Bool {
        switch self {
        case .airy, .poster: true
        default: false
        }
    }
}

extension View {
    /// Sets a trip's name in its chosen style. Use on trip titles only — the
    /// rest of the app's type is deliberately the system sans.
    func tripTitle(_ style: TripTitleStyle, size: CGFloat) -> some View {
        font(style.font(size))
            .tracking(style.tracking(size))
            .textCase(style.isUppercased ? .uppercase : nil)
    }
}
