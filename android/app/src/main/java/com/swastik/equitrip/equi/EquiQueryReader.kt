package com.swastik.equitrip.equi

import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import java.text.Normalizer

/** One earlier turn: what was said, and the trip and topic its answer was about. */
data class EquiTurn(
    val isUser: Boolean,
    val text: String,
    val tripId: String? = null,
    val topic: EquiQuery.Topic? = null,
)

/**
 * Reads a question into an `EquiQuery` with word rules alone — the `Cues` half of iOS
 * `EquiQueryReader`, without its model pass.
 *
 * iOS merges the rules with an on-device classifier. Android has no on-device model, and
 * classifying in the cloud would send every question — "what do I owe Priya?" included —
 * to Groq. The rules catch what a question says outright, and a question that names no
 * trip follows the conversation: the trip the last answer was about, then the one under
 * way or coming up next.
 */
object EquiQueryReader {

    fun read(question: String, turns: List<EquiTurn>, trips: List<Trip>, myId: String?): EquiQuery {
        val cues = Cues(question, trips)
        val focus = turns.lastOrNull { it.tripId != null }?.let { turn -> trips.firstOrNull { it.id == turn.tripId } }
        val previousTopic = turns.lastOrNull { !it.isUser }?.topic

        var scope: EquiQuery.Scope
        var chosen: List<Trip>
        if (cues.named.isNotEmpty()) {
            scope = EquiQuery.Scope.NAMED
            chosen = cues.named
        } else {
            scope = cues.scope ?: EquiQuery.Scope.CURRENT
            chosen = resolve(scope, trips, focus)
        }

        var topic = cues.topic
            ?: if (cues.isFollowUp && previousTopic != null) previousTopic
            else when (scope) {
                EquiQuery.Scope.ALL, EquiQuery.Scope.ALL_PAST, EquiQuery.Scope.ALL_UPCOMING -> EquiQuery.Topic.TRIPS
                EquiQuery.Scope.CURRENT -> previousTopic ?: EquiQuery.Topic.OVERVIEW
                else -> EquiQuery.Topic.OVERVIEW
            }
        if (topic == EquiQuery.Topic.TRIPS && (scope == EquiQuery.Scope.CURRENT || scope == EquiQuery.Scope.NAMED) && chosen.size <= 1) {
            // "Tell me about the trip" read as a list of one.
            topic = EquiQuery.Topic.OVERVIEW
        }
        if (topic == EquiQuery.Topic.TRIPS && chosen.size <= 1 && scope != EquiQuery.Scope.NAMED) {
            val keep = scope == EquiQuery.Scope.ALL_PAST || scope == EquiQuery.Scope.ALL_UPCOMING
            chosen = resolve(if (keep) scope else EquiQuery.Scope.ALL, trips, focus)
            if (!keep) scope = EquiQuery.Scope.ALL
        }
        if (topic !in setOf(EquiQuery.Topic.TRIPS, EquiQuery.Topic.BALANCE, EquiQuery.Topic.SPENDING) && chosen.size > 1) {
            chosen = chosen.take(1)
        }
        // "What's next?" while talking about a trip that's over means the one that isn't.
        if (scope == EquiQuery.Scope.CURRENT && (topic == EquiQuery.Topic.SCHEDULE || topic == EquiQuery.Topic.GAPS) &&
            chosen.firstOrNull()?.phase == TripPhase.PAST
        ) {
            resolve(EquiQuery.Scope.ALL_UPCOMING, trips, null).firstOrNull()?.let { chosen = listOf(it) }
        }

        val people = chosen.firstOrNull()?.let(::listOf) ?: trips
        return EquiQuery(
            topic = topic,
            scope = scope,
            tripIds = chosen.map { it.id },
            category = cues.category,
            personId = cues.person(people, myId)?.id,
            day = cues.day ?: EquiQuery.Day.ANY,
            byCost = cues.has("most", "least", "expensive", "cheapest", "cost", "costs", "costliest", "priciest",
                "spent", "spend", "biggest", "cheaper", "pricier", "rank"),
            asksBudget = cues.has("budget", "over budget", "afford", "overspent", "overspending"),
        )
    }

    /** Pins a scope to real trips. `PREVIOUS` and `NEXT` come back empty when there isn't one. */
    fun resolve(scope: EquiQuery.Scope, trips: List<Trip>, focus: Trip?): List<Trip> {
        val past = trips.filter { it.phase == TripPhase.PAST }.sortedByDescending { it.endDate }
        val upcoming = trips.filter { it.phase == TripPhase.UPCOMING }.sortedBy { it.startDate }
        val live = trips.filter { it.phase == TripPhase.LIVE }
        return when (scope) {
            EquiQuery.Scope.NAMED, EquiQuery.Scope.CURRENT ->
                listOfNotNull(focus ?: live.firstOrNull() ?: byRelevance(trips).firstOrNull())
            EquiQuery.Scope.NEXT -> upcoming.take(1)
            EquiQuery.Scope.PREVIOUS -> past.take(1)
            EquiQuery.Scope.ALL -> byRelevance(trips)
            EquiQuery.Scope.ALL_PAST -> past
            EquiQuery.Scope.ALL_UPCOMING -> live + upcoming
        }
    }

    /** Under way, then soonest to start, then most recently ended. */
    fun byRelevance(trips: List<Trip>): List<Trip> =
        trips.filter { it.phase == TripPhase.LIVE } +
            trips.filter { it.phase == TripPhase.UPCOMING }.sortedBy { it.startDate } +
            trips.filter { it.phase == TripPhase.PAST }.sortedByDescending { it.endDate }

    /**
     * What a question says outright. Phrases match whole words against a folded copy —
     * lowercase, no accents, apostrophes dropped ("who's" → "whos"), everything else a space.
     */
    class Cues(question: String, trips: List<Trip>) {
        private val text = " " + normalise(question) + " "
        val named: List<Trip> = namedTrips(trips)
        val scope: EquiQuery.Scope? = findScope()
        val category: ItineraryKind? = findCategory()
        val day: EquiQuery.Day? = when {
            has("today", "tonight", "this evening") -> EquiQuery.Day.TODAY
            has("tomorrow", "tmrw") -> EquiQuery.Day.TOMORROW
            else -> null
        }
        val topic: EquiQuery.Topic? = findTopic()

        fun has(vararg phrases: String) = phrases.any { text.contains(" $it ") }

        private val wordCount get() = text.trim().split(" ").count { it.isNotEmpty() }

        /** "and Kerala?", "what about Ed?" — leans on the last question for what it's asking. */
        val isFollowUp: Boolean
            get() = listOf(" and ", " what about ", " how about ", " same for ").any { text.startsWith(it) } || wordCount <= 2

        private fun namedTrips(trips: List<Trip>): List<Trip> = trips.mapNotNull { trip ->
            var score = 0
            val title = normalise(trip.title)
            if (title.length >= 3 && text.contains(" $title ")) score += 5
            normalise(trip.destination).split(" ").filter { it.length >= 3 && it !in GENERIC && has(it) }.forEach { _ -> score += 3 }
            title.split(" ").filter { it.length >= 3 && it !in GENERIC && has(it) }.forEach { _ -> score += 2 }
            if (score > 0) trip to score else null
        }.sortedByDescending { it.second }.map { it.first }

        private fun findScope(): EquiQuery.Scope? = when {
            has("past trips", "previous trips", "old trips", "finished trips", "completed trips", "trips ive been on",
                "trips i took", "trips weve done", "where have i been", "where ive been", "places ive been") -> EquiQuery.Scope.ALL_PAST
            has("upcoming trips", "future trips", "next trips", "planned trips", "coming trips") -> EquiQuery.Scope.ALL_UPCOMING
            has("last trip", "previous trip", "most recent trip", "recent trip", "last holiday", "last vacation",
                "last time", "past trip", "trip before", "last one", "previous one") -> EquiQuery.Scope.PREVIOUS
            has("next trip", "upcoming trip", "next holiday", "next vacation", "coming trip") -> EquiQuery.Scope.NEXT
            has("all my trips", "all trips", "my trips", "every trip", "each trip", "all of my trips", "which trip",
                "how many trips", "compare", "anywhere", "across", "any trip", "all the trips", "both trips") -> EquiQuery.Scope.ALL
            else -> null
        }

        /** Most specific words first, so "how much do I owe" is a balance before it's a cost. */
        private fun findTopic(): EquiQuery.Topic? = when {
            wordCount <= 3 && has("hi", "hello", "hey", "thanks", "thank you", "thx", "ok", "okay", "cool", "great",
                "yo", "good morning", "good night") -> EquiQuery.Topic.CHAT
            has("gap", "gaps", "missing", "forgot", "forgotten", "forget", "unbooked", "not booked", "still need to book",
                "havent booked", "empty day", "free day", "free days", "nothing planned", "left to book", "anything left") -> EquiQuery.Topic.GAPS
            has("owe", "owes", "owed", "owing", "settle", "settled", "settling", "pay back", "payback", "paid back",
                "square", "squared", "debt", "debts", "balance", "balances", "who pays", "i get back", "get back") -> EquiQuery.Topic.BALANCE
            has("whos on", "who is on", "whos coming", "who is coming", "whos going", "who is going", "who else",
                "travellers", "travelers", "members", "people", "who paid", "paid the most", "paid most",
                "contributed", "whos in", "who all") -> EquiQuery.Topic.PEOPLE
            has("pack", "packing", "weather", "wear", "temperature", "rain", "raining", "recommend", "recommendation",
                "suggest", "suggestion", "worth seeing", "worth visiting", "things to do", "what to do", "sightseeing",
                "tips", "nearby", "should i eat", "must try", "best time", "visa", "language", "safe", "currency exchange",
                "local", "culture", "etiquette") -> EquiQuery.Topic.ADVICE
            scope == EquiQuery.Scope.ALL || scope == EquiQuery.Scope.ALL_PAST || scope == EquiQuery.Scope.ALL_UPCOMING ||
                named.size > 1 || has("trips") -> EquiQuery.Topic.TRIPS
            category == null && has("when is my", "when does my", "when is the trip", "how long until", "how many days until",
                "how many days left", "countdown", "when do we leave for") -> EquiQuery.Topic.OVERVIEW
            has("spend", "spent", "spending", "cost", "costs", "costing", "expensive", "cheapest", "budget", "how much",
                "price", "pricey", "splurge", "money go", "money going", "money went", "total", "damage") -> EquiQuery.Topic.SPENDING
            // "Next" is the trip's own word in "my next trip", not a question about the plan.
            scope != EquiQuery.Scope.NEXT && scope != EquiQuery.Scope.ALL_UPCOMING && has("next", "up next") -> EquiQuery.Topic.SCHEDULE
            has("today", "tonight", "tomorrow", "when", "schedule", "plan for", "happening", "itinerary", "land", "landing",
                "depart", "departure", "leave", "leaving", "arrive", "arrival", "check in", "checkin", "check out",
                "what time", "whats on", "agenda", "fly", "flying") -> EquiQuery.Topic.SCHEDULE
            category != null || has("booked", "bookings", "booking", "reservations", "reservation") -> EquiQuery.Topic.BOOKINGS
            has("hows it going", "how is it going", "hows the trip", "going so far", "summary", "summarise", "summarize",
                "recap", "tell me about", "overview", "how long", "how many days", "status", "where am i going",
                "where are we going", "how was", "hows") -> EquiQuery.Topic.OVERVIEW
            else -> null
        }

        private fun findCategory(): ItineraryKind? = when {
            has("flight", "flights", "fly", "flying", "plane", "land", "landing", "airport", "airline", "boarding") -> ItineraryKind.FLIGHT
            has("stay", "staying", "hotel", "hotels", "hostel", "villa", "airbnb", "room", "rooms", "accommodation",
                "sleep", "sleeping", "check in", "checkin", "check out", "resort", "homestay", "stays") -> ItineraryKind.STAY
            has("food", "eat", "eating", "meal", "meals", "dinner", "dinners", "lunch", "lunches", "breakfast",
                "restaurant", "restaurants", "drinks", "cafe", "brunch") -> ItineraryKind.MEAL
            has("train", "trains", "rail") -> ItineraryKind.TRAIN
            has("cab", "cabs", "taxi", "taxis", "uber", "transfer", "transfers", "car", "bus", "drive", "ferry") -> ItineraryKind.DRIVE
            has("activity", "activities", "tour", "tours", "excursion", "excursions") -> ItineraryKind.ACTIVITY
            else -> null
        }

        /** A traveller named in the question — first name, whole word — who isn't the one asking. */
        fun person(trips: List<Trip>, myId: String?): Traveller? {
            for (trip in trips) for (traveller in trip.travellers) {
                if (traveller.id == myId) continue
                val first = normalise(traveller.name).split(" ").firstOrNull() ?: continue
                if (first.length < 2 || first in EVERYDAY_WORDS) continue
                if (has(first)) return traveller
            }
            return null
        }

        companion object {
            fun normalise(text: String): String {
                val folded = Normalizer.normalize(text.lowercase(), Normalizer.Form.NFD)
                    .replace(Regex("\\p{M}+"), "")
                    .replace("'", "").replace("’", "")
                return folded.split(Regex("[^\\p{L}\\p{N}]+")).filter { it.isNotEmpty() }.joinToString(" ")
            }

            /** Words in a trip's name that say nothing about which trip it is. */
            private val GENERIC = setOf(
                "the", "and", "with", "for", "our", "trip", "trips", "getaway", "holiday", "holidays", "vacation",
                "weekend", "summer", "winter", "spring", "autumn", "fall", "family", "friends", "road", "tour",
                "week", "days", "day", "long", "big", "little", "new", "year", "girls", "boys", "work", "team",
                "first", "last", "next", "back", "home", "city", "beach", "escape", "break", "time", "fun",
                "what", "where", "when", "how", "who", "much", "all", "money", "plan", "food", "stay",
            )

            /** First names that are also ordinary words — "will it rain?" isn't about Will. */
            private val EVERYDAY_WORDS = setOf(
                "will", "may", "june", "april", "mark", "bill", "joy", "hope", "grace", "sunny", "summer", "max",
                "rich", "sky", "rose", "faith",
            )
        }
    }
}
