//
//  SignalReader.swift
//  Equitrip
//

import Foundation
import FoundationModels

// MARK: - What the model is asked

@Generable
enum SignalTopic {
    case flooding
    case heavyRain
    case storm
    case heat
    case transport
    case closure
    case airQuality
    case allClear
    case notAWeatherReport
}

@Generable
enum SignalSeverity {
    case none, minor, moderate, severe, extreme
}

@Generable
struct SignalVerdict {
    @Guide(description: "The post's number, copied from the list.")
    var number: Int

    @Guide(description: "What the post reports about the weather or its effects on the ground. Use notAWeatherReport for anything else — music, jokes, ads, old memories, other places, or general chat that mentions rain.")
    var topic: SignalTopic

    @Guide(description: "How bad the conditions described are. none for all-clear or mild weather.")
    var severity: SignalSeverity
}

@Generable
struct SignalBatchReading {
    @Guide(description: "One entry per post, in the same order.")
    var verdicts: [SignalVerdict]
}

// MARK: - The pass

/// Decides which public posts are real reports about the weather where the
/// trip is, and what each one reports.
///
/// Same division as the booking reader: rules narrow, the model classifies,
/// Swift writes. A post survives the rules only if it names a place on the
/// trip (in Latin script, as a whole word) and uses a weather or disruption
/// word — "Goa" plus "rain" catches "goa trance – Acid Rain", which is why
/// there's a list of words that disqualify a post outright. What's left is
/// read by Apple Intelligence in batches of eight, choosing a topic and a
/// severity from fixed menus; the model never writes text anyone sees and
/// can't invent a place, because the place was matched before it looked.
/// Without Apple Intelligence (Simulator, older phones) the keyword reading
/// stands on its own.
enum SignalReader {

    private static let weatherWords = [
        "rain", "rains", "raining", "rainfall", "downpour", "monsoon", "shower", "drizzle", "cloudburst",
        "flood", "flooded", "flooding", "floods", "waterlog", "waterlogged", "waterlogging", "inundat",
        "storm", "cyclone", "thunder", "lightning", "gale", "gusty", "squall", "wind",
        "heat", "heatwave", "scorching", "temperature", "humid", "°c",
        "landslide", "orange alert", "red alert", "yellow alert", "imd", "warning", "alert",
        "traffic", "jam", "road closed", "roads closed", "closed", "shut", "suspended",
        "flight", "flights", "delayed", "delay", "cancelled", "canceled", "diverted", "airport",
        "ferry", "train", "trains", "local trains", "power cut", "outage", "aqi", "smog", "fog", "haze"
    ]

    private static let noiseWords = [
        "trance", "psytrance", "album", "remix", "track", "song", "lyrics", "playlist", "spotify",
        "giveaway", "nft", "crypto", "casino", "betting", "onlyfans", "#ad ", "sponsored",
        "throwback", "#tbt", "years ago", "anniversary", "movie", "trailer", "episode"
    ]

    /// Reads raw posts into signals about `places`. `primary` stands in for
    /// the place of an official alert that was matched by distance, not name.
    static func read(_ posts: [SocialSignalService.RawPost], places: [String], primary: String) async -> [SocialSignal] {
        var signals: [SocialSignal] = []

        for post in posts {
            let lower = post.text.lowercased()
            guard lower.count >= 18 else { continue }
            if noiseWords.contains(where: { lower.contains($0) }) { continue }

            let place: String? = post.source == .gdacs
                ? primary
                : places.first { mentions($0, in: lower) }
            guard let place else { continue }
            guard post.source.isOfficial || weatherWords.contains(where: { lower.contains($0) }) else { continue }

            let (category, severity) = keywordReading(lower)
            signals.append(SocialSignal(
                id: post.id,
                source: post.source,
                author: post.author,
                handle: post.handle,
                text: post.text,
                url: post.url,
                postedAt: post.postedAt,
                engagement: post.engagement,
                place: place,
                category: category,
                severity: severity,
                readByModel: false
            ))
        }

        signals.sort { $0.postedAt > $1.postedAt }
        return await refineWithModel(signals)
    }

    /// Whole-word match, so "Goa" doesn't match "goal" and "Pune" doesn't match "punet".
    static func mentions(_ place: String, in lower: String) -> Bool {
        let needle = place.lowercased()
        guard needle.count >= 3 else { return false }
        var range = lower.startIndex..<lower.endIndex
        while let hit = lower.range(of: needle, range: range) {
            let before = hit.lowerBound == lower.startIndex ? nil : lower[lower.index(before: hit.lowerBound)]
            let after = hit.upperBound == lower.endIndex ? nil : lower[hit.upperBound]
            let bounded = (before.map { !$0.isLetter } ?? true) && (after.map { !$0.isLetter } ?? true)
            if bounded { return true }
            range = hit.upperBound..<lower.endIndex
        }
        return false
    }

    // MARK: - Rules

    /// The keyword reading: good enough to stand alone, and the fallback the
    /// model's answer is checked against.
    static func keywordReading(_ lower: String) -> (SocialSignal.Category, Double) {
        func has(_ words: [String]) -> Bool { words.contains { lower.contains($0) } }

        let extreme = has(["red alert", "cyclone", "cloudburst", "landslide", "evacuat", "rescue", "stranded", "extremely heavy"])
        let strong = has(["orange alert", "heavy rain", "flooded", "waterlogged", "inundat", "severe", "very heavy", "suspended"])

        let category: SocialSignal.Category
        if has(["flood", "waterlog", "inundat", "submerged", "knee-deep", "waist-deep"]) {
            category = .flooding
        } else if has(["cyclone", "storm", "thunder", "lightning", "gale", "squall", "gusty"]) {
            category = .storm
        } else if has(["flight", "airport", "train", "ferry", "traffic", "jam", "diverted", "delayed", "cancelled", "canceled"]) {
            category = .transport
        } else if has(["closed", "shut", "suspended", "power cut", "outage"]) {
            category = .closure
        } else if has(["heatwave", "heat wave", "scorching", "heatstroke", "°c"]) || (has(["heat"]) && !has(["rain"])) {
            category = .heat
        } else if has(["aqi", "smog", "haze", "pollution"]) {
            category = .airQuality
        } else if has(["clear skies", "sunny", "no rain", "stopped raining", "all clear"]) {
            category = .allClear
        } else {
            category = .heavyRain
        }

        let severity: Double = category == .allClear ? 0 : extreme ? 0.95 : strong ? 0.7 : 0.4
        return (category, severity)
    }

    // MARK: - Model

    private static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private static let instructions = """
        You sort public social media posts and news headlines about weather in travel destinations.
        For each numbered post decide what it reports and how severe it is.
        Only current or forecast conditions count. Anything else is notAWeatherReport.
        """

    private static func refineWithModel(_ signals: [SocialSignal]) async -> [SocialSignal] {
        guard isAvailable, !signals.isEmpty else { return signals }

        var refined = signals
        // The freshest two dozen are worth the model's time; older ones keep
        // their keyword reading, and fade out of the digest on their own.
        let indices = Array(refined.indices.prefix(24))

        for start in stride(from: 0, to: indices.count, by: 8) {
            let batch = Array(indices[start..<min(start + 8, indices.count)])
            let list = batch.enumerated().map { offset, index in
                let text = refined[index].text.replacingOccurrences(of: "\n", with: " ")
                return "\(offset + 1). [\(refined[index].place)] \(String(text.prefix(220)))"
            }.joined(separator: "\n")

            do {
                let session = LanguageModelSession(instructions: instructions)
                let response = try await session.respond(
                    to: "Posts:\n\(list)",
                    generating: SignalBatchReading.self
                )
                for verdict in response.content.verdicts {
                    let offset = verdict.number - 1
                    guard batch.indices.contains(offset) else { continue }
                    let index = batch[offset]
                    guard let category = category(for: verdict.topic) else {
                        refined[index].severity = -1   // marked for removal
                        continue
                    }
                    refined[index].category = category
                    refined[index].severity = severity(for: verdict.severity, keyword: refined[index].severity)
                    refined[index].readByModel = true
                }
            } catch {
                continue
            }
        }

        // Official alerts are never dropped on the model's say-so.
        return refined.filter { $0.severity >= 0 || $0.source.isOfficial }.map { signal in
            var copy = signal
            copy.severity = max(copy.severity, 0)
            return copy
        }
    }

    private static func category(for topic: SignalTopic) -> SocialSignal.Category? {
        switch topic {
        case .flooding: .flooding
        case .heavyRain: .heavyRain
        case .storm: .storm
        case .heat: .heat
        case .transport: .transport
        case .closure: .closure
        case .airQuality: .airQuality
        case .allClear: .allClear
        case .notAWeatherReport: nil
        }
    }

    /// The model's severity, never more than one step from the keyword
    /// reading's — a small model shouldn't turn "light drizzle" into a red alert.
    private static func severity(for level: SignalSeverity, keyword: Double) -> Double {
        let model: Double = switch level {
        case .none: 0
        case .minor: 0.25
        case .moderate: 0.5
        case .severe: 0.75
        case .extreme: 0.95
        }
        return min(max(model, keyword - 0.3), keyword + 0.3)
    }
}
