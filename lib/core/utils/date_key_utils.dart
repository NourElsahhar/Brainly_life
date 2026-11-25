// DateKeyUtils = THE place for everything about "which day is it?".
// Nobody else writes "start of day" or "today" logic (Master Document E.8).
//
// A dateKey is the day as text: 'yyyy-MM-dd', for example '2026-11-16'.
// It is the day AS THE USER SEES IT, in the user's timezone
// (settings.timezone, an IANA name like 'Africa/Cairo').
//
// The rule for storing time:
//   - an exact moment (a task deadline)  -> Timestamp in UTC
//   - a whole day (habit log, study day) -> dateKey string
//
// Usage:
//   final tz = settings.timezone;                       // 'Africa/Cairo'
//   DateKeyUtils.todayKey(timezone: tz);                // '2026-11-16'
//   DateKeyUtils.toDateKey(task.dueAt, timezone: tz);   // day of a moment
//   DateKeyUtils.addDays('2026-11-30', 1);              // '2026-12-01'
//   DateKeyUtils.daysBetween('2026-11-10', '2026-11-16'); // 6
//
// Firestore query for "everything on this day":
//   final range = DateKeyUtils.dayBounds(key, timezone: tz);
//   .where('dueAt', isGreaterThanOrEqualTo: range.start)
//   .where('dueAt', isLessThan: range.end)
//
// In tests, never use DateTime.now(). todayKey uses package:clock, so you
// can fake the time:
//   withClock(Clock.fixed(DateTime.utc(2026, 11, 16)), () { ... });

import 'package:clock/clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A period of time in UTC. [start] is included, [end] is NOT included.
class UtcRange {
  const UtcRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class DateKeyUtils {
  const DateKeyUtils._();

  static bool _timezonesLoaded = false;
  static final RegExp _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static void _loadTimezones() {
    if (_timezonesLoaded) return;
    tz_data.initializeTimeZones();
    _timezonesLoaded = true;
  }

  /// Unknown timezone names fall back to UTC instead of crashing the app.
  static tz.Location _location(String timezone) {
    _loadTimezones();
    try {
      return tz.getLocation(timezone);
    } on Exception {
      return tz.UTC;
    }
  }

  /// True if [timezone] is a real IANA name like 'Africa/Cairo'.
  static bool isKnownTimezone(String timezone) {
    _loadTimezones();
    try {
      tz.getLocation(timezone);
      return true;
    } on Exception {
      return false;
    }
  }

  /// The day of [moment] in the user's [timezone], as 'yyyy-MM-dd'.
  static String toDateKey(DateTime moment, {required String timezone}) {
    final inUserZone = tz.TZDateTime.from(moment, _location(timezone));
    return fromCalendarDate(inUserZone);
  }

  /// Today in the user's [timezone].
  static String todayKey({required String timezone}) =>
      toDateKey(clock.now(), timezone: timezone);

  /// Formats the year, month and day of [date] as 'yyyy-MM-dd'.
  /// No timezone conversion happens here: the date is used as it is.
  static String fromCalendarDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Turns a dateKey into a date (UTC midnight). Only the year, month and
  /// day are meaningful. Returns null if the text is not a real date.
  static DateTime? tryParse(String dateKey) {
    if (!_pattern.hasMatch(dateKey)) return null;
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(5, 7));
    final day = int.parse(dateKey.substring(8, 10));
    final date = DateTime.utc(year, month, day);
    // DateTime rolls 2026-02-30 over to March, so check nothing moved.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Like [tryParse], but throws a FormatException for a bad dateKey.
  static DateTime parse(String dateKey) {
    final date = tryParse(dateKey);
    if (date == null) throw FormatException('Invalid dateKey: $dateKey');
    return date;
  }

  static bool isValid(String dateKey) => tryParse(dateKey) != null;

  /// Moves a dateKey by [days] (use a negative number to go back).
  static String addDays(String dateKey, int days) =>
      fromCalendarDate(parse(dateKey).add(Duration(days: days)));

  /// Number of days from [from] to [to]. Negative if [to] is earlier.
  static int daysBetween(String from, String to) =>
      parse(to).difference(parse(from)).inDays;

  /// The start (included) and end (NOT included) of a day, in UTC,
  /// for the user's [timezone]. Handles daylight saving (a day can have
  /// 23 or 25 hours).
  static UtcRange dayBounds(String dateKey, {required String timezone}) {
    final date = parse(dateKey);
    final next = date.add(const Duration(days: 1));
    final location = _location(timezone);

    return UtcRange(
      start: _toPlainUtc(
        tz.TZDateTime(location, date.year, date.month, date.day),
      ),
      end: _toPlainUtc(
        tz.TZDateTime(location, next.year, next.month, next.day),
      ),
    );
  }

  static DateTime _toPlainUtc(tz.TZDateTime value) =>
      DateTime.fromMillisecondsSinceEpoch(
        value.millisecondsSinceEpoch,
        isUtc: true,
      );
}
