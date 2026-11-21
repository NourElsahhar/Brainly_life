// Tests for DefaultHabitSummaryProvider: due and done counts, best streak,
// the empty state, and a failing repository.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_summary_provider.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepository extends MockHabitRepository {
  @override
  Future<Result<List<Habit>>> getHabits({bool includeArchived = false}) async =>
      const Result.failure(NetworkFailure());
}

void main() {
  // Monday 2026-11-16.
  final monday = Clock.fixed(DateTime.utc(2026, 11, 16, 10));

  Habit habit(
    String id, {
    HabitFrequencyType type = HabitFrequencyType.daily,
    List<int> weekdays = const [],
    int streak = 0,
  }) {
    return Habit(
      id: id,
      name: id,
      icon: 'book',
      colorValue: 0xFF2196F3,
      frequencyType: type,
      weekdays: weekdays,
      startDate: '2026-11-01',
      currentStreak: streak,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  Future<Result<HabitSummary>> summaryFor(MockHabitRepository repository) {
    return withClock(
      monday,
      () => DefaultHabitSummaryProvider(
        repository: repository,
        timezone: () => 'UTC',
      ).todaySummary(),
    );
  }

  test('counts habits due and done today and finds the best streak', () async {
    final repository = MockHabitRepository(
      habits: [
        habit('read', streak: 3),
        habit(
          'gym',
          type: HabitFrequencyType.weekdays,
          weekdays: const [2],
          streak: 7,
        ),
      ],
      logs: [
        HabitLog(
          habitId: 'read',
          date: '2026-11-16',
          completedAt: DateTime.utc(2026, 11, 16, 8),
        ),
      ],
    );

    final result = await summaryFor(repository);
    expect(
      result.dataOrNull,
      const HabitSummary(
        doneTodayCount: 1,
        dueTodayCount: 1,
        bestCurrentStreak: 7,
        bestStreakHabitName: 'gym',
      ),
    );
  });

  test('no habits gives an empty summary', () async {
    final result = await summaryFor(MockHabitRepository());
    final summary = result.dataOrNull!;
    expect(summary.isEmpty, isTrue);
    expect(summary.bestCurrentStreak, 0);
    expect(summary.bestStreakHabitName, isNull);
  });

  test('without any streak there is no best habit name', () async {
    final result = await summaryFor(
      MockHabitRepository(habits: [habit('read')]),
    );
    final summary = result.dataOrNull!;
    expect(summary.dueTodayCount, 1);
    expect(summary.doneTodayCount, 0);
    expect(summary.bestCurrentStreak, 0);
    expect(summary.bestStreakHabitName, isNull);
  });

  test('a failing repository returns the failure', () async {
    final result = await summaryFor(_FailingRepository());
    expect(result.failureOrNull, const NetworkFailure());
  });
}
