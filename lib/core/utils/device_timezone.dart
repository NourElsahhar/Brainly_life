// DeviceTimezone = the phone's time zone as an IANA name, like
// "Africa/Cairo". A NEW user gets it in their settings (instead of UTC),
// so "today", reminders and the AI daily limits follow their real day.
// The user can still change it in Settings > Time zone.
//
// Usage:
//   final zone = await DeviceTimezone.current();   // "Africa/Cairo"
//
// If the phone cannot tell (or in tests, where there is no phone), it
// returns "UTC". It never throws.

import 'package:flutter_timezone/flutter_timezone.dart';

class DeviceTimezone {
  const DeviceTimezone._();

  static const String fallback = 'UTC';

  static Future<String> current() async {
    try {
      // flutter_timezone 4+ returns a TimezoneInfo (with .identifier);
      // older versions return the name as a String. Both work here.
      final dynamic zone = await FlutterTimezone.getLocalTimezone();
      final name = zone is String ? zone : zone.identifier as String;
      return name.isEmpty ? fallback : name;
    } catch (_) {
      return fallback;
    }
  }
}
