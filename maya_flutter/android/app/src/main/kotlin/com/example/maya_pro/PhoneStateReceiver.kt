package com.example.maya_pro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.telephony.TelephonyManager
import android.util.Log
import org.json.JSONObject
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.MediaType
import java.io.IOException

class PhoneStateReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "PhoneStateReceiver"
        const val PREFS_NAME = "maya_phone_control"
        const val KEY_DEVICE_ID = "device_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: ""

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                Log.d(TAG, "Incoming call from: $number")
                logCall(context, number, "incoming", "ringing", "")
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                Log.d(TAG, "Call answered/active: $number")
                logCall(context, number, "incoming", "answered", "")
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                Log.d(TAG, "Call ended: $number")
                logCall(context, number, "incoming", "ended", "")
            }
        }
    }

    private fun logCall(context: Context, number: String, direction: String, status: String, transcript: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val deviceId = prefs.getString(KEY_DEVICE_ID, "") ?: "unknown"

        val logEntry = JSONObject().apply {
            put("type", "call_log")
            put("number", number)
            put("direction", direction)
            put("status", status)
            put("transcript", transcript)
            put("timestamp", System.currentTimeMillis())
            put("device_id", deviceId)
        }

        val client = OkHttpClient()
        val body = RequestBody.create(
            logEntry.toString(),
            MediaType.get("application/json")
        )
        val request = Request.Builder()
            .url("http://130.210.46.182:8000/api/v1/device/log")
            .post(body)
            .build()

        client.newCall(request).enqueue(object : okhttp3.Callback {
            override fun onFailure(call: okhttp3.Call, e: IOException) {
                Log.e(TAG, "Call log failed: ${e.message}")
            }
            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                response.close()
            }
        })
    }
}