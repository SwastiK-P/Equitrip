package com.swastik.equitrip.ui.newtrip

import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.Description
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.ImportState
import com.swastik.equitrip.R
import com.swastik.equitrip.importer.ExtractedKind
import com.swastik.equitrip.importer.ImportedTrip
import com.swastik.equitrip.importer.NugenReader
import com.swastik.equitrip.importer.PlannedItem
import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.KindBadge
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.home.CircleButton
import com.swastik.equitrip.ui.itinerary.Eyebrow
import com.swastik.equitrip.ui.theme.Brand
import java.time.format.DateTimeFormatter

/**
 * New trip on Android: import a booking PDF, nothing else — no blank trip, no join by code.
 *
 * The PDF is read by the Nugen domain-aligned model a day at a time (`TripImporter`), with
 * no pattern-matching fallback, so a day it can't read stops the import with a retry.
 * Review shows exactly what will be saved; the only edit is the trip's name.
 */
@Composable
fun ImportTripScreen(
    state: ImportState,
    onBack: () -> Unit,
    onPick: (Uri, String) -> Unit,
    onSave: (String) -> Unit,
) {
    val context = LocalContext.current
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) onPick(uri, displayName(context, uri))
    }
    val choose = { picker.launch(arrayOf("application/pdf")) }
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()

    Box(Modifier.fillMaxSize()) {
        LazyColumn(
            Modifier.fillMaxSize(),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = top + 4.dp, bottom = 120.dp + LocalBottomBarInset.current),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    CircleButton(Icons.AutoMirrored.Filled.ArrowBack, "Back", onClick = onBack)
                    Text("New trip", Modifier.padding(start = 4.dp), fontSize = 34.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
                }
            }
            when (state) {
                ImportState.Idle -> item { PickCard(choose) }
                is ImportState.Reading -> item { ReadingCard(state) }
                is ImportState.Failed -> item { FailedCard(state, retry = { state.uri?.let { onPick(it, state.fileName ?: "PDF") } }, choose = choose) }
                is ImportState.Review -> review(state)
            }
        }
        if (state is ImportState.Review) SaveBar(state, onSave, Modifier.align(Alignment.BottomCenter))
    }
}

@Composable
private fun ReaderLine() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Image(
            painterResource(R.drawable.nugen_mark), contentDescription = null,
            modifier = Modifier.size(22.dp).clip(RoundedCornerShape(6.dp)).border(0.5.dp, Brand.hairline, RoundedCornerShape(6.dp)),
        )
        Spacer(Modifier.width(8.dp))
        Text("Read by ${NugenReader.MODEL_NAME}", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary)
    }
}

@Composable
private fun PickCard(choose: () -> Unit) {
    SurfaceCard(corner = 24.dp) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Icon(Icons.Outlined.Description, null, tint = Brand.accent, modifier = Modifier.size(30.dp))
            Text("Import a booking PDF", fontSize = 19.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
            Text(
                "An itinerary, a travel agent's plan or a booking confirmation. Every day's bookings are read into the trip.",
                fontSize = 14.sp, color = Brand.inkSecondary,
            )
            ReaderLine()
            PrimaryButton("Choose PDF", onClick = choose)
            Text(
                "Each day's text is read on Nugen's servers, sent through Equitrip's own server. Times and amounts are copied from the PDF, never from the model.",
                fontSize = 12.sp, color = Brand.inkTertiary,
            )
        }
    }
}

@Composable
private fun ReadingCard(state: ImportState.Reading) {
    SurfaceCard(corner = 24.dp) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Text(state.fileName, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            ReaderLine()
            val caption = if (state.total == 0) "Opening the document…" else "Reading ${plural(state.total, "day")}… ${state.done} done"
            Text(caption, fontSize = 14.sp, color = Brand.inkSecondary)
            if (state.total == 0) {
                LinearProgressIndicator(Modifier.fillMaxWidth(), color = Brand.accent, trackColor = Brand.hairline)
            } else {
                LinearProgressIndicator(
                    progress = { state.done.toFloat() / state.total },
                    modifier = Modifier.fillMaxWidth(), color = Brand.accent, trackColor = Brand.hairline,
                )
            }
        }
    }
}

@Composable
private fun FailedCard(state: ImportState.Failed, retry: () -> Unit, choose: () -> Unit) {
    SurfaceCard(corner = 24.dp) {
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("Couldn't import this PDF", fontSize = 17.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
            Text(state.message, fontSize = 14.sp, color = Brand.inkSecondary)
            if (state.uri != null) PrimaryButton("Try again", onClick = retry)
            Text(
                "Choose another PDF", Modifier.padding(top = 2.dp).pressable(choose),
                fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.accent,
            )
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.review(state: ImportState.Review) {
    val trip = state.trip
    item { SummaryCard(trip) }
    if (trip.unsureDays.isNotEmpty()) item {
        Text(
            "Nugen was less sure of ${trip.unsureDays.joinToString { "day $it" }} — look at ${if (trip.unsureDays.size == 1) "that" else "those"} first.",
            Modifier.padding(horizontal = 6.dp), fontSize = 13.sp, color = Brand.inkSecondary,
        )
    }
    trip.days.forEach { day ->
        item(key = "day-${day.number}") {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Eyebrow("Day ${day.number} · ${day.date.format(DateTimeFormatter.ofPattern("EEE d MMM"))}")
                SurfaceCard(corner = 22.dp) {
                    day.items.forEachIndexed { index, item ->
                        if (index > 0) Box(Modifier.padding(start = 64.dp).fillMaxWidth().height(0.5.dp).background(Brand.hairline))
                        BookingRow(item, trip.currencyCode)
                    }
                }
            }
        }
    }
}

@Composable
private fun SummaryCard(trip: ImportedTrip) {
    SurfaceCard(corner = 24.dp) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            ReaderLine()
            val span = DateTimeFormatter.ofPattern("d MMM")
            Text(
                listOfNotNull(
                    trip.destination.ifEmpty { null },
                    "${trip.startDate.format(span)}–${trip.endDate.format(span)}",
                ).joinToString(" · "),
                fontSize = 14.sp, color = Brand.inkSecondary,
            )
            Text(
                "${plural(trip.items.size, "booking")} · ${Money.format(trip.items.sumOf { it.amount }, trip.currencyCode)}",
                fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Brand.ink,
            )
            if (trip.travellerCount > 1) {
                Text(
                    "The PDF is for ${trip.travellerCount} people. You'll be the only traveller until you invite the rest from iPhone.",
                    fontSize = 12.5.sp, color = Brand.inkTertiary,
                )
            }
        }
    }
}

@Composable
private fun BookingRow(item: PlannedItem, currency: String) {
    Row(Modifier.padding(horizontal = 14.dp, vertical = 11.dp), verticalAlignment = Alignment.CenterVertically) {
        KindBadge(item.kind.asItineraryKind(), size = 36.dp)
        Spacer(Modifier.width(14.dp))
        Column(Modifier.weight(1f)) {
            Text(item.title, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            val sub = listOf(item.clockText, item.detail).filter { it.isNotEmpty() }.joinToString(" · ")
            if (sub.isNotEmpty()) Text(sub, fontSize = 12.5.sp, color = Brand.inkSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (item.amount > 0) {
            Spacer(Modifier.width(8.dp))
            Text(Money.format(item.amount, currency), fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
        }
    }
}

@Composable
private fun SaveBar(state: ImportState.Review, onSave: (String) -> Unit, modifier: Modifier) {
    var title by rememberSaveable(state.fileName) { mutableStateOf(state.trip.title) }
    Column(
        modifier.fillMaxWidth().background(Brand.canvasBottom)
            .padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 12.dp + LocalBottomBarInset.current),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        state.error?.let { Text(it, fontSize = 13.sp, color = Brand.danger) }
        OutlinedTextField(
            value = title, onValueChange = { title = it.take(60) },
            label = { Text("Trip name") }, singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = Brand.card, unfocusedContainerColor = Brand.card,
                focusedBorderColor = Brand.accent, unfocusedBorderColor = Brand.hairline,
            ),
        )
        PrimaryButton(if (state.saving) "Saving…" else "Create trip", busy = state.saving) {
            if (title.isNotBlank()) onSave(title)
        }
    }
}

@Composable
private fun PrimaryButton(label: String, busy: Boolean = false, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(26.dp)).background(Brand.cta)
            .pressable { if (!busy) onClick() },
        horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
    ) {
        if (busy) {
            CircularProgressIndicator(Modifier.size(18.dp), color = Brand.card, strokeWidth = 2.dp)
            Spacer(Modifier.width(10.dp))
        }
        Text(label, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, color = Brand.card)
    }
}

private fun ExtractedKind.asItineraryKind() = when (this) {
    ExtractedKind.FLIGHT -> ItineraryKind.FLIGHT
    ExtractedKind.TRAIN -> ItineraryKind.TRAIN
    ExtractedKind.TRANSFER -> ItineraryKind.DRIVE
    ExtractedKind.STAY -> ItineraryKind.STAY
    ExtractedKind.ACTIVITY -> ItineraryKind.ACTIVITY
    ExtractedKind.MEAL -> ItineraryKind.MEAL
    ExtractedKind.OTHER -> ItineraryKind.OTHER
}

private fun displayName(context: android.content.Context, uri: Uri): String =
    runCatching {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0) else null
        }
    }.getOrNull() ?: "Booking PDF"
