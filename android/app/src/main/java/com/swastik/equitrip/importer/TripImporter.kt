package com.swastik.equitrip.importer

import com.swastik.equitrip.model.plural
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import java.time.LocalDate

/** What an import produced, ready for the review screen. */
data class ImportedTrip(
    val title: String,
    val destination: String,
    val currencyCode: String,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val days: List<PlannedDay>,
    /** How many people the document says are travelling — a count, never names. */
    val travellerCount: Int,
    /** Days Nugen answered with low confidence: still checked, but named on review. */
    val unsureDays: List<Int>,
) {
    val items get() = days.flatMap { it.items }
}

class ImportException(message: String) : Exception(message)

/**
 * Booking PDF text → a trip, read by the Nugen domain-aligned model — the Android side of
 * iOS `TripExtractor`'s Nugen path, with one difference: there is no pattern-matching
 * fallback. A day Nugen can't read fails the import, and the screen offers a retry.
 *
 * The division of labour is the iOS one. `ItineraryDocument` decides the days and cuts off
 * the cost tables; the model only names and sorts each day's rows; every time, price and
 * headcount is then copied from the row itself (`validate`), never from the model.
 */
class TripImporter(private val nugen: NugenReader) {

    suspend fun import(text: String, onProgress: (done: Int, total: Int) -> Unit): ImportedTrip {
        val document = ItineraryDocument.parse(text)
        val days = document.days.take(MAX_DAYS)
        if (days.isEmpty()) throw ImportException("Couldn't find any bookings in this PDF.")

        val destination = document.destinationHint?.let(::cityOnly).orEmpty()
        var done = 0
        onProgress(0, days.size)

        val unsure = mutableListOf<Int>()
        val read = coroutineScope {
            val gate = Semaphore(READING_WIDTH)
            days.map { day ->
                async {
                    gate.withPermit {
                        val reading = try {
                            nugen.readDay(dayPrompt(day, destination))
                        } catch (e: NugenException) {
                            throw ImportException("Couldn't read day ${day.number}: ${e.message}")
                        } catch (e: java.io.IOException) {
                            throw ImportException("Couldn't reach Nugen for day ${day.number}. Check your connection.")
                        }
                        val items = reading.items.take(minOf(day.lines.size, MAX_ITEMS_PER_DAY))
                            .mapNotNull { planned(it, day) }
                        val checked = validate(items, day)
                        if (checked.isEmpty()) throw ImportException("Nugen found nothing it could check on day ${day.number}.")
                        synchronized(unsure) {
                            if ((reading.confidence ?: 100.0) < UNSURE_BELOW) unsure += day.number
                            done += 1
                        }
                        onProgress(done, days.size)
                        PlannedDay(day.number, day.date ?: LocalDate.now(), day.heading, checked)
                    }
                }
            }.awaitAll()
        }

        val refined = ItineraryReasoner.refine(read)
        val dates = refined.flatMap { d -> d.items.map { it.day } }.sorted()
        val start = dates.firstOrNull() ?: LocalDate.now()
        return ImportedTrip(
            title = document.title ?: destination.ifEmpty { null }?.let { "${it.substringBefore(",")} trip" } ?: "Imported trip",
            destination = destination,
            currencyCode = document.currencyCode ?: "INR",
            startDate = start,
            endDate = dates.lastOrNull() ?: start,
            days = refined,
            travellerCount = document.travellerCount ?: 0,
            unsureDays = unsure.sorted(),
        )
    }

    /** The prompt format the model was aligned on — identical to iOS `dayPrompt`. Don't reword it. */
    private fun dayPrompt(day: ItineraryDocument.DaySection, destination: String): String {
        val lines = mutableListOf<String>()
        if (destination.isNotEmpty()) lines += "Trip to $destination."
        if (day.heading.isNotEmpty()) lines += "This day: ${day.heading}."
        lines += "It has ${plural(day.lines.size, "row")}."
        lines += ""
        lines += day.promptBody
        return lines.joinToString("\n")
    }

    private fun planned(item: NugenReader.Item, day: ItineraryDocument.DaySection): PlannedItem? {
        val title = item.title?.trim()?.takeIf { it.length >= 2 } ?: return null
        return PlannedItem(
            title = title,
            detail = "",
            day = day.date ?: LocalDate.now(),
            minuteOfDay = item.time?.let(TravelDate::minutes),
            kind = ItineraryReasoner.classify(title, "") ?: NugenReader.kind(item.kind),
            amount = 0.0,
            participantCount = 0,
        )
    }

    /**
     * A day's answer checked against the day's own rows. When the model gave one entry per
     * row, every time, price and headcount is taken from the row; otherwise no more entries
     * than rows, and no price at all — a price from a model becomes somebody's share.
     */
    private fun validate(items: List<PlannedItem>, day: ItineraryDocument.DaySection): List<PlannedItem> {
        val checked = items.take(minOf(day.lines.size, MAX_ITEMS_PER_DAY)).toMutableList()
        if (checked.size != day.lines.size) return checked.map { it.copy(minuteOfDay = null) }

        val described = day.promptBody.split("\n")
        for (index in checked.indices) {
            val line = day.lines[index]
            var item = checked[index]
            val title = settledTitle(item.title, line)
            val detail = described.getOrNull(index)?.let { describe(it, title) } ?: ""
            item = item.copy(
                title = title,
                detail = detail,
                amount = ItineraryDocument.amount(line) ?: 0.0,
                // No clock on the row means no time: a model-supplied 09:30 would be invented.
                minuteOfDay = TravelDate.clockMatches(line).firstOrNull()?.minute,
                participantCount = ItineraryDocument.trailingCount(line) ?: item.participantCount,
            )
            item = item.copy(kind = ItineraryReasoner.classify(title, detail) ?: day.hint(index) ?: item.kind)
            checked[index] = item
        }
        return checked
    }

    private val leadingClock = ci("^\\d{1,2}[:.]\\d{2}\\s*(am|pm)?\\s*")

    /** A bare category ("Flight") or the whole row read back is replaced by the row's own name. */
    private fun settledTitle(title: String, line: String): String {
        val head = ItineraryReasoner.splitTitle(line.replace(leadingClock, "")).first
        val bare = listOf("flight", "hotel", "train", "stay", "activity", "transfer",
            "booking", "tour", "check-in", "check in", "accommodation")
        if (title.trim().lowercase() in bare) return if (head.length >= 2) head else title
        if (title.split(" ").count { it.isNotEmpty() } >= 5 && head.length >= 2) return head
        return title
    }

    /** What's left of the row once its time and name are taken out — copied, so it can't drift. */
    private fun describe(line: String, title: String): String {
        var rest = line.replace(leadingClock, "")
        val head = title.trim()
        if (head.isNotEmpty() && rest.lowercase().startsWith(head.lowercase())) rest = rest.substring(head.length)
        rest = rest.trim { it in " -–—•|:,." }
        return if (rest.equals(title, ignoreCase = true)) "" else rest.take(120)
    }

    companion object {
        private const val MAX_DAYS = 30
        private const val MAX_ITEMS_PER_DAY = 24
        /** Days read at once, as on iOS. */
        private const val READING_WIDTH = 3
        private const val UNSURE_BELOW = 60.0

        /** "Mumbai → Delhi → Mumbai" is a trip to Delhi; "BOM to GOA" is Goa. */
        fun cityOnly(text: String): String {
            val legs = text.replace(Regex(" to ", RegexOption.IGNORE_CASE), "→")
                .split(Regex("[→>]"))
                .map { it.replace(Regex("\\([A-Za-z]{3}\\)"), "").trim { c -> c in " -–—," } }
                .filter { it.isNotEmpty() }
            val first = legs.firstOrNull() ?: return ""
            val last = legs.last()
            if (legs.size == 1) return first
            if (legs.size >= 3 && first.equals(last, ignoreCase = true)) return legs[1]
            return last
        }
    }
}
