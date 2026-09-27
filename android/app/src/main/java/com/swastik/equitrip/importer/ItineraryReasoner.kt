package com.swastik.equitrip.importer

import java.time.LocalDate

/** One booking read from the document, with its day already decided. */
data class PlannedItem(
    val title: String,
    val detail: String,
    val day: LocalDate,
    /** Minutes since midnight. Null when the row gave no time — not the same as midnight. */
    val minuteOfDay: Int?,
    val kind: ExtractedKind,
    val amount: Double,
    val participantCount: Int,
) {
    val clockText get() = minuteOfDay?.let { "%02d:%02d".format(it / 60, it % 60) } ?: ""
}

data class PlannedDay(val number: Int, val date: LocalDate, val heading: String, val items: List<PlannedItem>)

/**
 * The judgement pass — a port of iOS `ItineraryReasoner`. Deterministic, and it only ever
 * narrows what the model produced: it reclassifies, orders and drops, and never adds a
 * booking, a price or a time.
 */
object ItineraryReasoner {

    fun refine(days: List<PlannedDay>): List<PlannedDay> = days
        .map { it.copy(items = order(dedupe(it.items.mapNotNull(::clean)))) }
        .filter { it.items.isNotEmpty() }
        .sortedBy { it.date }

    private fun clean(item: PlannedItem): PlannedItem? {
        val title = tidyTitle(item.title)
        if (title.length < 2 || isNotABooking(title)) return null
        val detail = tidyDetail(item.detail, title)
        return item.copy(title = title, detail = detail, kind = classify(title, detail) ?: item.kind)
    }

    private val leadingClock = ci("^\\d{1,2}[:.]\\d{2}\\s*(am|pm)?\\s*")
    private val trailingPrice = ci("\\s*$CURRENCY\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$")

    private fun tidyTitle(raw: String) = raw.trim()
        .replace(leadingClock, "")
        .replace(trailingPrice, "")
        .replace(Regex("\\s{2,}"), " ")
        .trim { it in " -–—•|:,." }
        .take(60)

    private fun tidyDetail(raw: String, title: String): String {
        val detail = raw.trim().replace(trailingPrice, "").trim { it in " -–—•|:,." }
        return if (detail.isEmpty() || detail.equals(title, ignoreCase = true)) "" else detail.take(120)
    }

    /** Table furniture that survived the document pass — a summary line is never a booking. */
    private fun isNotABooking(title: String): Boolean {
        val lower = title.lowercase()
        val openers = listOf(
            "total", "subtotal", "grand total", "estimated", "category", "summary",
            "day total", "per person", "cost", "amount", "price", "participants",
            "payer", "split model", "inclusions", "exclusions", "terms",
            "international flights", "accommodation", "local transportation",
            "activities & attractions", "food & dining", "shopping / personal",
        )
        if (openers.any { lower == it || lower.startsWith("$it ") }) return true
        return title.count { it.isLetter() } < 2
    }

    // Classification

    private class Rule(val kind: ExtractedKind, val any: List<String>, val unless: List<String> = emptyList())

    /** Order is the design: flight is asked before transfer and stands down when a cab is mentioned. */
    private val rules = listOf(
        Rule(
            ExtractedKind.STAY,
            listOf("check-in", "check in", "checkin", "check-out", "check out", "checkout",
                "hotel", "resort", "villa", "hostel", "guesthouse", "guest house",
                "airbnb", "accommodation", "apartment", "lodge", "homestay", "riad",
                "night stay", "overnight"),
            listOf("airport", "terminal", "boarding", "flight", "counter", "immigration",
                "breakfast", "brunch", "lunch", "dinner", "supper", "buffet"),
        ),
        Rule(
            ExtractedKind.FLIGHT,
            listOf("flight", "airline", "airport", "terminal", "boarding", "departure formalities",
                "arrival formalities", "immigration", "layover", "fly", "pnr", "aeroplane", "airplane"),
            listOf("transfer", "cab", "taxi", "shuttle", "pickup", "pick-up", "drop",
                "metro", "bus", "train", "coach", "rental"),
        ),
        Rule(
            ExtractedKind.TRAIN,
            listOf("train", "rail", "railway", "eurostar", "tgv", "metro", "subway",
                "tram", "underground", "platform", "sncf", "shinkansen"),
        ),
        Rule(
            ExtractedKind.TRANSFER,
            listOf("transfer", "cab", "taxi", "uber", "ola", "shuttle", "pickup", "pick-up",
                "drop", "bus", "coach", "car rental", "private car", "self drive",
                "chauffeur", "limousine", "scooter", "auto"),
        ),
        Rule(
            ExtractedKind.MEAL,
            listOf("breakfast", "brunch", "lunch", "dinner", "supper", "meal", "restaurant",
                "cafe", "café", "bistro", "coffee", "bakery", "dining", "brasserie",
                "snack", "buffet", "pub", "eatery"),
            listOf("formalities", "counter", "market", "tour"),
        ),
        Rule(
            ExtractedKind.ACTIVITY,
            listOf("tour", "visit", "museum", "gallery", "palace", "tower", "cathedral",
                "basilica", "church", "temple", "monastery", "shrine", "park", "garden",
                "cruise", "show", "cabaret", "concert", "walk", "sightseeing", "shopping",
                "market", "monument", "fort", "castle", "beach", "trek", "hike", "diving",
                "snorkel", "safari", "zoo", "aquarium", "workshop", "experience", "ticket",
                "entry", "summit", "excursion", "free time", "exploration", "quarter",
                "district", "viewpoint", "sunset", "sunrise", "spa", "class", "souvenir",
                "tasting", "food"),
        ),
    )

    /** The title's opening words first, then the whole title, then the detail; vetoes hear the whole row. */
    fun classify(title: String, detail: String): ExtractedKind? {
        val opening = title.split(Regex("\\s+")).filter { it.isNotEmpty() }.take(3).joinToString(" ")
        val everything = "$title $detail"
        return match(opening, everything) ?: match(title, everything) ?: match(everything, everything)
    }

    private fun match(text: String, veto: String): ExtractedKind? {
        val words = tokens(text)
        if (words.isEmpty()) return null
        val joined = text.lowercase()
        val vetoWords = tokens(veto)
        val vetoJoined = veto.lowercase()
        return rules.firstOrNull { rule ->
            rule.any.any { hit(it, words, joined) } && rule.unless.none { hit(it, vetoWords, vetoJoined) }
        }?.kind
    }

    private fun tokens(text: String) = text.lowercase().split(Regex("[^\\p{L}]+")).filter { it.isNotEmpty() }

    /** Short keywords match whole words ("bus" ≠ "business"); longer ones match as prefixes. */
    private fun hit(keyword: String, words: List<String>, joined: String) = when {
        ' ' in keyword || '-' in keyword -> keyword in joined
        keyword.length <= 3 -> keyword in words
        else -> words.any { it.startsWith(keyword) }
    }

    // Ordering

    /** Clock order; an untimed row inherits the time above it so it stays where it was written. */
    fun order(items: List<PlannedItem>): List<PlannedItem> {
        var inherited = 0
        return items.mapIndexed { index, item ->
            item.minuteOfDay?.let { inherited = it }
            Triple(inherited, index, item)
        }.sortedWith(compareBy({ it.first }, { it.second })).map { it.third }
    }

    // Duplicates

    fun dedupe(items: List<PlannedItem>): List<PlannedItem> {
        val seen = mutableSetOf<String>()
        val result = items.filter { item ->
            seen.add(listOf(normalised(item.title), item.clockText, "%.0f".format(item.amount)).joinToString("|"))
        }
        return collapseRestatements(result)
    }

    /** One booking written in two tables: same clock and kind, one name containing the other. */
    private fun collapseRestatements(items: List<PlannedItem>): List<PlannedItem> {
        val result = mutableListOf<PlannedItem>()
        for (item in items) {
            val name = normalised(item.title)
            if (name.length < 4 || item.clockText.isEmpty()) { result += item; continue }
            val index = result.indexOfFirst { existing ->
                if (existing.clockText != item.clockText || existing.kind != item.kind) return@indexOfFirst false
                val other = normalised(existing.title)
                other.length >= 4 && (name in other || other in name)
            }
            if (index < 0) { result += item; continue }
            var kept = result[index]
            if (item.amount > kept.amount) kept = kept.copy(amount = item.amount)
            if (name.length < normalised(kept.title).length) kept = kept.copy(title = item.title)
            if (kept.detail.isEmpty()) kept = kept.copy(detail = item.detail)
            result[index] = kept
        }
        return result
    }

    private fun normalised(title: String) = title.lowercase().filter { it.isLetterOrDigit() }

    // Titles

    private val joiners = setOf("+", "&", "and", "at", "of", "to", "the", "a", "an", "in", "on",
        "for", "with", "via", "-", "–", "—", "→")
    private val typeNouns = setOf("tour", "tours", "train", "flight", "transfer", "museum", "cruise",
        "temple", "fort", "palace", "market", "experience", "tasting", "show",
        "walk", "visit", "safari", "trek", "class", "workshop", "gallery",
        "cathedral", "basilica", "garden", "park", "beach", "check-in", "checkin")

    /**
     * A row's name, from the row itself: before its first delimiter, or its first few words.
     * Used only to correct a model title that is a bare category or the whole row read back.
     */
    fun splitTitle(text: String): Pair<String, String> {
        for (delimiter in listOf(" — ", " – ", " - ", ": ", " | ")) {
            val at = text.indexOf(delimiter)
            if (at >= 0) return text.substring(0, at).trim() to text.substring(at + delimiter.length).trim()
        }
        val words = text.split(" ").filter { it.isNotEmpty() }
        if (words.size <= 4) return text to ""
        var cut = 3
        while (cut < words.size && cut < 6 && words[cut - 1].lowercase() in joiners) cut++
        if (cut < words.size && cut < 6 && words[cut].lowercase().trim { !it.isLetterOrDigit() && it != '-' } in typeNouns) cut++
        return words.take(cut).joinToString(" ") to words.drop(cut).joinToString(" ")
    }
}
