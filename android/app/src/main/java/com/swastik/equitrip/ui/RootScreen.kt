package com.swastik.equitrip.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Route
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.height
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.vectorResource
import com.swastik.equitrip.R
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.activity.compose.BackHandler
import com.swastik.equitrip.AppViewModel
import com.swastik.equitrip.ItineraryRoute
import com.swastik.equitrip.TripsState
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.ui.home.HomeScreen
import com.swastik.equitrip.ui.itinerary.PastTripsScreen
import com.swastik.equitrip.ui.itinerary.TripListScreen
import com.swastik.equitrip.ui.newtrip.ImportTripScreen
import com.swastik.equitrip.ui.itinerary.TripScreen
import com.swastik.equitrip.ui.settle.SettleScreen
import com.swastik.equitrip.ui.equi.EquiScreen
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.Canvas

enum class AppTab(val label: String, val selected: ImageVector?, val unselected: ImageVector?) {
    HOME("Home", Icons.Filled.Home, Icons.Outlined.Home),
    ITINERARY("Itinerary", Icons.Filled.Route, Icons.Outlined.Route),
    SETTLE("Settle", Icons.Filled.SwapHoriz, Icons.Outlined.SwapHoriz),
    /** Drawn from `R.drawable.ic_equi`, Equi's face — the same glyph as the iOS tab. */
    EQUI("Equi", null, null),
}

/** The tabs, as on iOS `RootTabView`, on a Material navigation bar. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RootScreen(vm: AppViewModel) {
    var tab by rememberSaveable { mutableStateOf(AppTab.HOME) }

    Canvas {
        Scaffold(
            containerColor = Color.Transparent,
            // Every tab draws its own header over the canvas, as on iOS.
            contentWindowInsets = WindowInsets(0),
            bottomBar = {
                Column {
                    Box(Modifier.fillMaxWidth().height(0.5.dp).background(Brand.hairline))
                    NavigationBar(containerColor = Brand.canvasBottom) {
                        AppTab.entries.forEach { entry ->
                            NavigationBarItem(
                                selected = tab == entry,
                                onClick = {
                                    // A second tap on Itinerary goes back to the list, as on iOS.
                                    if (tab == entry && entry == AppTab.ITINERARY) vm.itineraryRoute = null
                                    tab = entry
                                },
                                icon = {
                                    val vector = (if (tab == entry) entry.selected else entry.unselected)
                                        ?: ImageVector.vectorResource(R.drawable.ic_equi)
                                    Icon(vector, contentDescription = null)
                                },
                                label = { Text(entry.label, fontWeight = if (tab == entry) FontWeight.SemiBold else FontWeight.Medium) },
                                colors = NavigationBarItemDefaults.colors(
                                    indicatorColor = Brand.accent.copy(alpha = 0.14f),
                                    selectedIconColor = Brand.accent,
                                    selectedTextColor = Brand.accent,
                                    unselectedIconColor = Brand.inkSecondary,
                                    unselectedTextColor = Brand.inkSecondary,
                                ),
                            )
                        }
                    }
                }
            },
        ) { padding ->
            when (val state = vm.trips) {
                TripsState.Loading -> Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = Brand.accent)
                }
                is TripsState.Failed -> Failure(state.message, padding) { vm.refresh() }
                // Only the top inset is applied: lists run under the bar and pad their own ends by it.
                is TripsState.Loaded -> CompositionLocalProvider(LocalBottomBarInset provides padding.calculateBottomPadding()) {
                    Box(Modifier.fillMaxSize().padding(top = padding.calculateTopPadding())) {
                    when (tab) {
                        AppTab.HOME -> HomeScreen(
                            vm,
                            onOpenTrip = {
                                vm.selectedTripId = it.id
                                vm.itineraryRoute = ItineraryRoute.Trip(it.id)
                                tab = AppTab.ITINERARY
                            },
                            onShowAllTrips = { vm.itineraryRoute = null; tab = AppTab.ITINERARY },
                            onSettleUp = { tab = AppTab.SETTLE },
                        )
                        // No pull-to-refresh on the import: a pull mid-read would look like it restarts it.
                        AppTab.ITINERARY -> if (vm.itineraryRoute == ItineraryRoute.NewTrip) {
                            BackHandler { vm.closeNewTrip() }
                            ImportTripScreen(
                                vm.importState,
                                onBack = { vm.closeNewTrip() },
                                onPick = { uri, name -> vm.importPdf(uri, name) },
                                onSave = { vm.saveImport(it) },
                            )
                        } else {
                            Refreshable(vm) { ItineraryTab(vm, state.trips) }
                        }
                        AppTab.SETTLE -> SettleScreen(vm)
                        AppTab.EQUI -> EquiScreen(vm)
                    }
                    }
                }
            }
        }
    }
}

/** The Itinerary tab's stack — iOS `ItineraryRoute`: the trip list, past trips, one trip, or a new one. */
@Composable
private fun ItineraryTab(vm: AppViewModel, trips: List<Trip>) {
    when (val route = vm.itineraryRoute) {
        null -> TripListScreen(
            trips,
            onOpen = { vm.selectedTripId = it.id; vm.itineraryRoute = ItineraryRoute.Trip(it.id) },
            onPast = { vm.itineraryRoute = ItineraryRoute.PastTrips },
            onNewTrip = { vm.openNewTrip() },
        )
        // Drawn outside the pull-to-refresh wrapper, in the tab switch above.
        ItineraryRoute.NewTrip -> Unit
        ItineraryRoute.PastTrips -> {
            BackHandler { vm.itineraryRoute = null }
            PastTripsScreen(
                trips,
                onBack = { vm.itineraryRoute = null },
                onOpen = { vm.selectedTripId = it.id; vm.itineraryRoute = ItineraryRoute.Trip(it.id, fromPast = true) },
            )
        }
        is ItineraryRoute.Trip -> {
            val back = { vm.itineraryRoute = if (route.fromPast) ItineraryRoute.PastTrips else null }
            BackHandler(onBack = back)
            val trip = trips.firstOrNull { it.id == route.id }
            // A trip that's gone (deleted, or you left it) sends the stack back rather than showing nothing.
            if (trip == null) LaunchedEffect(route) { back() } else TripScreen(trip, vm.myId, onBack = back)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun Refreshable(vm: AppViewModel, content: @Composable () -> Unit) {
    PullToRefreshBox(isRefreshing = vm.refreshing, onRefresh = { vm.refresh() }, modifier = Modifier.fillMaxSize()) { content() }
}

@Composable
private fun Failure(message: String, padding: PaddingValues, retry: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(padding).padding(32.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text("Couldn't load your trips", style = MaterialTheme.typography.titleMedium)
        Text(message, textAlign = TextAlign.Center, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Button(onClick = retry) { Text("Try again") }
    }
}

