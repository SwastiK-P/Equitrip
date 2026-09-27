package com.swastik.equitrip.ui.itinerary

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.SectionHeader
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** One booking, in full — the read-only heart of iOS `ItineraryItemDetailView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingSheet(item: ItineraryItem, trip: Trip, me: String?, onDismiss: () -> Unit) {
    val tint = Brand.tint(item.kind)
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Brand.canvasTop) {
        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).navigationBarsPadding().padding(bottom = 20.dp),
            verticalArrangement = Arrangement.spacedBy(22.dp),
        ) {
            Box(
                Modifier.fillMaxWidth().height(170.dp).clip(RoundedCornerShape(24.dp))
                    .background(Brush.linearGradient(listOf(tint.copy(alpha = 0.85f), tint.copy(alpha = 0.55f)))),
            ) {
                item.coverUrl?.let { AsyncImage(it, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize()) }
                Box(Modifier.fillMaxSize().background(Brush.verticalGradient(0.35f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.55f))))
                Column(Modifier.align(Alignment.BottomStart).padding(16.dp)) {
                    Text(item.kind.label.uppercase(), fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White.copy(alpha = 0.8f))
                    Text(item.title, fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White)
                    if (item.vendor.isNotBlank()) Text(item.vendor, fontSize = 13.sp, color = Color.White.copy(alpha = 0.85f), maxLines = 2)
                }
            }

            SurfaceCard {
                val time = item.time?.atZoneSameInstant(ZoneId.systemDefault())
                Fact("When", item.day.format(DateTimeFormatter.ofPattern("EEEE, d MMMM")) + (time?.let { " · ${it.format(DateTimeFormatter.ofPattern("h:mm a"))}" } ?: ""))
                Hairline()
                Fact("Cost", if (item.cost > 0) Money.format(item.cost, trip.currencyCode) else "Not priced")
                Hairline()
                Fact("Split", item.split.label)
                Hairline()
                Fact("Paid by", trip.traveller(item.paidById)?.let { if (it.id == me) "You" else it.name } ?: "Nobody yet")
            }

            val shares = trip.shares(item)
            if (shares.isNotEmpty()) {
                Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
                    SectionHeader("Who's on it", caption = "${shares.size}")
                    SurfaceCard {
                        shares.forEachIndexed { index, (person, amount) ->
                            if (index > 0) Hairline(inset = 62.dp)
                            Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
                                Avatar(person, 34.dp)
                                Spacer(Modifier.width(12.dp))
                                Text(if (person.id == me) "You" else person.name, fontSize = 15.sp, fontWeight = FontWeight.Medium, color = Brand.ink, modifier = Modifier.weight(1f))
                                Text(Money.format(amount, trip.currencyCode), style = figure(15.sp), color = Brand.ink)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun Fact(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, fontSize = 14.sp, color = Brand.inkSecondary, modifier = Modifier.weight(1f))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
    }
}
