package com.maya.app.voice

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.MediaRecorder
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.maya.app.R
import java.io.File

class VoiceRecordingService : Service() {

    private var mediaRecorder: MediaRecorder? = null
    private var recordingFile: File? = null
    private val CHANNEL_ID = "VoiceRecordingChannel"
    private val NOTIFICATION_ID = 1001

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            "START_RECORDING" -> startRecording()
            "STOP_RECORDING" -> stopRecording()
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Voice Recording",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notification for voice recording"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Maya Assistant")
            .setContentText("Recording voice input...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .build()
    }

    private fun startRecording() {
        val foregroundNotification = createNotification()
        startForeground(NOTIFICATION_ID, foregroundNotification)

        try {
            recordingFile = File(filesDir, "voice_input_${System.currentTimeMillis()}.3gp")
            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                setOutputFile(recordingFile!!.absolutePath)
                setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                prepare()
                start()
            }
            Log.d("VoiceRecordingService", "Recording started: ${recordingFile?.absolutePath}")
        } catch (e: Exception) {
            Log.e("VoiceRecordingService", "Failed to start recording", e)
            stopSelf()
        }
    }

    private fun stopRecording() {
        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            Log.d("VoiceRecordingService", "Recording stopped: ${recordingFile?.absolutePath}")
        } catch (e: Exception) {
            Log.e("VoiceRecordingService", "Failed to stop recording", e)
        } finally {
            stopForeground(true)
            stopSelf()
        }
    }

    override fun onDestroy() {
        if (mediaRecorder != null) {
            stopRecording()
        }
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}