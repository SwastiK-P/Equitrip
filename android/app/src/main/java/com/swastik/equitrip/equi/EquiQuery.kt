package com.swastik.equitrip.equi

import com.swastik.equitrip.model.ItineraryKind

/**
 * What a question to Equi is about — topic, trip, category, person, day — worked out on
 * the device before a word of the answer is written. A port of iOS `EquiQuery`.
 *
 * On Android there is no on-device model to classify with, and sending the question to a
 * cloud model just to *sort* it would ship every money question off the phone. So the word
 * rules in `EquiQueryReader` read it alone, and only `ADVICE` and `CHAT` ever reach Groq.
 */
data class EquiQuery(
    val topic: Topic,
    val scope: Scope,
    /** The trips the answer is about, most relevant first. Empty when the scope has none. */
    val tripIds: List<String>,
    val category: ItineraryKind? = null,
    val personId: String? = null,
    val day: Day = Day.ANY,
    /** "Which trip cost the most?" — ranked by cost rather than listed by date. */
    val byCost: Boolean = false,
    /** "Am I over budget?" — the app records no budget, and the answer says so. */
    val asksBudget: Boolean = false,
) {
    enum class Topic { OVERVIEW, SCHEDULE, BOOKINGS, SPENDING, BALANCE, PEOPLE, TRIPS, GAPS, ADVICE, CHAT }
    enum class Day { ANY, TODAY, TOMORROW }
    enum class Scope { NAMED, CURRENT, NEXT, PREVIOUS, ALL, ALL_PAST, ALL_UPCOMING }

    val tripId: String? get() = tripIds.firstOrNull()

    /** The only topics whose reply a cloud model may write. Everything else is answered here. */
    val needsCloud: Boolean get() = topic == Topic.ADVICE || topic == Topic.CHAT
}
