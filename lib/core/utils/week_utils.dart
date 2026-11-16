// WeekUtils = THE place for everything about weeks.
// It respects the user's "week start day" setting.
// Nobody else writes "start of week" logic (Master Document E.8).
//
// weekStartDay is a number from 1 to 7 (the same as DateTime.monday ...
// DateTime.sunday): 1 = Monday, 6 = Saturday, 7 = Sunday.
// It comes from settings.weekStartDay. The default is Monday.
//
// Everything works with dateKeys ('yyyy-MM-dd'), see DateKeyUtils.
//
// Usage:
//   final today = DateKeyUtils.todayKey(timezone: tz);
//   WeekUtils.weekStartDateKey(today, weekStartDay: day);  // first day
//   WeekUtils.weekEndDateKey(today, weekStartDay: day);    // last day
//   WeekUtils.weekDateKeys(today, weekStartDay: day);      // all 7 days
//   WeekUtils.weekKey(today, weekStartDay: day);           // '2026-W47'
//   WeekUtils.currentWeekKey(timezone: tz, weekStartDay: day);
//
// Previous / next week:
//   final start = WeekUtils.weekStartDateKey(today, weekStartDay: day);
//   final lastWeek = DateKeyUtils.addDays(start, -7);
//
// Firestore query for a whole week:
//   final range = WeekUtils.weekBounds(today, timezone: tz, weekStartDay: day);
//   .where('startedAt', isGreaterThanOrEqualTo: range.start)
//   .where('startedAt', isLessThan: range.end)
//
// weekKey ('yyyy-Www', like '2026-W47'):
//   - When the week starts on Monday it is exactly the ISO week number.
//   - For another start day, the same rule is applied to the 4th day of
//     the user's week, so a week always has exactly one key.

import 'date_key_utils.dart';

class WeekUtils {
  const WeekUtils._();

  /// First day of the week that contains [dateKey].
  static String weekStartDateKey(
    String dateKey, {
    int weekStartDay = DateTime.monday,
  }) {
    final date = DateKeyUtils.parse(dateKey);
    return DateKeyUtils.fromCalendarDate(_startOfWeek(date, weekStartDay));
  }

  /// Last day of the week that contains [dateKey] (included).
  static String weekEndDateKey(
    String dateKey, {
    int weekStartDay = DateTime.monday,
  }) =>
      DateKeyUtils.addDays(
        weekStartDateKey(dateKey, weekStartDay: weekStartDay),
        6,
      );

  /// The 7 dateKeys of the week that contains [dateKey], first day first.
  static List<String> weekDateKeys(
    String dateKey, {
    int weekStartDay = DateTime.monday,
  }) {
    final start = weekStartDateKey(dateKey, weekStartDay: weekStartDay);
    return [for (var i = 0; i < 7; i++) DateKeyUtils.addDays(start, i)];
  }

  /// The weekKey ('yyyy-Www') of the week that contains [dateKey].
  static String weekKey(
    String dateKey, {
    int weekStartDay = DateTime.monday,
  }) {
    final start = _startOfWeek(DateKeyUtils.parse(dateKey), weekStartDay);
    final anchor = start.add(const Duration(days: 3));
    final dayOfYear = anchor.difference(DateTime.utc(anchor.year)).inDays + 1;
    final week = (dayOfYear - 1) ~/ 7 + 1;
    return '${anchor.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// The weekKey of the week that contains [moment] in the user's [timezone].
  static String weekKeyForMoment(
    DateTime moment, {
    required String timezone,
    int weekStartDay = DateTime.monday,
  }) =>
      weekKey(
        DateKeyUtils.toDateKey(moment, timezone: timezone),
        weekStartDay: weekStartDay,
      );

  /// The weekKey of this week (uses package:clock, so tests can fake it).
  static String currentWeekKey({
    required String timezone,
    int weekStartDay = DateTime.monday,
  }) =>
      weekKey(
        DateKeyUtils.todayKey(timezone: timezone),
        weekStartDay: weekStartDay,
      );

  /// Start (included) and end (NOT included) of the week, in UTC.
  static UtcRange weekBounds(
    String dateKey, {
    required String timezone,
    int weekStartDay = DateTime.monday,
  }) {
    final start = weekStartDateKey(dateKey, weekStartDay: weekStartDay);
    final nextWeekStart = DateKeyUtils.addDays(start, 7);

    return UtcRange(
      start: DateKeyUtils.dayBounds(start, timezone: timezone).start,
      end: DateKeyUtils.dayBounds(nextWeekStart, timezone: timezone).start,
    );
  }

  static DateTime _startOfWeek(DateTime date, int weekStartDay) {
    if (weekStartDay < 1 || weekStartDay > 7) {
      throw ArgumentError.value(
        weekStartDay,
        'weekStartDay',
        'Must be 1 (Monday) to 7 (Sunday)',
      );
    }
    final daysSinceStart = (date.weekday - weekStartDay + 7) % 7;
    return date.subtract(Duration(days: daysSinceStart));
  }
}