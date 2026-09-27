package com.swastik.equitrip

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.swastik.equitrip.data.Repository
import com.swastik.equitrip.data.Supabase
import com.swastik.equitrip.data.SupabaseException
import com.swastik.equitrip.equi.EquiChat
import com.swastik.equitrip.importer.ImportedTrip
import com.swastik.equitrip.importer.NugenReader
import com.swastik.equitrip.importer.PdfText
import com.swastik.equitrip.importer.TripImporter
import android.net.Uri
import kotlinx.coroutines.Job
import com.swastik.equitrip.model.AppNotification
import com.swastik.equitrip.model.Settlement
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.TripPhase
import kotlinx.coroutines.launch

sealed interface ItineraryRoute {
    data object PastTrips : ItineraryRoute
    data object NewTrip : ItineraryRoute
    data class Trip(val id: String, val fromPast: Boolean = false) : ItineraryRoute
}

/** Where a booking-PDF import is. There's no manual or join path on Android: import only. */
sealed interface ImportState {
    data object Idle : ImportState
    data class Reading(val fileName: String, val done: Int, val total: Int) : ImportState
    data class Review(val fileName: String, val trip: ImportedTrip, val saving: Boolean = false, val error: String? = null) : ImportState
    data class Failed(val fileName: String?, val message: String, val uri: Uri?) : ImportState
}

sealed interface TripsState {
    data object Loading : TripsState
    data class Loaded(val trips: List<Trip>) : TripsState
    data class Failed(val message: String) : TripsState
}

/**
 * The app's state: who's signed in, their trips and their notifications. The Android
 * stand-in for iOS `TripStore` + `NotificationStore` + `AuthService`; Postgres stays the
 * only source of truth and failures surface rather than falling back to anything.
 */
class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val supabase = Supabase(app)
    private val repository = Repository(supabase)

    /** Equi's conversation. In memory only — cleared on sign-out. */
    val equi = EquiChat(app, supabase, viewModelScope)

    var signedIn by mutableStateOf(supabase.session != null)
        private set
    var trips by mutableStateOf<TripsState>(TripsState.Loading)
        private set
    var refreshing by mutableStateOf(false)
        private set
    var selectedTripId by mutableStateOf<String?>(null)

    /** Where the Itinerary tab is: its trip list (null), the past trips, or one trip. */
    var itineraryRoute by mutableStateOf<ItineraryRoute?>(null)
    var notifications by mutableStateOf<List<AppNotification>>(emptyList())
        private set

    private val importer = TripImporter(NugenReader(supabase))
    private var importJob: Job? = null
    var importState by mutableStateOf<ImportState>(ImportState.Idle)
        private set

    val myName get() = repository.me?.display_name
    val myId get() = repository.me?.id
    val myEmail get() = supabase.session?.email
    /** Read after `trips` changes, which is what recomposes anything showing it. */
    val me: Traveller?
        get() = repository.me?.let { Traveller(it.id, it.display_name, it.avatar_asset, it.avatar_url, it.upi_id) }

    val currentTrips: List<Trip> get() = (trips as? TripsState.Loaded)?.trips.orEmpty()

    /** The trip under way, else the next one — iOS `TripStore.currentTrip`. A past trip is never "current". */
    val currentTrip: Trip?
        get() = currentTrips.firstOrNull { it.phase == TripPhase.LIVE }
            ?: currentTrips.filter { it.phase == TripPhase.UPCOMING }.minByOrNull { it.startDate }

    /** The trip the Itinerary and Settle tabs are showing. */
    val selectedTrip: Trip?
        get() = currentTrips.firstOrNull { it.id == selectedTripId } ?: currentTrip ?: currentTrips.firstOrNull()

    val activeTrips get() = currentTrips.filter { it.phase != TripPhase.PAST }

    /** The currency most trips use — what the all-trips total is stated in. */
    val primaryCurrency: String
        get() = currentTrips.groupingBy { it.currencyCode }.eachCount().maxByOrNull { it.value }?.key ?: "INR"

    /** Payments somebody says they made to you, waiting on your word. Newest first. */
    val settlementsAwaitingYou: List<Pair<Trip, Settlement>>
        get() = currentTrips.flatMap { trip ->
            trip.pendingSettlements.filter { it.toId == myId }.map { trip to it }
        }.sortedByDescending { it.second.createdAt }

    val unreadCount get() = notifications.count { it.isUnread }

    init {
        if (signedIn) refresh()
    }

    fun refresh() = viewModelScope.launch {
        if (trips is TripsState.Loaded) refreshing = true else trips = TripsState.Loading
        trips = runCatching { TripsState.Loaded(repository.loadTrips()) }.getOrElse { error ->
            if (error is SupabaseException && error.status == 401) signedIn = false
            TripsState.Failed(error.message ?: "Couldn't load your trips")
        }
        // A failed notification read leaves the list as it was: an empty feed would be a claim.
        runCatching { repository.loadNotifications() }.onSuccess { notifications = it }
        refreshing = false
    }

    fun markAllRead() {
        if (unreadCount == 0) return
        notifications = notifications.map { it.copy(isUnread = false) }
        viewModelScope.launch { runCatching { repository.markAllNotificationsRead() } }
    }

    fun markRead(notification: AppNotification) {
        if (!notification.isUnread) return
        notifications = notifications.map { if (it.id == notification.id) it.copy(isUnread = false) else it }
        viewModelScope.launch { runCatching { repository.markNotificationRead(notification.id) } }
    }

    // New trip — import a booking PDF

    fun openNewTrip() {
        importJob?.cancel()
        importState = ImportState.Idle
        itineraryRoute = ItineraryRoute.NewTrip
    }

    fun closeNewTrip() {
        importJob?.cancel()
        importState = ImportState.Idle
        itineraryRoute = null
    }

    /** Reads the PDF and has Nugen read it a day at a time. No pattern fallback: a failed day fails the import. */
    fun importPdf(uri: Uri, fileName: String) {
        importJob?.cancel()
        importState = ImportState.Reading(fileName, 0, 0)
        importJob = viewModelScope.launch {
            importState = runCatching {
                val text = PdfText.read(getApplication(), uri)
                val trip = importer.import(text) { done, total ->
                    viewModelScope.launch { importState = ImportState.Reading(fileName, done, total) }
                }
                ImportState.Review(fileName, trip)
            }.getOrElse { error ->
                if (error is kotlinx.coroutines.CancellationException) throw error
                ImportState.Failed(fileName, error.message ?: "Couldn't read that PDF.", uri)
            }
        }
    }

    fun saveImport(title: String) {
        val review = importState as? ImportState.Review ?: return
        if (review.saving) return
        importState = review.copy(saving = true, error = null)
        viewModelScope.launch {
            runCatching { repository.createImportedTrip(review.trip, title.trim().ifEmpty { review.trip.title }) }
                .onSuccess { id ->
                    trips = runCatching { TripsState.Loaded(repository.loadTrips()) }.getOrDefault(trips)
                    importState = ImportState.Idle
                    selectedTripId = id
                    itineraryRoute = ItineraryRoute.Trip(id)
                }
                .onFailure { importState = review.copy(saving = false, error = it.message ?: "Couldn't save the trip") }
        }
    }

    /** Returns an error message, or null when the call went through. */
    suspend fun signIn(email: String, password: String): String? = runCatching {
        repository.forget()
        supabase.signIn(email, password)
        signedIn = true
        refresh()
    }.exceptionOrNull()?.let { it.message ?: "Couldn't sign in" }

    suspend fun signUp(name: String, email: String, password: String): String? = runCatching {
        repository.forget()
        if (supabase.signUp(name, email, password)) {
            signedIn = true
            refresh()
            null
        } else {
            "Check your inbox to confirm your email, then sign in."
        }
    }.getOrElse { it.message ?: "Couldn't create the account" }

    fun signOut() = viewModelScope.launch {
        supabase.signOut()
        repository.forget()
        notifications = emptyList()
        equi.clear()
        selectedTripId = null
        itineraryRoute = null
        trips = TripsState.Loading
        signedIn = false
    }
}
