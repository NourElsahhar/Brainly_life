// Tests for StreakCalculator: daily, weekdays and times-per-week habits,
// month boundaries, "today not done yet", and the completion rate.

import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/logic/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = StreakCalculator();

  Habit habit({
    String startDate = '2026-11-01',
    HabitFrequencyType type = HabitFrequencyType.daily,
    List<int> weekdays = const [],
    int? timesPerWeek,
  }) {
    return Habit(
      id: 'h1',
      name: 'Read',
      icon: 'book',
      colorValue: 0xFF2196F3,
      frequencyType: type,
      weekdays: weekdays,
      timesPerWeek: timesPerWeek,
      startDate: startDate,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  StreakResult run(Habit h, List<String> done, String today) {
    return calculator.calculate(
      habit: h,
      completedDates: done.toSet(),
      today: today,
    );
  }

  group('daily habit', () {
    test('counts consecutive days including today', () {
      final result = run(habit(), [
        '2026-11-12',
        '2026-11-13',
        '2026-11-14',
      ], '2026-11-14');
      expect(result.currentStreak, 3);
      expect(result.bestStreak, 3);
    });

    test('today not done yet does not break the streak', () {
      final result = run(habit(), ['2026-11-12', '2026-11-13'], '2026-11-14');
      expect(result.currentStreak, 2);
      expect(result.bestStreak, 2);
    });

    test('a missed day breaks the streak but keeps the best', () {
      final result = run(habit(), [
        '2026-11-08',
        '2026-11-09',
        '2026-11-10',
        '2026-11-11',
        '2026-11-13',
      ], '2026-11-14');
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 4);
    });

    test('streak continues across a month boundary', () {
      final result = run(habit(startDate: '2026-10-25'), [
        '2026-10-30',
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
      ], '2026-11-02');
      expect(result.currentStreak, 4);
      expect(result.bestStreak, 4);
    });

    test('start date in the future gives zero', () {
      final result = run(habit(startDate: '2026-11-20'), [], '2026-11-15');
      expect(result.currentStreak, 0);
      expect(result.bestStreak, 0);
    });

    test('a backfilled yesterday joins the streak', () {
      final result = run(habit(), [
        '2026-11-12',
        '2026-11-13',
        '2026-11-14',
      ], '2026-11-15');
      expect(result.currentStreak, 3);
    });
  });

  group('weekdays habit', () {
    final mwf = habit(
      type: HabitFrequencyType.weekdays,
      weekdays: const [1, 3, 5],
    );

    test('ignores days that are not scheduled', () {
      final result = run(mwf, [
        '2026-11-02',
        '2026-11-04',
        '2026-11-06',
      ], '2026-11-07');
      expect(result.currentStreak, 3);
      expect(result.bestStreak, 3);
    });

    test('a missed scheduled day breaks the streak', () {
      final result = run(mwf, ['2026-11-02', '2026-11-06'], '2026-11-06');
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 1);
    });
  });

  group('times per week habit', () {
    final threePerWeek = habit(
      startDate: '2026-10-26',
      type: HabitFrequencyType.timesPerWeek,
      timesPerWeek: 3,
    );

    test('counts weeks that reached the target', () {
      final result = run(threePerWeek, [
        '2026-10-26',
        '2026-10-28',
        '2026-10-30',
        '2026-11-02',
        '2026-11-04',
        '2026-11-06',
        '2026-11-09',
      ], '2026-11-11');
      expect(result.currentStreak, 2);
      expect(result.bestStreak, 2);
    });

    test('a week below the target breaks the streak', () {
      final result = run(threePerWeek, [
        '2026-10-26',
        '2026-10-28',
        '2026-11-02',
        '2026-11-04',
        '2026-11-06',
      ], '2026-11-10');
      expect(result.currentStreak, 1);
      expect(result.bestStreak, 1);
    });
  });

  group('completionRate', () {
    test('divides completed days by due days in the window', () {
      final rate = calculator.completionRate(
        habit: habit(),
        completedDates: {
          '2026-11-08',
          '2026-11-09',
          '2026-11-11',
          '2026-11-12',
          '2026-11-13',
          '2026-11-14',
        },
        today: '2026-11-14',
        windowDays: 7,
      );
      expect(rate, closeTo(6 / 7, 1e-9));
    });

    test('window is cut at the start date', () {
      final rate = calculator.completionRate(
        habit: habit(startDate: '2026-11-13'),
        completedDates: {'2026-11-13'},
        today: '2026-11-14',
        windowDays: 30,
      );
      expect(rate, 1.0);
    });

    test('returns zero when nothing is due yet', () {
      final rate = calculator.completionRate(
        habit: habit(startDate: '2026-11-14'),
        completedDates: {},
        today: '2026-11-14',
        windowDays: 7,
      );
      expect(rate, 0.0);
    });
  });
}
