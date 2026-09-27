package com.swastik.equitrip.ui.itinerary

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.AvatarStack
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.TopFade
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.components.rememberCoverTint
import com.swastik.equitrip.ui.components.staggered
import com.swastik.equitrip.ui.home.CircleButton
import com.swastik.equitrip.ui.home.CoverImage
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.display
import com.swastik.equitrip.ui.theme.tripTitle

/** Every trip, grouped by where it is in its life — iOS `TripListView`. */
@Composable
fun TripListScreen(trips: List<Trip>, onOpen: (Trip) -> Unit, onPast: () -> Unit, onNewTrip: () -> Unit) {
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val live = trips.filter { it.phase == TripPhase.LIVE }
    val upcoming = trips.filter { it.phase == TripPhase.UPCOMING }.sortedBy { it.startDate }
    val past = trips.filter { it.phase == TripPhase.PAST }.sortedByDescending { it.endDate }

    val list = rememberLazyListState()
    val scrolled by remember { derivedStateOf { list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 0 } }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.fillMaxSize(),
            state = list,
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = top + 8.dp, bottom = 28.dp + LocalBottomBarInset.current),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                // New trip lives here, not on Home: Android creates trips by importing a PDF only.
                Row(Modifier.padding(start = 4.dp, bottom = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text("Trips", Modifier.weight(1f), fontSize = 34.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
                    CircleButton(Icons.Filled.Add, "New trip", onClick = onNewTrip)
                }
            }

            if (live.isEmpty() && upcoming.isEmpty()) item {
                SurfaceCard(corner = 24.dp) {
                    Column(Modifier.padding(22.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text("Nothing ahead", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
                        Text("Import a booking PDF with + to start one.", fontSize = 13.5.sp, color = Brand.inkSecondary)
                    }
                }
            }

            listOf("Happening now" to live, "Coming up" to upcoming).forEachIndexed { section, (title, group) ->
                if (group.isNotEmpty()) {
                    item { Eyebrow(title, Modifier.padding(top = if (section == 0) 0.dp else 12.dp)) }
                    items(group, key = { it.id }) { trip ->
                        TripPlaceCard(trip, Modifier.staggered(section + 1)) { onOpen(trip) }
                    }
                }
            }

            if (past.isNotEmpty()) item {
                Box(Modifier.padding(top = 12.dp)) { WrappedUpRow(past, onPast) }
            }
        }
        TopFade(scrolled)
    }
}

@Composable
fun Eyebrow(text: String, modifier: Modifier = Modifier) {
    Text(
        text.uppercase(), modifier.padding(start = 6.dp),
        fontSize = 11.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.1.em, color = Brand.inkTertiary,
    )
}

/**
 * One trip as a place — iOS `TripPlaceCard`: its name set in the trip's typeface over a panel
 * washed in the colour of its own photograph, and the photograph inset beneath.
 */
@Composable
fun TripPlaceCard(trip: Trip, modifier: Modifier = Modifier, onOpen: () -> Unit) {
    val tint = rememberCoverTint(trip.coverUrl) ?: Brand.accent
    val shape = RoundedCornerShape(26.dp)
    val region = trip.destination.split(",").map { it.trim() }.filter { it.isNotEmpty() }.let { parts ->
        when {
            parts.isEmpty() -> trip.dateRange
            parts.size > 2 -> "${parts.first()}, ${parts.last()}"
            else -> parts.joinToString(", ")
        }
    }

    Column(
        modifier.fillMaxWidth()
            .pressable(onOpen)
            .shadow(14.dp, shape, ambientColor = Brand.shadow, spotColor = Brand.shadow)
            .clip(shape)
            .background(Brand.card)
            .background(Brush.linearGradient(listOf(tint.copy(alpha = 0.30f), tint.copy(alpha = 0.10f))))
            .border(0.5.dp, Brand.cardStroke.copy(alpha = 0.05f), shape),
    ) {
        Column(Modifier.padding(start = 16.dp, end = 16.dp, top = 14.dp, bottom = 12.dp)) {
            Text(region, fontSize = 13.sp, color = Brand.inkSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
            val style = tripTitle(trip.titleStyle, 30f)
            BasicText(
                trip.titleStyle.display(trip.title),
                Modifier.padding(top = 2.dp),
                style = style.copy(color = Brand.ink),
                maxLines = 1,
                autoSize = TextAutoSize.StepBased(minFontSize = style.fontSize * 0.7f, maxFontSize = style.fontSize),
            )
            Row(Modifier.padding(top = 3.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Map, null, tint = Brand.inkSecondary, modifier = Modifier.size(13.dp))
                Spacer(Modifier.width(5.dp))
                Text(
                    "${plural(trip.items.size, "booking")} · ${Money.format(trip.totalCost, trip.currencyCode)}",
                    fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary, maxLines = 1,
                )
            }
        }
        Box(
            Modifier.padding(start = 8.dp, end = 8.dp, bottom = 8.dp).fillMaxWidth().height(178.dp)
                .clip(RoundedCornerShape(16.dp))
                .border(0.5.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape(16.dp)),
        ) {
            CoverImage(trip, Modifier.fillMaxSize())
            Row(Modifier.align(Alignment.BottomStart).fillMaxWidth().padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    "${trip.phase.label} · ${trip.dateRange}",
                    Modifier.clip(CircleShape).background(Color.White.copy(alpha = 0.78f)).padding(horizontal = 10.dp, vertical = 6.dp),
                    fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold, color = Color.Black,
                )
                Spacer(Modifier.weight(1f))
                AvatarStack(trip.travellers, size = 24.dp, max = 4)
            }
        }
    }
}

/** Finished trips, folded into one row with their covers fanned out. */
@Composable
private fun WrappedUpRow(past: List<Trip>, onClick: () -> Unit) {
    SurfaceCard(Modifier.pressable(onClick), corner = 22.dp) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            val fan = past.take(3)
            Box(Modifier.width(44.dp + 16.dp * (fan.size - 1)).height(44.dp)) {
                fan.withIndex().reversed().forEach { (index, trip) ->
                    CoverImage(
                        trip,
                        Modifier.offset(x = 16.dp * index).size(44.dp).clip(RoundedCornerShape(12.dp))
                            .border(2.dp, Brand.card, RoundedCornerShape(12.dp)),
                    )
                }
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text("Wrapped up", fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
                Text(
                    "${plural(past.size, "trip")} · latest ${past.first().title}",
                    fontSize = 13.sp, color = Brand.inkSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis,
                )
            }
            Icon(Icons.Filled.ChevronRight, null, tint = Brand.inkTertiary)
        }
    }
}

/** Every trip that has ended, newest first, grouped by the year it ended — iOS `PastTripsView`. */
@Composable
fun PastTripsScreen(trips: List<Trip>, onBack: () -> Unit, onOpen: (Trip) -> Unit) {
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val byYear = trips.filter { it.phase == TripPhase.PAST }.sortedByDescending { it.endDate }.groupBy { it.endDate.year }
    val list = rememberLazyListState()
    val scrolled by remember { derivedStateOf { list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 0 } }
    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.fillMaxSize(),
            state = list,
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = top + 4.dp, bottom = 28.dp + LocalBottomBarInset.current),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CircleButton(Icons.AutoMirrored.Filled.ArrowBack, "Back", onClick = onBack)
                    Text("Wrapped up", Modifier.padding(start = 4.dp), fontSize = 34.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
                }
            }
            byYear.forEach { (year, group) ->
                item { Eyebrow("$year", Modifier.padding(top = 8.dp)) }
                items(group, key = { it.id }) { trip -> TripPlaceCard(trip) { onOpen(trip) } }
            }
        }
        TopFade(scrolled)
    }
}
