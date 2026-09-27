package com.swastik.equitrip.equi

import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import com.swastik.equitrip.model.plural
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Kotlin's answer to an `EquiQuery`: a reply that answers it, what to ask next, and
 * whether a cloud model may add general knowledge. A port of iOS `EquiFacts`.
 *
 * Replies are a lead line, then `- ` bullets wherever there's a list; `EquiReplyText` draws
 * those as a list and `**…**` as bold, so an answer never lands as one long paragraph.
 *
 * Every figure is a question put to `Trip` — `cost`, `paid`, `suggestedTransfers` — never
 * arithmetic of Equi's own. On iOS the on-device model may phrase these; on Android the
 * reply is written here, because phrasing it in the cloud would mean sending names and
 * amounts off the phone. Only `ADVICE` and `CHAT` go to Groq, with `EquiPrivacy.brief`.
 */
data class EquiFacts(
    val headline: String,
    val suggestions: List<String> = emptyList(),
    /** Advice and small talk: a cloud model may write the reply from general knowledge. */
    val allowsGeneralKnowledge: Boolean = false,
    /** The trip a follow-up that names none is about. */
    val focusTripId: String? = null,
) {
    companion object {
        fun answer(query: EquiQuery, trips: List<Trip>, myId: String?): EquiFacts =
            Answerer(trips, myId).answer(query)
    }
}

private class Answerer(private val all: List<Trip>, private val me: String?) {

    fun answer(query: EquiQuery): EquiFacts {
        if (all.isEmpty()) return EquiFacts(
            "You don't have any trips yet. Start one from **Home** and I'll keep track of the plan and the money.",
            allowsGeneralKnowledge = query.needsCloud,
        )
        val trips = query.tripIds.mapNotNull { id -> all.firstOrNull { it.id == id } }
        when (query.topic) {
            EquiQuery.Topic.CHAT -> return chat(trips.firstOrNull())
            EquiQuery.Topic.ADVICE -> return advice(trips.firstOrNull())
            EquiQuery.Topic.TRIPS -> return compare(trips, query)
            else -> Unit
        }
        val trip = trips.firstOrNull() ?: return missing(query)
        if (trips.size > 1 && query.topic == EquiQuery.Topic.BALANCE) return balanceAcross(trips)
        if (trips.size > 1 && query.topic == EquiQuery.Topic.SPENDING) return compare(trips, query)

        val facts = when (query.topic) {
            EquiQuery.Topic.SCHEDULE -> schedule(trip, query)
            EquiQuery.Topic.BOOKINGS -> bookings(trip, query.category)
            EquiQuery.Topic.SPENDING -> spending(trip, query.category, query.asksBudget)
            EquiQuery.Topic.BALANCE -> balance(trip, query.personId)
            EquiQuery.Topic.PEOPLE -> people(trip, query.personId)
            EquiQuery.Topic.GAPS -> gaps(trip)
            else -> overview(trip)
        }
        return facts.copy(focusTripId = trip.id)
    }

    // One trip

    private fun overview(trip: Trip): EquiFacts {
        val code = trip.currencyCode
        return when (trip.phase) {
            TripPhase.UPCOMING -> EquiFacts(
                reply(
                    "**${trip.title}** starts ${startsIn(trip)} — ${plural(trip.dayCount, "day")} in ${trip.destination}, ${trip.dateRange}.",
                    if (trip.items.isEmpty()) listOf("Nothing's booked yet")
                    else listOf(
                        "${plural(trip.items.size, "booking")} so far",
                        "${label(trip)} planned",
                        "Your share: **${Money.format(yourShare(trip), code)}**",
                    ),
                ),
                listOf("What's still unbooked?", "Where am I staying?", "What should I pack?"),
            )
            TripPhase.LIVE -> {
                val next = trip.upcoming(2)
                EquiFacts(
                    reply(
                        "You're on **${trip.progressLabel.lowercase()}** in ${trip.destination}." + if (next.isNotEmpty()) " Next up:" else "",
                        next.map { "${it.title} · ${whenOf(it)}" },
                    ),
                    listOf("What's on tomorrow?", "Who still owes me?", "How much on food so far?"),
                )
            }
            TripPhase.PAST -> {
                val members = members(trip).size.coerceAtLeast(1)
                val total = Money.format(trip.totalCost.roundToInt().toDouble(), code)
                val each = Money.format((trip.totalCost / members).roundToInt().toDouble(), code)
                EquiFacts(
                    reply(
                        "**${trip.title}** wrapped up ${endedAgo(trip)} — ${plural(trip.dayCount, "day")} in ${trip.destination}.",
                        listOf("**$total** across ${plural(trip.items.size, "booking")}", "About $each each"),
                    ),
                    listOf("Who paid the most?", "Did everyone settle up?", "Compare my trips"),
                )
            }
        }
    }

    private fun schedule(trip: Trip, query: EquiQuery): EquiFacts {
        val suggestions = listOf("What's on tomorrow?", "Where am I staying?", "Any gaps in the plan?")
        if (query.day != EquiQuery.Day.ANY) {
            val date = LocalDate.now().plusDays(if (query.day == EquiQuery.Day.TODAY) 0 else 1)
            val word = if (query.day == EquiQuery.Day.TODAY) "Today" else "Tomorrow"
            val items = trip.items.filter { it.day == date }.sortedWith(chronological)
            val inTrip = !date.isBefore(trip.startDate) && !date.isAfter(trip.endDate)
            val headline = when {
                items.isNotEmpty() -> reply(
                    "$word you've got **${plural(items.size, "thing")}**:",
                    items.take(5).map { item -> timeLabel(item)?.let { "**$it** ${item.title}" } ?: item.title },
                )
                inTrip -> "$word is clear on ${trip.title} — nothing's booked."
                else -> "Nothing on ${word.lowercase()}. ${trip.title} ${if (trip.phase == TripPhase.PAST) "ended ${endedAgo(trip)}" else "starts ${startsIn(trip)}"}."
            }
            return EquiFacts(headline, listOf("What's up next?", "Where am I staying?", "Any gaps in the plan?"))
        }

        query.category?.let { category ->
            val every = trip.items.filter { it.kind == category }.sortedWith(chronological)
            val ahead = every.filter { !it.day.isBefore(LocalDate.now()) }
            val noun = category.label.lowercase()
            val target = ahead.firstOrNull() ?: every.lastOrNull()
                ?: return EquiFacts("There's no $noun booked on ${trip.title} yet.", listOf("What's still unbooked?", "What's up next?"))
            return EquiFacts(
                "${if (ahead.isEmpty()) "Your last" else "Your next"} $noun is **${target.title}** ${whenOf(target)}.",
                if (category == ItineraryKind.STAY) listOf("When do I fly?", "What's up next?") else suggestions,
            )
        }

        val next = trip.upcoming(3)
        val headline = when {
            trip.items.isEmpty() -> "Nothing's booked on ${trip.title} yet."
            trip.phase == TripPhase.PAST ->
                "${trip.title} is over. The last thing on it was **${trip.items.sortedWith(chronological).lastOrNull()?.title ?: "the trip home"}**."
            next.size == 1 -> "Next up: **${next[0].title}** ${whenOf(next[0])}."
            next.isNotEmpty() -> reply("Next up on ${trip.title}:", next.map { "**${it.title}** · ${whenOf(it)}" })
            else -> "Nothing else is booked on ${trip.title}."
        }
        return EquiFacts(headline, suggestions)
    }

    private fun bookings(trip: Trip, category: ItineraryKind?): EquiFacts {
        val items = trip.items.filter { category == null || it.kind == category }.sortedWith(chronological)
        if (items.isEmpty()) {
            val noun = category?.let(::pluralKind) ?: "bookings"
            return EquiFacts("No $noun booked on ${trip.title} yet.", listOf("What's still unbooked?", "What's up next?"))
        }
        val headline = when (category) {
            ItineraryKind.STAY -> {
                val stays = items.map { item ->
                    val nights = nights(item, trip)?.let { ", ${plural(it, "night")}" } ?: ""
                    "**${item.vendor.ifBlank { item.title }}** · from ${item.day.format(DAY)}$nights"
                }
                if (items.size == 1) "You're staying at ${stays[0]}." else reply("You're staying at **${items.size} places**:", stays)
            }
            null -> {
                val counts = items.groupBy { it.kind }.entries.sortedByDescending { it.value.size }
                    .map { count(it.value.size, it.key).replaceFirstChar { c -> c.uppercase() } }
                reply("**${plural(items.size, "booking")}** on ${trip.title}:", counts)
            }
            else -> reply(
                "**${count(items.size, category)}** booked${if (items.size > 5) " — the first five" else ""}:",
                items.take(5).map { "**${it.title}** · ${it.day.format(DAY)}" },
            )
        }
        return EquiFacts(
            headline,
            if (category == ItineraryKind.STAY) listOf("When do I fly?", "Any gaps in the plan?", "Where's the money going?")
            else listOf("Where am I staying?", "Where's the money going?", "Any gaps in the plan?"),
        )
    }

    private fun spending(trip: Trip, category: ItineraryKind?, asksBudget: Boolean): EquiFacts {
        val code = trip.currencyCode
        val total = trip.totalCost
        val verb = if (trip.phase == TripPhase.UPCOMING) "planned" else "spent"
        val suggestions = if (category == null) listOf("How much on food?", "Who paid the most?", "What do I owe?")
        else listOf("Where's the money going?", "Who paid the most?", "What do I owe?")
        if (total <= 0) return EquiFacts("Nothing on ${trip.title} has a price on it yet.", listOf("What's still unbooked?", "What's up next?"))

        val headline = when {
            category != null -> {
                val items = trip.items.filter { it.kind == category && it.cost > 0 }
                if (items.isEmpty()) {
                    "Nothing $verb on ${category.label.lowercase()} on ${trip.title} yet. The trip's at **${label(trip)}** overall."
                } else {
                    val amount = items.sumOf { it.cost }
                    val yours = me?.let { id -> items.sumOf { trip.share(it, id) } } ?: 0.0
                    reply(
                        "**${Money.format(amount, code)}** $verb on ${category.label.lowercase()} on ${trip.title}.",
                        listOf(
                            plural(items.size, "booking"),
                            "${percent(amount, total)}% of ${label(trip)}",
                            "Your part: **${Money.format(yours, code)}**",
                        ),
                    )
                }
            }
            asksBudget -> reply(
                "There's no budget set in Equitrip, so I can't say if you're over.",
                listOf("${label(trip)} $verb on ${trip.title}", "Your share: **${Money.format(yourShare(trip), code)}**"),
            )
            else -> {
                val slices = trip.items.groupBy { it.kind }.mapValues { (_, v) -> v.sumOf { it.cost } }
                    .filter { it.value > 0 }.entries.sortedByDescending { it.value }
                reply(
                    "**${label(trip)}** $verb on ${trip.title}. Your share is **${Money.format(yourShare(trip), code)}**.",
                    slices.take(4).map { "${it.key.label} · ${Money.format(it.value, code)} (${percent(it.value, total)}%)" },
                )
            }
        }
        return EquiFacts(headline, suggestions)
    }

    private fun balance(trip: Trip, personId: String?): EquiFacts {
        val code = trip.currencyCode
        val suggestions = listOf("Who paid the most?", "Where's the money going?", "What's up next?")
        if (!trip.hasPayments) return EquiFacts(
            reply(
                "Nobody has logged a payment on ${trip.title} yet, so nobody owes anything.",
                listOf("Your share of the plan: **${Money.format(yourShare(trip), code)}**"),
            ),
            suggestions,
        )
        val transfers = trip.suggestedTransfers
        val person = personId?.let(trip::traveller)
        val headline = if (person != null) {
            val theyPay = transfers.firstOrNull { it.from == person.id && it.to == me }
            val youPay = transfers.firstOrNull { it.from == me && it.to == person.id }
            val net = trip.remainingBalance(person.id)
            when {
                theyPay != null -> "${person.name} owes you **${Money.format(theyPay.amount, code)}** on ${trip.title}."
                youPay != null -> "You owe ${person.name} **${Money.format(youPay.amount, code)}** on ${trip.title}."
                abs(net) < 0.01 -> "${person.name} is all square on ${trip.title}. Nothing owed either way."
                net > 0 -> "Nothing between you and ${person.name}. They're owed **${Money.format(net, code)}** by the others."
                else -> "Nothing between you and ${person.name}. They owe **${Money.format(-net, code)}** to the others."
            }
        } else {
            val parts = transfers.filter { it.from == me }.map { "You pay ${nameOf(trip.traveller(it.to))} **${Money.format(it.amount, code)}**" } +
                transfers.filter { it.to == me }.map { "${nameOf(trip.traveller(it.from))} pays you **${Money.format(it.amount, code)}**" }
            when {
                parts.isNotEmpty() -> reply("To settle up on ${trip.title}:", parts)
                transfers.isNotEmpty() -> "You're all square on ${trip.title}. ${plural(transfers.size, "payment")} between the others ${if (transfers.size == 1) "is" else "are"} still open."
                else -> "You're all square on ${trip.title}, and so is everyone else."
            }
        }
        val pending = trip.pendingSettlements.size
        val footer = if (pending > 0) "\n\n${plural(pending, "payment")} marked as sent ${if (pending == 1) "is" else "are"} waiting to be confirmed." else ""
        return EquiFacts(headline + footer, suggestions)
    }

    private fun people(trip: Trip, personId: String?): EquiFacts {
        val code = trip.currencyCode
        val person = personId?.let(trip::traveller)
        val headline = if (person != null) {
            val paid = trip.paid(person.id)
            val count = trip.items.count { it.paidById == person.id }
            val net = trip.remainingBalance(person.id)
            val standing = when {
                abs(net) < 0.01 -> "They're square"
                net > 0 -> "They get **${Money.format(net, code)}** back"
                else -> "They owe **${Money.format(-net, code)}**"
            }
            reply(
                "**${person.name}** on ${trip.title}:",
                listOf(
                    "Paid ${Money.format(paid, code)} across ${plural(count, "booking")}",
                    "Share: ${Money.format(trip.cost(person.id), code)}",
                    standing,
                ),
            )
        } else {
            val members = members(trip)
            val top = members.maxByOrNull { trip.paid(it.id) }?.takeIf { trip.paid(it.id) > 0 }
            val invited = trip.travellers.filter { it.id in trip.invitedIds }
            reply(
                "**${members.size} ${if (members.size == 1) "person" else "people"}** on ${trip.title}:",
                members.map { member ->
                    val paid = trip.paid(member.id)
                    nameOf(member).replaceFirstChar { it.uppercase() } +
                        (if (paid > 0) " · paid ${Money.format(paid, code)}" else "") +
                        (if (member == top) " · **paid the most**" else "")
                } + invited.map { "${it.name} · invited" },
            )
        }
        return EquiFacts(
            headline,
            if (person == null) listOf("What do I owe?", "Where's the money going?") else listOf("Who else is on the trip?", "What do I owe?"),
        )
    }

    private fun gaps(trip: Trip): EquiFacts {
        val gaps = EquiPlanCheck(trip).gaps
        if (gaps.isEmpty()) return EquiFacts(
            reply(
                "Nothing obviously missing on ${trip.title}.",
                listOf("Every night has a stay", "Every day has something on", "Travel's booked both ways"),
            ),
            listOf("What's up next?", "What should I pack?"),
        )
        val parts = buildList {
            if (gaps.any { it.kind == EquiPlanCheck.Kind.NO_WAY_THERE }) add("No way there booked")
            val nights = gaps.filter { it.kind == EquiPlanCheck.Kind.NO_STAY }
            if (nights.isNotEmpty()) add("No stay for **${plural(nights.size, "night")}** from ${nights[0].date.format(DAY)}")
            val empty = gaps.count { it.kind == EquiPlanCheck.Kind.EMPTY_DAY }
            if (empty > 0) add("**${plural(empty, "day")}** with nothing planned")
            if (gaps.any { it.kind == EquiPlanCheck.Kind.NO_WAY_BACK }) add("No way home booked")
        }
        return EquiFacts(
            reply("A few things look open on ${trip.title}:", parts),
            listOf("Where am I staying?", "What's up next?", "What should I pack?"),
        )
    }

    // Several trips

    private fun compare(trips: List<Trip>, query: EquiQuery): EquiFacts {
        val suggestions = listOf("Tell me about my last trip", "What's my next trip?", "Which trip cost the most?")
        if (trips.isEmpty()) return EquiFacts(
            if (query.scope == EquiQuery.Scope.ALL_PAST) "You haven't finished a trip yet."
            else "There's nothing coming up — no upcoming trips on the books.",
            suggestions,
        )
        val ranking = query.byCost || query.topic == EquiQuery.Topic.SPENDING
        val headline = if (ranking) {
            val ranked = trips.sortedByDescending { it.totalCost }
            val lead = when {
                trips.map { it.currencyCode }.toSet().size > 1 -> "Your trips are in different currencies, so they can't be ranked on one scale:"
                ranked.size == 1 -> "**${ranked[0].title}** comes to ${label(ranked[0])}."
                else -> "**${ranked[0].title}** cost the most:"
            }
            reply(lead, if (ranked.size == 1) emptyList() else ranked.take(5).map { "${it.title} · ${label(it)}" })
        } else when (query.scope) {
            EquiQuery.Scope.NAMED -> reply("Side by side:", trips.map { "**${it.title}** · ${plural(it.dayCount, "day")} · ${label(it)}" })
            EquiQuery.Scope.ALL_PAST ->
                reply("You've been on **${plural(trips.size, "trip")}**:", trips.take(6).map { "${it.title} · ${it.startDate.format(MONTH_YEAR)}" })
            EquiQuery.Scope.ALL_UPCOMING -> reply(
                "Coming up:",
                trips.take(6).map { "**${it.title}** · ${if (it.phase == TripPhase.LIVE) "under way" else "starts ${startsIn(it)}"}" },
            )
            else -> reply(
                "You have **${plural(trips.size, "trip")}**:",
                buildList {
                    trips.count { it.phase == TripPhase.LIVE }.takeIf { it > 0 }?.let { add("$it under way") }
                    trips.count { it.phase == TripPhase.UPCOMING }.takeIf { it > 0 }?.let { add("$it coming up") }
                    trips.count { it.phase == TripPhase.PAST }.takeIf { it > 0 }?.let { add("$it wrapped up") }
                },
            )
        }
        return EquiFacts(headline, suggestions)
    }

    private fun balanceAcross(trips: List<Trip>): EquiFacts {
        val suggestions = listOf("Who paid the most?", "Tell me about my last trip")
        val net = { trip: Trip -> me?.let(trip::remainingBalance) ?: 0.0 }
        val open = trips.filter { it.hasPayments && abs(net(it)) >= 0.01 }
        if (open.isEmpty()) return EquiFacts("You're square everywhere. Nobody owes anybody on any of your trips.", suggestions)
        return EquiFacts(
            reply("Across your trips:", open.map { trip ->
                val amount = Money.format(abs(net(trip)), trip.currencyCode)
                if (net(trip) < 0) "${trip.title} · you owe **$amount**" else "${trip.title} · you're owed **$amount**"
            }),
            suggestions,
        )
    }

    // No trip, or no data

    private fun missing(query: EquiQuery): EquiFacts {
        val next = EquiQueryReader.resolve(EquiQuery.Scope.NEXT, all, null).firstOrNull()
        val previous = EquiQueryReader.resolve(EquiQuery.Scope.PREVIOUS, all, null).firstOrNull()
        return when (query.scope) {
            EquiQuery.Scope.PREVIOUS -> EquiFacts(
                "You haven't finished a trip yet." + (next?.let { " **${it.title}** is next, starting ${startsIn(it)}." } ?: ""),
                listOf("What's my next trip?", "Show my trips"),
                focusTripId = next?.id,
            )
            EquiQuery.Scope.NEXT -> EquiFacts(
                "There's no trip coming up." + (previous?.let { " Your last was **${it.title}**, which ended ${endedAgo(it)}." } ?: ""),
                listOf("Tell me about my last trip", "Show my trips"),
                focusTripId = previous?.id,
            )
            else -> EquiFacts("I couldn't tell which trip you meant. Try its name?", listOf("Show my trips"))
        }
    }

    private fun chat(trip: Trip?) = EquiFacts(
        "Hi! Ask me about your trips — what's next, where you're staying, who owes whom.",
        listOf("What's up next?", "Who still owes me?", "Tell me about my last trip"),
        allowsGeneralKnowledge = true,
        focusTripId = trip?.id,
    )

    private fun advice(trip: Trip?): EquiFacts {
        trip ?: return EquiFacts(
            "Tell me which trip you're thinking of and I'll help you plan for it.",
            listOf("Show my trips"),
            allowsGeneralKnowledge = true,
        )
        return EquiFacts(
            "I can't look that up right now, but **${trip.title}** runs ${trip.dateRange} in ${trip.destination} — ${plural(trip.dayCount, "day")} to plan around.",
            listOf("What's still unbooked?", "Where am I staying?", "What's up next?"),
            allowsGeneralKnowledge = true,
            focusTripId = trip.id,
        )
    }

    // Words

    /** A lead line, then one bullet per item — or just the lead when there's nothing to list. */
    private fun reply(lead: String, bullets: List<String>) =
        if (bullets.isEmpty()) lead else lead + "\n" + bullets.joinToString("\n") { "- $it" }

    private fun members(trip: Trip) = trip.travellers.filter { it.id !in trip.invitedIds }
    private fun yourShare(trip: Trip) = me?.let(trip::cost) ?: 0.0
    private fun label(trip: Trip) = Money.format(trip.totalCost, trip.currencyCode)
    private fun percent(part: Double, whole: Double) = (part / whole * 100).roundToInt()
    private fun nameOf(traveller: Traveller?) = when {
        traveller == null -> "someone"
        traveller.id == me -> "you"
        else -> traveller.name
    }

    private fun startsIn(trip: Trip) = when (val days = ChronoUnit.DAYS.between(LocalDate.now(), trip.startDate).toInt()) {
        in Int.MIN_VALUE..0 -> "today"
        1 -> "tomorrow"
        in 2..13 -> "in $days days"
        else -> "on ${trip.startDate.format(FULL)}"
    }

    private fun endedAgo(trip: Trip) = when (val days = ChronoUnit.DAYS.between(trip.endDate, LocalDate.now()).toInt()) {
        in Int.MIN_VALUE..0 -> "today"
        1 -> "yesterday"
        in 2..13 -> "$days days ago"
        else -> "on ${trip.endDate.format(FULL)}"
    }

    /** "today at 14:00", "tomorrow", "Tue 12 Oct at 09:40". */
    private fun whenOf(item: ItineraryItem): String {
        val today = LocalDate.now()
        val day = when (item.day) {
            today -> "today"
            today.plusDays(1) -> "tomorrow"
            else -> item.day.format(DAY)
        }
        return timeLabel(item)?.let { "$day at $it" } ?: day
    }

    private fun timeLabel(item: ItineraryItem) = item.time?.atZoneSameInstant(ZoneId.systemDefault())?.format(TIME)

    /** How many nights a stay covers: up to the next stay, or the end of the trip. */
    private fun nights(stay: ItineraryItem, trip: Trip): Int? {
        val next = trip.items.filter { it.kind == ItineraryKind.STAY && it.day.isAfter(stay.day) }.minOfOrNull { it.day } ?: trip.endDate
        return ChronoUnit.DAYS.between(stay.day, next).toInt().takeIf { it > 0 }
    }

    private fun count(n: Int, kind: ItineraryKind) = if (n == 1) "1 ${kind.label.lowercase()}" else "$n ${pluralKind(kind)}"

    private fun pluralKind(kind: ItineraryKind) = when (kind) {
        ItineraryKind.FLIGHT -> "flights"
        ItineraryKind.TRAIN -> "trains"
        ItineraryKind.DRIVE -> "transfers"
        ItineraryKind.STAY -> "stays"
        ItineraryKind.ACTIVITY -> "activities"
        ItineraryKind.MEAL -> "meals"
        ItineraryKind.OTHER -> "other bookings"
    }

    companion object {
        private val DAY = DateTimeFormatter.ofPattern("EEE d MMM")
        private val FULL = DateTimeFormatter.ofPattern("d MMM yyyy")
        private val MONTH_YEAR = DateTimeFormatter.ofPattern("MMM yyyy")
        private val TIME = DateTimeFormatter.ofPattern("HH:mm")
        private val chronological = compareBy<ItineraryItem>({ it.day }, { it.time })
    }
}
