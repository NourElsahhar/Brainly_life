// FocusStatsCalculator turns saved focus sessions into the numbers shown on
// the focus statistics screen: minutes per day, total sessions, best hour of
// the day, and the focus-day streak.
//
// Only focus blocks count (breaks are ignored). Pure Dart: no Firebase, and
// it never reads the clock (the caller passes `today`). Day and hour logic
// goes through DateKeyUtils, so the user's timezone is respected.

import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';

class FocusStatsCalculator {
  const FocusStatsCalculator({required this.timezone});

  /// The user's timezone, for example 'Africa/Cairo'.
  final String timezone;

  /// Focus minutes for every day from [fromDate] to [toDate] (both included).
  /// Days without sessions are 0, so the result is ready for a bar chart.
  /// Keys are dateKeys, oldest first.
  Map<String, int> minutesPerDay({
    required Iterable<FocusSession> sessions,
    required String fromDate,
    required String toDate,
  }) {
    final result = <String, int>{};
    final dayCount = DateKeyUtils.daysBetween(fromDate, toDate);
    for (var i = 0; i <= dayCount; i++) {
      result[DateKeyUtils.addDays(fromDate, i)] = 0;
    }
    for (final session in _focusOnly(sessions)) {
      final current = result[session.dateKey];
      if (current != null) {
        result[session.dateKey] = current + session.actualMinutes;
      }
    }
    return result;
  }

  /// Number of focus blocks.
  int totalSessions(Iterable<FocusSession> sessions) =>
      _focusOnly(sessions).length;

  /// Total focus minutes.
  int totalMinutes(Iterable<FocusSession> sessions) =>
      _focusOnly(sessions)
          .fold(0, (sum, session) => sum + session.actualMinutes);

  /// The hour of the day (0 to 23, in the user's timezone) with the most
  /// focus minutes. If two hours tie, the earlier one wins.
  /// Returns null when there are no focus sessions.
  int? bestHour(Iterable<FocusSession> sessions) {
    final minutesByHour = <int, int>{};
    for (final session in _focusOnly(sessions)) {
      final dayStart = DateKeyUtils.dayBounds(
        session.dateKey,
        timezone: timezone,
      ).start;
      final hour = session.startedAt
          .difference(dayStart)
          .inHours
          .clamp(0, 23)
          .toInt();
      minutesByHour[hour] = (minutesByHour[hour] ?? 0) + session.actualMinutes;
    }
    if (minutesByHour.isEmpty) return null;

    int? best;
    var bestMinutes = -1;
    for (final hour in minutesByHour.keys.toList()..sort()) {
      if (minutesByHour[hour]! > bestMinutes) {
        best = hour;
        bestMinutes = minutesByHour[hour]!;
      }
    }
    return best;
  }

  /// Days in a row with at least one focus minute. Today does not break the
  /// streak until the day is over. Pass enough history (for example 60 days).
  int focusDayStreak({
    required Iterable<FocusSession> sessions,
    required String today,
  }) {
    final days = {
      for (final session in _focusOnly(sessions))
        if (session.actualMinutes > 0) session.dateKey,
    };
    var day = days.contains(today) ? today : DateKeyUtils.addDays(today, -1);
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = DateKeyUtils.addDays(day, -1);
    }
    return streak;
  }

  List<FocusSession> _focusOnly(Iterable<FocusSession> sessions) => sessions
      .where((session) => session.type == FocusSessionType.focus)
      .toList();
}
