//
//  ItineraryInspector.swift
//  Equitrip
//

import Foundation
import FoundationModels

// MARK: - What the model is asked

/// Whether a booking's name belongs to somewhere this trip actually goes.
@Generable
enum PlaceVerdict {
    /// A place in one of the trip's own cities, or near enough to one.
    case belongs
    /// A well-known place somewhere else entirely — a different city, a
    /// different country.
    case elsewhere
    /// No idea. A restaurant, a generic name, somewhere too small to know.
    case unsure
}

/// One booking, placed.
///
/// Note what the model is *not* asked for: no sentence, no severity, no
/// advice. It answers where a named place is and picks one of three words.
/// Everything a reader eventually sees is written in Swift from that, which
/// is the same division `EquiCard` draws — the model chooses, the app writes.
@Generable
struct PlaceCheck {
    @Guide(description: "The booking's title, copied back exactly as it appears in the list.")
    var bookingTitle: String

    @Guide(description: "Where this named place really is, as city and country — 'Paris, France'. Write 'unknown' unless you genuinely recognise the place by name.")
    var actualLocation: String

    @Guide(description: "Whether it belongs on this trip. Use 'elsewhere' only for a landmark you certainly recognise as being in another city or country; use 'unsure' for anything you do not confidently know.")
    var verdict: PlaceVerdict
}

@Generable
struct PlaceReview {
    @Guide(description: "One entry for each booking in the list, in the same order.")
    var checks: [PlaceCheck]
}

// MARK: - The pass

/// The judgement pass over a plan: the one question about an itinerary that
/// needs knowing something about the world rather than doing arithmetic.
///
/// This began as an open brief — read these days, tell me what looks wrong.
/// Measured against a fixture over nine runs it produced thirteen findings and
/// was right about one or two: it called a 10am and a 3pm booking "both in the
/// afternoon", it announced that a flight was "booked before departure", and
/// when the brief listed the kinds of problem to look for it handed those
/// sentences straight back as though they were findings. None of that is a
/// prompt that needed more tuning. Timing is subtraction, and something that
/// can do subtraction was already doing it.
///
/// So the question got smaller until it was one the model could actually
/// answer: *where is this place?* A named landmark on the wrong continent is
/// knowledge, it is exactly what arithmetic cannot check, and it is the one
/// thing this pass has ever got right. The model now returns a place name and
/// one of three words; every sentence a reader sees is composed here.
@MainActor
enum ItineraryInspector {

    enum Availability: Equatable {
        case ready
        case unavailable(String)
    }

    /// Whether this device can run the model, and why not when it can't. The
    /// caller shows the rule results either way and only changes what it
    /// claims about how they were found.
    static var availability: Availability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(.deviceNotEligible):
            return .unavailable("This device can't run Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable("Apple Intelligence is turned off in Settings.")
        case .unavailable(.modelNotReady):
            return .unavailable("The on-device model is still downloading.")
        case .unavailable:
            return .unavailable("Apple Intelligence isn't available right now.")
        }
    }

    /// Bookings worth asking about at once. The whole trip goes in one prompt
    /// rather than a few days at a time, because the question is geographic
    /// and a model shown three days of a five-day trip decides the other two
    /// cities aren't on it — which is precisely the mistake windowing caused.
    private static let maxChecked = 14

    /// The most this pass may add on top of the rules.
    private static let maxIssues = 2

    // MARK: - Entry point

    /// Streams the bookings that look like they're somewhere else, one at a
    /// time. Each element is the cumulative list — assign it, don't append.
    ///
    /// Never throws. Every failure ends the stream quietly and leaves the
    /// caller with its rule results, which are the ones that matter.
    static func stream(
        items: [ItineraryItem],
        destination: String,
        known: [ItineraryIssue]
    ) -> AsyncStream<[ItineraryIssue]> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                guard case .ready = availability else {
                    continuation.finish()
                    return
                }

                let subjects = namedPlaces(in: items)
                let places = tripPlaces(items: items, destination: destination)
                guard subjects.count >= 2, !places.isEmpty else {
                    continuation.finish()
                    return
                }

                let claimed = Set(known.flatMap(\.itemIDs))
                var found: [ItineraryIssue] = []

                do {
                    let session = LanguageModelSession(instructions: instructions)
                    session.prewarm()

                    let stream = session.streamResponse(
                        to: prompt(subjects, places: places),
                        generating: PlaceReview.self
                    )

                    var delivered = Set<UUID>()

                    for try await snapshot in stream {
                        try Task.checkCancellation()
                        guard let checks = snapshot.content.checks else { continue }

                        for partial in checks {
                            guard found.count < maxIssues else { break }
                            guard let check = settle(partial) else { continue }
                            guard let issue = validate(
                                check,
                                against: subjects,
                                places: places,
                                destination: destination,
                                claimed: claimed
                            ) else { continue }
                            guard delivered.insert(issue.itemIDs[0]).inserted else { continue }

                            found.append(issue)
                            continuation.yield(found)
                        }
                    }
                } catch {
                    // The rule results are already on screen and they are the
                    // half that can't be wrong. Nothing here is worth an
                    // error message about a guardrail.
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - What to ask about

    /// Bookings that are named after somewhere, which is the only kind this
    /// question means anything for.
    ///
    /// A flight is a route and a transfer is a car; neither is a place, and
    /// asking where "Airport Transfer" is invites an answer. Meals and stays
    /// stay in — "Karim's" and "The Imperial New Delhi" are real places with
    /// real addresses.
    private static func namedPlaces(in items: [ItineraryItem]) -> [ItineraryItem] {
        let generic = [
            "lunch", "dinner", "breakfast", "brunch", "supper", "meal", "free time",
            "check-in", "check in", "checkin", "check-out", "checkout", "transfer",
            "flight", "train", "taxi", "cab", "shopping", "rest", "departure", "arrival"
        ]

        return items
            .filter { $0.kind == .activity || $0.kind == .stay || $0.kind == .meal }
            .filter { item in
                let name = item.title.lowercased()
                guard item.title.filter(\.isLetter).count >= 5 else { return false }
                // A title that is only a category names no place.
                return !generic.contains { name == $0 || name.hasPrefix($0 + " ") }
            }
            .prefix(maxChecked)
            .map { $0 }
    }

    /// Everywhere this trip is known to go.
    ///
    /// Gathered from the whole plan rather than the one destination field,
    /// because a trip that reads "Delhi, India" in its header still spends two
    /// days in Agra — and a model told only about Delhi decides the Taj Mahal
    /// doesn't belong, which is how this pass spent its first draft attacking
    /// the itinerary's most obviously correct bookings.
    private static func tripPlaces(items: [ItineraryItem], destination: String) -> [String] {
        var seen: [String] = []

        func add(_ raw: String?) {
            guard let raw else { return }
            for piece in raw.components(separatedBy: CharacterSet(charactersIn: ",/→-–—()")) {
                let place = piece.trimmingCharacters(in: .whitespacesAndNewlines)
                guard place.count >= 3, place.count <= 30,
                      place.rangeOfCharacter(from: .decimalDigits) == nil,
                      !seen.contains(where: { $0.caseInsensitiveCompare(place) == .orderedSame })
                else { continue }
                seen.append(place)
            }
        }

        add(destination)
        for item in items {
            add(item.vendorName)
            add(item.flight?.departureCity)
            add(item.flight?.arrivalCity)
        }

        // "Delhi, India" and a vendor of "New Delhi" leave both "Delhi" and
        // "New Delhi" on the list, and the sentence a reader sees then opens
        // "This trip goes to Delhi, India, New Delhi". The fuller name wins.
        let deduped = seen.filter { place in
            !seen.contains { other in
                other.count > place.count
                    && other.range(of: place, options: .caseInsensitive) != nil
            }
        }

        return Array(deduped.prefix(12))
    }

    // MARK: - Reading the answer

    private static func settle(_ partial: PlaceCheck.PartiallyGenerated) -> PlaceCheck? {
        guard let title = partial.bookingTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              let location = partial.actualLocation?.trimmingCharacters(in: .whitespacesAndNewlines),
              let verdict = partial.verdict,
              !title.isEmpty
        else { return nil }

        return PlaceCheck(bookingTitle: title, actualLocation: location, verdict: verdict)
    }

    /// The guard everything rests on.
    ///
    /// Three ways an answer is thrown away: it names a booking that isn't
    /// there, it can't say where the place is, or the "somewhere else" it
    /// names is somewhere the trip already goes — which is the model
    /// contradicting itself and was the single most common wrong answer.
    private static func validate(
        _ check: PlaceCheck,
        against subjects: [ItineraryItem],
        places: [String],
        destination: String,
        claimed: Set<UUID>
    ) -> ItineraryIssue? {
        guard check.verdict == .elsewhere else { return nil }

        let query = check.bookingTitle.lowercased()
        guard query.count >= 3 else { return nil }

        let match = subjects.first { $0.title.lowercased() == query }
            ?? subjects.first {
                let title = $0.title.lowercased()
                return title.count >= 3 && (title.contains(query) || query.contains(title))
            }
        guard let item = match, !claimed.contains(item.id) else { return nil }

        // The place name is the only model-written text that reaches a reader,
        // so it is held to the shape of a place name and nothing else.
        let location = check.actualLocation.trimmingCharacters(in: CharacterSet(charactersIn: " .,"))
        guard location.count >= 3, location.count <= 40,
              location.rangeOfCharacter(from: .letters) != nil,
              location.rangeOfCharacter(from: .decimalDigits) == nil,
              location.lowercased() != "unknown"
        else { return nil }

        // "Somewhere else" that is one of the trip's own cities is not
        // somewhere else.
        let lowered = location.lowercased()
        guard !places.contains(where: { lowered.contains($0.lowercased()) }) else { return nil }

        // The trip's own destination, not the scraped list. The list is
        // gathered wide on purpose so the model knows Agra is on the
        // itinerary, and reading it back gives "This trip goes to India, New
        // Delhi, Old Delhi" — true, and not how anyone describes a trip.
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        let visiting = trimmed.isEmpty ? places.prefix(2).joined(separator: " and ") : trimmed
        guard !visiting.isEmpty else { return nil }

        return ItineraryIssue(
            severity: .worthChecking,
            symbol: "mappin.slash.circle.fill",
            headline: "\(item.title) looks like it's in \(location)",
            problem: "This trip goes to \(visiting). \(item.title) is named after somewhere in \(location), which isn't on it.",
            fix: "Check the booking — it may be named after the wrong place, or belong to another trip.",
            itemIDs: [item.id],
            origin: .intelligence,
            anchor: item.time ?? item.date
        )
    }

    // MARK: - Prompting

    private static let instructions = """
        You are given the places a trip visits and a list of bookings from it. \
        For each booking you say where that place really is in the world, and \
        whether it belongs on this trip.

        Judge the name only. A booking belongs when the place it is named \
        after is in one of the trip's cities, or close enough to reach from \
        one. It is elsewhere only when you genuinely recognise the name as a \
        landmark, museum, building or district in a different city — the kind \
        of place you could name the country of without thinking.

        Say unsure for everything else, and mean it. Restaurants, hotels, \
        cafés, markets, tours and anything you do not recognise are all \
        unsure. A name you half recognise is unsure. Unsure is the ordinary \
        answer and there is nothing wrong with giving it every time.

        The one thing unsure is not for: a landmark famous enough that you \
        could name its country without hesitating, sitting on a trip that \
        never goes near that country. Say elsewhere for that one.

        Say nothing about times, dates, prices, order or how the bookings sit \
        against each other. None of that is being asked and all of it has \
        already been checked.
        """

    private static func prompt(_ subjects: [ItineraryItem], places: [String]) -> String {
        var lines = ["This trip visits: \(places.joined(separator: ", "))."]
        lines.append("")
        lines.append("Bookings:")
        for (index, item) in subjects.enumerated() {
            var row = "\(index + 1). \(item.title)"
            if let vendor = item.vendorName { row += " — listed at \(vendor)" }
            lines.append(row)
        }
        lines.append("")
        lines.append("For each one: where is that place, and does it belong on this trip?")
        return lines.joined(separator: "\n")
    }
}
