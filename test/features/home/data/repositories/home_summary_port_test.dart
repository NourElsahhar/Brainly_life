import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskSummary.isEmpty', () {
    test('is true when every count is zero', () {
      const summary = TaskSummary(
        dueTodayCount: 0,
        overdueCount: 0,
        completedTodayCount: 0,
      );

      expect(summary.isEmpty, isTrue);
    });

    test('is false when there are only overdue tasks', () {
      const summary = TaskSummary(
        dueTodayCount: 0,
        overdueCount: 1,
        completedTodayCount: 0,
      );

      expect(summary.isEmpty, isFalse);
    });

    test('is false when tasks were completed today', () {
      const summary = TaskSummary(
        dueTodayCount: 0,
        overdueCount: 0,
        completedTodayCount: 2,
      );

      expect(summary.isEmpty, isFalse);
    });
  });

  group('HabitSummary.isEmpty', () {
    test('is true when no habit is due today, even with a streak', () {
      const summary = HabitSummary(
        doneTodayCount: 0,
        dueTodayCount: 0,
        bestCurrentStreak: 4,
      );

      expect(summary.isEmpty, isTrue);
    });

    test('is false when a habit is due today', () {
      const summary = HabitSummary(
        doneTodayCount: 0,
        dueTodayCount: 1,
        bestCurrentStreak: 0,
      );

      expect(summary.isEmpty, isFalse);
    });
  });

  group('FocusSummary.isEmpty', () {
    test('is true when there was no session today', () {
      const summary = FocusSummary(minutesToday: 0, sessionsToday: 0);

      expect(summary.isEmpty, isTrue);
    });

    test('is false after one session', () {
      const summary = FocusSummary(minutesToday: 25, sessionsToday: 1);

      expect(summary.isEmpty, isFalse);
    });
  });

  test('summaries with the same values are equal', () {
    final startAt = DateTime.utc(2026, 11, 15, 15);

    expect(
      StudySummary(
        sessionId: 's1',
        subjectName: 'Math',
        topicTitle: 'Limits',
        startAt: startAt,
        plannedMinutes: 45,
      ),
      equals(
        StudySummary(
          sessionId: 's1',
          subjectName: 'Math',
          topicTitle: 'Limits',
          startAt: startAt,
          plannedMinutes: 45,
        ),
      ),
    );
  });
}
