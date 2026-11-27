// HabitAiStats = the short statistics the AI gets for habit suggestions
// (the same numbers the server built in habitSuggest.ts):
//   name, schedule ("daily", "on Mon, Wed", "3 times per week"),
//   days done in the last 30 days, current and best streak, and the
//   weekdays when the habit was done most.
// Pure Dart, so it is easy to test.

import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';

abstract final class HabitAiStats {
  /// Days the statistics cover.
  static const int windowDays = 30;

  /// At most this many habits go to the AI (the oldest first).
  static const int maxHabits = 20;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// The first day of the window that ends [today].
  static String firstDay(String today) =>
      DateKeyUtils.addDays(today, -(windowDays - 1));

  /// The payload of AiFeature.habitSuggest: {today, habits: [...]}.
  static Map<String, Object?> payload({
    required String today,
    required List<Habit> habits,
    required List<HabitLog> logs,
  }) {
    final active = habits.where((h) => !h.archived).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final from = firstDay(today);
    final doneDays = <String, List<String>>{};
    for (final log in logs) {
      if (log.date.compareTo(from) < 0 || log.date.compareTo(today) > 0) {
        continue;
      }
      doneDays.putIfAbsent(log.habitId, () => []).add(log.date);
    }

    return {
      'today': today,
      'habits': [
        for (final habit in active.take(maxHabits))
          _stat(habit, doneDays[habit.id] ?? const []),
      ],
    };
  }

  static Map<String, Object?> _stat(Habit habit, List<String> days) {
    final perWeekday = <int, int>{};
    for (final day in days) {
      final weekday = DateKeyUtils.parse(day).weekday;
      perWeekday[weekday] = (perWeekday[weekday] ?? 0) + 1;
    }
    final most = perWeekday.values.fold<int>(0, (a, b) => a > b ? a : b);
    final bestWeekdays = most < 2
        ? const <String>[]
        : ([
            for (final entry in perWeekday.entries)
              if (entry.value == most) entry.key,
          ]..sort()).map((weekday) => _weekdays[weekday - 1]).toList();

    return {
      'name': habit.name,
      'schedule': schedule(habit),
      'doneLast30Days': days.length,
      'currentStreak': habit.currentStreak,
      'bestStreak': habit.bestStreak,
      'bestWeekdays': bestWeekdays,
    };
  }

  /// "daily", "on Mon, Fri" or "3 times per week".
  static String schedule(Habit habit) {
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
        return 'daily';
      case HabitFrequencyType.weekdays:
        final days = habit.weekdays.where((d) => d >= 1 && d <= 7).toList()
          ..sort();
        return days.isEmpty
            ? 'daily'
            : 'on ${days.map((d) => _weekdays[d - 1]).join(', ')}';
      case HabitFrequencyType.timesPerWeek:
        final times = habit.timesPerWeek;
        return times == null ? 'daily' : '$times times per week';
    }
  }
}
