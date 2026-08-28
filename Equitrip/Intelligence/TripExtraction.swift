//
//  TripExtraction.swift
//  Equitrip
//

import FoundationModels
import Foundation
import Observation

// MARK: - Generable schema
//
// Two small schemas rather than one big one. Asking the model for a whole trip
// in a single generation made it responsible for the document's structure as
// well as its meaning, and it isn't good at that: it invented bookings out of
// the cost-summary table, drifted a day at a time down a long list, and — worst
// of all — filled in a `travellers: [String]` field with plausible names for a
// document that only ever said "4 people".
//
// So `ItineraryDocument` works out the structure first, and the model is asked
// one narrow question at a time: what does this header say, and what is on this
// one day. Dates never appear in these schemas at all, because the day it
// belongs to is already known and a date the model doesn't have to guess is a
// date it can't get wrong.

@Generable(description: "The header of a travel itinerary")
struct ExtractedOverview {
    @Guide(description: "A short human name for the trip, two or three words, like 'Paris escape'. Not a booking reference and not the word 'itinerary'.")
    var title: String

    @Guide(description: "The main city or region the trip is to, with its country, like 'Paris, France'. One destination, not the route.")
    var destination: String

    @Guide(description: "Three-letter ISO code of the currency the prices are in: INR, USD, EUR, GBP.")
    var currencyCode: String

    @Guide(description: "How many people are travelling, as a number. 0 if the document never says.")
    var travellerCount: Int

    @Guide(description: "The travellers' names, copied exactly, and ONLY if the document writes them out. A document that says '4 people' without naming them has no names: return an empty list. Never invent a name.")
    var travellerNames: [String]
}

@Generable(description: "What happens on one day of a trip")
struct ExtractedDayPlan {
    @Guide(description: "One entry per row of this day's plan, in the order they are written. Never split a row in two, never merge two rows, and never add anything the day doesn't list.")
    var items: [ExtractedItem]
}

@Generable(description: "One entry on a day's plan")
struct ExtractedItem {
    @Guide(description: "What the row calls this, in two or three words: 'Airport transfer', 'Eiffel Tower', 'Farewell dinner'. The name only — not the description after it.")
    var title: String

    @Guide(description: "Start time in 24-hour HH:mm. Empty string if the row gives no time. Never guess one.")
    var time: String

    @Guide(description: "Which kind of thing this is. An airport transfer is a transfer, not a flight — the flight is the thing that flies. Hotel breakfast is a meal, not a stay.")
    var kind: ExtractedKind
}

@Generable
enum ExtractedKind {
    case flight
    case train
    case transfer
    case stay
    case activity
    case meal
    case other
}

// MARK: - Resolved output

/// One booking, with its day already decided.
struct PlannedItem: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var detail: String
    var day: Date
    /// Minutes since midnight. Nil when the document gave no time, which is
    /// normal for stays and is not the same as midnight.
    var minuteOfDay: Int?
    var kind: ExtractedKind
    var amount: Double
    var participantCount: Int
    var photoQuery: String

    var clockText: String {
        guard let minuteOfDay else { return "" }
        return String(format: "%02d:%02d", minuteOfDay / 60, minuteOfDay % 60)
    }
}

/// One day of resolved bookings.
struct PlannedDay: Identifiable, Hashable {
    var id: Int { number }
    var number: Int
    var date: Date
    var heading: String
    var items: [PlannedItem]
}

// MARK: - Availability

enum IntelligenceAvailability {
    case ready
    case unsupportedDevice
    case notEnabled
    case warmingUp

    var headline: String {
        switch self {
        case .ready: "On-device reading"
        case .unsupportedDevice: "Reading it the simple way"
        case .notEnabled: "Apple Intelligence is off"
        case .warmingUp: "Model still downloading"
        }
    }

    var detail: String {
        switch self {
        case .ready:
            "Apple Intelligence reads the document on this device. Nothing is uploaded."
        case .unsupportedDevice:
            "This device can't run Apple Intelligence, so we'll pull out what we can by pattern instead."
        case .notEnabled:
            "Turn on Apple Intelligence in Settings for a much better read. We'll use pattern matching until then."
        case .warmingUp:
            "The on-device model is still downloading. Using pattern matching for now."
        }
    }

    var isReady: Bool { self == .ready }
}

// MARK: - Service

/// Turns a booking PDF into a trip.
///
/// The pipeline, in order, because each stage exists to stop a specific way the
/// last version got things wrong:
///
///  1. `ItineraryDocument` finds the shape — header, dated days, appendix — so
///     the cost-summary table can never become bookings and no date is guessed.
///  2. The model reads the header, then one day at a time. Small prompts with
///     the date supplied are the difference between 45 rows and 69.
///  3. Every day's output is checked against the day's own text: no more items
///     than there were lines, and no price that isn't written down.
///  4. `ItineraryReasoner` applies what the model keeps getting wrong anyway —
///     an airport transfer is a transfer — and puts the day in clock order.
///
/// When Apple Intelligence isn't available the same document structure is read
/// by `StructuredRowParser` instead, so the shape of the result is identical
/// and only the quality of the reading changes.
@MainActor
@Observable
final class TripExtractor {

    /// What the import screen renders while this runs.
    struct Progress {
        var title = ""
        var destination = ""
        var currencyCode = ""
        /// How many people the document says are on the trip. Names are asked
        /// for, never invented — see `travellerNames`.
        var travellerCount = 0
        /// Only names the document actually writes down. Usually empty.
        var travellerNames: [String] = []
        var days: [PlannedDay] = []
        var stage: Stage = .opening
        var isComplete = false

        var items: [PlannedItem] { days.flatMap(\.items) }
        var itemCount: Int { days.reduce(0) { $0 + $1.items.count } }
        var hasSummary: Bool { !title.isEmpty || !destination.isEmpty }
    }

    /// Narrated because the read takes a few seconds and a spinner that says
    /// nothing for five seconds reads as a hang.
    enum Stage: Equatable {
        case opening
        case understanding
        case reading(done: Int, of: Int)
        case tidying
        case finished

        var caption: String {
            switch self {
            case .opening: "Opening the document…"
            case .understanding: "Working out the trip…"
            case .reading(let done, let total): "Reading \(total.pluralised("day"))… \(done) done"
            case .tidying: "Putting it in order…"
            case .finished: "Done"
            }
        }

        var isReading: Bool {
            if case .reading = self { return true }
            return false
        }
    }

    private(set) var progress = Progress()
    private(set) var usedFallback = false
    private(set) var document = ItineraryDocument()

    /// Days the model actually read. When this ends up at zero the screen must
    /// not claim Apple Intelligence read the document — every day quietly fell
    /// through to the pattern parser, and saying otherwise oversells an
    /// accuracy nobody got.
    private var daysReadByModel = 0

    var availability: IntelligenceAvailability {
        switch SystemLanguageModel.default.availability {
        case .available: .ready
        case .unavailable(.deviceNotEligible): .unsupportedDevice
        case .unavailable(.appleIntelligenceNotEnabled): .notEnabled
        case .unavailable(.modelNotReady): .warmingUp
        case .unavailable: .unsupportedDevice
        }
    }

    /// Guard rails. A booking PDF with more than this is a catalogue, and
    /// reading all of it would take longer than typing the trip in by hand.
    private static let maxDays = 30
    private static let maxItemsPerDay = 24

    /// Days read at once. The on-device model overlaps them properly — seven
    /// days one after another took a minute, three at a time takes twenty-odd
    /// seconds — but a phone doing this on battery isn't a Mac, so the width is
    /// kept modest rather than "all of them".
    private static let readingWidth = 3

    // MARK: - Entry point

    func extract(from text: String) async {
        progress = Progress()
        usedFallback = false
        daysReadByModel = 0

        document = ItineraryDocument.parse(text)
        guard !document.days.isEmpty else {
            progress.stage = .finished
            progress.isComplete = true
            return
        }

        // Whatever the header parse found is shown immediately — it costs
        // nothing and it means the screen has something true on it before the
        // model has produced a token.
        seedFromDocument()

        let days = Array(document.days.prefix(Self.maxDays))

        if availability.isReady {
            await readWithModel(days)
            if daysReadByModel == 0 { usedFallback = true }
        } else {
            usedFallback = true
            await readWithParser(days)
        }

        progress.stage = .tidying
        progress.days = ItineraryReasoner.refine(progress.days, destination: progress.destination)
        progress.stage = .finished
        progress.isComplete = true
    }

    private func seedFromDocument() {
        progress.destination = document.destinationHint.map(Self.cityOnly) ?? ""
        progress.currencyCode = document.currencyCode ?? ""
        progress.travellerCount = document.travellerCount ?? 0
        progress.travellerNames = document.namedTravellers
        progress.title = document.title ?? ""
    }

    // MARK: - On-device model

    private static let overviewInstructions = """
        You read the header of a travel document and report only what it says.

        Rules:
        - Copy facts. Never invent one, and never fill a field in with something \
        that would be reasonable.
        - Names are the important one. If the document gives a number of \
        travellers but no names, there are no names. Return an empty list.
        - The destination is where the trip goes, not where it starts from.
        """

    private static let dayInstructions = """
        You read one day of a travel itinerary and name what is on it.

        Rules:
        - One entry per row, in the order they are written. The day has exactly \
        as many entries as it has rows: never merge two, never split one, never \
        add one.
        - The title is the row's name for the thing and nothing else. In the row \
        "09:30 Airport transfer Central Paris to CDG" the title is \
        "Airport transfer" — not the whole row. In "13:00 Lunch Café near the \
        Louvre" it is "Lunch". Two or three words, almost always.
        - Getting to or from an airport is a transfer; only the thing that flies \
        is a flight. Checking into a hotel is a stay; checking in at an airport \
        is not. Hotel breakfast is a meal.
        """

    private func readWithModel(_ days: [ItineraryDocument.DaySection]) async {
        progress.stage = .understanding
        await readOverview()

        // Days are independent of each other — that's the whole point of having
        // split them — so they're read a few at a time rather than one after
        // another. They land out of order and get sorted at the end; on screen
        // that reads as the trip assembling itself, which is closer to what is
        // actually happening than a single bar creeping along.
        var finished = 0
        progress.stage = .reading(done: 0, of: days.count)

        await withTaskGroup(of: Void.self) { group in
            var next = days.startIndex

            func schedule() {
                guard next < days.endIndex else { return }
                let day = days[next]
                next += 1
                group.addTask { @MainActor [weak self] in
                    guard let self else { return }
                    let items = await self.readDay(day)
                    self.append(
                        PlannedDay(
                            number: day.number,
                            date: day.date ?? Date(),
                            heading: day.heading,
                            items: items
                        )
                    )
                }
            }

            for _ in 0..<min(Self.readingWidth, days.count) { schedule() }

            while await group.next() != nil {
                finished += 1
                progress.stage = .reading(done: finished, of: days.count)
                schedule()
            }
        }
    }

    private func readOverview() async {
        let header = document.preamble.prefix(14).joined(separator: "\n")
        guard header.count > 20 else { return }

        do {
            let session = LanguageModelSession(instructions: Self.overviewInstructions)
            let stream = session.streamResponse(
                to: """
                    Read this itinerary header.

                    \(header)
                    """,
                generating: ExtractedOverview.self
            )

            for try await snapshot in stream {
                let partial = snapshot.content
                if let title = partial.title, !title.isEmpty { progress.title = title }
                if let destination = partial.destination, !destination.isEmpty {
                    progress.destination = destination
                }
                if let code = partial.currencyCode, code.count == 3, document.currencyCode == nil {
                    progress.currencyCode = code.uppercased()
                }
                if let count = partial.travellerCount, (1...30).contains(count) {
                    progress.travellerCount = count
                }
                if let names = partial.travellerNames {
                    progress.travellerNames = verified(names)
                }
            }
        } catch {
            // The header is the least important part and the document parse
            // already filled most of it in. Losing it isn't worth failing over.
        }

        if progress.travellerCount == 0, let counted = document.travellerCount {
            progress.travellerCount = counted
        }
        if progress.travellerNames.isEmpty { progress.travellerNames = document.namedTravellers }
    }

    /// The single most important guard in the whole pipeline.
    ///
    /// A name that isn't written in the document isn't a name — it's the model
    /// being helpful, and the result is four strangers on someone's trip with a
    /// share of the bill each. Anything that doesn't appear in the source text
    /// is dropped, no matter how confidently it was produced.
    private func verified(_ names: [String]) -> [String] {
        names.compactMap { raw in
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard name.count >= 2, name.count <= 28,
                  name.rangeOfCharacter(from: .decimalDigits) == nil,
                  document.haystack.contains(name.lowercased())
            else { return nil }
            return name
        }
    }

    private func readDay(_ day: ItineraryDocument.DaySection) async -> [PlannedItem] {
        guard !day.lines.isEmpty else { return [] }

        do {
            let session = LanguageModelSession(instructions: Self.dayInstructions)
            session.prewarm()
            let stream = session.streamResponse(to: dayPrompt(day), generating: ExtractedDayPlan.self)

            var latest: [PlannedItem] = []
            for try await snapshot in stream {
                guard let items = snapshot.content.items else { continue }
                // The ceiling applies while it streams, not only at the end.
                // A model that over-runs a day does it in full view, and a
                // counter that climbs to ninety before settling at forty-five
                // is the screen telling the user something untrue and then
                // taking it back.
                latest = items.prefix(min(day.lines.count, Self.maxItemsPerDay))
                    .compactMap { settle($0, on: day) }
                publish(latest, for: day)
            }

            let checked = validate(latest, against: day)
            guard !checked.isEmpty else { return StructuredRowParser.items(in: day) }
            daysReadByModel += 1
            return checked
        } catch {
            // One bad day shouldn't cost the other six.
            return StructuredRowParser.items(in: day)
        }
    }

    private func dayPrompt(_ day: ItineraryDocument.DaySection) -> String {
        var lines: [String] = []
        if !progress.destination.isEmpty { lines.append("Trip to \(progress.destination).") }
        if !day.heading.isEmpty { lines.append("This day: \(day.heading).") }
        lines.append("It has \(day.lines.count.pluralised("row")).")
        lines.append("")
        lines.append(day.promptBody)
        return lines.joined(separator: "\n")
    }

    /// A partially generated entry is only worth showing once it has a title.
    private func settle(_ item: ExtractedItem.PartiallyGenerated, on day: ItineraryDocument.DaySection) -> PlannedItem? {
        guard let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), title.count >= 2
        else { return nil }

        let kind = item.kind ?? .other
        return PlannedItem(
            title: title,
            detail: "",
            day: day.date ?? Date(),
            minuteOfDay: Self.minutes(from: item.time ?? ""),
            // Reasoned as it arrives, not only at the end. The tidy-up pass
            // used to be the first thing to notice that an airport transfer
            // isn't a flight, which meant the live list showed the model's
            // first guess for half a minute and then quietly corrected itself
            // — the one moment the user is actually watching it work.
            kind: ItineraryReasoner.classify(title: title, detail: "") ?? kind,
            amount: 0,
            participantCount: 0,
            photoQuery: ""
        )
    }

    /// Checks a day's output against the day's own text.
    ///
    /// The division of labour: the model is trusted with language — what a row
    /// is called, what it is — and the text is trusted with numbers. A price or
    /// a time is a fact sitting right there in the row, and the reader that can
    /// simply copy it will always beat the one predicting it.
    ///
    /// When the model returned exactly one entry per row, the two readings can
    /// be lined up and every scalar taken from the source. When it didn't, the
    /// weaker check applies: no more entries than there were rows, and no price
    /// that isn't written somewhere on the day. A hallucinated ₹12,000 is not a
    /// cosmetic error — it becomes somebody's ₹3,000 share of the bill.
    private func validate(_ items: [PlannedItem], against day: ItineraryDocument.DaySection) -> [PlannedItem] {
        let ceiling = min(day.lines.count, Self.maxItemsPerDay)
        var checked = Array(items.prefix(ceiling))

        guard checked.count == day.lines.count else { return checked }

        let described = day.promptBody.components(separatedBy: "\n")
        for index in checked.indices {
            let line = day.lines[index]
            checked[index].amount = ItineraryDocument.amount(in: line) ?? 0
            if let leading = TravelDate.time(in: String(line.prefix(8))) {
                checked[index].minuteOfDay = leading.hour * 60 + leading.minute
            }
            if let counted = Self.trailingCount(in: line) {
                checked[index].participantCount = counted
            }
            if index < described.count {
                checked[index].detail = Self.describe(described[index], titled: checked[index].title)
            }
            // Now that the row's own words are attached, ask again — "Sacré-Cœur"
            // says nothing on its own and "Basilica visit" settles it.
            if let ruled = ItineraryReasoner.classify(
                title: checked[index].title, detail: checked[index].detail
            ) {
                checked[index].kind = ruled
            }
        }
        return checked
    }

    /// What's left of the row once its time and its name have been taken out.
    /// Deriving the description rather than generating it halves what the model
    /// has to write, and a description copied from the row is one that can't
    /// drift from it.
    private static func describe(_ line: String, titled title: String) -> String {
        var rest = line.replacingOccurrences(
            of: "^\\d{1,2}[:.]\\d{2}\\s*(am|pm)?\\s*", with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        // The model's title is usually the row's own opening words, so it can
        // simply be cut off the front. When it isn't, the whole row stands as
        // the description rather than being mangled.
        let head = title.trimmingCharacters(in: .whitespaces)
        if !head.isEmpty, rest.lowercased().hasPrefix(head.lowercased()) {
            rest = String(rest.dropFirst(head.count))
        }

        rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: " -–—•|:,."))
        return rest.caseInsensitiveCompare(title) == .orderedSame ? "" : String(rest.prefix(120))
    }

    /// The participants column: the number a table row ends with.
    private static func trailingCount(in line: String) -> Int? {
        guard let range = line.range(of: "\\b(\\d{1,2})\\s*$", options: .regularExpression),
              let value = Int(line[range].trimmingCharacters(in: .whitespaces)),
              (1...30).contains(value) else { return nil }
        return value
    }

    private static func minutes(from text: String) -> Int? {
        guard let parsed = TravelDate.time(in: text) else { return nil }
        return parsed.hour * 60 + parsed.minute
    }

    // MARK: - Fallback

    private func readWithParser(_ days: [ItineraryDocument.DaySection]) async {
        progress.stage = .understanding
        if progress.title.isEmpty {
            progress.title = document.destinationHint.map(Self.cityOnly) ?? "Imported trip"
        }

        for (offset, day) in days.enumerated() {
            progress.stage = .reading(done: offset, of: days.count)
            append(
                PlannedDay(
                    number: day.number,
                    date: day.date ?? Date(),
                    heading: day.heading,
                    items: StructuredRowParser.items(in: day)
                )
            )
            // Paced so the screen reads the same either way, instead of
            // snapping to a finished list the moment the file is picked.
            try? await Task.sleep(for: .milliseconds(110))
        }
    }

    // MARK: - Accumulating

    private func append(_ day: PlannedDay) {
        if let index = progress.days.firstIndex(where: { $0.number == day.number }) {
            progress.days[index] = day
        } else {
            progress.days.append(day)
        }
    }

    private func publish(_ items: [PlannedItem], for day: ItineraryDocument.DaySection) {
        append(
            PlannedDay(number: day.number, date: day.date ?? Date(), heading: day.heading, items: items)
        )
    }

    /// A route is not a destination.
    ///
    /// "Mumbai (BOM) → Paris (CDG) → Mumbai (BOM)" ends in Mumbai, so taking
    /// the last leg named the city everyone is flying home to. A route that
    /// returns where it started is a round trip and the middle of it is the
    /// point; a one-way route ends at it.
    nonisolated static func cityOnly(_ text: String) -> String {
        let legs = text
            .replacingOccurrences(of: " to ", with: "→", options: .caseInsensitive)
            .components(separatedBy: CharacterSet(charactersIn: "→>"))
            .map { leg in
                leg
                    .replacingOccurrences(of: "\\([A-Za-z]{3}\\)", with: "", options: .regularExpression)
                    .trimmingCharacters(in: CharacterSet(charactersIn: " -–—,"))
            }
            .filter { !$0.isEmpty }

        guard let first = legs.first, let last = legs.last else { return "" }
        guard legs.count > 1 else { return first }
        if legs.count >= 3, first.caseInsensitiveCompare(last) == .orderedSame { return legs[1] }
        return last
    }
}
