//
//  OpenMeteoCache.swift
//  Equitrip
//

import CryptoKit
import Foundation

/// Open-Meteo responses kept on disk, keyed by request.
///
/// Every open of the Weather Twin used to refetch everything — forecast,
/// ensemble, history, flood and air for each place — and the free tier's
/// per-IP daily limit ran out after a day of use ("Daily API request limit
/// exceeded"). Most of that barely changes: an hour-old forecast is still the
/// forecast, and last week's observed rain never changes. Lives in Caches, so
/// the system may clear it; nothing depends on it being there.
enum OpenMeteoCache {

    /// How long an answer is served without asking again, by endpoint.
    static func lifetime(for what: String) -> TimeInterval {
        switch what {
        case "forecast": 30 * 60
        case "ensemble": 3 * 3600
        case "air quality": 3600
        case "flood outlook": 12 * 3600
        // Observed and year-ago history don't change once recorded.
        case "history": 7 * 86_400
        default: 3600
        }
    }

    static func read(_ url: URL, maxAge: TimeInterval) -> Data? {
        let file = path(for: url)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
              let modified = attributes[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) <= maxAge
        else { return nil }
        return try? Data(contentsOf: file)
    }

    static func write(_ data: Data, for url: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: path(for: url), options: .atomic)
    }

    private static let directory = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("OpenMeteo", isDirectory: true)

    /// The key leaves out `apikey`, so adding a paid key keeps what's cached.
    private static func path(for url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems?.removeAll { $0.name == "apikey" }
        let host = components?.host?.replacingOccurrences(of: "customer-", with: "")
        components?.host = host
        let key = components?.url?.absoluteString ?? url.absoluteString
        let digest = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(digest + ".json")
    }
}
