package com.example.maya_pro

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlin.math.pow
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import org.json.JSONArray
import org.json.JSONObject
import java.net.URI
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class PhoneControlService : Service() {

    companion object {
        const val CHANNEL_ID = "phone_control_channel"
        const val NOTIFICATION_ID = 1001
        const val TAG = "PhoneControlService"
        const val PREFS_NAME = "maya_phone_control"
        const val KEY_AUTONOMY_ENABLED = "autonomy_enabled"
        const val KEY_VPS_URL = "vps_ws_url"
        const val KEY_DEVICE_ID = "device_id"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wsExecutor: ScheduledExecutorService? = null
    private var webSocket: okhttp3.WebSocket? = null
    private var okHttpClient: okhttp3.OkHttpClient? = null
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var isConnected = false
    private var reconnectAttempts = 0
    private val maxReconnectAttempts = 10
    private var deviceId: String = ""

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")

        // Acquire wake lock to keep service alive
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Maya::PhoneControlWakeLock")
        wakeLock?.acquire()

        // Initialize device ID
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        deviceId = prefs.getString(KEY_DEVICE_ID, "") ?: java.util.UUID.randomUUID().toString()
        prefs.edit().putString(KEY_DEVICE_ID, deviceId).apply()

        // Create notification channel
        createNotificationChannel()

        // Start foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        // Connect to VPS WebSocket
        connectToVps()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Maya Phone Control",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background service for autonomous phone control"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Maya Phone Control Active")
            .setContentText("Ready for autonomous calls/SMS via VPS")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .build()
    }

    private fun connectToVps() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val vpsUrl = prefs.getString(KEY_VPS_URL, null)
        
        if (vpsUrl == null || vpsUrl.isBlank()) {
            Log.w(TAG, "No VPS WebSocket URL configured, skipping connection")
            updateNotification("No VPS URL configured")
            return
        }
        
        okHttpClient = okhttp3.OkHttpClient.Builder()
            .pingInterval(30, TimeUnit.SECONDS)
            .build()

        val request = okhttp3.Request.Builder()
            .url("$vpsUrl?device_id=$deviceId")
            .build()

        webSocket = okHttpClient?.newWebSocket(request, object : okhttp3.WebSocketListener() {
            override fun onOpen(webSocket: okhttp3.WebSocket, response: okhttp3.Response) {
                isConnected = true
                reconnectAttempts = 0
                Log.d(TAG, "WebSocket connected to VPS")
                sendRegistration()
                updateNotification("Connected to VPS")
            }

            override fun onMessage(webSocket: okhttp3.WebSocket, text: String) {
                handleVpsMessage(text)
            }

            override fun onMessage(webSocket: okhttp3.WebSocket, bytes: okio.ByteString) {
                // Handle binary if needed
            }

            override fun onClosing(webSocket: okhttp3.WebSocket, code: Int, reason: String) {
                isConnected = false
                Log.d(TAG, "WebSocket closing: $code $reason")
            }

            override fun onClosed(webSocket: okhttp3.WebSocket, code: Int, reason: String) {
                isConnected = false
                Log.d(TAG, "WebSocket closed: $code $reason")
                scheduleReconnect()
            }

            override fun onFailure(webSocket: okhttp3.WebSocket, t: Throwable, response: okhttp3.Response?) {
                isConnected = false
                Log.e(TAG, "WebSocket failure: ${t.message}")
                scheduleReconnect()
            }
        })
    }

    private fun sendRegistration() {
        val msg = JSONObject().apply {
            put("type", "register")
            put("device_id", deviceId)
            put("capabilities", JSONArray().put("call").put("sms").put("logs"))
        }.toString()
        webSocket?.send(msg)
    }

    private fun handleVpsMessage(text: String) {
        try {
            val json = JSONObject(text)
            val type = json.optString("type", "")
            val requestId = json.optString("request_id", "")

            when (type) {
                "call" -> {
                    val number = json.optString("number", "")
                    val requireConfirmation = json.optBoolean("require_confirmation", true)
                    makeCall(number, requireConfirmation, requestId)
                }
                "sms" -> {
                    val number = json.optString("number", "")
                    val message = json.optString("message", "")
                    val requireConfirmation = json.optBoolean("require_confirmation", true)
                    sendSms(number, message, requireConfirmation, requestId)
                }
                "get_logs" -> {
                    sendLogs(requestId)
                }
                "ping" -> {
                    webSocket?.send(JSONObject().put("type", "pong").put("request_id", requestId).toString())
                }
                "set_autonomy" -> {
                    val enabled = json.optBoolean("enabled", true)
                    setAutonomyEnabled(enabled)
                    sendResponse(requestId, true, "Autonomy set to $enabled")
                }
                "get_status" -> {
                    sendStatus(requestId)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling VPS message: ${e.message}")
        }
    }

    private fun makeCall(number: String, requireConfirmation: Boolean, requestId: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val autonomyEnabled = prefs.getBoolean(KEY_AUTONOMY_ENABLED, false)
        val shouldConfirm = requireConfirmation && !autonomyEnabled

        if (shouldConfirm) {
            // Send back that confirmation is needed
            sendResponse(requestId, false, "Confirmation required - autonomy disabled")
            return
        }

        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = android.net.Uri.parse("tel:$number")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            
            // Log the call
            logCall(number, "outgoing", "initiated", "")
            sendResponse(requestId, true, "Call initiated to $number")
        } catch (e: Exception) {
            Log.e(TAG, "Call failed: ${e.message}")
            logCall(number, "outgoing", "failed", e.message ?: "Unknown error")
            sendResponse(requestId, false, "Call failed: ${e.message}")
        }
    }

    private fun sendSms(number: String, message: String, requireConfirmation: Boolean, requestId: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val autonomyEnabled = prefs.getBoolean(KEY_AUTONOMY_ENABLED, false)
        val shouldConfirm = requireConfirmation && !autonomyEnabled

        if (shouldConfirm) {
            sendResponse(requestId, false, "Confirmation required - autonomy disabled")
            return
        }

        try {
            val smsManager = android.telephony.SmsManager.getDefault()
            smsManager.sendTextMessage(number, null, message, null, null)
            
            // Log the SMS
            logSms(number, "outgoing", message, "sent")
            sendResponse(requestId, true, "SMS sent to $number")
        } catch (e: Exception) {
            Log.e(TAG, "SMS failed: ${e.message}")
            logSms(number, "outgoing", message, "failed: ${e.message}")
            sendResponse(requestId, false, "SMS failed: ${e.message}")
        }
    }

    private fun logCall(number: String, direction: String, status: String, transcript: String) {
        BackendLogger.logCall(this, number, direction, status, deviceId)
    }

    private fun logSms(number: String, direction: String, content: String, status: String) {
        BackendLogger.logSms(this, number, direction, status, deviceId)
    }

    private fun sendLogs(requestId: String) {
        // Query call log and SMS from device
        val logs = JSONObject()
        // This would query the actual call log and SMS content provider
        // For now send empty array
        logs.put("logs", JSONArray())
        sendResponse(requestId, true, logs.toString())
    }

    private fun sendStatus(requestId: String) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val autonomyEnabled = prefs.getBoolean(KEY_AUTONOMY_ENABLED, false)
        
        val status = JSONObject().apply {
            put("device_id", deviceId)
            put("connected", isConnected)
            put("autonomy_enabled", autonomyEnabled)
            put("permissions_granted", checkPermissions())
        }
        sendResponse(requestId, true, status.toString())
    }

    private fun checkPermissions(): Boolean {
        val permissions = arrayOf(
            android.Manifest.permission.CALL_PHONE,
            android.Manifest.permission.SEND_SMS,
            android.Manifest.permission.READ_PHONE_STATE,
            android.Manifest.permission.READ_CALL_LOG,
            android.Manifest.permission.READ_SMS
        )
        return permissions.all { checkCallingOrSelfPermission(it) == android.content.pm.PackageManager.PERMISSION_GRANTED }
    }

    private fun setAutonomyEnabled(enabled: Boolean) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_AUTONOMY_ENABLED, enabled).apply()
        updateNotification(if (enabled) "Autonomy ENABLED" else "Autonomy DISABLED (confirmation required)")
    }

    private fun sendResponse(requestId: String, success: Boolean, message: String) {
        val response = JSONObject().apply {
            put("type", "response")
            put("request_id", requestId)
            put("success", success)
            put("message", message)
        }
        webSocket?.send(response.toString())
    }

    private fun updateNotification(text: String) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Maya Phone Control")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun scheduleReconnect() {
        if (reconnectAttempts >= maxReconnectAttempts) {
            Log.e(TAG, "Max reconnect attempts reached")
            updateNotification("Disconnected - max retries reached")
            return
        }
        
        reconnectAttempts++
        val delay = minOf(1000 * 2.0.pow(reconnectAttempts - 1).toLong(), 60000)
        
        wsExecutor?.schedule({ connectToVps() }, delay, TimeUnit.MILLISECONDS)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        wakeLock?.release()
        webSocket?.close(1000, "Service destroyed")
        okHttpClient?.dispatcher?.executorService?.shutdown()
        wsExecutor?.shutdown()
        super.onDestroy()
        Log.d(TAG, "Service destroyed")
    }
}