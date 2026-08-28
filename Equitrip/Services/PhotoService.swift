//
//  PhotoService.swift
//  Equitrip
//

import SwiftUI

/// Where destination and activity photography comes from.
///
/// Unsplash first, Pexels as the alternate — both are configured by dropping
/// a key into `PhotoConfig`. With no key at all the app still works: callers
/// fall back to a generated gradient, so the flow never blocks on a network
/// service a demo machine might not have set up.
@MainActor
@Observable
final class PhotoService {
    static let shared = PhotoService()

    /// Query → resolved photo. Keeps a scrolling list from re-requesting the
    /// same beach twelve times, and keeps covers stable between screens.
    private var cache: [String: TripPhoto] = [:]
    private var inFlight: [String: Task<TripPhoto?, Never>] = [:]

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 120 * 1024 * 1024
        )
        // Photos are immutable once published, so serve from cache when we can
        // and only hit the network on a miss.
        configuration.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: configuration)
    }

    /// Whether a *premium* provider is configured. Wikimedia runs regardless —
    /// this only gates whether the better-credentialed sources are also tried.
    var isConfigured: Bool { PhotoConfig.provider != nil }

    func cached(_ query: String) -> TripPhoto? { cache[normalise(query)] }

    /// Resolves a photo for a place. Concurrent callers for the same query
    /// share one request rather than racing.
    @discardableResult
    func photo(for query: String) async -> TripPhoto? {
        let key = normalise(query)
        guard !key.isEmpty else { return nil }
        if let hit = cache[key] { return hit }
        if let running = inFlight[key] { return await running.value }

        let task = Task<TripPhoto?, Never> { [weak self] in
            guard let self else { return nil }
            let photo = await self.fetch(key)
            if let photo { self.cache[key] = photo }
            self.inFlight[key] = nil
            return photo
        }
        inFlight[key] = task
        return await task.value
    }

    /// Several results for one query, so a person can pick rather than
    /// accept whatever `photo(for:)` decided was the best single match.
    /// Unsplash only — it's the source with results worth choosing between;
    /// Wikimedia's single-hit search has nothing to offer a grid.
    func search(_ query: String) async -> [TripPhoto] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, case .unsplash(let key) = PhotoConfig.provider else { return [] }
        return (try? await searchUnsplash(trimmed, key: key)) ?? []
    }

    // MARK: - Providers

    /// Unsplash or Pexels first when a key is configured — both have deeper,
    /// better-curated travel libraries. Wikimedia Commons is the fallback
    /// underneath *and* the zero-config default: it needs no key at all, so a
    /// freshly cloned build still shows real photographs instead of gradients.
    private func fetch(_ query: String) async -> TripPhoto? {
        if let provider = PhotoConfig.provider {
            do {
                let result: TripPhoto?
                switch provider {
                case .unsplash(let key): result = try await fetchUnsplash(query, key: key)
                case .pexels(let key): result = try await fetchPexels(query, key: key)
                }
                if let result { return result }
            } catch {
                // Fall through to Wikimedia below.
            }
        }

        return await fetchWikimedia(query)
    }

    /// No key, no signup — Wikimedia Commons' search API is open and
    /// CORS-enabled for exactly this kind of client-side lookup.
    private func fetchWikimedia(_ query: String) async -> TripPhoto? {
        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            .init(name: "action", value: "query"),
            .init(name: "generator", value: "search"),
            .init(name: "gsrsearch", value: "\(query) filetype:bitmap"),
            .init(name: "gsrlimit", value: "1"),
            .init(name: "gsrnamespace", value: "6"),
            .init(name: "prop", value: "imageinfo"),
            .init(name: "iiprop", value: "url|extmetadata"),
            .init(name: "iiurlwidth", value: "1200"),
            .init(name: "format", value: "json"),
            .init(name: "origin", value: "*")
        ]

        guard let url = components.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            let decoded = try JSONDecoder().decode(WikimediaSearch.self, from: data)
            guard let page = decoded.query?.pages.values.first,
                  let info = page.imageinfo?.first,
                  let imageURL = URL(string: info.thumburl ?? info.url) else { return nil }

            let credit = info.extmetadata?.artist?.value.strippingHTML ?? "Wikimedia contributors"

            return TripPhoto(
                url: imageURL,
                thumbURL: imageURL,
                photographer: credit,
                photographerURL: URL(string: "https://commons.wikimedia.org"),
                sourceName: "Wikimedia Commons"
            )
        } catch {
            return nil
        }
    }

    private func fetchUnsplash(_ query: String, key: String) async throws -> TripPhoto? {
        try await searchUnsplash(query, key: key, perPage: 1).first
    }

    private func searchUnsplash(_ query: String, key: String, perPage: Int = 20) async throws -> [TripPhoto] {
        var components = URLComponents(string: "https://api.unsplash.com/search/photos")!
        components.queryItems = [
            .init(name: "query", value: query),
            .init(name: "per_page", value: String(perPage)),
            .init(name: "orientation", value: "landscape"),
            .init(name: "content_filter", value: "high")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Client-ID \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

        let decoded = try JSONDecoder().decode(UnsplashSearch.self, from: data)
        // Unsplash's API terms require the photographer credit to be shown.
        return decoded.results.compactMap { hit in
            guard let url = URL(string: hit.urls.regular) else { return nil }
            return TripPhoto(
                url: url,
                thumbURL: URL(string: hit.urls.small),
                photographer: hit.user.name,
                photographerURL: URL(string: hit.user.links.html),
                sourceName: "Unsplash"
            )
        }
    }

    private func fetchPexels(_ query: String, key: String) async throws -> TripPhoto? {
        var components = URLComponents(string: "https://api.pexels.com/v1/search")!
        components.queryItems = [
            .init(name: "query", value: query),
            .init(name: "per_page", value: "1"),
            .init(name: "orientation", value: "landscape")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(key, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

        let decoded = try JSONDecoder().decode(PexelsSearch.self, from: data)
        guard let hit = decoded.photos.first, let url = URL(string: hit.src.large) else { return nil }

        return TripPhoto(
            url: url,
            thumbURL: URL(string: hit.src.medium),
            photographer: hit.photographer,
            photographerURL: URL(string: hit.photographerURL),
            sourceName: "Pexels"
        )
    }

    // MARK: - Helpers

    private func normalise(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

// MARK: - Wire formats

private struct UnsplashSearch: Decodable {
    struct Result: Decodable {
        struct URLs: Decodable { let regular: String; let small: String }
        struct User: Decodable {
            struct Links: Decodable { let html: String }
            let name: String
            let links: Links
        }
        let urls: URLs
        let user: User
    }
    let results: [Result]
}

private struct WikimediaSearch: Decodable {
    struct Query: Decodable { let pages: [String: Page] }
    struct Page: Decodable { let imageinfo: [ImageInfo]? }
    struct ImageInfo: Decodable {
        let url: String
        let thumburl: String?
        let extmetadata: ExtMetadata?
    }
    struct ExtMetadata: Decodable {
        let artist: MetadataValue?
    }
    struct MetadataValue: Decodable { let value: String }

    let query: Query?
}

private extension String {
    /// Wikimedia's artist field is often an HTML anchor; a plain photographer
    /// name reads better next to "Wikimedia Commons" than raw markup does.
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct PexelsSearch: Decodable {
    struct Photo: Decodable {
        struct Source: Decodable { let large: String; let medium: String }
        let src: Source
        let photographer: String
        let photographerURL: String

        enum CodingKeys: String, CodingKey {
            case src, photographer
            case photographerURL = "photographer_url"
        }
    }
    let photos: [Photo]
}
