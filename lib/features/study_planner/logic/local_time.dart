import 'package:brainly_life/core/utils/date_key_utils.dart';

/// Converts between UTC moments and the user's local "day + time of day",
/// the format the AI uses ('yyyy-MM-dd' + 'HH:mm').
///
/// Both functions count minutes from the start of the local day that
/// `DateKeyUtils.dayBounds` gives. That is exact on every normal day. On the
/// one day a year when the clocks move, a time after the change is off by
/// that change (one hour). Open team decision 5 in the README asks M1 for a
/// DST-safe helper in DateKeyUtils; when it exists, only this file changes.
abstract final class LocalTime {
  /// The UTC moment of [minuteOfDay] (0 = midnight) on [dateKey] in
  /// [timezone].
  static DateTime toUtc(
    String dateKey,
    int minuteOfDay, {
    required String timezone,
  }) {
    final start = DateKeyUtils.dayBounds(dateKey, timezone: timezone).start;
    return start.add(Duration(minutes: minuteOfDay));
  }

  /// Minutes since the start of the local day of [moment].
  static int minuteOfDay(DateTime moment, {required String timezone}) {
    final dateKey = DateKeyUtils.toDateKey(moment, timezone: timezone);
    final start = DateKeyUtils.dayBounds(dateKey, timezone: timezone).start;
    return moment.toUtc().difference(start).inMinutes;
  }

  /// 'HH:mm' -> minutes since midnight. null if the text is not a time.
  static int? parseTime(String text) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text);
    if (match == null) return null;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }

  /// Minutes since midnight -> 'HH:mm'.
  static String formatTime(int minuteOfDay) {
    final hours = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minutes = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
