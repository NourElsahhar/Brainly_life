import 'package:brainly_life/features/analytics/data/models/analytics_models.dart';
import 'package:brainly_life/features/analytics/logic/iana_analytics_calendar.dart';
import 'package:brainly_life/features/analytics/logic/productivity_score.dart';
import 'package:brainly_life/features/analytics/logic/weekly_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  test('Timezone converts the week boundary and honors exclusive end', () {
    final calendar = ianaAnalyticsCalendar(
      timezone: 'Africa/Cairo',
      weekStartDay: DateTime.monday,
    );
    final week = calendar.weekContaining(DateTime.utc(2026, 1, 4, 22));
    expect(week.key, '2026-W02');
    expect(week.days.first, '2026-01-05');
    expect(week.startUtc, DateTime.utc(2026, 1, 4, 22));
    expect(week.contains(week.endUtc), isFalse);
    expect(week.contains(week.startUtc), isTrue);
  });

  test('Week through a daylight-saving transition uses local midnights', () {
    final calendar = ianaAnalyticsCalendar(
      timezone: 'America/New_York',
      weekStartDay: DateTime.monday,
    );
    final week = calendar.weekContaining(DateTime.utc(2026, 3, 7, 12));
    expect(week.endUtc.difference(week.startUtc), const Duration(hours: 167));
    expect(week.days.length, 7);
  });

  test('Empty weeks have no score and available weights are normalized', () {
    final calendar = ianaAnalyticsCalendar(
      timezone: 'UTC',
      weekStartDay: DateTime.monday,
    );
    final now = DateTime.utc(2026, 1, 10);
    final week = calendar.weekContaining(now);
    final calculator = const WeeklyStatsCalculator();
    final empty = calculator.calculate(
      AnalyticsInput(),
      week,
      now: now,
      dateKey: calendar.dateKey,
    );
    expect(empty.isEmpty, isTrue);
    expect(const ProductivityScore().calculate(empty), isNull);
    final stats = calculator.calculate(
      AnalyticsInput(
        tasks: [
          TaskStat(createdAt: week.startUtc, dueAt: week.startUtc),
          TaskStat(createdAt: week.startUtc, completedAt: week.startUtc),
          TaskStat(createdAt: week.endUtc, completedAt: week.endUtc),
        ],
        study: const [StudyStat(subject: 'Math', planned: 30, actual: 30)],
      ),
      week,
      now: now,
      dateKey: calendar.dateKey,
    );
    expect(stats.tasksCreated, 2);
    expect(stats.tasksCompleted, 1);
    expect(stats.tasksOverdue, 1);
    expect(stats.studyBySubject, {'Math': 30});
    expect(const ProductivityScore().calculate(stats), 71);
  });
}
