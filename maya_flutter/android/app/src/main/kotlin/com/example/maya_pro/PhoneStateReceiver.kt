package com.example.maya_pro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

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
        BackendLogger.logCall(context, number, direction, status, deviceId)
    }
}