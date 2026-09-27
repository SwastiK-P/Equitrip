//
//  SocialSignalService.swift
//  Equitrip
//

import Foundation

/// Collects what people, newsrooms and disaster agencies are publicly saying
/// about the weather where the trip is.
///
/// Five open sources, each chosen because it's free, keyless and attributable:
///
/// - **Bluesky** (`app.bsky.feed.searchPosts` on the public AppView) — traveller
///   and resident posts, searchable by text.
/// - **Mastodon** (mastodon.social tag timelines) — the same, by hashtag.
/// - **GDELT** (DOC 2.0 article list) — local and national news, by publisher.
/// - **NDMA Sachet** (India's Common Alerting Protocol feed) — official
///   warnings from IMD, CWC and the state disaster authorities.
/// - **GDACS** (UN/EC Global Disaster Alert and Coordination System) — cyclones,
///   floods and storms anywhere.
///
/// Reddit isn't here: its API now refuses unauthenticated clients. X isn't
/// either: search is paid. Nothing is sent to any of these beyond a place name
/// and a weather word; no account is involved. What comes back is raw — every
/// post still goes through `SignalReader`, which throws away most of it.
enum SocialSignalService {

    /// A post before anything has decided whether it matters.
    struct RawPost: Hashable {
        let id: String
        let source: SocialSignal.Source
        let author: String
        let handle: String?
        let text: String
        let url: URL?
        let postedAt: Date
        let engagement: Int
    }

    /// Everything the five sources have said in the last three days about any
    /// of `places` (most specific first — the city, then neighbourhoods).
    static func posts(about places: [String], near point: GeoPoint?) async -> [RawPost] {
        let names = Array(places.prefix(3))
        guard let primary = names.first else { return [] }

        async let bluesky = blueskyPosts(names)
        async let mastodon = mastodonPosts(names)
        async let news = gdeltArticles(primary)
        async let ndma = sachetAlerts()
        async let gdacs = gdacsEvents(near: point)

        let (a, b, c, d, e) = await (bluesky, mastodon, news, ndma, gdacs)
        var seen = Set<String>()
        return (a + b + c + d + e).filter { seen.insert($0.id).inserted }
    }

    // MARK: - Bluesky

    private static func blueskyPosts(_ places: [String]) async -> [RawPost] {
        var posts: [RawPost] = []
        let since = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3 * 86_400))
        for place in places.prefix(2) {
            for word in ["rain", "flood"] {
                var components = URLComponents(string: "https://api.bsky.app/xrpc/app.bsky.feed.searchPosts")!
                components.queryItems = [
                    URLQueryItem(name: "q", value: "\(place) \(word)"),
                    URLQueryItem(name: "sort", value: "latest"),
                    URLQueryItem(name: "lang", value: "en"),
                    URLQueryItem(name: "since", value: since),
                    URLQueryItem(name: "limit", value: "25")
                ]
                guard let json = await json(components.url!) as? [String: Any],
                      let list = json["posts"] as? [[String: Any]] else { continue }

                for post in list {
                    guard let uri = post["uri"] as? String,
                          let author = post["author"] as? [String: Any],
                          let record = post["record"] as? [String: Any],
                          let text = record["text"] as? String else { continue }
                    let handle = author["handle"] as? String ?? ""
                    let rkey = uri.split(separator: "/").last.map(String.init) ?? ""
                    let created = (record["createdAt"] as? String).flatMap(parseISO)
                        ?? (post["indexedAt"] as? String).flatMap(parseISO)
                        ?? Date()
                    let name = (author["displayName"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? handle
                    posts.append(RawPost(
                        id: "bsky:\(uri)",
                        source: .bluesky,
                        author: name,
                        handle: "@\(handle)",
                        text: text,
                        url: URL(string: "https://bsky.app/profile/\(handle)/post/\(rkey)"),
                        postedAt: created,
                        engagement: (post["likeCount"] as? Int ?? 0) + (post["repostCount"] as? Int ?? 0)
                    ))
                }
            }
        }
        return posts
    }

    // MARK: - Mastodon

    private static func mastodonPosts(_ places: [String]) async -> [RawPost] {
        var posts: [RawPost] = []
        let cutoff = Date().addingTimeInterval(-3 * 86_400)
        for place in places.prefix(2) {
            let slug = place.lowercased().filter { $0.isLetter || $0.isNumber }
            guard slug.count >= 3 else { continue }
            for tag in ["\(slug)rains", "\(slug)rain", "\(slug)weather", "\(slug)floods"] {
                let url = URL(string: "https://mastodon.social/api/v1/timelines/tag/\(tag)?limit=20")!
                guard let list = await json(url) as? [[String: Any]] else { continue }
                for status in list {
                    guard let id = status["id"] as? String,
                          let html = status["content"] as? String,
                          let created = (status["created_at"] as? String).flatMap(parseISO),
                          created >= cutoff else { continue }
                    if let language = status["language"] as? String, language != "en" { continue }
                    let account = status["account"] as? [String: Any] ?? [:]
                    let acct = account["acct"] as? String ?? ""
                    let name = (account["display_name"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? acct
                    posts.append(RawPost(
                        id: "masto:\(id)",
                        source: .mastodon,
                        author: name,
                        handle: "@\(acct)",
                        text: plainText(html),
                        url: (status["url"] as? String).flatMap(URL.init(string:)),
                        postedAt: created,
                        engagement: (status["favourites_count"] as? Int ?? 0) + (status["reblogs_count"] as? Int ?? 0)
                    ))
                }
            }
        }
        return posts
    }

    // MARK: - GDELT

    /// GDELT allows one request per five seconds per address — so one query,
    /// for the city, at most every refresh.
    private static var lastGDELT: Date?

    private static func gdeltArticles(_ place: String) async -> [RawPost] {
        if let lastGDELT, Date().timeIntervalSince(lastGDELT) < 6 { return [] }
        lastGDELT = Date()

        var components = URLComponents(string: "https://api.gdeltproject.org/api/v2/doc/doc")!
        components.queryItems = [
            URLQueryItem(name: "query", value: "\"\(place)\" (rain OR flood OR flooding OR waterlogging OR storm OR cyclone OR heatwave) sourcelang:english"),
            URLQueryItem(name: "mode", value: "artlist"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "maxrecords", value: "30"),
            URLQueryItem(name: "timespan", value: "3d"),
            URLQueryItem(name: "sort", value: "datedesc")
        ]
        guard let json = await json(components.url!) as? [String: Any],
              let articles = json["articles"] as? [[String: Any]] else { return [] }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"

        return articles.compactMap { article in
            guard let link = article["url"] as? String, let title = article["title"] as? String else { return nil }
            let domain = article["domain"] as? String ?? URL(string: link)?.host() ?? "News"
            return RawPost(
                id: "gdelt:\(link)",
                source: .news,
                author: domain.replacingOccurrences(of: "www.", with: ""),
                handle: nil,
                text: title,
                url: URL(string: link),
                postedAt: (article["seendate"] as? String).flatMap(formatter.date(from:)) ?? Date(),
                engagement: 0
            )
        }
    }

    // MARK: - NDMA Sachet

    /// India's all-hazard CAP feed. Public domain; titles are sometimes in
    /// Hindi or a regional language — those survive only if they name a place
    /// on the trip in Latin script, which `SignalReader` checks.
    private static func sachetAlerts() async -> [RawPost] {
        let url = URL(string: "https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml")!
        guard let data = await data(url) else { return [] }
        let items = RSSReader.items(in: data)
        let cutoff = Date().addingTimeInterval(-3 * 86_400)

        return items.compactMap { item in
            guard item.date >= cutoff else { return nil }
            // "controlroom@ndma.gov.in (IMD)" → "IMD"
            let agency = item.author
                .split(separator: "(").last?
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: .whitespaces)
            return RawPost(
                id: "ndma:\(item.guid.isEmpty ? item.link : item.guid)",
                source: .ndma,
                author: agency.map { "NDMA · \($0)" } ?? "NDMA",
                handle: nil,
                text: item.title,
                url: URL(string: item.link),
                postedAt: item.date,
                engagement: 0
            )
        }
    }

    // MARK: - GDACS

    private static func gdacsEvents(near point: GeoPoint?) async -> [RawPost] {
        guard let point else { return [] }
        let from = DateFormatter.cached("yyyy-MM-dd").string(from: Date().addingTimeInterval(-10 * 86_400))
        let to = DateFormatter.cached("yyyy-MM-dd").string(from: Date().addingTimeInterval(86_400))
        let url = URL(string: "https://www.gdacs.org/gdacsapi/api/events/geteventlist/SEARCH?eventlist=TC;FL;DR&fromDate=\(from)&toDate=\(to)")!
        guard let json = await json(url) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else { return [] }

        return features.compactMap { feature in
            guard let properties = feature["properties"] as? [String: Any],
                  let geometry = feature["geometry"] as? [String: Any],
                  let coordinates = geometry["coordinates"] as? [Double], coordinates.count >= 2 else { return nil }
            let at = GeoPoint(latitude: coordinates[1], longitude: coordinates[0])
            // Cyclones reach far; a flood or drought is only news nearby.
            let reach: Double = (properties["eventtype"] as? String) == "TC" ? 900 : 350
            guard at.distance(to: point) <= reach else { return nil }

            let text = (properties["htmldescription"] as? String).map(plainText)
                ?? properties["description"] as? String
                ?? properties["name"] as? String
                ?? "Disaster alert"
            let report = (properties["url"] as? [String: Any])?["report"] as? String
            let date = (properties["fromdate"] as? String).flatMap(parseISO) ?? Date()
            return RawPost(
                id: "gdacs:\((properties["eventid"] as? NSNumber)?.stringValue ?? text)",
                source: .gdacs,
                author: "GDACS · \((properties["alertlevel"] as? String) ?? "Alert")",
                handle: nil,
                text: text,
                url: report.flatMap(URL.init(string:)),
                postedAt: date,
                engagement: 0
            )
        }
    }

    // MARK: - Plumbing

    private static func data(_ url: URL) async -> Data? {
        var request = URLRequest(url: url, timeoutInterval: 12)
        request.setValue("Equitrip/1.0 (iOS; weather twin)", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }

    private static func json(_ url: URL) async -> Any? {
        guard let data = await data(url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private static func parseISO(_ string: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: string) { return date }
        let plain = ISO8601DateFormatter()
        if let date = plain.date(from: string) { return date }
        // GDACS writes local-less timestamps: "2026-09-22T00:00:00".
        let bare = DateFormatter()
        bare.locale = Locale(identifier: "en_US_POSIX")
        bare.timeZone = TimeZone(identifier: "UTC")
        bare.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return bare.date(from: string)
    }

    /// HTML to one line of text: tags out, the common entities decoded.
    static func plainText(_ html: String) -> String {
        var text = html.replacingOccurrences(of: "<br\\s*/?>|</p>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        for (entity, value) in ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&nbsp;": " "] {
            text = text.replacingOccurrences(of: entity, with: value)
        }
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// The few RSS 2.0 fields the Sachet feed carries.
nonisolated final class RSSReader: NSObject, XMLParserDelegate {
    struct Item {
        var title = ""
        var link = ""
        var author = ""
        var guid = ""
        var date = Date.distantPast
    }

    private var items: [Item] = []
    private var current: Item?
    private var text = ""

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return f
    }()

    static func items(in data: Data) -> [Item] {
        let reader = RSSReader()
        let parser = XMLParser(data: data)
        parser.delegate = reader
        parser.parse()
        return reader.items
    }

    func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if name == "item" { current = Item() }
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch name {
        case "title": current?.title = value
        case "link": current?.link = value
        case "author": current?.author = value
        case "guid": current?.guid = value
        case "pubDate": current?.date = Self.dateFormatter.date(from: value) ?? Date.distantPast
        case "item":
            if let current { items.append(current) }
            current = nil
        default: break
        }
    }
}
