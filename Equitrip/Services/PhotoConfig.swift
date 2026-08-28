//
//  PhotoConfig.swift
//  Equitrip
//

import Foundation

/// Where to get destination photography.
///
/// Drop a key into whichever service you have an account with and it starts
/// working — no other change needed. Both are free tiers; Unsplash tends to
/// have the better travel library, Pexels the more generous rate limit.
///
///   Unsplash → https://unsplash.com/oauth/applications (use the *Access Key*)
///   Pexels   → https://www.pexels.com/api/
///
/// Leave both empty and the app falls back to generated gradient covers, so
/// nothing in the trip flow breaks on a machine that hasn't been set up.
enum PhotoConfig {
    static let unsplashAccessKey = "C5HpZEk73VjKlSPXzgNXFmgcVGhR1xxQpBWUQmXXQ6Y"
    static let pexelsAPIKey = ""

    enum Provider {
        case unsplash(String)
        case pexels(String)
    }

    static var provider: Provider? {
        if !unsplashAccessKey.isEmpty { return .unsplash(unsplashAccessKey) }
        if !pexelsAPIKey.isEmpty { return .pexels(pexelsAPIKey) }
        return nil
    }
}
