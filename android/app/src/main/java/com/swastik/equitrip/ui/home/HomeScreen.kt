package com.swastik.equitrip.ui.home

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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.AppViewModel
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.SectionHeader
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.staggered
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure
import java.time.LocalTime

/**
 * The "where do I stand?" screen — iOS `HomeView`, in its phone order: what's asking you
 * something, then the balance, then the trip, then what's next and what's changed.
 */
@Composable
fun HomeScreen(
    vm: AppViewModel,
    onOpenTrip: (Trip) -> Unit,
    onShowAllTrips: () -> Unit,
    onSettleUp: () -> Unit,
) {
    val trips = vm.currentTrips
    val me = vm.myId
    var scopeId by rememberSaveable { mutableStateOf<String?>(null) }
    var sheet by rememberSaveable { mutableStateOf<String?>(null) }

    val scope = trips.firstOrNull { it.id == scopeId }
    val owedToYou = me?.let { id -> scope?.owedTo(id) ?: trips.sumOf { it.owedTo(id) } } ?: 0.0
    val youOwe = me?.let { id -> scope?.owing(id) ?: trips.sumOf { it.owing(id) } } ?: 0.0
    val current = vm.currentTrip
    val upNext = current?.upcoming(3).orEmpty()
    val activity = vm.notifications.take(4)
    val awaiting = vm.settlementsAwaitingYou
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()

    Box(Modifier.fillMaxSize()) {
        PullToRefreshBox(isRefreshing = vm.refreshing, onRefresh = { vm.refresh() }, modifier = Modifier.fillMaxSize()) {
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = top + 68.dp, bottom = 28.dp + LocalBottomBarInset.current),
                verticalArrangement = Arrangement.spacedBy(26.dp),
            ) {
                item(key = "greeting") { Greeting(vm.myName, Modifier.staggered(0)) }

                if (awaiting.isNotEmpty()) item(key = "inbox") {
                    Box(Modifier.staggered(1)) { PendingSettlementsCard(awaiting) { _, _ -> onSettleUp() } }
                }

                item(key = "balance") {
                    Box(Modifier.staggered(1)) {
                        BalanceHero(
                            trips = trips,
                            scope = scope,
                            owedToYou = owedToYou,
                            youOwe = youOwe,
                            currency = scope?.currencyCode ?: vm.primaryCurrency,
                            activeCount = vm.activeTrips.size,
                            onScope = { scopeId = it?.id },
                            onSettleUp = {
                                scope?.let { vm.selectedTripId = it.id }
                                onSettleUp()
                            },
                        )
                    }
                }

                item(key = "current") {
                    Column(Modifier.staggered(3), verticalArrangement = Arrangement.spacedBy(13.dp)) {
                        if (current != null) {
                            SectionHeader(
                                if (current.phase == TripPhase.LIVE) "Happening now" else "Up next",
                                action = "All trips",
                                onAction = onShowAllTrips,
                            )
                            CurrentTripCard(current, me) { onOpenTrip(current) }
                        } else {
                            SectionHeader("Your trips", action = if (trips.isEmpty()) null else "All trips", onAction = onShowAllTrips)
                            NoTripCard()
                        }
                    }
                }

                if (current != null && upNext.isNotEmpty()) item(key = "upnext") {
                    Column(Modifier.staggered(4), verticalArrangement = Arrangement.spacedBy(13.dp)) {
                        SectionHeader("Up next", caption = current.title, action = "Itinerary") { onOpenTrip(current) }
                        SurfaceCard {
                            upNext.forEachIndexed { index, item ->
                                if (index > 0) Hairline()
                                UpNextRow(item, current)
                            }
                        }
                    }
                }

                item(key = "activity") {
                    Column(Modifier.staggered(5), verticalArrangement = Arrangement.spacedBy(13.dp)) {
                        SectionHeader("Recent activity", action = if (activity.isEmpty()) null else "See all") { sheet = "notifications" }
                        SurfaceCard {
                            if (activity.isEmpty()) {
                                Text(
                                    "Nothing has changed yet. Bookings, arrivals and payments show up here.",
                                    Modifier.padding(16.dp), fontSize = 13.sp, color = Brand.inkTertiary,
                                )
                            } else {
                                activity.forEachIndexed { index, item ->
                                    if (index > 0) Hairline()
                                    ActivityRow(item)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Fixed over the page; the canvas fades in behind it instead of ending on a bar edge.
        Row(
            Modifier.fillMaxWidth()
                .drawBehind {
                    drawRect(
                        Brush.verticalGradient(
                            0f to Brand.canvasTop,
                            0.62f to Brand.canvasTop.copy(alpha = 0.94f),
                            1f to Brand.canvasTop.copy(alpha = 0f),
                            startY = 0f,
                            endY = size.height,
                        ),
                    )
                }
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(start = 20.dp, end = 20.dp, top = 4.dp, bottom = 14.dp),
        ) {
            CircleButton(Icons.Outlined.Notifications, "Notifications", badge = vm.unreadCount) { sheet = "notifications" }
            Spacer(Modifier.weight(1f))
            ProfileButton(vm.me) { sheet = "profile" }
        }
    }

    when (sheet) {
        "notifications" -> NotificationsSheet(vm) { sheet = null }
        "profile" -> ProfileSheet(vm) { sheet = null }
    }
}

@Composable
private fun Greeting(name: String?, modifier: Modifier = Modifier) {
    val greeting = when (LocalTime.now().hour) {
        in 5..11 -> "Good morning,"
        in 12..16 -> "Good afternoon,"
        in 17..21 -> "Good evening,"
        else -> "Still up,"
    }
    // Emails stand in for the name when signup metadata is missing.
    val first = name?.substringBefore("@")?.split(" ")?.firstOrNull()
        ?.replaceFirstChar { it.uppercase() }?.takeIf { it.isNotBlank() } ?: "Traveller"
    Column(modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(greeting, fontSize = 14.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary)
        Text(first, style = figure(30.sp), color = Brand.ink)
    }
}
