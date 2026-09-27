package com.swastik.equitrip.equi

import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import java.time.format.DateTimeFormatter

/**
 * Everything that decides what leaves the phone when Equi asks Groq.
 *
 * iOS never has this problem: Apple Intelligence runs on the device. Here a cloud model
 * writes advice and small talk, so what it's sent is cut to what that needs:
 *
 * - **Routing** (`EquiQuery.needsCloud`): only advice and small talk are sent. Plans,
 *   money, balances and people are answered by `EquiFacts` on the phone.
 * - **Brief** (`brief`): a trip is described by destination, month, length, group size and
 *   the *kinds* of booking made — no names, titles, vendors, exact dates or amounts.
 * - **Redaction** (`Redactor`): the question and earlier cloud turns have traveller names
 *   swapped for "Person A", trip titles for "the trip", and emails, UPI IDs, phone numbers,
 *   booking references, links and amounts masked. Names are put back into the reply here.
 * - **Grounding** (`isGrounded`): a reply stating an amount is dropped for the on-device
 *   answer — no money from a model, the same rule as iOS.
 */
object EquiPrivacy {

    /** The one-paragraph context the model gets about a trip. Nothing in it identifies anyone. */
    fun brief(trip: Trip?): String {
        trip ?: return "The user hasn't said which trip they mean."
        val month = DateTimeFormatter.ofPattern("MMMM yyyy")
        val start = trip.startDate.format(month)
        val end = trip.endDate.format(month)
        val `when` = if (start == end) "in $start" else "from $start to $end"
        val status = when (trip.phase) {
            TripPhase.UPCOMING -> "upcoming"
            TripPhase.LIVE -> "under way now (${trip.progressLabel.lowercase()})"
            TripPhase.PAST -> "already finished"
        }
        val people = trip.travellers.count { it.id !in trip.invitedIds }.coerceAtLeast(1)
        val kinds = trip.items.groupingBy { it.kind }.eachCount().entries.sortedByDescending { it.value }
            .joinToString(", ") { "${it.value} ${kindWord(it.key, it.value)}" }
        return buildString {
            append("The trip: ${trip.destination}, $`when`, ${trip.dayCount} days, $status, a group of $people.")
            append(if (kinds.isEmpty()) " Nothing is booked yet." else " Booked so far: $kinds.")
        }
    }

    private fun kindWord(kind: ItineraryKind, n: Int) = when (kind) {
        ItineraryKind.FLIGHT -> if (n == 1) "flight" else "flights"
        ItineraryKind.TRAIN -> if (n == 1) "train" else "trains"
        ItineraryKind.DRIVE -> if (n == 1) "transfer" else "transfers"
        ItineraryKind.STAY -> if (n == 1) "stay" else "stays"
        ItineraryKind.ACTIVITY -> if (n == 1) "activity" else "activities"
        ItineraryKind.MEAL -> if (n == 1) "meal" else "meals"
        ItineraryKind.OTHER -> "other"
    }

    /**
     * Masks what identifies people in free text, and remembers the stand-ins it used so a
     * reply that mentions "Person A" can be shown with the real name — on the phone only.
     */
    class Redactor(trips: List<Trip>) {
        private val aliases = linkedMapOf<String, String>()
        private val names: List<Pair<Regex, String>>
        private val titles: List<Regex>

        init {
            val people = trips.flatMap { it.travellers }.distinctBy { it.id }
            var index = 0
            names = people.flatMap { person ->
                val alias = "Person ${alias(index++)}"
                aliases[alias] = person.name.split(" ").first()
                val first = person.name.split(" ").firstOrNull().orEmpty()
                // Full name first, so "Priya Shah" doesn't become "Person A Shah".
                listOf(person.name, first).filter { it.length >= 2 }.distinct().map { word(it) to alias }
            }.sortedByDescending { it.first.pattern.length }
            titles = trips.map { it.title }.filter { it.length >= 3 }.distinct().sortedByDescending { it.length }.map(::word)
        }

        fun redact(text: String): String {
            var out = text
            PATTERNS.forEach { (pattern, mask) -> out = pattern.replace(out, mask) }
            titles.forEach { out = it.replace(out, "the trip") }
            names.forEach { (pattern, alias) -> out = pattern.replace(out, alias) }
            return out
        }

        /** Puts first names back where the reply used a stand-in. */
        fun restore(text: String): String =
            aliases.entries.sortedByDescending { it.key.length }.fold(text) { acc, (alias, name) -> acc.replace(alias, name) }

        private fun word(text: String) = Regex("(?<![\\p{L}\\p{N}])${Regex.escape(text)}(?![\\p{L}\\p{N}])", RegexOption.IGNORE_CASE)

        private fun alias(i: Int): String = if (i < 26) ('A' + i).toString() else "${'A' + i / 26 - 1}${'A' + i % 26}"

        companion object {
            /** Order matters: links and emails before the digit runs inside them. */
            private val PATTERNS = listOf(
                Regex("https?://\\S+|www\\.\\S+", RegexOption.IGNORE_CASE) to "[link]",
                // Emails and UPI IDs (name@bank) share a shape.
                Regex("[\\w.+-]+@[\\w.-]+") to "[account]",
                Regex("(?:[₹$€£¥]|\\b(?:rs\\.?|inr|usd|eur|gbp)\\s?)\\s?\\d[\\d,]*(?:\\.\\d+)?", RegexOption.IGNORE_CASE) to "[amount]",
                Regex("\\d[\\d,]*(?:\\.\\d+)?\\s?(?:rupees|rs|inr|dollars|usd|euros?|eur|pounds|gbp)\\b", RegexOption.IGNORE_CASE) to "[amount]",
                Regex("\\+?\\d[\\d\\s-]{7,}\\d") to "[number]",
                // PNRs, booking and card-ending references: 5+ characters mixing letters and digits.
                Regex("\\b(?=[A-Za-z0-9]*\\d)(?=[A-Za-z0-9]*[A-Za-z])[A-Za-z0-9]{5,}\\b") to "[reference]",
            )
        }
    }

    /**
     * Whether a reply is free of amounts. The model is told it has no figures and must not
     * give prices; this is for the time it does anyway. Plain numbers (days, degrees) pass.
     */
    fun isGrounded(reply: String): Boolean = MONEY.find(reply) == null

    private val MONEY = Regex(
        "[₹$€£¥]\\s?\\d|\\b\\d[\\d,]*(?:\\.\\d+)?\\s?(?:rupees|rs\\.?|inr|dollars|usd|euros?|eur|pounds|gbp)\\b",
        RegexOption.IGNORE_CASE,
    )
}
