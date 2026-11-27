package com.example.brainly_life

import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// MainActivity adds one small channel, "baseet/timer_alert", used by the
// Focus timer when a block ends (TimerAlert in Dart):
//   play {sound: bool, vibrate: bool}
//     sound   -> the phone's notification sound
//     vibrate -> three strong pulses
// Flutter's own SystemSound has no "alert" sound on Android, and
// HapticFeedback is only a tiny tap, so they are not enough.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "play") {
                    if (call.argument<Boolean>("sound") == true) playSound()
                    if (call.argument<Boolean>("vibrate") == true) vibrate()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun playSound() {
        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val ringtone = RingtoneManager.getRingtone(applicationContext, uri) ?: return
            ringtone.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            ringtone.play()
        } catch (_: Exception) {
            // No sound is better than a crash.
        }
    }

    private fun vibrate() {
        try {
            val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            if (!vibrator.hasVibrator()) return
            val pattern = longArrayOf(0, 400, 200, 400, 200, 600)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, -1)
            }
        } catch (_: Exception) {
            // No vibration is better than a crash.
        }
    }

    companion object {
        private const val CHANNEL = "baseet/timer_alert"
    }
}
