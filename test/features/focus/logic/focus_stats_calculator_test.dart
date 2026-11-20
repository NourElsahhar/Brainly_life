// Tests for FocusStatsCalculator: minutes per day, totals, best hour
// (including timezone), and the focus-day streak.

import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = FocusStatsCalculator(timezone: 'UTC');

  FocusSession session(
    String dateKey, {
    int hour = 9,
    int minutes = 25,
    FocusSessionType type = FocusSessionType.focus,
  }) {
    final day = DateKeyUtils.parse(dateKey);
    final start = DateTime.utc(day.year, day.month, day.day, hour);
    return FocusSession(
      id: '$dateKey-$hour',
      type: type,
      startedAt: start,
      endedAt: start.add(Duration(minutes: minutes)),
      plannedMinutes: 25,
      actualMinutes: minutes,
      completed: true,
      dateKey: dateKey,
      createdAt: start,
      updatedAt: start,
    );
  }

  group('minutesPerDay', () {
    test('sums per day and fills empty days with zero', () {
      final result = calculator.minutesPerDay(
        sessions: [
          session('2026-11-14'),
          session('2026-11-14', hour: 15, minutes: 10),
          session('2026-11-16', minutes: 50),
        ],
        fromDate: '2026-11-14',
        toDate: '2026-11-16',
      );
      expect(result, {'2026-11-14': 35, '2026-11-15': 0, '2026-11-16': 50});
    });

    test('ignores breaks and sessions outside the range', () {
      final result = calculator.minutesPerDay(
        sessions: [
          session('2026-11-14', type: FocusSessionType.shortBreak),
          session('2026-11-10'),
        ],
        fromDate: '2026-11-14',
        toDate: '2026-11-15',
      );
      expect(result, {'2026-11-14': 0, '2026-11-15': 0});
    });
  });

  group('totals', () {
    final sessions = [
      session('2026-11-14'),
      session('2026-11-15', minutes: 10),
      session('2026-11-15', type: FocusSessionType.longBreak, minutes: 15),
    ];

    test('totalSessions counts focus blocks only', () {
      expect(calculator.totalSessions(sessions), 2);
    });

    test('totalMinutes sums focus minutes only', () {
      expect(calculator.totalMinutes(sessions), 35);
    });
  });

  group('bestHour', () {
    test('returns the hour with the most minutes', () {
      final hour = calculator.bestHour([
        session('2026-11-14'),
        session('2026-11-15'),
        session('2026-11-15', hour: 15, minutes: 40),
      ]);
      expect(hour, 9);
    });

    test('a tie goes to the earlier hour', () {
      final hour = calculator.bestHour([
        session('2026-11-14', hour: 14, minutes: 30),
        session('2026-11-14', hour: 10, minutes: 30),
      ]);
      expect(hour, 10);
    });

    test('uses the hour in the user timezone', () {
      const cairo = FocusStatsCalculator(timezone: 'Africa/Cairo');
      // 07:00 UTC is 09:00 in Cairo in November.
      final hour = cairo.bestHour([session('2026-11-16', hour: 7)]);
      expect(hour, 9);
    });

    test('returns null when there are no focus sessions', () {
      expect(calculator.bestHour([]), isNull);
    });
  });

  group('focusDayStreak', () {
    test('counts consecutive days including today', () {
      final streak = calculator.focusDayStreak(
        sessions: [
          session('2026-11-14'),
          session('2026-11-15'),
          session('2026-11-16'),
        ],
        today: '2026-11-16',
      );
      expect(streak, 3);
    });

    test('today with no session yet does not break the streak', () {
      final streak = calculator.focusDayStreak(
        sessions: [session('2026-11-14'), session('2026-11-15')],
        today: '2026-11-16',
      );
      expect(streak, 2);
    });

    test('a missed day breaks the streak', () {
      final streak = calculator.focusDayStreak(
        sessions: [
          session('2026-11-12'),
          session('2026-11-14'),
          session('2026-11-15'),
        ],
        today: '2026-11-15',
      );
      expect(streak, 2);
    });

    test('continues across a month boundary', () {
      final streak = calculator.focusDayStreak(
        sessions: [session('2026-10-31'), session('2026-11-01')],
        today: '2026-11-01',
      );
      expect(streak, 2);
    });

    test('breaks and empty history give zero', () {
      expect(calculator.focusDayStreak(sessions: [], today: '2026-11-16'), 0);
      expect(
        calculator.focusDayStreak(
          sessions: [session('2026-11-16', type: FocusSessionType.shortBreak)],
          today: '2026-11-16',
        ),
        0,
      );
    });
  });
}
