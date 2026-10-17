package com.example.maya_pro

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    private val CHANNEL = "maya/phone_control"
    private val TAG = "MainActivity"
    private val PERMISSIONS_REQUEST_CODE = 1001
    private val BATTERY_OPTIMIZATION_REQUEST_CODE = 1002

    private val requiredPermissions = arrayOf(
        Manifest.permission.CALL_PHONE,
        Manifest.permission.SEND_SMS,
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.READ_CALL_LOG,
        Manifest.permission.READ_SMS,
        Manifest.permission.POST_NOTIFICATIONS
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "requestPermissions" -> requestPermissions(result)
            "checkPermissions" -> checkPermissions(result)
            "openBatteryOptimizationSettings" -> openBatteryOptimizationSettings(result)
            "makeCall" -> makeCall(call, result)
            "sendSms" -> sendSms(call, result)
            "getCallLogs" -> getCallLogs(result)
            "getSmsLogs" -> getSmsLogs(result)
            "setAutonomyEnabled" -> setAutonomyEnabled(call, result)
            "getAutonomyEnabled" -> getAutonomyEnabled(result)
            "startForegroundService" -> startForegroundService(result)
            "stopForegroundService" -> stopForegroundService(result)
            "getDeviceId" -> getDeviceId(result)
            "setVpsUrl" -> setVpsUrl(call, result)
            "getServiceStatus" -> getServiceStatus(result)
            else -> result.notImplemented()
        }
    }

    private fun requestPermissions(result: Result) {
        val missingPermissions = requiredPermissions.filter { 
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED 
        }
        
        if (missingPermissions.isEmpty()) {
            result.success(true)
            return
        }

        ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), PERMISSIONS_REQUEST_CODE)
        // Result will be delivered via onRequestPermissionsResult
        // We'll store the result callback
        pendingPermissionResult = result
    }

    private var pendingPermissionResult: Result? = null

    private val noOpResult = object : io.flutter.plugin.common.MethodChannel.Result {
        override fun success(result: Any?) {}
        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {}
        override fun notImplemented() {}
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSIONS_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionResult?.success(allGranted)
            pendingPermissionResult = null
        }
    }

    private fun checkPermissions(result: Result) {
        val granted = requiredPermissions.all { 
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED 
        }
        result.success(granted)
    }

    private fun openBatteryOptimizationSettings(result: Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivityForResult(intent, BATTERY_OPTIMIZATION_REQUEST_CODE)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    private fun makeCall(call: MethodCall, result: Result) {
        val number = call.argument<String>("number") ?: ""
        if (number.isEmpty()) {
            result.error("INVALID_NUMBER", "Phone number required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
            return
        }

        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$number")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            result.success("Call initiated to $number")
        } catch (e: Exception) {
            result.error("CALL_FAILED", e.message ?: "Unknown error", null)
        }
    }

    private fun sendSms(call: MethodCall, result: Result) {
        val number = call.argument<String>("number") ?: ""
        val message = call.argument<String>("message") ?: ""
        
        if (number.isEmpty() || message.isEmpty()) {
            result.error("INVALID_ARGS", "Number and message required", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "SEND_SMS permission not granted", null)
            return
        }

        try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(number, null, message, null, null)
            result.success("SMS sent to $number")
        } catch (e: Exception) {
            result.error("SMS_FAILED", e.message ?: "Unknown error", null)
        }
    }

    private fun getCallLogs(result: Result) {
        // Query call log content provider
        // This is a simplified version - in production you'd want pagination
        result.success(JSONObject().put("logs", JSONObject()).toString())
    }

    private fun getSmsLogs(result: Result) {
        // Query SMS content provider
        result.success(JSONObject().put("logs", JSONObject()).toString())
    }

    private fun setAutonomyEnabled(call: MethodCall, result: Result) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val prefs = getSharedPreferences(PhoneControlService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(PhoneControlService.KEY_AUTONOMY_ENABLED, enabled).apply()
        result.success(enabled)
    }

    private fun getAutonomyEnabled(result: Result) {
        val prefs = getSharedPreferences(PhoneControlService.PREFS_NAME, Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean(PhoneControlService.KEY_AUTONOMY_ENABLED, false)
        result.success(enabled)
    }

    private fun startForegroundService(result: Result) {
        val intent = Intent(this, PhoneControlService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        result.success(true)
    }

    private fun stopForegroundService(result: Result) {
        val intent = Intent(this, PhoneControlService::class.java)
        stopService(intent)
        result.success(true)
    }

    private fun getDeviceId(result: Result) {
        val prefs = getSharedPreferences(PhoneControlService.PREFS_NAME, Context.MODE_PRIVATE)
        val deviceId = prefs.getString(PhoneControlService.KEY_DEVICE_ID, "") ?: java.util.UUID.randomUUID().toString()
        prefs.edit().putString(PhoneControlService.KEY_DEVICE_ID, deviceId).apply()
        result.success(deviceId)
    }

    private fun setVpsUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url") ?: ""
        val prefs = getSharedPreferences(PhoneControlService.PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(PhoneControlService.KEY_VPS_URL, url).apply()
        // Restart service to pick up new URL
        stopForegroundService(noOpResult)
        startForegroundService(noOpResult)
        result.success(true)
    }

    private fun getServiceStatus(result: Result) {
        // Check if service is running
        // This would need a more robust implementation
        val prefs = getSharedPreferences(PhoneControlService.PREFS_NAME, Context.MODE_PRIVATE)
        val autonomyEnabled = prefs.getBoolean(PhoneControlService.KEY_AUTONOMY_ENABLED, false)
        val permissionsGranted = checkPermissionsSync()
        
        val status = JSONObject().apply {
            put("autonomy_enabled", autonomyEnabled)
            put("permissions_granted", permissionsGranted)
            put("device_id", prefs.getString(PhoneControlService.KEY_DEVICE_ID, ""))
        }
        result.success(status.toString())
    }

    private fun checkPermissionsSync(): Boolean {
        return requiredPermissions.all { 
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED 
        }
    }
}