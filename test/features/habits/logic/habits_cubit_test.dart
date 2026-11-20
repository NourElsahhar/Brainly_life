// Tests for HabitsCubit: loading today's habits, empty and error states,
// the optimistic toggle, and the rollback when saving fails.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habits_cubit.dart';
import 'package:brainly_life/features/habits/logic/habits_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingToggleRepository extends MockHabitRepository {
  _FailingToggleRepository({required super.habits});

  @override
  Future<Result<bool>> toggleCompletion({
    required String habitId,
    required String dateKey,
  }) async => const Result.failure(NetworkFailure());
}

class _FailingLoadRepository extends MockHabitRepository {
  @override
  Future<Result<List<Habit>>> getHabits({bool includeArchived = false}) async =>
      const Result.failure(NetworkFailure());
}

void main() {
  /// Runs [body] with the clock fixed on Monday 2026-11-16.
  Future<void> at(Future<void> Function() body) =>
      withClock(Clock.fixed(DateTime.utc(2026, 11, 16, 10)), body);

  Habit habit(
    String id, {
    HabitFrequencyType type = HabitFrequencyType.daily,
    List<int> weekdays = const [],
  }) {
    return Habit(
      id: id,
      name: id,
      icon: 'book',
      colorValue: 0xFF2196F3,
      frequencyType: type,
      weekdays: weekdays,
      startDate: '2026-11-01',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
  }

  blocTest<HabitsCubit, HabitsState>(
    'loadHabits emits loading then only the habits due today',
    build: () => HabitsCubit(
      repository: MockHabitRepository(
        habits: [
          habit('daily'),
          habit('tuesday', type: HabitFrequencyType.weekdays, weekdays: [2]),
        ],
      ),
      timezone: 'UTC',
    ),
    act: (cubit) => at(() => cubit.loadHabits()),
    expect: () => [
      const HabitsLoading(),
      isA<HabitsLoaded>()
          .having((s) => s.items.map((item) => item.habit.id).toList(), 'ids', [
            'daily',
          ])
          .having((s) => s.today, 'today', '2026-11-16'),
    ],
  );

  blocTest<HabitsCubit, HabitsState>(
    'loadHabits emits empty when the user has no habits',
    build: () =>
        HabitsCubit(repository: MockHabitRepository(), timezone: 'UTC'),
    act: (cubit) => at(() => cubit.loadHabits()),
    expect: () => [const HabitsLoading(), const HabitsEmpty()],
  );

  blocTest<HabitsCubit, HabitsState>(
    'loadHabits emits error when loading fails',
    build: () =>
        HabitsCubit(repository: _FailingLoadRepository(), timezone: 'UTC'),
    act: (cubit) => at(() => cubit.loadHabits()),
    expect: () => [const HabitsLoading(), const HabitsError(NetworkFailure())],
  );

  blocTest<HabitsCubit, HabitsState>(
    'toggleHabit marks the habit done, then refreshes the streak',
    build: () => HabitsCubit(
      repository: MockHabitRepository(habits: [habit('daily')]),
      timezone: 'UTC',
    ),
    act: (cubit) => at(() async {
      await cubit.loadHabits();
      await cubit.toggleHabit('daily');
    }),
    skip: 2,
    expect: () => [
      isA<HabitsLoaded>().having((s) => s.items.single.isDone, 'isDone', true),
      isA<HabitsLoaded>().having(
        (s) => s.items.single.habit.currentStreak,
        'currentStreak',
        1,
      ),
    ],
  );

  blocTest<HabitsCubit, HabitsState>(
    'toggleHabit rolls back and reports the failure when saving fails',
    build: () => HabitsCubit(
      repository: _FailingToggleRepository(habits: [habit('daily')]),
      timezone: 'UTC',
    ),
    act: (cubit) => at(() async {
      await cubit.loadHabits();
      await cubit.toggleHabit('daily');
    }),
    skip: 2,
    expect: () => [
      isA<HabitsLoaded>().having((s) => s.items.single.isDone, 'isDone', true),
      isA<HabitsLoaded>()
          .having((s) => s.items.single.isDone, 'isDone', false)
          .having(
            (s) => s.toggleFailure,
            'toggleFailure',
            const NetworkFailure(),
          ),
    ],
  );
}
