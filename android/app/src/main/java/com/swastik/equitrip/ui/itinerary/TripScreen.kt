package com.swastik.equitrip.ui.itinerary

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.EventNote
import androidx.compose.material.icons.filled.PersonSearch
import androidx.compose.material.icons.filled.Place
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.AvatarStack
import com.swastik.equitrip.ui.components.TopFade
import com.swastik.equitrip.ui.home.CircleButton
import com.swastik.equitrip.ui.home.CoverImage
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.display
import com.swastik.equitrip.ui.theme.figure
import com.swastik.equitrip.ui.theme.tripTitle
import java.time.LocalDate

private enum class Section { TIMELINE, LEDGER }

/**
 * The master itinerary — iOS `TripItineraryView` on a phone: the trip as a photograph, then
 * Timeline or Ledger, the timeline filterable to just the bookings you're on.
 */
@Composable
fun TripScreen(trip: Trip, me: String?, onBack: () -> Unit) {
    var section by rememberSaveable { mutableStateOf(Section.TIMELINE) }
    var justMe by rememberSaveable { mutableStateOf(false) }
    var collapsed by remember { mutableStateOf(setOf<LocalDate>()) }
    var viewing by remember { mutableStateOf<ItineraryItem?>(null) }
    val list = rememberLazyListState()

    val mineCount = trip.items.count { trip.isYours(it, me) }
    val days = trip.days.mapNotNull { (date, items) ->
        val shown = if (justMe) items.filter { trip.isYours(it, me) } else items
        if (shown.isEmpty()) null else date to shown
    }
    // Day numbers count from the trip's own first booked day, filtered or not.
    val dayIndex = trip.days.map { it.first }.withIndex().associate { it.value to it.index }

    Box(Modifier.fillMaxSize()) {
        LazyColumn(Modifier.fillMaxSize(), state = list, contentPadding = PaddingValues(bottom = 28.dp + LocalBottomBarInset.current)) {
            item(key = "banner") { Banner(trip, me) }

            item(key = "switch") {
                SegmentedSwitch(
                    listOf(Section.TIMELINE to "Timeline", Section.LEDGER to "Ledger"),
                    section, { section = it },
                    Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp),
                )
            }

            if (section == Section.LEDGER) {
                item(key = "ledger") { LedgerSection(trip, me) { viewing = it } }
            } else {
                item(key = "scope") {
                    Row(Modifier.padding(start = 20.dp, end = 20.dp, top = 16.dp, bottom = 2.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ScopeChip("Everyone", trip.items.size, !justMe) { justMe = false }
                        ScopeChip("Just you", mineCount, justMe) { justMe = true }
                    }
                }
                if (days.isEmpty()) item(key = "empty") { NoBookings(justMe, trip.items.size) }
                days.forEachIndexed { dayPosition, (date, items) ->
                    val isClosed = date in collapsed
                    item(key = "day-$date") {
                        DayHeader(dayIndex[date] ?: dayPosition, date, isClosed) {
                            collapsed = if (isClosed) collapsed - date else collapsed + date
                        }
                    }
                    if (!isClosed) itemsIndexed(items, key = { _, item -> item.id }) { index, item ->
                        val lastOfDay = index == items.lastIndex
                        TimelineRow(
                            item, trip, me,
                            isLast = lastOfDay && dayPosition == days.lastIndex,
                            closesDay = lastOfDay,
                        ) { viewing = item }
                    }
                }
            }
        }

        val scrolledPastBanner by remember { derivedStateOf { list.firstVisibleItemIndex > 0 } }
        TopFade(scrolledPastBanner)

        // Floats over the photograph; the page scrolls beneath it.
        Row(Modifier.fillMaxWidth().windowInsetsPadding(WindowInsets.statusBars).padding(horizontal = 16.dp, vertical = 4.dp)) {
            CircleButton(Icons.AutoMirrored.Filled.ArrowBack, "Back to trips", onClick = onBack)
        }
    }

    viewing?.let { BookingSheet(it, trip, me) { viewing = null } }
}

@Composable
private fun Banner(trip: Trip, me: String?, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(340.dp)) {
        CoverImage(trip, Modifier.fillMaxSize())
        Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.40f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.62f))))
        Column(Modifier.align(Alignment.BottomStart).padding(start = 20.dp, end = 20.dp, bottom = 16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Place, null, tint = Color.White.copy(alpha = 0.85f), modifier = Modifier.size(12.dp))
                Spacer(Modifier.width(5.dp))
                Text(
                    trip.destination.ifBlank { "Destination not set" },
                    fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color.White.copy(alpha = 0.85f), maxLines = 1,
                )
            }
            val style = tripTitle(trip.titleStyle, 27f)
            BasicText(
                trip.titleStyle.display(trip.title),
                Modifier.padding(top = 3.dp),
                style = style.copy(color = Color.White),
                maxLines = 1,
                autoSize = TextAutoSize.StepBased(minFontSize = style.fontSize * 0.7f, maxFontSize = style.fontSize),
            )
            Row(Modifier.padding(top = 5.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "${trip.dateRange} · ${plural(trip.dayCount, "day")}",
                    fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Color.White.copy(alpha = 0.85f),
                    modifier = Modifier.weight(1f),
                )
                AvatarStack(trip.travellers, size = 24.dp, max = 4)
            }
            Box(Modifier.padding(top = 12.dp).fillMaxWidth().height(1.dp).background(Color.White.copy(alpha = 0.22f)))
            Row(Modifier.padding(top = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                BannerFigure(Money.format(trip.totalCost, trip.currencyCode), "Projected cost", Modifier.weight(1f))
                Box(Modifier.padding(horizontal = 14.dp).width(1.dp).height(26.dp).background(Color.White.copy(alpha = 0.22f)))
                BannerFigure(
                    Money.format(Math.round(me?.let { trip.cost(it) } ?: 0.0).toDouble(), trip.currencyCode),
                    "Your share", Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun BannerFigure(value: String, label: String, modifier: Modifier) {
    Column(modifier) {
        Text(value, style = figure(17.sp), color = Color.White, maxLines = 1)
        Text(label, fontSize = 10.5.sp, fontWeight = FontWeight.Medium, color = Color.White.copy(alpha = 0.75f))
    }
}

@Composable
private fun NoBookings(justMe: Boolean, total: Int) {
    Column(
        Modifier.fillMaxWidth().padding(horizontal = 34.dp, vertical = 44.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(11.dp),
    ) {
        Icon(if (justMe) Icons.Filled.PersonSearch else Icons.Filled.EventNote, null, tint = Brand.inkTertiary, modifier = Modifier.size(34.dp))
        Text(if (justMe) "You're not on anything yet" else "Nothing booked yet", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
        Text(
            if (justMe) "The group has ${plural(total, "booking")}, but none of them list you."
            else "Add flights, stays and activities and they'll line up here.",
            fontSize = 13.5.sp, color = Brand.inkSecondary, textAlign = TextAlign.Center,
        )
    }
}
