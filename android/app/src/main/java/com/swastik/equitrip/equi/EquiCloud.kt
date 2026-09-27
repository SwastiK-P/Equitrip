package com.swastik.equitrip.equi

import com.swastik.equitrip.BuildConfig
import com.swastik.equitrip.data.Supabase
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

class EquiCloudException(message: String, val status: Int = 0) : Exception(message)

/**
 * Groq, reached through the `equi-chat` Supabase Edge Function.
 *
 * The Groq key lives only in the function's secrets: a key in an APK can be pulled out by
 * anyone who has the APK, and the free tier's limits are shared across every install.
 * Going through Supabase also means only a signed-in user can spend them, and Groq sees
 * Supabase's address rather than the user's. The function picks the model and caps the
 * reply; the app can't ask for anything else.
 *
 * A debug build can set `groq.key` in `local.properties` to call Groq directly before the
 * function is deployed. Release builds never carry a key.
 */
class EquiCloud(private val supabase: Supabase) {
    private val http = OkHttpClient.Builder().readTimeout(45, TimeUnit.SECONDS).build()
    private val json = supabase.json

    data class Message(val role: String, val content: String)

    /** Streams the reply through `onPartial` (cumulative text) and returns where it ended up. */
    suspend fun stream(messages: List<Message>, onPartial: (String) -> Unit): String = withContext(Dispatchers.IO) {
        val body = buildJsonObject {
            put("messages", buildJsonArray {
                messages.forEach { add(buildJsonObject { put("role", it.role); put("content", it.content) }) }
            })
        }
        if (BuildConfig.GROQ_KEY.isNotEmpty()) {
            // Debug only: same two models, same caps as the Edge Function.
            var last: EquiCloudException? = null
            for (model in DIRECT_MODELS) {
                try {
                    return@withContext read(direct(model, body), onPartial)
                } catch (e: EquiCloudException) {
                    last = e
                    if (e.status != 429 && e.status < 500) throw e
                }
            }
            throw last ?: EquiCloudException("Groq didn't answer")
        }
        read(supabase.functionRequest(FUNCTION, body), onPartial)
    }

    private fun direct(model: String, body: JsonObject): Request {
        val payload = buildJsonObject {
            put("model", model)
            put("messages", body["messages"]!!)
            put("stream", true)
            put("temperature", 0.5)
            put("max_completion_tokens", 400)
            if (model.startsWith("openai/gpt-oss")) {
                put("reasoning_effort", "low")
                put("include_reasoning", false)
            }
        }
        return Request.Builder().url("https://api.groq.com/openai/v1/chat/completions")
            .header("Authorization", "Bearer ${BuildConfig.GROQ_KEY}")
            .post(json.encodeToString(JsonObject.serializer(), payload).toRequestBody(JSON))
            .build()
    }

    /** Reads an OpenAI-style server-sent event stream: `data: {choices:[{delta:{content}}]}`. */
    private suspend fun read(request: Request, onPartial: (String) -> Unit): String {
        http.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                val text = response.body.string()
                val message = runCatching {
                    val o = json.parseToJsonElement(text).jsonObject
                    (o["error"]?.let { e -> (e as? JsonObject)?.get("message") ?: e })?.jsonPrimitive?.contentOrNull
                }.getOrNull()
                throw EquiCloudException(message ?: "Equi's cloud helper answered ${response.code}", response.code)
            }
            val source = response.body.source()
            val text = StringBuilder()
            while (!source.exhausted()) {
                currentCoroutineContext().ensureActive()
                val line = source.readUtf8Line() ?: break
                if (!line.startsWith("data:")) continue
                val data = line.removePrefix("data:").trim()
                if (data == "[DONE]") break
                val delta = runCatching {
                    json.parseToJsonElement(data).jsonObject["choices"]?.jsonArray?.firstOrNull()
                        ?.jsonObject?.get("delta")?.jsonObject?.get("content")?.jsonPrimitive?.contentOrNull
                }.getOrNull() ?: continue
                text.append(delta)
                withContext(Dispatchers.Main) { onPartial(text.toString()) }
            }
            return text.toString().trim()
        }
    }

    companion object {
        const val FUNCTION = "equi-chat"
        /**
         * Fast and small first; on the free tier's rate limit the smaller Llama takes over.
         * Kept in step with `supabase/functions/equi-chat/index.ts`.
         */
        private val DIRECT_MODELS = listOf("openai/gpt-oss-20b", "llama-3.1-8b-instant")
        private val JSON = "application/json".toMediaType()
    }
}
