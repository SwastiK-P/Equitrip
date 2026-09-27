package com.swastik.equitrip.model

import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

data class Traveller(
    val id: String,
    val name: String,
    /** The stored `avatar_asset`; `Avatars.artwork` turns it into one of the 15 faces. */
    val avatarAsset: String,
    val avatarUrl: String?,
    val upiId: String?,
) {
    val initials: String
        get() = name.split(" ").filter { it.isNotBlank() }.take(2)
            .joinToString("") { it.first().uppercase() }.ifEmpty { "?" }
}

/** What a booking *is* — mirrors iOS `ItineraryKind`, including `drive` being labelled "Transfer". */
enum class ItineraryKind(val label: String) {
    FLIGHT("Flight"), TRAIN("Train"), DRIVE("Transfer"), STAY("Stay"),
    ACTIVITY("Activity"), MEAL("Food"), OTHER("Other");

    companion object {
        fun decode(raw: String) = entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: OTHER
    }
}

/** Mirrors iOS `SplitMode`, including reading the retired `room` value as `participants`. */
enum class SplitMode(val label: String) {
    EQUAL("Split equally"), PARTICIPANTS("Only participants"), CUSTOM("Exact amounts"),
    ORGANISER("Organiser pays"), INDIVIDUAL("One person");

    companion object {
        fun decode(raw: String): SplitMode {
            if (raw == "room") return PARTICIPANTS
            return entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: EQUAL
        }
    }
}

/** The typeface a trip's name is set in — the `title_style` column, shared with iOS `TripTitleStyle`. */
enum class TitleStyle {
    CLASSIC, BOLD, AIRY, POSTER, CLEAN, SCRIPT, TYPEWRITER;

    companion object {
        fun decode(raw: String?) = entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: CLASSIC
    }
}

enum class PaymentMethod(val label: String) {
    CASH("Cash"), UPI("UPI"), CARD("Card"), TRANSFER("Bank transfer"), OTHER("Other");

    companion object {
        fun decode(raw: String?) = entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: CASH
    }
}

data class ItineraryItem(
    val id: String,
    val title: String,
    val vendor: String,
    val kind: ItineraryKind,
    val day: LocalDate,
    val time: OffsetDateTime?,
    val cost: Double,
    val split: SplitMode,
    val participantIds: Set<String>,
    val customShares: Map<String, Double>,
    val paidById: String?,
    val coverUrl: String?,
    /** When the row was written. iOS never reads this back; here it drives the dashed "added on the trip" card. */
    val createdAt: OffsetDateTime?,
)

enum class SettlementStatus { PENDING, CONFIRMED, DECLINED }

data class Settlement(
    val id: String,
    val fromId: String,
    val toId: String,
    val amount: Double,
    val currencyCode: String,
    val method: PaymentMethod,
    val status: SettlementStatus,
    val createdAt: OffsetDateTime,
)

data class Transfer(val from: String, val to: String, val amount: Double)

enum class TripPhase(val label: String) { UPCOMING("Upcoming"), LIVE("In progress"), PAST("Wrapped up") }

/**
 * One trip and its ledger.
 *
 * The share and balance rules are a straight port of iOS `Trip` + `SettlementEngine`,
 * because the two apps read the same rows and must never disagree about who owes whom.
 * Mid-trip departures are not modelled yet: a trip with a confirmed departure can show
 * a different split here than on iOS.
 */
data class Trip(
    val id: String,
    val title: String,
    val destination: String,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val currencyCode: String,
    val coverUrl: String?,
    val titleStyle: TitleStyle,
    val inviteCode: String,
    val travellers: List<Traveller>,
    val organiserIds: Set<String>,
    val invitedIds: Set<String>,
    val items: List<ItineraryItem>,
    val settlements: List<Settlement>,
) {
    val phase: TripPhase
        get() {
            val today = LocalDate.now()
            return when {
                today.isBefore(startDate) -> TripPhase.UPCOMING
                today.isAfter(endDate) -> TripPhase.PAST
                else -> TripPhase.LIVE
            }
        }

    val dayCount: Int get() = (ChronoUnit.DAYS.between(startDate, endDate).toInt() + 1).coerceAtLeast(1)

    private val elapsedDays: Int get() = ChronoUnit.DAYS.between(startDate, LocalDate.now()).toInt()

    /** How far along the trip is — or, before it starts, how much of it is booked. Same as iOS. */
    val progress: Double
        get() = when (phase) {
            TripPhase.UPCOMING -> if (items.isEmpty()) 0.04 else minOf(1.0, items.size.toDouble() / maxOf(dayCount * 2, 1))
            TripPhase.LIVE -> minOf(1.0, (elapsedDays + 1).toDouble() / dayCount)
            TripPhase.PAST -> 1.0
        }

    val progressLabel: String
        get() = when (phase) {
            TripPhase.UPCOMING -> if (items.isEmpty()) "Nothing booked yet" else "${items.size} booked"
            TripPhase.LIVE -> "Day ${minOf(dayCount, elapsedDays + 1)} of $dayCount"
            TripPhase.PAST -> plural(items.size, "booking")
        }

    /** "12–21 Sep", or "28 Sep–3 Oct" across a month boundary. */
    val dateRange: String
        get() {
            val sameMonth = startDate.month == endDate.month && startDate.year == endDate.year
            val start = startDate.format(DateTimeFormatter.ofPattern(if (sameMonth) "d" else "d MMM"))
            return "$start–${endDate.format(DateTimeFormatter.ofPattern("d MMM"))}"
        }

    val totalCost: Double get() = items.sumOf { it.cost }

    fun traveller(id: String?) = travellers.firstOrNull { it.id == id }

    private val organisers get() = travellers.filter { it.id in organiserIds }

    private fun participants(item: ItineraryItem) = travellers.filter { it.id in item.participantIds }

    /** Who a booking's cost lands on, by its sharing rule. Invitees aren't on the trip yet. */
    fun bearers(item: ItineraryItem): List<Traveller> {
        val candidates = when (item.split) {
            SplitMode.EQUAL -> travellers
            SplitMode.PARTICIPANTS -> participants(item)
            SplitMode.CUSTOM -> participants(item).filter { (item.customShares[it.id] ?: 0.0) > 0 }
            SplitMode.ORGANISER -> organisers.ifEmpty { travellers }
            SplitMode.INDIVIDUAL -> travellers.firstOrNull { it.id in item.participantIds }?.let(::listOf)
                ?: traveller(item.paidById)?.let(::listOf) ?: emptyList()
        }
        val present = candidates.filter { it.id !in invitedIds }
        return present.ifEmpty { candidates }
    }

    fun shares(item: ItineraryItem): List<Pair<Traveller, Double>> {
        if (item.split == SplitMode.CUSTOM) return bearers(item).map { it to (item.customShares[it.id] ?: 0.0) }
        val people = bearers(item)
        if (people.isEmpty()) return emptyList()
        val holder = people.indexOfFirst { it.id == item.paidById }.coerceAtLeast(0)
        return people.zip(Money.evenSplit(item.cost, people.size, holder))
    }

    fun share(item: ItineraryItem, travellerId: String) =
        shares(item).firstOrNull { it.first.id == travellerId }?.second ?: 0.0

    /** Added once the trip was already under way — a spend, not part of the plan. */
    fun isUnplanned(item: ItineraryItem) = item.createdAt?.toLocalDate()?.let { !it.isBefore(startDate) } ?: false

    /** Named on it, or nobody is — a booking with no names is the whole group's. */
    fun isYours(item: ItineraryItem, travellerId: String?) =
        item.participantIds.isEmpty() || item.participantIds.contains(travellerId)

    fun paid(travellerId: String) = items.filter { it.paidById == travellerId }.sumOf { it.cost }

    /** What the whole plan costs one person, paid for or not. */
    fun cost(travellerId: String) = items.sumOf { share(it, travellerId) }

    /** Only bookings somebody has actually paid for are debts. */
    private fun owed(travellerId: String) = items.filter { it.paidById != null }.sumOf { share(it, travellerId) }

    /** What the rest of the group owes this person: everything they laid out, less their own share. */
    fun owedTo(travellerId: String) =
        items.filter { it.paidById == travellerId }.sumOf { it.cost - share(it, travellerId) }

    /** What this person owes the people who paid for things they're on. */
    fun owing(travellerId: String) =
        items.filter { it.paidById != null && it.paidById != travellerId }.sumOf { share(it, travellerId) }

    fun balance(travellerId: String) = paid(travellerId) - owed(travellerId)

    val hasPayments get() = items.any { it.paidById != null }

    /** Before the trip, or before anyone has paid, the useful figure is your share — not a balance of zero. */
    val showsBalance get() = phase != TripPhase.UPCOMING && hasPayments

    fun remainingBalance(travellerId: String): Double {
        val delta = settlements.filter { it.status == SettlementStatus.CONFIRMED }.sumOf {
            when (travellerId) {
                it.fromId -> it.amount
                it.toId -> -it.amount
                else -> 0.0
            }
        }
        return balance(travellerId) + delta
    }

    val suggestedTransfers: List<Transfer>
        get() = SettlementEngine.minimalTransfers(travellers.associate { it.id to remainingBalance(it.id) })

    val pendingSettlements get() = settlements.filter { it.status == SettlementStatus.PENDING }

    fun pendingSettlement(from: String, to: String) = pendingSettlements.firstOrNull { it.fromId == from && it.toId == to }

    /** Somebody paid for something, and every debt it made has been cleared and confirmed. */
    val isFullySettled get() = hasPayments && suggestedTransfers.isEmpty() && pendingSettlements.isEmpty()

    /** Worth a place on Settle: shared, and money has moved or been claimed. */
    val needsSettling get() = travellers.size > 1 && (hasPayments || settlements.isNotEmpty())

    private val chronological = compareBy<ItineraryItem>({ it.day }, { it.time })

    /** Bookings grouped by day, in order — the itinerary's backing data. */
    val days: List<Pair<LocalDate, List<ItineraryItem>>>
        get() = items.sortedWith(chronological).groupBy { it.day }.toList()

    /** The next few things happening, for Home's "Up next". Falls back to the start of the plan. */
    fun upcoming(limit: Int = 3): List<ItineraryItem> {
        val now = OffsetDateTime.now()
        val ahead = items.filter { item ->
            item.time?.let { !it.isBefore(now) } ?: !item.day.isBefore(LocalDate.now())
        }.sortedWith(chronological)
        return ahead.ifEmpty { items.sortedWith(chronological) }.take(limit)
    }
}

fun plural(count: Int, noun: String) = "$count ${if (count == 1) noun else "${noun}s"}"
