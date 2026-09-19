package com.shipaton.sonicmixer.sonic_mixer

import android.content.Context
import android.database.ContentObserver
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shipaton.sonicmixer/volume"
    private var isVolumeLocked = false
    private var watchdogHandler: Handler? = null
    private var watchdogRunnable: Runnable? = null
    private var volumeObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val audioManager = applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setMaxVolume" -> {
                    try {
                        forceMaxVolume(audioManager)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "lockMaxVolume" -> {
                    isVolumeLocked = true
                    startVolumeWatchdog(audioManager)
                    registerVolumeObserver(audioManager)
                    result.success(true)
                }
                "unlockVolume" -> {
                    isVolumeLocked = false
                    stopVolumeWatchdog()
                    unregisterVolumeObserver()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun forceMaxVolume(audioManager: AudioManager) {
        try {
            val streams = intArrayOf(
                AudioManager.STREAM_MUSIC,
                AudioManager.STREAM_ALARM,
                AudioManager.STREAM_SYSTEM
            )
            for (stream in streams) {
                val max = audioManager.getStreamMaxVolume(stream)
                val curr = audioManager.getStreamVolume(stream)
                if (curr < max) {
                    audioManager.setStreamVolume(stream, max, 0)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun registerVolumeObserver(audioManager: AudioManager) {
        if (volumeObserver == null) {
            volumeObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean) {
                    super.onChange(selfChange)
                    if (isVolumeLocked) {
                        forceMaxVolume(audioManager)
                    }
                }
            }
            try {
                applicationContext.contentResolver.registerContentObserver(
                    Settings.System.CONTENT_URI,
                    true,
                    volumeObserver!!
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun unregisterVolumeObserver() {
        volumeObserver?.let {
            try {
                applicationContext.contentResolver.unregisterContentObserver(it)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            volumeObserver = null
        }
    }

    private fun startVolumeWatchdog(audioManager: AudioManager) {
        if (watchdogHandler == null) {
            watchdogHandler = Handler(Looper.getMainLooper())
        }
        watchdogRunnable?.let { watchdogHandler?.removeCallbacks(it) }

        // Immediately force to max
        forceMaxVolume(audioManager)

        watchdogRunnable = object : Runnable {
            override fun run() {
                if (isVolumeLocked) {
                    forceMaxVolume(audioManager)
                    watchdogHandler?.postDelayed(this, 150) // Aggressive 150ms check
                }
            }
        }
        watchdogHandler?.post(watchdogRunnable!!)
    }

    private fun stopVolumeWatchdog() {
        watchdogRunnable?.let { watchdogHandler?.removeCallbacks(it) }
        watchdogRunnable = null
    }

    override fun onDestroy() {
        stopVolumeWatchdog()
        unregisterVolumeObserver()
        super.onDestroy()
    }
}
