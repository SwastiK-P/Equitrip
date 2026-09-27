package com.swastik.equitrip.ui.settle

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
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallReceived
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.CreditCard
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.AppViewModel
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Settlement
import com.swastik.equitrip.model.Transfer
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.AvatarStack
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.SectionHeader
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.TopFade
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.components.staggered
import com.swastik.equitrip.ui.home.CircleButton
import com.swastik.equitrip.ui.home.CoverImage
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure

/** What a row on Settle opened: a transfer you owe, or a claim somebody made to you. */
sealed interface SettleFocus {
    data class Pay(val trip: Trip, val transfer: Transfer) : SettleFocus
    data class Review(val trip: Trip, val settlement: Settlement) : SettleFocus
}

/** Who pays whom, minimised, across every shared trip — iOS `SettleView` on a phone. */
@Composable
fun SettleScreen(vm: AppViewModel) {
    val me = vm.myId
    val relevant = vm.currentTrips.filter { it.needsSettling }
    val active = relevant.filter { !it.isFullySettled }
    val settled = relevant.filter { it.isFullySettled }
    val awaiting = vm.settlementsAwaitingYou
    val owedToYou = me?.let { id -> relevant.sumOf { maxOf(0.0, it.remainingBalance(id)) } } ?: 0.0
    val youOwe = me?.let { id -> relevant.sumOf { maxOf(0.0, -it.remainingBalance(id)) } } ?: 0.0
    val currency = relevant.firstOrNull()?.currencyCode ?: vm.primaryCurrency
    val transfers = relevant.sumOf { it.suggestedTransfers.size }

    var focus by remember { mutableStateOf<SettleFocus?>(null) }
    var showHistory by remember { mutableStateOf(false) }
    val list = rememberLazyListState()
    val scrolled by remember { derivedStateOf { list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 0 } }
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()

    Box(Modifier.fillMaxSize()) {
        PullToRefreshBox(isRefreshing = vm.refreshing, onRefresh = { vm.refresh() }, modifier = Modifier.fillMaxSize()) {
            LazyColumn(
                Modifier.fillMaxSize(),
                state = list,
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = top + 8.dp, bottom = 28.dp + LocalBottomBarInset.current),
                verticalArrangement = Arrangement.spacedBy(24.dp),
            ) {
                item(key = "header") {
                    Row(Modifier.staggered(0), verticalAlignment = Alignment.Top) {
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                            Text("Settle up", style = figure(30.sp), color = Brand.ink)
                            Text(
                                "Minimised to the fewest transfers, every time something changes.",
                                fontSize = 13.5.sp, color = Brand.inkSecondary,
                            )
                        }
                        Spacer(Modifier.width(12.dp))
                        Box(Modifier.alpha(if (settled.isEmpty()) 0.35f else 1f)) {
                            CircleButton(Icons.Filled.History, "History") { if (settled.isNotEmpty()) showHistory = true }
                        }
                    }
                }

                item(key = "summary") {
                    SurfaceCard(Modifier.staggered(1), corner = 26.dp, elevation = 14.dp) {
                        Column(Modifier.padding(18.dp)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                SummaryFigure("You're owed", owedToYou, currency, Brand.accent, Modifier.weight(1f))
                                Box(Modifier.width(1.dp).height(34.dp).background(Brand.cardStroke.copy(alpha = 0.10f)))
                                SummaryFigure("You owe", youOwe, currency, Brand.danger, Modifier.weight(1f).padding(start = 16.dp))
                            }
                            if (relevant.isNotEmpty()) {
                                Box(Modifier.padding(vertical = 14.dp)) { Hairline(inset = 0.dp) }
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(Icons.Filled.AutoAwesome, null, tint = Brand.accent, modifier = Modifier.size(13.dp))
                                    Spacer(Modifier.width(6.dp))
                                    Text(
                                        "${plural(transfers, "transfer")} closes out every trip here",
                                        fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary,
                                    )
                                }
                            }
                        }
                    }
                }

                if (awaiting.isNotEmpty()) item(key = "waiting") {
                    Column(Modifier.staggered(2), verticalArrangement = Arrangement.spacedBy(11.dp)) {
                        SectionHeader("Waiting on you", caption = "${awaiting.size}")
                        awaiting.forEach { (trip, settlement) ->
                            WaitingOnYouRow(trip, settlement) { focus = SettleFocus.Review(trip, settlement) }
                        }
                    }
                }

                when {
                    relevant.isEmpty() -> item(key = "empty") { EmptyState(Modifier.staggered(3)) }
                    active.isEmpty() -> item(key = "clear") { AllClear(settled.size, Modifier.staggered(3)) { showHistory = true } }
                    else -> {
                        item(key = "bytrip") { SectionHeader("By trip", Modifier.staggered(3)) }
                        items(active, key = { it.id }) { trip ->
                            TripSettleCard(trip, me, Modifier.staggered(3)) { focus = it }
                        }
                    }
                }
            }
        }
        TopFade(scrolled)
    }

    focus?.let { SettleSheet(it) { focus = null } }
    if (showHistory) HistorySheet(settled) { showHistory = false }
}

@Composable
private fun SummaryFigure(label: String, value: Double, code: String, dot: Color, modifier: Modifier) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(5.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(6.dp).clip(CircleShape).background(dot))
            Spacer(Modifier.width(5.dp))
            Text(label, fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary)
        }
        Text(Money.format(value, code), style = figure(24.sp), color = Brand.ink, maxLines = 1)
    }
}

@Composable
private fun WaitingOnYouRow(trip: Trip, settlement: Settlement, onClick: () -> Unit) {
    val payer = trip.traveller(settlement.fromId)
    val shape = RoundedCornerShape(20.dp)
    Row(
        Modifier.fillMaxWidth().pressable(onClick).clip(shape).background(Brand.accent.copy(alpha = 0.06f))
            .border(0.5.dp, Brand.accent.copy(alpha = 0.16f), shape).padding(13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        payer?.let { Avatar(it, 40.dp) }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                "${payer?.name ?: "Someone"} paid you ${Money.format(settlement.amount, settlement.currencyCode)}",
                fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 2,
            )
            Text("${trip.title} · ${settlement.method.label} · tap to review", fontSize = 11.5.sp, color = Brand.inkTertiary, maxLines = 1)
        }
        Icon(Icons.Filled.ChevronRight, null, tint = Brand.inkTertiary)
    }
}

/** One trip's transfers, each with what you can do about it — iOS `TripSettleCard`. */
@Composable
private fun TripSettleCard(trip: Trip, me: String?, modifier: Modifier, onFocus: (SettleFocus) -> Unit) {
    SurfaceCard(modifier) {
        Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            CoverImage(trip, Modifier.size(34.dp).clip(RoundedCornerShape(10.dp)))
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Text(trip.title, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 1)
                Text(trip.dateRange, fontSize = 11.5.sp, color = Brand.inkTertiary)
            }
            AvatarStack(trip.travellers, size = 22.dp, max = 4)
        }
        Hairline()
        trip.suggestedTransfers.forEachIndexed { index, transfer ->
            if (index > 0) Hairline()
            TransferRow(trip, transfer, me, onFocus)
        }
    }
}

@Composable
private fun TransferRow(trip: Trip, transfer: Transfer, me: String?, onFocus: (SettleFocus) -> Unit) {
    val from = trip.traveller(transfer.from)
    val to = trip.traveller(transfer.to)
    val youPay = transfer.from == me
    val youGet = transfer.to == me
    val pending = trip.pendingSettlement(transfer.from, transfer.to)

    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.width(52.dp)) {
            to?.let { Box(Modifier.offset(x = 22.dp)) { Avatar(it, 30.dp) } }
            from?.let { Avatar(it, 30.dp, Modifier.border(1.5.dp, Brand.card, CircleShape)) }
        }
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                "${if (youPay) "You" else from?.name ?: "Someone"} → ${if (youGet) "you" else to?.name ?: "someone"}",
                fontSize = 13.5.sp, fontWeight = FontWeight.Medium, color = Brand.ink, maxLines = 2,
            )
            Text(Money.format(transfer.amount, trip.currencyCode), style = figure(16.sp), color = Brand.ink)
        }
        Spacer(Modifier.width(6.dp))
        when {
            pending != null && youGet -> TagChip("Review", Brand.accent, Icons.Filled.Notifications) { onFocus(SettleFocus.Review(trip, pending)) }
            pending != null && youPay -> TagChip("Waiting", Brand.amber, Icons.Filled.Schedule)
            pending != null -> TagChip("Pending", Brand.amber, Icons.Filled.Schedule)
            youPay -> Text(
                "Settle",
                Modifier.clip(CircleShape).background(Brand.cta).pressable { onFocus(SettleFocus.Pay(trip, transfer)) }
                    .padding(horizontal = 14.dp, vertical = 8.dp),
                fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = Color.White,
            )
            youGet -> TagChip("Owed to you", Brand.accent, Icons.AutoMirrored.Filled.CallReceived)
        }
    }
}

/** A small tinted capsule with a glyph — iOS `TagChip`. */
@Composable
fun TagChip(title: String, tint: Color, icon: ImageVector, onClick: (() -> Unit)? = null) {
    Row(
        Modifier.clip(CircleShape).background(tint.copy(alpha = 0.12f))
            .then(if (onClick != null) Modifier.pressable(onClick) else Modifier)
            .padding(horizontal = 9.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = tint, modifier = Modifier.size(11.dp))
        Spacer(Modifier.width(4.dp))
        Text(title, fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold, color = tint)
    }
}

@Composable
private fun AllClear(count: Int, modifier: Modifier, onClick: () -> Unit) {
    SurfaceCard(modifier.pressable(onClick)) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Verified, null, tint = Brand.positive, modifier = Modifier.size(30.dp))
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text("All settled up", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
                Text("${plural(count, "trip")} squared away — view in History", fontSize = 12.5.sp, color = Brand.inkSecondary)
            }
            Icon(Icons.Filled.ChevronRight, null, tint = Brand.inkTertiary)
        }
    }
}

@Composable
private fun EmptyState(modifier: Modifier) {
    SurfaceCard(modifier) {
        Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(40.dp).clip(CircleShape).background(Brand.positive.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Check, null, tint = Brand.positive, modifier = Modifier.size(18.dp))
                }
                Spacer(Modifier.width(12.dp))
                Column {
                    Text("All square", fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
                    Text("Nobody owes anybody yet", fontSize = 12.5.sp, color = Brand.inkSecondary)
                }
            }
            Hairline(inset = 0.dp)
            listOf(
                Icons.Filled.Flight to "Add a booking to a shared trip",
                Icons.Filled.CreditCard to "Mark who paid for it",
                Icons.Filled.SwapHoriz to "Who owes whom shows up here",
            ).forEachIndexed { index, (icon, text) ->
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(28.dp).clip(CircleShape).background(Brand.inkTertiary.copy(alpha = 0.12f)), contentAlignment = Alignment.Center) {
                        Icon(icon, null, tint = Brand.inkSecondary, modifier = Modifier.size(14.dp))
                    }
                    Spacer(Modifier.width(12.dp))
                    Text(text, fontSize = 13.5.sp, fontWeight = FontWeight.Medium, color = Brand.ink, modifier = Modifier.weight(1f))
                    Text("${index + 1}", style = figure(11.5.sp), color = Brand.inkTertiary)
                }
            }
        }
    }
}
