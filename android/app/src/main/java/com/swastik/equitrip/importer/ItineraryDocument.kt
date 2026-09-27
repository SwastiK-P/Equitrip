package com.swastik.equitrip.importer

import java.time.LocalDate

/** What a row is, as the reader and the rules name it — iOS `ExtractedKind`. */
enum class ExtractedKind { FLIGHT, TRAIN, TRANSFER, STAY, ACTIVITY, MEAL, OTHER }

/** The currency marks a price can open with, shared by every amount pattern. */
internal const val CURRENCY = "(?:₹|rs\\.?|inr|\\\$|usd|€|eur|£|gbp)"

internal fun ci(pattern: String) = Regex(pattern, RegexOption.IGNORE_CASE)

/**
 * A booking document read for its *shape*, before anything reads it for meaning — a port of
 * iOS `ItineraryDocument`.
 *
 * Which lines are the header, which belong to which dated day, and which are the appendix
 * (cost summaries, payment tables) that must never become bookings is worked out here,
 * deterministically. The model is then asked one small question per day with the date
 * supplied, so it can neither invent bookings from the cost table nor drift a day.
 * Keep the two ports in step: a document should split the same way on both platforms.
 */
class ItineraryDocument private constructor() {

    /** One dated block of the itinerary. */
    data class DaySection(
        /** 1-based, in document order — not necessarily the "DAY n" label. */
        val number: Int,
        val date: LocalDate?,
        /** The line under the date header: "Montmartre | Sacré-Cœur". */
        val heading: String,
        /** The rows, cleaned of table furniture and totals. */
        val lines: List<String>,
        /** What the table each row came from was a table of, aligned with `lines`. */
        val hints: List<ExtractedKind?> = emptyList(),
    ) {
        fun hint(index: Int) = hints.getOrNull(index)

        /** The rows with their price and participant columns taken off — those are read from the text. */
        val promptBody: String
            get() = lines.joinToString("\n") { line ->
                line.replace(ci("\\s*$CURRENCY\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}\\s*$"), "")
                    .replace(ci("\\s+(included|free|complimentary|n/a)\\s*\\d{0,2}\\s*$"), "")
                    .trim()
            }
    }

    var preamble: List<String> = emptyList(); private set
    var days: List<DaySection> = emptyList(); private set
    /** Cost summaries, ledger tables, terms — read for context, never for items. */
    var appendix: List<String> = emptyList(); private set
    var travellerCount: Int? = null; private set
    /** Only names actually written down. */
    var namedTravellers: List<String> = emptyList(); private set
    var currencyCode: String? = null; private set
    var title: String? = null; private set
    var destinationHint: String? = null; private set
    /** The whole cleaned body, lowercased, for checking a name the model gave is really there. */
    var haystack: String = ""; private set
    private var rawTail: List<String> = emptyList()

    companion object {
        fun parse(raw: String, reference: LocalDate = LocalDate.now()): ItineraryDocument {
            val document = ItineraryDocument()
            val cleaned = stripFurniture(raw.split(Regex("\\r\\n|\\r|\\n|\\u2028|\\u2029")))
                .flatMap(::explodeRunTogetherRows)
                .filter { it.isNotEmpty() }

            document.haystack = cleaned.joinToString("\n").lowercase()
            document.rawTail = cleaned

            val markers = dayMarkers(cleaned, reference)

            // Fewer than two day headings may still be a table that dates its own rows.
            if (markers.size < 2) {
                tabularParse(cleaned, reference)?.let { (preamble, days, appendix) ->
                    document.preamble = preamble
                    document.days = days
                    document.appendix = appendix
                    document.absorbHeaderFacts()
                    return document
                }
            }

            val first = markers.firstOrNull()
            if (first == null) {
                // No day headers at all — an email confirmation, a single booking.
                val (body, appendix) = splitAppendix(cleaned)
                document.preamble = body.take(12)
                document.appendix = appendix
                // A line with no number in it is the letter around the booking, not a booking.
                val candidates = body.filter { line -> line.any { it.isDigit() } }
                val rows = candidates.ifEmpty { body }
                if (rows.isNotEmpty()) {
                    document.days = listOf(
                        DaySection(1, TravelDate.first(body.joinToString(" "), reference), "", cleanRows(rows)),
                    )
                }
                document.absorbHeaderFacts()
                return document
            }

            document.preamble = cleaned.subList(0, first.index)
            val days = mutableListOf<DaySection>()
            val appendix = mutableListOf<String>()
            markers.forEachIndexed { offset, marker ->
                val start = marker.index + 1
                val end = if (offset + 1 < markers.size) markers[offset + 1].index else cleaned.size
                if (start > end) return@forEachIndexed
                val (body, tail) = splitAppendix(cleaned.subList(start, end))
                appendix += tail
                val block = body.toMutableList()
                val heading = block.firstOrNull()?.takeUnless { isRow(it) || isFurniture(it) } ?: ""
                if (heading.isNotEmpty()) block.removeAt(0)
                days += DaySection(offset + 1, marker.date, heading, cleanRows(block))
            }
            document.days = days
            document.appendix = appendix
            document.inferMissingDates()
            document.repairOrphanedAmounts()
            document.absorbHeaderFacts()
            document.days = document.days.filter { it.lines.isNotEmpty() }
            return document
        }

        // Furniture

        /** Page headers and footers repeat on every page and carry nothing. */
        private fun stripFurniture(lines: List<String>): List<String> {
            val trimmed = lines.map { it.trim() }
            val frequency = trimmed.filter { it.length < 90 }.groupingBy { it }.eachCount()
            val page = ci("\\bpage\\s+\\d+\\b")
            return trimmed.filter { line ->
                when {
                    line.isEmpty() -> false
                    line.length < 90 && page.containsMatchIn(line) -> false
                    (frequency[line] ?: 0) >= 3 && line.length < 90 -> false
                    else -> true
                }
            }
        }

        /** A whole table body extracted as one line: three or more clock times means rows run together. */
        private fun explodeRunTogetherRows(line: String): List<String> {
            if (line.length <= 100) return listOf(line)
            val matches = Regex("(?<![\\d:])\\d{1,2}:\\d{2}(?![\\d:])").findAll(line).toList()
            if (matches.size < 3) return listOf(line)
            val pieces = mutableListOf<String>()
            var cursor = 0
            for (m in matches) {
                val start = m.range.first
                if (start <= cursor) continue
                pieces += line.substring(cursor, start)
                cursor = start
            }
            pieces += line.substring(cursor)
            return pieces.map { it.trim() }.filter { it.isNotEmpty() }
        }

        // Day markers

        private class DayMarker(val index: Int, val date: LocalDate?)

        private fun dayMarkers(lines: List<String>, reference: LocalDate): List<DayMarker> =
            lines.mapIndexedNotNull { index, line ->
                if (!looksLikeDayHeader(line)) return@mapIndexedNotNull null
                // A date on the header wins; failing that, the line under it often carries one.
                val date = TravelDate.first(line, reference)
                    ?: lines.getOrNull(index + 1)?.takeIf { it.length < 60 }?.let { TravelDate.first(it, reference) }
                DayMarker(index, date)
            }

        private val dayWord = ci("^day\\s*\\d+\\b")
        private val dateOpening = ci(
            "^(?:\\d{1,2}\\b|\\d{4}-|(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday" +
                "|mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun" +
                "|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))",
        )

        private fun looksLikeDayHeader(line: String): Boolean {
            if (line.length > 110) return false
            if (dayWord.containsMatchIn(line)) return true
            // Otherwise essentially just a date. "Check-in 12 Sep" is a booking, not a heading.
            if (isRow(line) || amount(line) != null) return false
            if (line.count { it.isLetter() } > 32) return false
            if (TravelDate.first(line) == null) return false
            return dateOpening.containsMatchIn(line)
        }

        // Tables that date their own rows

        private enum class TableKind(val hint: ExtractedKind?) {
            FLIGHTS(ExtractedKind.FLIGHT), STAYS(ExtractedKind.STAY), ACTIVITIES(null), LEDGER(null)
        }

        private val tableHeadings = listOf(
            "flight" to TableKind.FLIGHTS, "air travel" to TableKind.FLIGHTS, "air ticket" to TableKind.FLIGHTS,
            "accommodation" to TableKind.STAYS, "hotel" to TableKind.STAYS, "stay" to TableKind.STAYS,
            "lodging" to TableKind.STAYS, "rooms" to TableKind.STAYS,
            "activit" to TableKind.ACTIVITIES, "sightseeing" to TableKind.ACTIVITIES,
            "excursion" to TableKind.ACTIVITIES, "tour" to TableKind.ACTIVITIES,
            "transport" to TableKind.ACTIVITIES, "transfer" to TableKind.ACTIVITIES,
            "day-by-day" to TableKind.ACTIVITIES, "day by day" to TableKind.ACTIVITIES,
            "schedule" to TableKind.ACTIVITIES, "itinerary" to TableKind.ACTIVITIES,
            "bookings" to TableKind.ACTIVITIES,
            "expense" to TableKind.LEDGER, "payment record" to TableKind.LEDGER, "payment" to TableKind.LEDGER,
            "transaction" to TableKind.LEDGER, "ledger" to TableKind.LEDGER, "billing" to TableKind.LEDGER,
            "invoice" to TableKind.LEDGER, "cost summary" to TableKind.LEDGER, "receipts" to TableKind.LEDGER,
        )

        /** A short line of words, no date and no price, that names the table under it. */
        private fun tableHeading(line: String): TableKind? {
            if (line.length > 60 || amount(line) != null || line.any { it.isDigit() }) return null
            val lower = line.lowercase().trim { it in " :—–-" }
            return tableHeadings.firstOrNull { lower.startsWith(it.first) }?.second
        }

        private fun looksLikeProse(line: String): Boolean {
            val trimmed = line.trim()
            val first = trimmed.firstOrNull() ?: return true
            if (first in "•*◦▪·") return true
            val words = trimmed.split(" ").filter { it.isNotEmpty() }
            if (trimmed.endsWith(".") && words.size > 10) return true
            return words.size > 22
        }

        private val nightsBeforeStatus =
            ci("\\b\\d{1,2}\\s+(?=(?:confirmed|pending|cancelled|refunded|paid|included|complimentary)\\b)")
        private val status = ci("\\b(?:confirmed|pending|cancelled|refunded|booked)\\b")
        private val referenceCode = ci("\\b(?:txn|ref|pnr|conf)[-–—#: ]?[a-z0-9][a-z0-9-]{3,}\\b")
        private val trailingAmount = ci("$CURRENCY\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*$")

        private class DatedRow(val date: LocalDate, val minute: Int?, val line: String)

        /** One self-dating table row, rewritten as "HH:mm booking price" for everything downstream. */
        private fun datedRow(line: String, kind: TableKind, reference: LocalDate): DatedRow? {
            if (looksLikeProse(line) || isFurniture(line)) return null
            val dates = TravelDate.matches(line, reference)
            val first = dates.firstOrNull() ?: return null
            val clocks = TravelDate.clockMatches(line)
            // A date on its own is a sentence that mentions one; beside a time or price it's a row.
            if (clocks.isEmpty() && amount(line) == null) return null

            var body = line
            merged(dates.map { it.range } + clocks.map { it.range }).asReversed().forEach { range ->
                body = body.removeRange(range)
            }
            body = body.replace(nightsBeforeStatus, "")
                .replace(status, "")
                .replace(referenceCode, "")
                .replace(Regex("\\s{2,}"), " ")
                .trim { it in " ,;:—–-" }

            var amountText = ""
            trailingAmount.find(body)?.let { m ->
                amountText = m.value.trim()
                body = body.removeRange(m.range)
            }
            body = body.trim { it in " ,;:—–-*†‡" }
            if (body.count { it.isLetter() } < 3) return null

            if (kind == TableKind.FLIGHTS && !body.contains("flight", ignoreCase = true)) body = "Flight $body"

            val minute = clocks.firstOrNull()?.minute
            val pieces = listOfNotNull(minute?.let { "%02d:%02d".format(it / 60, it % 60) }, body, amountText.ifEmpty { null })
            return DatedRow(first.date, minute, pieces.joinToString(" "))
        }

        private fun merged(ranges: List<IntRange>): List<IntRange> {
            val kept = mutableListOf<IntRange>()
            for (range in ranges.sortedBy { it.first }) {
                val last = kept.lastOrNull()
                if (last != null && range.first <= last.last) continue
                kept += range
            }
            return kept
        }

        /** Category tables of self-dating rows. Nil unless it really works: 4+ rows over 2+ days. */
        private fun tabularParse(
            lines: List<String>,
            reference: LocalDate,
        ): Triple<List<String>, List<DaySection>, List<String>>? {
            var kind = TableKind.ACTIVITIES
            var seenHeading = false
            val preamble = mutableListOf<String>()
            val appendix = mutableListOf<String>()
            class Row(val date: LocalDate, val minute: Int?, val line: String, val hint: ExtractedKind?)
            val rows = mutableListOf<Row>()

            for (line in lines) {
                val heading = tableHeading(line)
                if (heading != null) {
                    kind = heading
                    seenHeading = true
                    if (heading == TableKind.LEDGER) appendix += line
                    continue
                }
                // A payments table restates bookings listed above it. Read once, not twice.
                if (kind == TableKind.LEDGER) {
                    appendix += line
                    continue
                }
                val row = datedRow(line, kind, reference)
                if (row != null) rows += Row(row.date, row.minute, row.line, kind.hint)
                else if (!seenHeading) preamble += line
            }

            if (rows.size < 4 || rows.map { it.date }.distinct().size < 2) return null
            val days = rows.groupBy { it.date }.toSortedMap().entries.mapIndexed { index, (day, group) ->
                val ordered = group.sortedBy { it.minute ?: -1 }
                DaySection(index + 1, day, "", ordered.map { it.line }, ordered.map { it.hint })
            }
            return Triple(preamble.take(12), days, appendix)
        }

        // Appendix

        private val appendixHeadings = listOf(
            "trip cost summary", "cost summary", "price summary", "summary of costs",
            "ledger-ready structure", "ledger ready structure",
            "terms and conditions", "terms & conditions", "cancellation policy",
            "payment schedule", "inclusions", "exclusions", "what's included",
            "important information", "booking conditions", "category",
            "expenses", "expense record", "payment record", "payments",
            "transactions", "ledger", "billing", "invoice", "receipts",
        )

        private fun splitAppendix(lines: List<String>): Pair<List<String>, List<String>> {
            lines.forEachIndexed { index, line ->
                val lower = line.lowercase()
                if (line.length <= 60 && appendixHeadings.any { lower.startsWith(it) }) {
                    return lines.subList(0, index) to lines.subList(index, lines.size)
                }
            }
            return lines to emptyList()
        }

        // Row cleaning

        private val dayTotalTail = ci("\\s*\\b(?:day\\s+)?(?:total|subtotal)\\s*[:\\-].*$")

        private fun cleanRows(lines: List<String>): List<String> {
            val rows = lines.map { it.replace(dayTotalTail, "").trim() }.filter { !isFurniture(it) }
            // In a timetable every booking starts with a clock; anything else is wrapped prose.
            val timed = rows.filter(::isRow)
            if (timed.size < 2 || timed.size.toDouble() / rows.size < 0.6) return rows
            return timed
        }

        private val headerWords = listOf(
            "time", "item", "details", "description", "cost", "amount",
            "participants", "pax", "activity", "price", "category", "payer",
            "split model", "group cost",
        )
        private val totalOpening = Regex("^(sub)?total\\b")
        private val noteOpening =
            Regex("^(note|notes|sharing example|prototype note|important|tip|disclaimer|please note)\\b\\s*:")

        private fun isFurniture(line: String): Boolean {
            val lower = line.lowercase()
            if (lower.startsWith("day total") || lower.startsWith("total for")) return true
            if (totalOpening.containsMatchIn(lower) || noteOpening.containsMatchIn(lower)) return true
            val words = lower.split(Regex("[^\\p{L}\\p{N}]+")).filter { it.length > 2 }
            if (words.size >= 3 && words.all { word -> headerWords.any { it.contains(word) } }) return true
            if (isOrphanAmount(line)) return true
            return line.count { it.isLetterOrDigit() } < 3
        }

        private val rowStart = Regex("^\\d{1,2}:\\d{2}\\b")
        private fun isRow(line: String) = rowStart.containsMatchIn(line)

        private val orphanAmount = ci("^$CURRENCY\\s*[\\d,]+(?:\\.\\d{1,2})?\\s*\\d{0,2}$")
        private fun isOrphanAmount(line: String) = orphanAmount.containsMatchIn(line)

        // Header facts

        fun travellerCount(text: String): Int? {
            val patterns = listOf(
                "(?:travell?ers?|passengers?|guests?|pax|party size|group size|adults?)\\s*[:\\-]?\\s*(\\d{1,2})\\b",
                "\\b(\\d{1,2})\\s*(?:people|persons?|adults?|travell?ers?|passengers?|guests?|pax)\\b",
            )
            for (pattern in patterns) {
                val value = ci(pattern).find(text)?.groupValues?.get(1)?.toIntOrNull() ?: continue
                if (value in 1..30) return value
            }
            return null
        }

        private val trailingCountRegex = Regex("\\b(\\d{1,2})\\s*$")

        /** The participants column: the number a table row ends with, 1–30. */
        fun trailingCount(line: String): Int? =
            trailingCountRegex.find(line)?.value?.trim()?.toIntOrNull()?.takeIf { it in 1..30 }

        private fun participantColumnCount(days: List<DaySection>): Int? {
            val tally = days.flatMap { it.lines }.mapNotNull(::trailingCount).groupingBy { it }.eachCount()
            val best = tally.maxByOrNull { it.value } ?: return null
            return if (best.value >= 3) best.key else null
        }

        private val nameLabel =
            ci("^(?:passengers?|travell?ers?|guests?|names?|party|in the name of|lead passenger)\\s*[:\\-]")
        private val nextLabel =
            ci("\\s+\\b(?:trip|tour|dates?|destination|route|package|from|to|booking|ref)\\b\\s*[:\\-]")

        /** Names only when the document writes them out after a label — a headcount is not names. */
        private fun explicitNames(lines: List<String>): List<String> {
            val found = mutableListOf<String>()
            for (line in lines) {
                if (!nameLabel.containsMatchIn(line)) continue
                val cut = line.indexOfFirst { it == ':' || it == '-' }
                var tail = if (cut >= 0) line.substring(cut + 1) else ""
                nextLabel.find(tail)?.let { tail = tail.substring(0, it.range.first) }
                if (tail.none { it.isLetter() }) continue
                for (piece in tail.split(Regex("[,/&+;]"))) {
                    val name = piece.trim().trim { !it.isLetterOrDigit() && !it.isWhitespace() }.trim()
                    if (name.length !in 2..28 || !name.first().isUpperCase() || name.any { it.isDigit() }) continue
                    if (found.any { it.equals(name, ignoreCase = true) }) continue
                    found += name
                }
            }
            return found.take(12)
        }

        private fun labelled(labels: String, lines: List<String>): String? {
            val regex = ci("^(?:$labels)\\s*[:\\-]?\\s+")
            for (line in lines) {
                val m = regex.find(line) ?: continue
                val value = line.substring(m.range.last + 1).trim()
                if (value.length in 3..60) return value
            }
            return null
        }

        fun currency(text: String): String? = when {
            "₹" in text || ci("\\binr\\b").containsMatchIn(text) -> "INR"
            "€" in text || ci("\\beur\\b").containsMatchIn(text) -> "EUR"
            "£" in text || ci("\\bgbp\\b").containsMatchIn(text) -> "GBP"
            "$" in text || ci("\\busd\\b").containsMatchIn(text) -> "USD"
            ci("\\baed\\b").containsMatchIn(text) -> "AED"
            ci("\\bthb\\b").containsMatchIn(text) -> "THB"
            else -> null
        }

        private val amountRegex = ci("$CURRENCY\\s*([\\d,]+(?:\\.\\d{1,2})?)")

        /** The first price written on a line. The only place an amount ever comes from. */
        fun amount(line: String): Double? =
            amountRegex.find(line)?.groupValues?.get(1)?.replace(",", "")?.toDoubleOrNull()
    }

    private fun absorbHeaderFacts() {
        val header = preamble.joinToString("\n")
        travellerCount = travellerCount(header) ?: participantColumnCount(days)
        namedTravellers = explicitNames(preamble)
        currencyCode = currency(header) ?: currency(haystack)
        title = labelled("trip|tour|package|itinerary name", preamble)
        destinationHint = labelled("destination|route|going to", preamble)
    }

    /** "DAY 4" with days 1 and 7 dated is not ambiguous. */
    private fun inferMissingDates() {
        if (days.none { it.date == null }) return
        val anchorIndex = days.indexOfFirst { it.date != null }
        if (anchorIndex < 0) return
        val anchor = days[anchorIndex].date!!
        days = days.mapIndexed { index, day ->
            if (day.date != null) day else day.copy(date = anchor.plusDays((index - anchorIndex).toLong()))
        }
    }

    /**
     * A cost column extracted separately from its rows. When a block of bare amounts is as
     * long as a day's unpriced rows they go back in order; otherwise nothing is guessed.
     */
    private fun repairOrphanedAmounts() {
        val blocks = orphanAmountBlocks().toMutableList()
        if (blocks.isEmpty()) return
        days = days.map { day ->
            val needing = day.lines.indices.filter { amount(day.lines[it]) == null && isRow(day.lines[it]) }
            val match = blocks.indexOfFirst { it.size == needing.size }
            if (needing.size < 2 || match < 0) return@map day
            val lines = day.lines.toMutableList()
            needing.forEachIndexed { offset, lineIndex -> lines[lineIndex] += " " + blocks[match][offset] }
            blocks.removeAt(match)
            day.copy(lines = lines)
        }
    }

    private fun orphanAmountBlocks(): List<List<String>> {
        val blocks = mutableListOf<List<String>>()
        var current = mutableListOf<String>()
        for (line in rawTail) {
            if (isOrphanAmount(line)) current += line
            else if (current.isNotEmpty()) { blocks += current; current = mutableListOf() }
        }
        if (current.isNotEmpty()) blocks += current
        return blocks.filter { it.size >= 2 }
    }
}
