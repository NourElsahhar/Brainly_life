import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/home/data/repositories/mock_home_summary_providers.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MockTaskSummaryProvider returns its sample summary', () async {
    final result = await MockTaskSummaryProvider().todaySummary();

    expect(result.dataOrNull!.dueTodayCount, 3);
    expect(result.dataOrNull!.nextTaskTitle, 'Email the supervisor');
  });

  test('MockStudySummaryProvider without a session returns null', () async {
    final result = await MockStudySummaryProvider().nextSession();

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, isNull);
  });

  test('MockStudySummaryProvider.withSampleData starts in 2 hours', () async {
    final now = DateTime.utc(2026, 11, 15, 13);
    final provider = withClock(
      Clock.fixed(now),
      () => MockStudySummaryProvider.withSampleData(),
    );

    final result = await provider.nextSession();

    expect(result.dataOrNull!.startAt, now.add(const Duration(hours: 2)));
  });

  test('MockHabitSummaryProvider returns its sample summary', () async {
    final result = await MockHabitSummaryProvider().todaySummary();

    expect(result.dataOrNull!.bestCurrentStreak, 5);
  });

  test('MockFocusSummaryProvider returns its sample summary', () async {
    final result = await MockFocusSummaryProvider().todaySummary();

    expect(result.dataOrNull!.minutesToday, 50);
  });

  test('MockAiTipProvider returns its tip', () async {
    final result = await MockAiTipProvider(tip: 'Drink water').dailyTip();

    expect(result.dataOrNull, 'Drink water');
  });

  test('every mock returns its failWith', () async {
    const failure = NetworkFailure();

    final results = [
      await MockTaskSummaryProvider(failWith: failure).todaySummary(),
      await MockStudySummaryProvider(failWith: failure).nextSession(),
      await MockHabitSummaryProvider(failWith: failure).todaySummary(),
      await MockFocusSummaryProvider(failWith: failure).todaySummary(),
      await MockAiTipProvider(failWith: failure).dailyTip(),
    ];

    for (final result in results) {
      expect(result.failureOrNull, failure);
    }
  });
}
