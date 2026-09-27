package com.swastik.equitrip.equi

import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import java.time.LocalDate

/**
 * The holes in a trip's plan: nights with nowhere to sleep, days with nothing on, and no
 * way there or back. A port of iOS `EquiPlanCheck` — counted, never eyeballed by a model,
 * which named things that were already booked.
 */
class EquiPlanCheck(trip: Trip) {

    enum class Kind(val label: String, val order: Int) {
        NO_WAY_THERE("No way there booked", 0),
        NO_STAY("No stay booked", 1),
        EMPTY_DAY("Nothing planned", 2),
        NO_WAY_BACK("No way home booked", 3),
    }

    data class Gap(val kind: Kind, val date: LocalDate)

    val gaps: List<Gap>

    init {
        val start = trip.startDate
        val end = trip.endDate
        val dates = (0 until maxOf(1, trip.dayCount)).map { start.plusDays(it.toLong()) }
        val travel = setOf(ItineraryKind.FLIGHT, ItineraryKind.TRAIN, ItineraryKind.DRIVE)
        val found = mutableListOf<Gap>()

        // A night is covered from a stay's first day up to the next stay, or the trip's end.
        val stays = trip.items.filter { it.kind == ItineraryKind.STAY }.map { it.day }
        if (trip.items.isNotEmpty() || trip.phase != TripPhase.PAST) {
            dates.filter { it.isBefore(end) }
                .filter { night -> stays.none { !it.isAfter(night) } }
                .forEach { found += Gap(Kind.NO_STAY, it) }
        }

        val booked = trip.items.map { it.day }.toSet()
        if (dates.size > 1) dates.filter { it !in booked }.forEach { found += Gap(Kind.EMPTY_DAY, it) }

        if (trip.items.none { it.kind in travel && !it.day.isAfter(start) }) found += Gap(Kind.NO_WAY_THERE, start)
        if (dates.size > 1 && trip.items.none { it.kind in travel && !it.day.isBefore(end) }) found += Gap(Kind.NO_WAY_BACK, end)

        // An empty day that's also a night with no bed is one problem, not two.
        val noStay = found.filter { it.kind == Kind.NO_STAY }.map { it.date }.toSet()
        gaps = found.filter { it.kind != Kind.EMPTY_DAY || it.date !in noStay }
            .sortedWith(compareBy({ it.date }, { it.kind.order }))
    }
}
