// TimerAlert = the sound and vibration when a Focus block ends.
//
// On Android it uses the native channel "baseet/timer_alert" (MainActivity):
// the phone's notification sound and three strong vibration pulses.
// Flutter's own SystemSound has no alert sound on Android and
// HapticFeedback is only a tiny tap, so they are only the fallback (iOS,
// tests, or if the channel fails).
//
// Usage:
//   TimerAlert.play(sound: settings.sound, vibration: settings.vibration);

import 'package:flutter/services.dart';

class TimerAlert {
  const TimerAlert._();

  static const MethodChannel _channel = MethodChannel('baseet/timer_alert');

  static Future<void> play({
    required bool sound,
    required bool vibration,
  }) async {
    if (!sound && !vibration) return;
    try {
      await _channel.invokeMethod<void>('play', {
        'sound': sound,
        'vibrate': vibration,
      });
    } catch (_) {
      // No native channel (iOS, tests): the Flutter fallback.
      if (vibration) await HapticFeedback.vibrate();
      if (sound) await SystemSound.play(SystemSoundType.alert);
    }
  }
}
