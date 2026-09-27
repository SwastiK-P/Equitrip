package com.swastik.equitrip.ui.itinerary

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.DragHandle
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.SplitMode
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.ui.components.AvatarStack
import com.swastik.equitrip.ui.components.KindBadge
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

private val clock = DateTimeFormatter.ofPattern("h:mm")
private val meridiem = DateTimeFormatter.ofPattern("a")
private val dayFormat = DateTimeFormatter.ofPattern("EEE d MMM")

/** Two options on a sunken track, the chosen one a dark pill — the iOS segmented picker. */
@Composable
fun <T> SegmentedSwitch(options: List<Pair<T, String>>, selected: T, onSelect: (T) -> Unit, modifier: Modifier = Modifier) {
    Row(
        modifier.fillMaxWidth().height(42.dp).clip(CircleShape).background(Brand.cardStroke.copy(alpha = 0.06f)).padding(3.dp),
    ) {
        options.forEach { (value, label) ->
            val on = value == selected
            val fill by animateColorAsState(if (on) Brand.cta else Color.Transparent, label = "segment")
            Box(
                Modifier.weight(1f).fillMaxHeight().clip(CircleShape).background(fill).pressable { onSelect(value) },
                contentAlignment = Alignment.Center,
            ) {
                Text(label, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = if (on) Color.White else Brand.inkSecondary)
            }
        }
    }
}

/** "Everyone 45" — a filter chip with its count. */
@Composable
fun ScopeChip(title: String, count: Int, on: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.clip(CircleShape)
            .background(if (on) Brand.cta else Brand.card.copy(alpha = 0.7f))
            .border(0.5.dp, if (on) Color.Transparent else Brand.cardStroke.copy(alpha = 0.07f), CircleShape)
            .pressable(onClick)
            .padding(horizontal = 11.dp, vertical = 6.5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val ink = if (on) Color.White else Brand.inkSecondary
        Text(title, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = ink)
        Spacer(Modifier.width(5.dp))
        Text("$count", style = figure(11.sp), color = ink.copy(alpha = 0.65f))
    }
}

/** "Day 1  Sat 12 Sep  TODAY  ›" on a frosted pill; tapping folds the day away. */
@Composable
fun DayHeader(index: Int, date: LocalDate, collapsed: Boolean, onToggle: () -> Unit) {
    val turn by animateFloatAsState(if (collapsed) 0f else 90f, label = "chevron")
    Row(
        Modifier.padding(start = 20.dp, end = 20.dp, top = 14.dp, bottom = 10.dp).fillMaxWidth()
            .clip(CircleShape).background(Color.White.copy(alpha = 0.72f))
            .border(0.5.dp, Brand.cardStroke.copy(alpha = 0.07f), CircleShape)
            .pressable(onToggle)
            .padding(horizontal = 14.dp, vertical = 9.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(9.dp),
    ) {
        Text("Day ${index + 1}", style = figure(13.5.sp), color = Brand.ink)
        Text(date.format(dayFormat), fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary)
        if (date == LocalDate.now()) {
            Text(
                "TODAY",
                Modifier.clip(CircleShape).background(Brand.accent).padding(horizontal = 6.dp, vertical = 3.dp),
                fontSize = 9.5.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.06.em, color = Color.White,
            )
        }
        Spacer(Modifier.weight(1f))
        Icon(Icons.Filled.ChevronRight, null, tint = Brand.inkTertiary, modifier = Modifier.size(16.dp).rotate(turn))
    }
}

/**
 * One booking on the day's rail — iOS `TimelineRow`: the time in a gutter, a dot in the
 * booking's colour on a line that runs down the day, and the card. The line fades out under
 * a day's last booking, and stops under the trip's last.
 */
@Composable
fun TimelineRow(item: ItineraryItem, trip: Trip, me: String?, isLast: Boolean, closesDay: Boolean, onClick: () -> Unit) {
    Row(Modifier.padding(horizontal = 20.dp).height(IntrinsicSize.Min)) {
        Column(Modifier.width(42.dp).padding(top = 2.dp), horizontalAlignment = Alignment.End) {
            val time = item.time?.atZoneSameInstant(ZoneId.systemDefault())
            if (time != null) {
                Text(time.format(clock), style = figure(13.5.sp), color = Brand.ink)
                Text(time.format(meridiem).uppercase(), fontSize = 9.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.inkTertiary)
            } else {
                Text("All\nday", fontSize = 10.sp, fontWeight = FontWeight.SemiBold, color = Brand.inkTertiary, textAlign = TextAlign.End)
            }
        }
        Column(Modifier.width(34.dp).fillMaxHeight(), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                Modifier.padding(top = 5.dp).size(10.dp).clip(CircleShape).background(Brand.canvasTop).padding(2.dp)
                    .clip(CircleShape).background(Brand.tint(item.kind)),
            )
            if (!isLast) {
                val line = Brand.cardStroke.copy(alpha = 0.14f)
                Box(
                    Modifier.width(1.5.dp).weight(1f).background(
                        if (closesDay) Brush.verticalGradient(listOf(line, line.copy(alpha = 0f))) else Brush.linearGradient(listOf(line, line)),
                    ),
                )
            }
        }
        Box(Modifier.weight(1f).padding(bottom = 14.dp)) { TimelineCard(item, trip, me, onClick) }
    }
}

@Composable
private fun TimelineCard(item: ItineraryItem, trip: Trip, me: String?, onClick: () -> Unit) {
    val dashed = trip.isUnplanned(item)
    val shape = RoundedCornerShape(20.dp)
    val body: @Composable () -> Unit = {
        Column(Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                KindBadge(item.kind, 34.dp)
                Spacer(Modifier.width(11.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(item.title, fontSize = 15.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
                    if (item.vendor.isNotBlank()) Text(item.vendor.trim(), fontSize = 12.5.sp, color = Brand.inkSecondary, maxLines = 1)
                }
                if (item.cost > 0) {
                    Spacer(Modifier.width(6.dp))
                    Column(horizontalAlignment = Alignment.End) {
                        Text(Money.format(item.cost, trip.currencyCode), style = figure(14.5.sp), color = Brand.ink)
                        Text("total", fontSize = 9.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkTertiary)
                    }
                }
            }
            Row(Modifier.padding(top = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                AvatarStack(trip.bearers(item), size = 24.dp, max = 4)
                trip.traveller(item.paidById)?.let { payer ->
                    Spacer(Modifier.width(8.dp))
                    Text("${if (payer.id == me) "You" else payer.name} paid", fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Brand.inkTertiary, maxLines = 1)
                }
                Spacer(Modifier.weight(1f))
                SplitChip(item, trip)
            }
        }
    }
    if (dashed) {
        // Added once the trip was running: the same card, drawn as an outline rather than a surface.
        Box(
            Modifier.fillMaxWidth().pressable(onClick).clip(shape).background(Brand.card).drawBehind {
                drawRoundRect(
                    Brand.accent.copy(alpha = 0.35f),
                    cornerRadius = CornerRadius(20.dp.toPx()),
                    style = Stroke(1.2.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(5.dp.toPx(), 4.dp.toPx()))),
                )
            },
        ) { body() }
    } else {
        SurfaceCard(Modifier.pressable(onClick), corner = 20.dp, elevation = 6.dp) { body() }
    }
}

/** How the cost divides, said as the figure it comes to where that's meaningful — "₹96,000 each". */
@Composable
fun SplitChip(item: ItineraryItem, trip: Trip) {
    val heads = trip.shares(item).size
    val label = when {
        item.cost <= 0 || item.split == SplitMode.INDIVIDUAL -> item.split.label
        item.split == SplitMode.ORGANISER && heads <= 1 -> item.split.label
        heads == 0 -> item.split.label
        else -> "${Money.format(Math.floor(item.cost / heads), trip.currencyCode)} each"
    }
    Row(
        Modifier.clip(CircleShape).background(Brand.cardStroke.copy(alpha = 0.06f)).padding(horizontal = 8.dp, vertical = 4.5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(item.split.icon(), null, tint = Brand.inkSecondary, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(4.dp))
        Text(label, fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = Brand.inkSecondary, maxLines = 1)
    }
}

fun SplitMode.icon(): ImageVector = when (this) {
    SplitMode.EQUAL -> Icons.Filled.DragHandle
    SplitMode.PARTICIPANTS -> Icons.Filled.People
    SplitMode.CUSTOM -> Icons.Filled.Tune
    SplitMode.ORGANISER -> Icons.Filled.Star
    SplitMode.INDIVIDUAL -> Icons.Filled.Person
}
