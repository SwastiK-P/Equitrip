package com.swastik.equitrip.importer

import com.swastik.equitrip.data.Supabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

class NugenException(message: String) : Exception(message)

/**
 * The booking import's line to the Nugen domain-aligned model — the Android side of iOS
 * `NugenService`.
 *
 * It goes through the `nudge-reader` Supabase function (named `nugen-reader` in the
 * dashboard; the slug is from its first deploy), which holds the Nugen key and the prompt
 * the model was aligned on. An APK's strings can be read by anyone who has it and every
 * call is billed, so the app never talks to api.nugen.in itself. What comes back is the
 * model's text and Nugen's confidence; turning it into bookings, and checking each one
 * against the document, happens in `TripImporter`.
 */
class NugenReader(private val supabase: Supabase) {
    // Nugen gives up after 50 s on a cold model; the function answers just after that.
    private val http = OkHttpClient.Builder().readTimeout(70, TimeUnit.SECONDS).callTimeout(75, TimeUnit.SECONDS).build()

    @Serializable
    data class Item(val title: String? = null, val time: String? = null, val kind: String? = null)

    @Serializable
    private data class Plan(val items: List<Item>)

    class DayReading(val items: List<Item>, val confidence: Double?)

    suspend fun readDay(prompt: String): DayReading = withContext(Dispatchers.IO) {
        val body = buildJsonObject {
            put("action", "read_day")
            put("model", MODEL_ID)
            put("day", prompt)
        }
        http.newCall(supabase.functionRequest(FUNCTION, body)).execute().use { response ->
            val text = response.body.string()
            val json = runCatching { supabase.json.parseToJsonElement(text).jsonObject }.getOrNull()
            if (!response.isSuccessful) {
                val message = json?.get("error")?.jsonObject?.get("message")?.jsonPrimitive?.contentOrNull
                    ?: json?.get("message")?.jsonPrimitive?.contentOrNull
                throw NugenException(
                    when {
                        response.code == 401 -> "Sign in again to read bookings with Nugen."
                        response.code == 404 && message == null -> "The booking reader function isn't deployed."
                        message != null -> message
                        else -> "Nugen didn't answer (${response.code})."
                    },
                )
            }
            val content = json?.get("content")?.jsonPrimitive?.contentOrNull.orEmpty()
            val items = parse(content) ?: throw NugenException("Nugen's answer wasn't a list of bookings.")
            DayReading(items, json?.get("confidence")?.jsonPrimitive?.doubleOrNull)
        }
    }

    /** The outermost JSON object in a reply, after any "thinking out loud" or code fence. */
    private fun parse(content: String): List<Item>? {
        val text = content.substringAfter("</think>", content)
        val open = text.indexOf('{')
        val close = text.lastIndexOf('}')
        if (open < 0 || close <= open) return null
        return runCatching { supabase.json.decodeFromString<Plan>(text.substring(open, close + 1)).items }.getOrNull()
    }

    companion object {
        /** Nugen Domain-Aligned — the same model iOS defaults to (`BookingReader.nugenDefault`). */
        const val MODEL_ID = "model_01m3gncr4m0jbnqf"
        const val MODEL_NAME = "Nugen Domain-Aligned"
        private const val FUNCTION = "nudge-reader"

        fun kind(word: String?): ExtractedKind = when (word?.trim()?.lowercase()) {
            "flight" -> ExtractedKind.FLIGHT
            "train" -> ExtractedKind.TRAIN
            "transfer" -> ExtractedKind.TRANSFER
            "stay" -> ExtractedKind.STAY
            "activity" -> ExtractedKind.ACTIVITY
            "meal", "food" -> ExtractedKind.MEAL
            else -> ExtractedKind.OTHER
        }
    }
}
