//
//  SocialSignal.swift
//  Equitrip
//

import SwiftUI

/// One public post, article or official alert about the weather where the
/// trip is — with who said it, where, and a link back to it.
///
/// Attribution is not decoration here. The twin raises a booking's risk when
/// people on the ground report a flooded road, so every report it acts on
/// has to be one a traveller can open and read for themselves.
struct SocialSignal: Identifiable, Hashable, Codable {
    enum Source: String, Codable, Hashable, CaseIterable {
        case bluesky, mastodon, news, ndma, gdacs

        var label: String {
            switch self {
            case .bluesky: "Bluesky"
            case .mastodon: "Mastodon"
            case .news: "News"
            case .ndma: "NDMA Sachet"
            case .gdacs: "GDACS"
            }
        }

        /// Official feeds outrank a post, in the digest and in the model.
        var isOfficial: Bool { self == .ndma || self == .gdacs }

        var symbol: String {
            switch self {
            case .bluesky: "bubble.left.and.text.bubble.right.fill"
            case .mastodon: "bubble.left.fill"
            case .news: "newspaper.fill"
            case .ndma: "exclamationmark.shield.fill"
            case .gdacs: "globe.badge.chevron.backward"
            }
        }

        var tint: Color {
            switch self {
            case .bluesky: Palette.blue
            case .mastodon: Palette.indigo
            case .news: Palette.stone
            case .ndma: AppTheme.danger
            case .gdacs: Palette.amberDeep
            }
        }

        /// How much one of these moves the twin, before severity.
        var weight: Double {
            switch self {
            case .ndma, .gdacs: 1.0
            case .news: 0.7
            case .bluesky, .mastodon: 0.45
            }
        }
    }

    /// What a report is about, in the terms the twin reasons in.
    enum Category: String, Codable, Hashable, CaseIterable {
        case flooding, heavyRain, storm, heat, transport, closure, airQuality, allClear

        var label: String {
            switch self {
            case .flooding: "Flooding"
            case .heavyRain: "Heavy rain"
            case .storm: "Storm & wind"
            case .heat: "Heat"
            case .transport: "Travel disruption"
            case .closure: "Closures"
            case .airQuality: "Air quality"
            case .allClear: "All clear"
            }
        }

        var symbol: String {
            switch self {
            case .flooding: "water.waves"
            case .heavyRain: "cloud.heavyrain.fill"
            case .storm: "wind"
            case .heat: "thermometer.sun.fill"
            case .transport: "car.side.rear.and.collision.and.car.side.front"
            case .closure: "xmark.octagon.fill"
            case .airQuality: "aqi.high"
            case .allClear: "checkmark.seal.fill"
            }
        }

        var tint: Color {
            switch self {
            case .flooding: Palette.teal
            case .heavyRain: Palette.blue
            case .storm: Palette.indigo
            case .heat: Palette.amberDeep
            case .transport: AppTheme.danger
            case .closure: AppTheme.danger
            case .airQuality: Palette.stone
            case .allClear: AppTheme.positive
            }
        }
    }

    let id: String
    let source: Source
    /// A display name, a handle, or a publisher's domain.
    let author: String
    let handle: String?
    let text: String
    let url: URL?
    let postedAt: Date
    /// Likes plus reposts, where the network counts them.
    let engagement: Int
    /// The place named in the text that tied it to this trip — required: a
    /// report that doesn't name somewhere on the trip isn't evidence for it.
    var place: String
    var category: Category
    /// 0–1: how bad the reported conditions are.
    var severity: Double
    /// Whether the on-device model read it, or only the keyword rules.
    var readByModel: Bool

    /// How old, as people say it.
    var age: String {
        let minutes = Int(Date().timeIntervalSince(postedAt) / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }

    /// Recency-weighted strength: a report fades over a day and a half.
    var strength: Double {
        let hours = max(0, Date().timeIntervalSince(postedAt) / 3600)
        let freshness = exp(-hours / 36)
        let reach = 1 + min(0.5, log10(Double(max(engagement, 1))) / 6)
        return severity * source.weight * freshness * reach
    }
}
