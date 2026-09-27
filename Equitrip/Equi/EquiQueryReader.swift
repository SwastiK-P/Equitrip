//
//  EquiQueryReader.swift
//  Equitrip
//

import Foundation
import FoundationModels

// MARK: - What the model is asked

@Generable
enum EquiTopicChoice {
    case overview, schedule, bookings, spending, balance, people, trips, gaps, advice, chat
}

@Generable
enum EquiTripChoice {
    case named, current, next, previous, all, unspecified
}

@Generable
enum EquiCategoryChoice {
    case anything, flight, train, transfer, stay, activity, food, other
}

@Generable
enum EquiDayChoice {
    case anyDay, today, tomorrow
}

/// The model's reading of a question. It classifies and copies a title or a
/// name out of the list it was shown — it never answers.
@Generable
struct EquiQueryDraft {
    @Guide(description: "What the question is about.")
    var topic: EquiTopicChoice

    @Guide(description: "Which trip the question means.")
    var trip: EquiTripChoice

    @Guide(description: "When trip is 'named': that trip's exact title, copied from the list. Otherwise empty.")
    var tripTitle: String

    @Guide(description: "The kind of booking the question is limited to, if any.")
    var category: EquiCategoryChoice

    @Guide(description: "A traveller's first name when the question is about one person other than the user. Otherwise empty.")
    var person: String

    @Guide(description: "A day the question is limited to, if any.")
    var day: EquiDayChoice
}

// MARK: - Reader

/// Reads a question into an `EquiQuery`: which trips, which topic, narrowed
/// to what.
///
/// Two readers, merged. Plain word rules (`Cues`) catch what a question says
/// outright — a trip's name, "last trip", "owe", "food", "tomorrow" — and a
/// small classification pass on the on-device model catches the paraphrases
/// the rules miss ("what's the damage on dinners?"). Where they disagree about
/// *which trip*, the words win: a trip named in the question is the one being
/// asked about, whatever a classifier thinks. Without Apple Intelligence the
/// rules run alone, so Equi still answers the questions it has figures for.
///
/// A question that names no trip follows the conversation: the trip the last
/// answer was about (`focus`), then the one under way or coming up next.
@MainActor
enum EquiQueryReader {

    static func read(
        _ question: String,
        turns: [EquiIntelligence.Turn],
        store: TripStore,
        useModel: Bool
    ) async -> EquiQuery {
        let trips = store.trips
        let cues = Cues(question, trips: trips)
        let focus = turns.last(where: { $0.tripID != nil }).flatMap { store.trip($0.tripID) }
        let previousCard = turns.last(where: { !$0.isUser })?.card

        let draft: EquiQueryDraft? = useModel && !trips.isEmpty
            ? await modelDraft(
                question: question,
                previous: turns.last(where: \.isUser)?.text,
                focus: focus,
                trips: trips
            )
            : nil

        // Which trips.
        var scope: EquiQuery.Scope
        var chosen: [Trip]
        if !cues.named.isEmpty {
            scope = .named
            chosen = cues.named
        } else if let cued = cues.scope {
            scope = cued
            chosen = resolve(cued, trips: trips, focus: focus)
        } else if let draft, draft.trip == .named, let trip = match(title: draft.tripTitle, in: trips) {
            scope = .named
            chosen = [trip]
        } else {
            scope = draft.map { scopeOf($0.trip) } ?? .current
            chosen = resolve(scope, trips: trips, focus: focus)
        }

        // What about them.
        var topic = pickTopic(
            cues: cues.topic,
            model: draft.map { topicOf($0.topic) },
            previous: previousCard,
            isFollowUp: cues.isFollowUp,
            scope: scope
        )
        if topic == .trips, scope == .current || scope == .named, chosen.count <= 1 {
            // "Tell me about the trip" read as a list of one.
            topic = .overview
        }
        if topic == .trips, chosen.count <= 1, scope != .named {
            chosen = resolve(scope == .allPast || scope == .allUpcoming ? scope : .all, trips: trips, focus: focus)
            if scope != .allPast && scope != .allUpcoming { scope = .all }
        }
        if topic != .trips, topic != .balance, topic != .spending, chosen.count > 1 {
            chosen = Array(chosen.prefix(1))
        }

        // "What's next?" while talking about a trip that's over means the
        // trip that isn't: the one under way, or the next one.
        if scope == .current, topic == .schedule || topic == .gaps, chosen.first?.phase == .past,
           let ahead = resolve(.allUpcoming, trips: trips, focus: nil).first {
            chosen = [ahead]
        }

        let category = cues.category ?? draft.flatMap { categoryOf($0.category) }
        let day = cues.day ?? draft.map { dayOf($0.day) } ?? .any

        var personID: UUID?
        let people = chosen.first.map { [$0] } ?? trips
        if let named = cues.person(in: people) {
            personID = named.id
        } else if let draft, !draft.person.isEmpty, let trip = chosen.first,
                  let named = TripMatcher.traveller(named: draft.person, on: trip),
                  named.id != Traveller.you.id {
            personID = named.id
        }

        return EquiQuery(
            topic: topic,
            scope: scope,
            tripIDs: chosen.map(\.id),
            category: category,
            personID: personID,
            day: day,
            byCost: cues.has(["most", "least", "expensive", "cheapest", "cost", "costs", "costliest", "priciest",
                              "spent", "spend", "biggest", "cheaper", "pricier", "rank"]),
            asksBudget: cues.has(["budget", "over budget", "afford", "overspent", "overspending"])
        )
    }

    // MARK: - Trips

    /// Pins a scope to real trips. `.previous` and `.next` come back empty
    /// when there isn't one — the answer says so rather than substituting.
    static func resolve(_ scope: EquiQuery.Scope, trips: [Trip], focus: Trip?) -> [Trip] {
        let past = trips.filter { $0.phase == .past }.sorted { $0.endDate > $1.endDate }
        let upcoming = trips.filter { $0.phase == .upcoming }.sorted { $0.startDate < $1.startDate }
        let live = trips.filter { $0.phase == .live }

        switch scope {
        case .named, .current:
            let likeliest = focus ?? live.first ?? TripMatcher.likeliest(in: trips)
            return likeliest.map { [$0] } ?? []
        case .next: return Array(upcoming.prefix(1))
        case .previous: return Array(past.prefix(1))
        case .all: return TripMatcher.byRelevance(trips)
        case .allPast: return past
        case .allUpcoming: return live + upcoming
        }
    }

    private static func match(title: String, in trips: [Trip]) -> Trip? {
        let wanted = Cues.normalise(title)
        guard !wanted.isEmpty else { return nil }
        return trips.first { Cues.normalise($0.title) == wanted }
            ?? TripMatcher.trips(matching: title, in: trips).first
    }

    private static func scopeOf(_ choice: EquiTripChoice) -> EquiQuery.Scope {
        switch choice {
        case .named, .current, .unspecified: .current
        case .next: .next
        case .previous: .previous
        case .all: .all
        }
    }

    // MARK: - Topic

    /// The rules' topic where they caught a phrase; the model's where they
    /// found nothing and it saw more than small talk. With neither, a follow-up ("and Kerala?")
    /// asks the last card's question of another trip, and anything else about
    /// one trip is taken as asking after the trip itself.
    private static func pickTopic(
        cues: EquiQuery.Topic?,
        model: EquiQuery.Topic?,
        previous: EquiCard?,
        isFollowUp: Bool,
        scope: EquiQuery.Scope
    ) -> EquiQuery.Topic {
        // The rules match whole phrases ("who paid", "owe", "how much"), so
        // when one hits it's right far more often than the classifier — which
        // was seen filing "who paid the most?" under balance.
        if let cues { return cues }
        if let model, model != .chat { return model }
        if isFollowUp, let previous { return previous.kind.topic }
        if let model { return model }
        switch scope {
        case .all, .allPast, .allUpcoming: return .trips
        case .named, .next, .previous: return .overview
        case .current: return previous?.kind.topic ?? .overview
        }
    }

    private static func topicOf(_ choice: EquiTopicChoice) -> EquiQuery.Topic {
        switch choice {
        case .overview: .overview
        case .schedule: .schedule
        case .bookings: .bookings
        case .spending: .spending
        case .balance: .balance
        case .people: .people
        case .trips: .trips
        case .gaps: .gaps
        case .advice: .advice
        case .chat: .chat
        }
    }

    private static func categoryOf(_ choice: EquiCategoryChoice) -> ItineraryKind? {
        switch choice {
        case .anything: nil
        case .flight: .flight
        case .train: .train
        case .transfer: .drive
        case .stay: .stay
        case .activity: .activity
        case .food: .meal
        case .other: nil
        }
    }

    private static func dayOf(_ choice: EquiDayChoice) -> EquiQuery.Day {
        switch choice {
        case .anyDay: .any
        case .today: .today
        case .tomorrow: .tomorrow
        }
    }

    // MARK: - Model pass

    /// Kept to a list of titles and one line per topic: the on-device context
    /// window is a few thousand tokens, and this pass only has to sort.
    private static let instructions = """
    You sort questions for Equi, the assistant in a group-trip app. Never answer the question — only classify it.
    Topics:
    overview: one trip as a whole — when it is, how it's going, a summary or recap.
    schedule: what happens next, today or tomorrow, or when something happens (a flight, a check-in).
    bookings: what is booked of one kind — where they're staying, which flights, what activities.
    spending: what things cost, where the money went, budget, the most expensive thing.
    balance: who owes whom, what the user owes or is owed, settling up.
    people: who is on a trip, who paid for things, one traveller's part.
    trips: several trips at once — listing, counting or comparing trips.
    gaps: what's missing — nights with no stay, empty days, things not booked yet.
    advice: packing, weather, sights, food to try, tips — general travel knowledge.
    chat: greetings, thanks, or anything not about travel.
    Trip: named when a trip in the list is meant (copy its exact title); previous for their last finished trip; next for the next one coming up; current for the one being discussed or under way; all for every trip.
    A short follow-up like "and the other one?" keeps the previous question's topic.
    """

    private static func modelDraft(question: String, previous: String?, focus: Trip?, trips: [Trip]) async -> EquiQueryDraft? {
        var prompt = "Trips:\n"
        for trip in TripMatcher.byRelevance(trips).prefix(12) {
            let dates = DateFormatter.cached("d MMM yyyy")
            prompt += "- \"\(trip.title)\" — \(trip.destination), \(dates.string(from: trip.startDate)) to \(dates.string(from: trip.endDate)), \(phaseWord(trip.phase))\n"
        }
        if let focus { prompt += "Being discussed: \"\(focus.title)\"\n" }
        if let previous { prompt += "Previous question: \(previous.prefix(200))\n" }
        prompt += "Question: \(question.prefix(400))"

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(
                to: prompt,
                generating: EquiQueryDraft.self,
                options: GenerationOptions(samplingMode: .greedy)
            )
            return response.content
        } catch {
            // The rules still stand on their own; a failed sort is not a
            // failed answer.
            return nil
        }
    }

    private static func phaseWord(_ phase: Trip.Phase) -> String {
        switch phase {
        case .upcoming: "upcoming"
        case .live: "under way now"
        case .past: "finished"
        }
    }
}

// MARK: - Word rules

extension EquiQueryReader {

    /// What a question says outright. Phrases are matched on whole words
    /// against a folded copy — lowercase, no accents, apostrophes dropped
    /// ("who's" → "whos"), everything else a space.
    struct Cues {
        let text: String
        var named: [Trip] = []
        var scope: EquiQuery.Scope?
        var topic: EquiQuery.Topic?
        var category: ItineraryKind?
        var day: EquiQuery.Day?

        init(_ question: String, trips: [Trip]) {
            text = " " + Self.normalise(question) + " "
            named = namedTrips(in: trips)
            scope = findScope()
            category = findCategory()
            day = has(["today", "tonight", "this evening"]) ? .today : has(["tomorrow", "tmrw"]) ? .tomorrow : nil
            topic = findTopic()
        }

        static func normalise(_ text: String) -> String {
            let folded = text
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "’", with: "")
            return folded
                .split { !$0.isLetter && !$0.isNumber }
                .joined(separator: " ")
        }

        func has(_ phrases: [String]) -> Bool {
            phrases.contains { text.contains(" \($0) ") }
        }

        private var wordCount: Int { text.split(separator: " ").count }

        /// "and Kerala?", "what about Ed?" — a question that leans on the
        /// last one for what it's asking.
        var isFollowUp: Bool {
            text.hasPrefix(" and ") || text.hasPrefix(" what about ") || text.hasPrefix(" how about ")
                || text.hasPrefix(" same for ") || wordCount <= 2
        }

        // MARK: Trips

        /// Words in a trip's name that say nothing about which trip it is.
        private static let generic: Set<String> = [
            "the", "and", "with", "for", "our", "trip", "trips", "getaway", "holiday", "holidays", "vacation",
            "weekend", "summer", "winter", "spring", "autumn", "fall", "family", "friends", "road", "tour",
            "week", "days", "day", "long", "big", "little", "new", "year", "girls", "boys", "work", "team",
            "first", "last", "next", "back", "home", "city", "beach", "escape", "break", "time", "fun",
            "what", "where", "when", "how", "who", "much", "all", "money", "plan", "food", "stay"
        ]

        private func namedTrips(in trips: [Trip]) -> [Trip] {
            trips
                .compactMap { trip -> (Trip, Int)? in
                    var score = 0
                    let title = Self.normalise(trip.title)
                    if title.count >= 3, text.contains(" \(title) ") { score += 5 }
                    for word in Self.normalise(trip.destination).split(separator: " ").map(String.init)
                    where word.count >= 3 && !Self.generic.contains(word) && has([word]) {
                        score += 3
                    }
                    for word in title.split(separator: " ").map(String.init)
                    where word.count >= 3 && !Self.generic.contains(word) && has([word]) {
                        score += 2
                    }
                    return score > 0 ? (trip, score) : nil
                }
                .sorted { $0.1 > $1.1 }
                .map(\.0)
        }

        private func findScope() -> EquiQuery.Scope? {
            if has(["past trips", "previous trips", "old trips", "finished trips", "completed trips", "trips ive been on",
                    "trips i took", "trips weve done", "where have i been", "where ive been", "places ive been"]) {
                return .allPast
            }
            if has(["upcoming trips", "future trips", "next trips", "planned trips", "coming trips"]) {
                return .allUpcoming
            }
            if has(["last trip", "previous trip", "most recent trip", "recent trip", "last holiday", "last vacation",
                    "last time", "past trip", "trip before", "last one", "previous one"]) {
                return .previous
            }
            if has(["next trip", "upcoming trip", "next holiday", "next vacation", "coming trip"]) {
                return .next
            }
            if has(["all my trips", "all trips", "my trips", "every trip", "each trip", "all of my trips", "which trip",
                    "how many trips", "compare", "anywhere", "across", "any trip", "all the trips", "both trips"]) {
                return .all
            }
            return nil
        }

        // MARK: Topic

        /// Checked in order: the most specific words first, so "how much do
        /// I owe" is a balance before it's a cost.
        private func findTopic() -> EquiQuery.Topic? {
            if wordCount <= 3, has(["hi", "hello", "hey", "thanks", "thank you", "thx", "ok", "okay", "cool", "great", "yo", "good morning", "good night"]) {
                return .chat
            }
            if has(["gap", "gaps", "missing", "forgot", "forgotten", "forget", "unbooked", "not booked", "still need to book",
                    "havent booked", "empty day", "free day", "free days", "nothing planned", "left to book", "anything left"]) {
                return .gaps
            }
            if has(["owe", "owes", "owed", "owing", "settle", "settled", "settling", "pay back", "payback", "paid back",
                    "square", "squared", "debt", "debts", "balance", "balances", "who pays", "i get back", "get back"]) {
                return .balance
            }
            if has(["whos on", "who is on", "whos coming", "who is coming", "whos going", "who is going", "who else",
                    "travellers", "travelers", "members", "people", "who paid", "paid the most", "paid most",
                    "contributed", "whos in", "who all"]) {
                return .people
            }
            if has(["pack", "packing", "weather", "wear", "temperature", "rain", "raining", "recommend", "recommendation",
                    "suggest", "suggestion", "worth seeing", "worth visiting", "things to do", "what to do", "sightseeing",
                    "tips", "nearby", "should i eat", "must try", "best time", "visa", "language"]) {
                return .advice
            }
            if scope == .all || scope == .allPast || scope == .allUpcoming || named.count > 1 || has(["trips"]) {
                return .trips
            }
            if category == nil, has(["when is my", "when does my", "when is the trip", "how long until", "how many days until",
                                     "how many days left", "countdown", "when do we leave for"]) {
                return .overview
            }
            if has(["spend", "spent", "spending", "cost", "costs", "costing", "expensive", "cheapest", "budget", "how much",
                    "price", "pricey", "splurge", "money go", "money going", "money went", "total", "damage"]) {
                return .spending
            }
            // "Next" is the trip's own word in "my next trip", not a question
            // about what's on the plan.
            if scope != .next, scope != .allUpcoming, has(["next", "up next"]) { return .schedule }
            if has(["today", "tonight", "tomorrow", "when", "schedule", "plan for", "happening",
                    "itinerary", "land", "landing", "depart", "departure", "leave", "leaving", "arrive", "arrival",
                    "check in", "checkin", "check out", "what time", "whats on", "agenda", "fly", "flying"]) {
                return .schedule
            }
            if category != nil || has(["booked", "bookings", "booking", "reservations", "reservation"]) {
                return .bookings
            }
            if has(["hows it going", "how is it going", "hows the trip", "going so far", "summary", "summarise", "summarize",
                    "recap", "tell me about", "overview", "how long", "how many days", "status", "where am i going",
                    "where are we going", "how was", "hows"]) {
                return .overview
            }
            return nil
        }

        private func findCategory() -> ItineraryKind? {
            if has(["flight", "flights", "fly", "flying", "plane", "land", "landing", "airport", "airline", "boarding"]) { return .flight }
            if has(["stay", "staying", "hotel", "hotels", "hostel", "villa", "airbnb", "room", "rooms", "accommodation",
                    "sleep", "sleeping", "check in", "checkin", "check out", "resort", "homestay", "stays"]) { return .stay }
            if has(["food", "eat", "eating", "meal", "meals", "dinner", "dinners", "lunch", "lunches", "breakfast",
                    "restaurant", "restaurants", "drinks", "cafe", "brunch"]) { return .meal }
            if has(["train", "trains", "rail"]) { return .train }
            if has(["cab", "cabs", "taxi", "taxis", "uber", "transfer", "transfers", "car", "bus", "drive", "ferry"]) { return .drive }
            if has(["activity", "activities", "tour", "tours", "excursion", "excursions"]) { return .activity }
            return nil
        }

        // MARK: People

        /// First names that are also ordinary words in a question — "will it
        /// rain?" isn't about Will.
        private static let everydayWords: Set<String> = [
            "will", "may", "june", "april", "mark", "bill", "joy", "hope", "grace", "sunny", "summer", "max", "rich", "sky", "rose", "faith"
        ]

        /// A traveller named in the question — first name, whole word — who
        /// isn't the person asking.
        func person(in trips: [Trip]) -> Traveller? {
            let you = Traveller.you.id
            for trip in trips {
                for traveller in trip.travellers where traveller.id != you {
                    guard let first = Self.normalise(traveller.name).split(separator: " ").first.map(String.init),
                          first.count >= 2, !Self.everydayWords.contains(first) else { continue }
                    if has([first]) { return traveller }
                }
            }
            return nil
        }
    }
}

private extension EquiCardKind {
    /// The question a card answered, for a follow-up that doesn't say what
    /// it's asking about.
    var topic: EquiQuery.Topic {
        switch self {
        case .trip, .recap: .overview
        case .balance: .balance
        case .itinerary: .schedule
        case .bookings: .bookings
        case .spending: .spending
        case .people: .people
        case .trips: .trips
        case .gaps: .gaps
        }
    }
}
