package com.swastik.equitrip.ui.itinerary

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.automirrored.filled.Redo
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.KindBadge
import com.swastik.equitrip.ui.components.SectionHeader
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure
import java.time.format.DateTimeFormatter

/** The money side of one trip — iOS `TripLedger`: what it cost, where it went, and every expense. */
@Composable
fun LedgerSection(trip: Trip, me: String?, onOpen: (ItineraryItem) -> Unit) {
    val code = trip.currencyCode
    val priced = trip.items.filter { it.cost > 0 }.sortedWith(compareByDescending<ItineraryItem> { it.day }.thenByDescending { it.time })
    val total = priced.sumOf { it.cost }
    var showAll by rememberSaveable { mutableStateOf(false) }

    Column(Modifier.padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(26.dp)) {
        SurfaceCard(corner = 28.dp, elevation = 16.dp) {
            Column(Modifier.padding(18.dp)) {
                Text("TRIP SPEND", fontSize = 10.5.sp, fontWeight = FontWeight.Bold, letterSpacing = 0.09.em, color = Brand.inkTertiary)
                Text(Money.format(Math.round(total).toDouble(), code), Modifier.padding(top = 2.dp), style = figure(34.sp), color = Brand.ink, maxLines = 1)
                Text("across ${plural(priced.size, "booking")}", fontSize = 12.5.sp, color = Brand.inkSecondary)
                SpendBreakdown(trip, priced, total, Modifier.padding(top = 16.dp))
                Box(Modifier.padding(vertical = 16.dp)) { Hairline(inset = 0.dp) }
                if (me != null) {
                    Column(verticalArrangement = Arrangement.spacedBy(9.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                            Figure("Your share", trip.cost(me), code, Icons.Filled.Person, Brand.inkSecondary, Modifier.weight(1f))
                            Figure("You paid", trip.paid(me), code, Icons.Filled.CreditCard, Brand.inkSecondary, Modifier.weight(1f))
                        }
                        Row(horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                            Figure("You're owed", trip.owedTo(me), code, Icons.AutoMirrored.Filled.Undo, Brand.accent, Modifier.weight(1f))
                            Figure("You owe", trip.owing(me), code, Icons.AutoMirrored.Filled.Redo, Brand.danger, Modifier.weight(1f))
                        }
                    }
                }
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
            SectionHeader("Expenses", caption = Money.format(Math.round(total).toDouble(), code))
            if (priced.isEmpty()) {
                SurfaceCard(corner = 22.dp) {
                    Text("Nothing priced up yet.", Modifier.padding(16.dp), fontSize = 13.5.sp, color = Brand.inkSecondary)
                }
            } else {
                val shown = if (showAll) priced else priced.take(8)
                SurfaceCard {
                    shown.forEachIndexed { index, item ->
                        if (index > 0) Hairline()
                        LedgerRow(item, trip, me) { onOpen(item) }
                    }
                }
                if (priced.size > shown.size) {
                    Text(
                        "View all ${priced.size} expenses",
                        Modifier.fillMaxWidth().clip(CircleShape).background(Brand.card.copy(alpha = 0.7f)).pressable { showAll = true }
                            .padding(vertical = 12.dp),
                        fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.accent,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                    )
                }
            }
        }
    }
}

/** Where the money went, by kind: one stacked bar and the three biggest slices beneath it. */
@Composable
private fun SpendBreakdown(trip: Trip, priced: List<ItineraryItem>, total: Double, modifier: Modifier = Modifier) {
    if (total <= 0) return
    val slices = priced.groupBy { it.kind }.mapValues { (_, v) -> v.sumOf { it.cost } }.toList().sortedByDescending { it.second }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth().height(10.dp).clip(CircleShape), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
            slices.forEach { (kind, amount) ->
                Box(Modifier.weight((amount / total).toFloat().coerceAtLeast(0.01f)).fillMaxHeight().background(Brand.tint(kind)))
            }
        }
        slices.take(4).forEach { (kind, amount) ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(8.dp).clip(CircleShape).background(Brand.tint(kind)))
                Spacer(Modifier.width(8.dp))
                Text(kind.label, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Brand.ink, modifier = Modifier.weight(1f))
                Text("${Math.round(amount / total * 100)}%", fontSize = 12.sp, color = Brand.inkTertiary)
                Spacer(Modifier.width(10.dp))
                Text(Money.format(Math.round(amount).toDouble(), trip.currencyCode), style = figure(13.5.sp, FontWeight.SemiBold), color = Brand.ink)
            }
        }
    }
}

@Composable
private fun Figure(label: String, value: Double, code: String, icon: ImageVector, tint: Color, modifier: Modifier) {
    Row(
        modifier.clip(RoundedCornerShape(16.dp)).background(Brand.canvasBottom.copy(alpha = 0.45f)).padding(horizontal = 12.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(24.dp).clip(CircleShape).background(tint.copy(alpha = 0.13f)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = tint, modifier = Modifier.size(12.dp))
        }
        Spacer(Modifier.width(10.dp))
        Column {
            Text(label, fontSize = 11.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary, maxLines = 1)
            Text(
                Money.format(Math.round(value).toDouble(), code), style = figure(16.5.sp),
                color = if (value > 0) Brand.ink else Brand.inkTertiary, maxLines = 1,
            )
        }
    }
}

private val shortDay = DateTimeFormatter.ofPattern("d MMM")

@Composable
private fun LedgerRow(item: ItineraryItem, trip: Trip, me: String?, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().pressable(onClick).padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        KindBadge(item.kind, 36.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(item.title, fontSize = 14.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            val payer = trip.traveller(item.paidById)
            Text(
                "${item.day.format(shortDay)} · ${payer?.let { if (it.id == me) "You paid" else "${it.name} paid" } ?: "Nobody's paid yet"}",
                fontSize = 12.sp, color = if (payer == null) Brand.amber else Brand.inkSecondary, maxLines = 1,
            )
        }
        Spacer(Modifier.width(8.dp))
        Column(horizontalAlignment = Alignment.End) {
            Text(Money.format(item.cost, trip.currencyCode), style = figure(14.5.sp), color = Brand.ink)
            if (me != null) Text("you ${Money.format(trip.share(item, me), trip.currencyCode)}", fontSize = 10.5.sp, color = Brand.inkTertiary)
        }
    }
}
