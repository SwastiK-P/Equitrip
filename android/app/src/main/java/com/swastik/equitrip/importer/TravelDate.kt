package com.swastik.equitrip.importer

import java.time.LocalDate

/** Dates as travel documents write them, which is every way at once — iOS `TravelDate`. */
object TravelDate {
    private val months = mapOf(
        "jan" to 1, "feb" to 2, "mar" to 3, "apr" to 4, "may" to 5, "jun" to 6,
        "jul" to 7, "aug" to 8, "sep" to 9, "oct" to 10, "nov" to 11, "dec" to 12,
    )

    private class Parts(val day: Int, val month: Int, val year: Int?)

    private class Form(pattern: String, val read: (MatchResult) -> Parts?) {
        val regex = Regex(pattern, RegexOption.IGNORE_CASE)
    }

    private fun MatchResult.int(i: Int) = groups[i]?.value?.toIntOrNull()
    private fun MatchResult.text(i: Int) = groups[i]?.value

    private val forms = listOf(
        // 2026-09-12
        Form("\\b(\\d{4})-(\\d{2})-(\\d{2})\\b") { m ->
            val y = m.int(1) ?: return@Form null
            val mo = m.int(2) ?: return@Form null
            val d = m.int(3) ?: return@Form null
            Parts(d, mo, y)
        },
        // 12 September 2026 / 12 Sep 2026 / 12th September 2026
        Form("\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+([a-z]{3,9})\\.?,?\\s*(\\d{4})?\\b") { m ->
            val d = m.int(1) ?: return@Form null
            val mo = m.text(2)?.let(::month) ?: return@Form null
            Parts(d, mo, m.int(3))
        },
        // September 12, 2026 / Sep 12 2026
        Form("\\b([a-z]{3,9})\\.?\\s+(\\d{1,2})(?:st|nd|rd|th)?,?\\s*(\\d{4})?\\b") { m ->
            val mo = m.text(1)?.let(::month) ?: return@Form null
            val d = m.int(2) ?: return@Form null
            Parts(d, mo, m.int(3))
        },
        // 12/09/2026 — day first, which is how everywhere but the US writes it.
        Form("\\b(\\d{1,2})[/.](\\d{1,2})[/.](\\d{2,4})\\b") { m ->
            val d = m.int(1) ?: return@Form null
            val mo = m.int(2) ?: return@Form null
            var y = m.int(3) ?: return@Form null
            if (y < 100) y += 2000
            Parts(d, mo, y)
        },
    )

    private fun month(name: String) = months[name.take(3).lowercase()]

    /** The first date in a line. A year that isn't written rolls forward from `reference`. */
    fun first(line: String, reference: LocalDate = LocalDate.now()): LocalDate? {
        for (form in forms) {
            for (m in form.regex.findAll(line)) {
                val parts = form.read(m) ?: continue
                make(parts, reference)?.let { return it }
            }
        }
        return null
    }

    class Hit(val date: LocalDate, val range: IntRange)

    /** Every date in a line with where it sits; earliest wins where two forms overlap. */
    fun matches(line: String, reference: LocalDate = LocalDate.now()): List<Hit> {
        val found = mutableListOf<Hit>()
        for (form in forms) {
            for (m in form.regex.findAll(line)) {
                val parts = form.read(m) ?: continue
                val date = make(parts, reference) ?: continue
                found += Hit(date, m.range)
            }
        }
        val kept = mutableListOf<Hit>()
        for (hit in found.sortedBy { it.range.first }) {
            val last = kept.lastOrNull()
            if (last != null && hit.range.first <= last.range.last) continue
            kept += hit
        }
        return kept
    }

    class Clock(val minute: Int, val range: IntRange)

    private val clockRegex = Regex(
        "\\b(\\d{1,2})[:.](\\d{2})\\s*(am|pm)?(?:\\s*[–—-]\\s*\\d{1,2}[:.]\\d{2}\\s*(?:am|pm)?)?",
        RegexOption.IGNORE_CASE,
    )

    /** "08:00", and "08:00–10:10" as one match — a row's time column is a span. */
    fun clockMatches(line: String): List<Clock> = clockRegex.findAll(line).mapNotNull { m ->
        var hour = m.int(1) ?: return@mapNotNull null
        val minute = m.int(2) ?: return@mapNotNull null
        when (m.text(3)?.lowercase()) {
            "pm" -> if (hour < 12) hour += 12
            "am" -> if (hour == 12) hour = 0
        }
        if (hour !in 0..23 || minute !in 0..59) null else Clock(hour * 60 + minute, m.range)
    }.toList()

    private val timeRegex = Regex("\\b(\\d{1,2})[:.](\\d{2})\\s*(am|pm)?\\b", RegexOption.IGNORE_CASE)

    /** "06:30", "6:30 PM" → minutes since midnight. */
    fun minutes(line: String): Int? {
        val m = timeRegex.find(line) ?: return null
        var hour = m.int(1) ?: return null
        val minute = m.int(2) ?: return null
        when (m.text(3)?.lowercase()) {
            "pm" -> if (hour < 12) hour += 12
            "am" -> if (hour == 12) hour = 0
        }
        return if (hour !in 0..23 || minute !in 0..59) null else hour * 60 + minute
    }

    private fun make(parts: Parts, reference: LocalDate): LocalDate? {
        if (parts.day !in 1..31 || parts.month !in 1..12) return null
        parts.year?.let { year ->
            if (year !in 2000..2100) return null
            return runCatching { LocalDate.of(year, parts.month, parts.day) }.getOrNull()
        }
        // No year written: this year, rolled forward if that's more than two months gone.
        val candidate = runCatching { LocalDate.of(reference.year, parts.month, parts.day) }.getOrNull() ?: return null
        return if (candidate < reference.minusMonths(2)) {
            runCatching { LocalDate.of(reference.year + 1, parts.month, parts.day) }.getOrNull()
        } else candidate
    }
}
