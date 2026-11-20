// Tests for HabitSchedule: which habits are due on a given day.

import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/habit_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Habit habit({
    HabitFrequencyType type = HabitFrequencyType.daily,
    List<int> weekdays = const [],
    String startDate = '2026-11-01',
    bool archived = false,
  }) {
    return Habit(
      id: 'h1',
      name: 'Read',
      icon: 'book',
      colorValue: 0xFF2196F3,
      frequencyType: type,
      weekdays: weekdays,
      startDate: startDate,
      archived: archived,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  // 2026-11-16 is a Monday.
  test('a daily habit is due every day after its start date', () {
    expect(HabitSchedule.isDueOn(habit(), '2026-11-16'), isTrue);
    expect(HabitSchedule.isDueOn(habit(), '2026-10-31'), isFalse);
  });

  test('an archived habit is never due', () {
    expect(HabitSchedule.isDueOn(habit(archived: true), '2026-11-16'), isFalse);
  });

  test('a weekdays habit is due only on its weekdays', () {
    final monWed = habit(
      type: HabitFrequencyType.weekdays,
      weekdays: const [1, 3],
    );
    final tuesday = habit(
      type: HabitFrequencyType.weekdays,
      weekdays: const [2],
    );
    expect(HabitSchedule.isDueOn(monWed, '2026-11-16'), isTrue);
    expect(HabitSchedule.isDueOn(tuesday, '2026-11-16'), isFalse);
  });

  test('a times-per-week habit is due every day', () {
    final weekly = habit(type: HabitFrequencyType.timesPerWeek);
    expect(HabitSchedule.isDueOn(weekly, '2026-11-18'), isTrue);
  });
}
