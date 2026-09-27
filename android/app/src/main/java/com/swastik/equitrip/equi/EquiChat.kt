package com.swastik.equitrip.equi

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.swastik.equitrip.data.Supabase
import com.swastik.equitrip.model.Trip
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.UUID

enum class EquiSource { USER, EQUI, CONSENT }

data class EquiMessage(
    val id: String = UUID.randomUUID().toString(),
    val source: EquiSource,
    val text: String,
    val suggestions: List<String> = emptyList(),
    val tripId: String? = null,
    val topic: EquiQuery.Topic? = null,
    /** For a consent prompt: the question waiting on the answer. */
    val pending: String? = null,
) {
    val isUser get() = source == EquiSource.USER
}

/**
 * Equi's conversation on Android: reads each question on the phone, answers it there when
 * it's about the trips, and sends only advice and small talk to Groq — redacted
 * (`EquiPrivacy`), and only once the user has agreed.
 *
 * The conversation lives in memory alone. iOS keeps Equi's history in Supabase; on Android
 * nothing Equi says is written anywhere, and signing out or closing the app forgets it.
 */
class EquiChat(context: Context, supabase: Supabase, private val scope: CoroutineScope) {
    private val cloud = EquiCloud(supabase)
    private val prefs = context.getSharedPreferences("equitrip.equi", Context.MODE_PRIVATE)
    private var job: Job? = null

    val messages = mutableStateListOf<EquiMessage>()
    var busy by mutableStateOf(false)
        private set

    /** Busy, and nothing of the reply on screen yet — what the typing indicator stands for. */
    val thinking: Boolean
        get() = busy && messages.lastOrNull().let { it == null || it.isUser || it.text.isEmpty() }

    /** null until asked; then whether advice and small talk may go to Groq. */
    var cloudAllowed by mutableStateOf(
        if (prefs.contains(KEY_CLOUD)) prefs.getBoolean(KEY_CLOUD, false) else null,
    )
        private set

    private fun setCloudAllowed(allowed: Boolean) {
        cloudAllowed = allowed
        prefs.edit().putBoolean(KEY_CLOUD, allowed).apply()
    }

    fun ask(question: String, trips: List<Trip>, myId: String?) {
        val trimmed = question.trim()
        if (trimmed.isEmpty() || busy) return
        messages += EquiMessage(source = EquiSource.USER, text = trimmed)
        answer(trimmed, trips, myId)
    }

    /** The user's answer to a consent prompt: runs the question it was holding. */
    fun resolveConsent(message: EquiMessage, allow: Boolean, trips: List<Trip>, myId: String?) {
        if (busy) return
        setCloudAllowed(allow)
        messages.remove(message)
        message.pending?.let { answer(it, trips, myId) }
    }

    fun stop() {
        job?.cancel()
        busy = false
        // A reply cut off before its first word leaves nothing worth keeping.
        messages.lastOrNull()?.takeIf { !it.isUser && it.text.isEmpty() }?.let(messages::remove)
    }

    fun clear() {
        stop()
        messages.clear()
    }

    private fun answer(question: String, trips: List<Trip>, myId: String?) {
        val history = messages.dropLast(1).map { EquiTurn(it.isUser, it.text, it.tripId, it.topic) }
        val query = EquiQueryReader.read(question, history, trips, myId)
        val facts = EquiFacts.answer(query, trips, myId)
        val asked = EquiQueryReader.Cues.normalise(question)
        val suggestions = facts.suggestions.filter { EquiQueryReader.Cues.normalise(it) != asked }.take(3)
        val base = EquiMessage(source = EquiSource.EQUI, text = "", tripId = facts.focusTripId, topic = query.topic)
        val useCloud = query.needsCloud && facts.allowsGeneralKnowledge && trips.isNotEmpty()

        busy = true
        job = scope.launch {
            try {
                when {
                    !useCloud || cloudAllowed == false -> {
                        // A beat of "typing" first: an answer that lands the instant you
                        // send reads as canned rather than considered.
                        delay(THINK_MS)
                        reveal(base, facts.headline, suggestions)
                    }
                    cloudAllowed == null -> {
                        delay(THINK_MS / 2)
                        messages += base.copy(
                            source = EquiSource.CONSENT,
                            text = "This one needs general travel knowledge, so I'd ask Groq. Names and amounts stay here.",
                            pending = question,
                        )
                    }
                    else -> writeInCloud(question, query, facts, trips, history, base, suggestions)
                }
            } finally {
                busy = false
            }
        }
    }

    private suspend fun writeInCloud(
        question: String,
        query: EquiQuery,
        facts: EquiFacts,
        trips: List<Trip>,
        history: List<EquiTurn>,
        base: EquiMessage,
        suggestions: List<String>,
    ) {
        val redactor = EquiPrivacy.Redactor(trips)
        val trip = trips.firstOrNull { it.id == (query.tripId ?: facts.focusTripId) }
        val system = instructions(if (query.topic == EquiQuery.Topic.ADVICE) EquiPrivacy.brief(trip) else null)
        // Only earlier cloud turns go back as context: an on-device answer holds names and
        // amounts, and a question that got one may too.
        val turns = history.zipWithNext().filter { (asked, said) ->
            asked.isUser && said.topic?.let { it == EquiQuery.Topic.ADVICE || it == EquiQuery.Topic.CHAT } == true
        }.takeLast(2).flatMap { (asked, said) ->
            listOf(
                EquiCloud.Message("user", redactor.redact(asked.text).take(300)),
                EquiCloud.Message("assistant", redactor.redact(said.text).take(400)),
            )
        }
        val outgoing = listOf(EquiCloud.Message("system", system)) + turns +
            EquiCloud.Message("user", redactor.redact(question).take(600))

        messages += base
        val written = runCatching {
            cloud.stream(outgoing) { partial -> replace(base.id) { it.copy(text = tidy(redactor.restore(partial))) } }
        }.getOrNull()?.let { tidy(redactor.restore(it)) }

        if (written.isNullOrBlank() || !EquiPrivacy.isGrounded(written)) {
            // Nothing back, or a price quoted: Equi's own answer stands in, without comment.
            replace(base.id) { it.copy(text = "") }
            reveal(base, facts.headline, suggestions, append = false)
        } else {
            replace(base.id) { it.copy(text = written, suggestions = suggestions) }
        }
    }

    /**
     * Lays an answer down a few words at a time, the way a written one arrives — fast
     * enough that a five-line reply is done in well under a second.
     */
    private suspend fun reveal(base: EquiMessage, text: String, suggestions: List<String>, append: Boolean = true) {
        if (append) messages += base
        val words = text.split(" ")
        val step = maxOf(1, words.size / 18)
        for (end in step..words.size step step) {
            replace(base.id) { it.copy(text = words.take(end).joinToString(" ")) }
            delay(26)
        }
        replace(base.id) { it.copy(text = text, suggestions = suggestions) }
    }

    private fun replace(id: String, change: (EquiMessage) -> EquiMessage) {
        val index = messages.indexOfFirst { it.id == id }
        if (index >= 0) messages[index] = change(messages[index])
    }

    /** Folds what small models add despite being asked not to: headings, `*` bullets, sign-offs. */
    private fun tidy(text: String): String = text.lines()
        .map { it.trimEnd() }
        .map { line ->
            when {
                line.trimStart().startsWith("#") -> "**" + line.trimStart('#', ' ') + "**"
                line.trimStart().startsWith("* ") || line.trimStart().startsWith("• ") -> "- " + line.trimStart().drop(2)
                else -> line
            }
        }
        .joinToString("\n")
        .replace(Regex("\n{3,}"), "\n\n")
        .trim()

    private fun instructions(brief: String?) = buildString {
        appendLine("You are Equi, the assistant in Equitrip, a group-trip planning app. Today is ${LocalDate.now().format(DateTimeFormatter.ofPattern("d MMMM yyyy"))}.")
        appendLine()
        appendLine("Answer only what was asked. Format:")
        appendLine("- First line: the direct answer in one short sentence.")
        appendLine("- Then, only if it helps, 2 to 4 bullets starting with \"- \", each under 10 words. Bold the key word with **.")
        appendLine("- Nothing else: no headings, no intro, no closing line, no follow-up questions, no disclaimers.")
        appendLine("- Under 60 words in total. For a greeting or thanks, one short sentence.")
        appendLine()
        appendLine("You know general travel: weather, packing, sights, food, customs, getting around. You can't see the user's bookings or money. Never state prices or amounts, and never say something is booked or paid. If asked about their plan or money, say to ask Equi directly, in one line.")
        appendLine("People appear as \"Person A\", \"Person B\"; keep those labels. [amount], [reference] and similar were removed — ignore them.")
        if (brief != null) {
            appendLine()
            append(brief)
        }
    }

    companion object {
        private const val KEY_CLOUD = "cloud"
        private const val THINK_MS = 650L
    }
}
