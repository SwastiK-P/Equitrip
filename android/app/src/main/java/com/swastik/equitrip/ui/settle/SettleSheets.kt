package com.swastik.equitrip.ui.settle

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.SettlementStatus
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.home.CoverImage
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure
import java.time.format.DateTimeFormatter

/**
 * A transfer you owe, or a payment somebody says they made you — the read side of iOS
 * `SettleUpSheet` / `SettlementReviewSheet`. Recording and confirming write the audit trail
 * and notify the other person, so they stay on iPhone until Android does both.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettleSheet(focus: SettleFocus, onDismiss: () -> Unit) {
    val context = LocalContext.current
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Brand.canvasTop) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).navigationBarsPadding().padding(bottom = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            when (focus) {
                is SettleFocus.Pay -> {
                    val trip = focus.trip
                    val to = trip.traveller(focus.transfer.to)
                    People(trip.traveller(focus.transfer.from), to)
                    Text("You pay ${to?.name ?: "them"}", fontSize = 15.sp, color = Brand.inkSecondary)
                    Text(Money.format(focus.transfer.amount, trip.currencyCode), style = figure(44.sp), color = Brand.ink)
                    Text(trip.title, fontSize = 13.sp, color = Brand.inkTertiary)
                    val vpa = to?.upiId?.trim().orEmpty()
                    if (vpa.contains("@") && trip.currencyCode == "INR") {
                        Button(
                            onClick = {
                                val uri = Uri.Builder().scheme("upi").authority("pay")
                                    .appendQueryParameter("pa", vpa)
                                    .appendQueryParameter("pn", to?.name.orEmpty())
                                    .appendQueryParameter("am", "%.2f".format(focus.transfer.amount))
                                    .appendQueryParameter("cu", "INR")
                                    .appendQueryParameter("tn", trip.title)
                                    .build()
                                try {
                                    context.startActivity(Intent(Intent.ACTION_VIEW, uri))
                                } catch (_: ActivityNotFoundException) {
                                    // No UPI app on this phone; the note below still says how to finish.
                                }
                            },
                            modifier = Modifier.fillMaxWidth().height(52.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = Brand.accent),
                        ) {
                            Text("Pay with UPI", fontSize = 15.5.sp, fontWeight = FontWeight.SemiBold)
                            Spacer(Modifier.width(6.dp))
                            Icon(Icons.AutoMirrored.Filled.ArrowForward, null, modifier = Modifier.size(16.dp))
                        }
                        Text(vpa, fontSize = 12.5.sp, color = Brand.inkTertiary)
                    }
                    Note("Once you've paid, record it from the iPhone app so ${to?.name ?: "they"} can confirm it.")
                }
                is SettleFocus.Review -> {
                    val trip = focus.trip
                    val s = focus.settlement
                    val payer = trip.traveller(s.fromId)
                    People(payer, trip.traveller(s.toId))
                    Text("${payer?.name ?: "Someone"} says they paid you", fontSize = 15.sp, color = Brand.inkSecondary)
                    Text(Money.format(s.amount, s.currencyCode), style = figure(44.sp), color = Brand.ink)
                    SurfaceCard {
                        Fact("Trip", trip.title)
                        Hairline()
                        Fact("Method", s.method.label)
                        Hairline()
                        Fact("Sent", s.createdAt.format(DateTimeFormatter.ofPattern("d MMM, h:mm a")))
                    }
                    Note("Confirm or decline it from the iPhone app. Only you can: the balance moves once you say it arrived.")
                }
            }
        }
    }
}

@Composable
private fun People(from: Traveller?, to: Traveller?) {
    Box(Modifier.width(104.dp).height(58.dp)) {
        to?.let { Box(Modifier.offset(x = 46.dp)) { Avatar(it, 58.dp) } }
        from?.let { Avatar(it, 58.dp) }
    }
}

@Composable
private fun Fact(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp)) {
        Text(label, fontSize = 14.sp, color = Brand.inkSecondary, modifier = Modifier.weight(1f))
        Text(value, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
    }
}

@Composable
private fun Note(text: String) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Brand.cardStroke.copy(alpha = 0.05f)).padding(14.dp),
        verticalAlignment = Alignment.Top,
    ) {
        Icon(Icons.Filled.Info, null, tint = Brand.inkTertiary, modifier = Modifier.size(16.dp))
        Spacer(Modifier.width(10.dp))
        Text(text, fontSize = 12.5.sp, color = Brand.inkSecondary, textAlign = TextAlign.Start)
    }
}

/** Everywhere the group has already squared up — iOS `SettleHistorySheet`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistorySheet(trips: List<Trip>, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Brand.canvasTop) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).navigationBarsPadding().padding(bottom = 20.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("History", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Brand.ink)
            Text("${plural(trips.size, "trip")} squared away", fontSize = 13.sp, color = Brand.inkSecondary)
            SurfaceCard {
                trips.forEachIndexed { index, trip ->
                    if (index > 0) Hairline()
                    Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                        CoverImage(trip, Modifier.size(40.dp).clip(RoundedCornerShape(12.dp)))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(trip.title, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
                            Text(
                                "${trip.dateRange} · ${plural(trip.settlements.count { it.status == SettlementStatus.CONFIRMED }, "payment")}",
                                fontSize = 12.sp, color = Brand.inkTertiary,
                            )
                        }
                        Text(
                            "Settled",
                            Modifier.clip(CircleShape).background(Brand.positive.copy(alpha = 0.12f)).padding(horizontal = 9.dp, vertical = 5.dp),
                            fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.positive,
                        )
                    }
                }
            }
        }
    }
}
