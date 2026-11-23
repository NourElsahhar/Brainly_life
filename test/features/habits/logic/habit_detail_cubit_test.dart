// Tests for HabitDetailCubit: streaks and rates, habit not found, month
// navigation limits, archive, delete, and a failing archive.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingArchiveRepository extends MockHabitRepository {
  _FailingArchiveRepository({required super.habits});

  @override
  Future<Result<void>> archiveHabit(String habitId) async =>
      const Result.failure(NetworkFailure());
}

void main() {
  /// Runs [body] with the clock fixed on 2026-11-16.
  Future<void> at(Future<void> Function() body) =>
      withClock(Clock.fixed(DateTime.utc(2026, 11, 16, 10)), body);

  Habit habit({String startDate = '2026-11-01'}) {
    return Habit(
      id: 'h1',
      name: 'Read',
      icon: 'book',
      colorValue: 0xFF2196F3,
      startDate: startDate,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  List<HabitLog> logs(List<String> days) => [
    for (final day in days)
      HabitLog(
        habitId: 'h1',
        date: day,
        completedAt: DateTime.utc(2026, 11, 14, 18),
      ),
  ];

  HabitDetailCubit buildCubit(HabitRepository repository) =>
      HabitDetailCubit(repository: repository, habitId: 'h1', timezone: 'UTC');

  MockHabitRepository threeDays({String startDate = '2026-11-01'}) =>
      MockHabitRepository(
        habits: [habit(startDate: startDate)],
        logs: logs(['2026-11-13', '2026-11-14', '2026-11-15']),
      );

  Matcher monthIs(String monthStart) => isA<HabitDetailLoaded>().having(
    (s) => s.monthStart,
    'monthStart',
    monthStart,
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'load emits loading then the streaks and completion rates',
    build: () => buildCubit(threeDays()),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [
      const HabitDetailLoading(),
      isA<HabitDetailLoaded>()
          .having((s) => s.currentStreak, 'currentStreak', 3)
          .having((s) => s.bestStreak, 'bestStreak', 3)
          .having((s) => s.rate7, 'rate7', closeTo(0.5, 1e-9))
          .having((s) => s.rate30, 'rate30', closeTo(0.2, 1e-9))
          .having((s) => s.monthStart, 'monthStart', '2026-11-01')
          .having((s) => s.canGoPrevious, 'canGoPrevious', false)
          .having((s) => s.canGoNext, 'canGoNext', false),
    ],
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'load emits an error when the habit does not exist',
    build: () => buildCubit(MockHabitRepository()),
    act: (cubit) => at(() => cubit.load()),
    expect: () => [
      const HabitDetailLoading(),
      const HabitDetailError(NotFoundFailure()),
    ],
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'months can be changed only between the start month and this month',
    build: () => buildCubit(threeDays(startDate: '2026-09-15')),
    act: (cubit) => at(() async {
      await cubit.load();
      cubit.previousMonth();
      cubit.previousMonth();
      cubit.previousMonth();
      cubit.nextMonth();
    }),
    skip: 2,
    expect: () => [
      monthIs('2026-10-01'),
      monthIs('2026-09-01'),
      monthIs('2026-10-01'),
    ],
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'archive closes the screen and archives the habit',
    build: () => buildCubit(threeDays()),
    act: (cubit) => at(() async {
      await cubit.load();
      await cubit.archive();
    }),
    skip: 2,
    expect: () => [const HabitDetailRemoved()],
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'delete closes the screen',
    build: () => buildCubit(threeDays()),
    act: (cubit) => at(() async {
      await cubit.load();
      await cubit.delete();
    }),
    skip: 2,
    expect: () => [const HabitDetailRemoved()],
  );

  blocTest<HabitDetailCubit, HabitDetailState>(
    'a failing archive keeps the screen open and reports the failure',
    build: () => buildCubit(_FailingArchiveRepository(habits: [habit()])),
    act: (cubit) => at(() async {
      await cubit.load();
      await cubit.archive();
    }),
    skip: 2,
    expect: () => [
      isA<HabitDetailLoaded>().having(
        (s) => s.actionFailure,
        'actionFailure',
        const NetworkFailure(),
      ),
    ],
  );
}
