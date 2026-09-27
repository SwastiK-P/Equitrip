package com.swastik.equitrip.data

import android.content.Context
import com.swastik.equitrip.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody

class SupabaseException(message: String, val status: Int = 0) : Exception(message)

@Serializable
data class Session(
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: Long,
    val userId: String,
    val email: String?,
)

/**
 * Just enough of Supabase Auth and PostgREST over plain HTTP.
 *
 * The iOS app uses the Swift SDK; a hand-rolled client keeps the Android build to OkHttp
 * and kotlinx.serialization. Row Level Security does the real gatekeeping: every request
 * carries the signed-in user's JWT, and the publishable key alone can read nothing.
 */
class Supabase(context: Context) {
    private val base = BuildConfig.SUPABASE_URL.trimEnd('/')
    private val key = BuildConfig.SUPABASE_KEY
    private val http = OkHttpClient()
    private val prefs = context.getSharedPreferences("equitrip.auth", Context.MODE_PRIVATE)
    private val jsonType = "application/json".toMediaType()

    val json = Json { ignoreUnknownKeys = true; explicitNulls = false }

    val isConfigured get() = base.isNotEmpty() && key.isNotEmpty()

    var session: Session? = prefs.getString("session", null)?.let {
        runCatching { json.decodeFromString<Session>(it) }.getOrNull()
    }
        private set(value) {
            field = value
            prefs.edit().apply {
                if (value == null) remove("session") else putString("session", json.encodeToString(value))
            }.apply()
        }

    // Auth

    suspend fun signIn(email: String, password: String) {
        session = null
        session = token("password", buildJsonObject {
            put("email", email.trim())
            put("password", password)
        })
    }

    /** Returns false when the project wants the email confirmed before there's a session. */
    suspend fun signUp(name: String, email: String, password: String): Boolean {
        session = null
        val body = buildJsonObject {
            put("email", email.trim())
            put("password", password)
            put("data", buildJsonObject { put("full_name", name.trim()) })
        }
        val response = send(post("$base/auth/v1/signup", body), authorised = false).jsonObject
        if (response["access_token"] == null) return false
        session = sessionFrom(response)
        return true
    }

    suspend fun signOut() {
        runCatching { send(post("$base/auth/v1/logout", JsonObject(emptyMap())), authorised = true) }
        session = null
    }

    private suspend fun token(grant: String, body: JsonObject): Session =
        sessionFrom(send(post("$base/auth/v1/token?grant_type=$grant", body), authorised = false).jsonObject)

    private fun sessionFrom(o: JsonObject): Session {
        val user = o["user"]!!.jsonObject
        val expiresIn = o["expires_in"]?.jsonPrimitive?.content?.toLongOrNull() ?: 3600
        return Session(
            accessToken = o["access_token"]!!.jsonPrimitive.content,
            refreshToken = o["refresh_token"]!!.jsonPrimitive.content,
            expiresAt = System.currentTimeMillis() / 1000 + expiresIn,
            userId = user["id"]!!.jsonPrimitive.content,
            email = user["email"]?.jsonPrimitive?.content,
        )
    }

    private suspend fun freshSession(): Session {
        val current = session ?: throw SupabaseException("Not signed in", 401)
        if (current.expiresAt - 60 > System.currentTimeMillis() / 1000) return current
        return runCatching {
            token("refresh_token", buildJsonObject { put("refresh_token", current.refreshToken) })
        }.onFailure { session = null }.getOrThrow().also { session = it }
    }

    // PostgREST

    /**
     * `GET /rest/v1/<table>` with PostgREST query parameters — filters such as
     * `"trip_id" to "in.(a,b)"`, and `order` / `limit` the same way.
     */
    suspend fun select(table: String, vararg filters: Pair<String, String>): JsonElement {
        val url = "$base/rest/v1/$table".toHttpUrl().newBuilder().addQueryParameter("select", "*")
        filters.forEach { (column, op) -> url.addQueryParameter(column, op) }
        return send(Request.Builder().url(url.build()).get(), authorised = true)
    }

    suspend fun insert(table: String, row: JsonObject): JsonElement =
        send(post("$base/rest/v1/$table", row).header("Prefer", "return=representation"), authorised = true)

    /**
     * Inserts one row or an array of rows without reading them back. A new trip isn't
     * readable until its roster is written, so `return=representation` would fail RLS
     * (iOS uses `returning: .minimal` for the same reason).
     */
    suspend fun insertQuietly(table: String, rows: JsonElement) {
        send(post("$base/rest/v1/$table", rows).header("Prefer", "return=minimal"), authorised = true)
    }

    /** `PATCH /rest/v1/<table>` on the rows the filters match. */
    suspend fun update(table: String, body: JsonObject, vararg filters: Pair<String, String>) {
        val url = "$base/rest/v1/$table".toHttpUrl().newBuilder()
        filters.forEach { (column, op) -> url.addQueryParameter(column, op) }
        send(
            Request.Builder().url(url.build()).patch(json.encodeToString(body).toRequestBody(jsonType))
                .header("Prefer", "return=minimal"),
            authorised = true,
        )
    }

    /**
     * A signed request to an Edge Function, for a caller that reads the response itself —
     * Equi streams Groq's reply through `equi-chat`, which `send` would buffer whole.
     */
    suspend fun functionRequest(name: String, body: JsonElement): Request {
        if (!isConfigured) throw SupabaseException("Supabase isn't configured for this build")
        return post("$base/functions/v1/$name", body)
            .header("apikey", key)
            .header("Authorization", "Bearer ${freshSession().accessToken}")
            .build()
    }

    private fun post(url: String, body: JsonElement) =
        Request.Builder().url(url).post(json.encodeToString(body).toRequestBody(jsonType))

    private suspend fun send(builder: Request.Builder, authorised: Boolean): JsonElement = withContext(Dispatchers.IO) {
        if (!isConfigured) throw SupabaseException("Supabase isn't configured for this build")
        builder.header("apikey", key)
        if (authorised) builder.header("Authorization", "Bearer ${freshSession().accessToken}")
        http.newCall(builder.build()).execute().use { response ->
            val text = response.body.string()
            if (!response.isSuccessful) {
                val message = runCatching {
                    val o = json.parseToJsonElement(text).jsonObject
                    (o["msg"] ?: o["error_description"] ?: o["message"] ?: o["error"])?.jsonPrimitive?.content
                }.getOrNull()
                throw SupabaseException(message ?: "Request failed (${response.code})", response.code)
            }
            if (text.isBlank()) JsonObject(emptyMap()) else json.parseToJsonElement(text)
        }
    }
}
