//
//  RiskLevel.swift
//  Equitrip
//

import SwiftUI

/// How worried to be, in four steps — the one scale every weather surface
/// in the app shares, so a chip on the timeline and the banner on the twin
/// can't disagree about what "amber" means.
enum RiskLevel: Int, Comparable, Hashable, CaseIterable, Codable {
    case calm, watch, warning, severe

    init(probability p: Double) {
        switch p {
        case ..<0.15: self = .calm
        case ..<0.35: self = .watch
        case ..<0.6: self = .warning
        default: self = .severe
        }
    }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .calm: "On track"
        case .watch: "Worth watching"
        case .warning: "Likely disrupted"
        case .severe: "At serious risk"
        }
    }

    /// One word, for chips.
    var short: String {
        switch self {
        case .calm: "Clear"
        case .watch: "Watch"
        case .warning: "Warning"
        case .severe: "Severe"
        }
    }

    var symbol: String {
        switch self {
        case .calm: "checkmark.circle.fill"
        case .watch: "eye.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .severe: "exclamationmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .calm: AppTheme.positive
        case .watch: Palette.amber
        case .warning: Palette.amberDeep
        case .severe: AppTheme.danger
        }
    }

    /// Whether a surface should speak up at all. Calm stays quiet.
    var isNotable: Bool { self >= .watch }
}
