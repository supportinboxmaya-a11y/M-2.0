package com.example.maya_pro

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URL
import java.util.concurrent.TimeUnit

object BackendLogger {

    private const val PREFS_NAME = "maya_phone_control"
    private const val KEY_HTTP_BASE_URL = "vps_http_base_url"
    private const val TAG = "BackendLogger"

    private val client = OkHttpClient.Builder()
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(5, TimeUnit.SECONDS)
        .writeTimeout(5, TimeUnit.SECONDS)
        .build()

    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    private val scope = CoroutineScope(Dispatchers.IO)

    data class LogEvent(
        val type: String,           // "call_log" or "sms_log"
        val direction: String,      // "incoming" or "outgoing"
        val status: String,         // "ringing", "answered", "ended", "sent", "failed", etc.
        val numberLast4: String,    // last 4 digits only
        val timestamp: Long = System.currentTimeMillis(),
        val deviceId: String
    )

    fun logCall(
        context: Context,
        fullNumber: String,
        direction: String,
        status: String,
        deviceId: String
    ) {
        val numberLast4 = getLast4Digits(fullNumber)
        val event = LogEvent(
            type = "call_log",
            direction = direction,
            status = status,
            numberLast4 = numberLast4,
            deviceId = deviceId
        )
        send(context, event)
    }

    fun logSms(
        context: Context,
        fullNumber: String,
        direction: String,
        status: String,
        deviceId: String
    ) {
        val numberLast4 = getLast4Digits(fullNumber)
        val event = LogEvent(
            type = "sms_log",
            direction = direction,
            status = status,
            numberLast4 = numberLast4,
            deviceId = deviceId
        )
        send(context, event)
    }

    private fun getLast4Digits(fullNumber: String): String {
        val digits = fullNumber.replace(Regex("[^0-9]"), "")
        return if (digits.length >= 4) digits.substring(digits.length - 4) else digits
    }

    private fun send(context: Context, event: LogEvent) {
        scope.launch {
            val baseUrl = getHttpBaseUrl(context) ?: return@launch
            if (!isSchemeAllowed(baseUrl)) {
                Log.w(TAG, "Refusing to send log over insecure scheme: $baseUrl")
                return@launch
            }

            val endpoint = "$baseUrl/api/v1/device/log"
            val json = eventToJson(event)
            val body = json.toRequestBody(jsonMediaType)
            val request = Request.Builder()
                .url(endpoint)
                .post(body)
                .build()

            try {
                val response = withTimeoutOrNull(5000) {
                    client.newCall(request).execute()
                }
                response?.use { it.close() }
            } catch (e: Exception) {
                Log.w(TAG, "Log send failed (non-fatal): ${e.message}")
            }
        }
    }

    private fun getHttpBaseUrl(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        // First check for explicit HTTP base URL
        val explicit = prefs.getString(KEY_HTTP_BASE_URL, null)
        if (explicit != null && explicit.isNotBlank()) return explicit

        // Fallback: derive from WebSocket URL if present
        val wsUrl = prefs.getString("vps_ws_url", null)
        if (wsUrl == null || wsUrl.isBlank()) {
            Log.w(TAG, "No VPS URL configured, skipping log send")
            return null
        }

        // Convert ws://host:port/path -> http://host:port
        try {
            val url = URL(wsUrl.replace("ws://", "http://").replace("wss://", "https://"))
            val derived = "${url.protocol}://${url.host}:${if (url.port != -1) url.port else (if (url.protocol == "https") 443 else 80)}"
            return derived
        } catch (e: Exception) {
            Log.w(TAG, "Failed to derive HTTP URL from WebSocket URL: ${e.message}")
            return null
        }
    }

    private fun isSchemeAllowed(baseUrl: String): Boolean {
        val lower = baseUrl.lowercase()
        if (lower.startsWith("https://")) return true
        if (!lower.startsWith("http://")) return false

        // Allow http:// only for localhost or private IP ranges
        try {
            val url = URL(baseUrl)
            val host = url.host
            return when {
                host == "localhost" || host == "127.0.0.1" || host == "::1" -> true
                host.startsWith("10.") -> true
                host.startsWith("192.168.") -> true
                host.startsWith("172.") && (16..31).contains(host.substringAfter("172.").substringBefore(".").toIntOrNull() ?: -1) -> true
                else -> false
            }
        } catch (e: Exception) {
            return false
        }
    }

    private fun eventToJson(event: LogEvent): String {
        return org.json.JSONObject().apply {
            put("type", event.type)
            put("direction", event.direction)
            put("status", event.status)
            put("number_last4", event.numberLast4)
            put("timestamp", event.timestamp)
            put("device_id", event.deviceId)
        }.toString()
    }
}