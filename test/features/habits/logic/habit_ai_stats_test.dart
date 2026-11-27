// Tests for HabitAiStats: the statistics sent for habit suggestions.

import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/habit_ai_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Habit habit(
    String id, {
    HabitFrequencyType type = HabitFrequencyType.daily,
    List<int> weekdays = const [],
    int? timesPerWeek,
    bool archived = false,
    int streak = 0,
  }) => Habit(
    id: id,
    name: id,
    icon: 'book',
    colorValue: 0xFF2196F3,
    frequencyType: type,
    weekdays: weekdays,
    timesPerWeek: timesPerWeek,
    startDate: '2026-10-01',
    archived: archived,
    currentStreak: streak,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  HabitLog log(String habitId, String date) =>
      HabitLog(habitId: habitId, date: date, completedAt: DateTime.utc(2026));

  test('counts, streaks, schedule and best weekdays', () {
    // 2026-11-16 and 2026-11-23 are Mondays.
    final payload = HabitAiStats.payload(
      today: '2026-11-27',
      habits: [
        habit('Read', streak: 4),
        habit('Gym', type: HabitFrequencyType.weekdays, weekdays: [3, 1]),
        habit('Old', archived: true),
      ],
      logs: [
        log('Read', '2026-11-26'),
        log('Read', '2026-11-27'),
        log('Read', '2026-10-01'), // older than 30 days
        log('Gym', '2026-11-16'),
        log('Gym', '2026-11-23'),
      ],
    );

    final habits = payload['habits']! as List;
    expect(habits, hasLength(2)); // the archived one is left out
    expect(habits[0], {
      'name': 'Read',
      'schedule': 'daily',
      'doneLast30Days': 2,
      'currentStreak': 4,
      'bestStreak': 0,
      'bestWeekdays': <String>[],
    });
    expect((habits[1] as Map)['schedule'], 'on Mon, Wed');
    expect((habits[1] as Map)['bestWeekdays'], ['Mon']);
  });

  test('times per week', () {
    expect(
      HabitAiStats.schedule(
        habit('x', type: HabitFrequencyType.timesPerWeek, timesPerWeek: 3),
      ),
      '3 times per week',
    );
  });
}
