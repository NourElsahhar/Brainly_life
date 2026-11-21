// Tests for HabitFormCubit: defaults, inline validation errors, duplicate
// names, creating, editing and a failing save.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_form_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingCreateRepository extends MockHabitRepository {
  @override
  Future<Result<Habit>> createHabit(Habit habit) async =>
      const Result.failure(NetworkFailure());
}

void main() {
  final fixed = Clock.fixed(DateTime.utc(2026, 11, 16, 10));

  Future<void> at(Future<void> Function() body) => withClock(fixed, body);

  final existing = Habit(
    id: 'h1',
    name: 'Read',
    icon: 'book',
    colorValue: 0xFF2196F3,
    startDate: '2026-11-01',
    createdAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  late MockHabitRepository repository;

  setUp(() {
    repository = MockHabitRepository(habits: [existing]);
  });

  HabitFormCubit createCubit({HabitRepository? repo, Habit? habit}) {
    return withClock(
      fixed,
      () => HabitFormCubit(
        repository: repo ?? repository,
        timezone: 'UTC',
        habit: habit,
      ),
    );
  }

  Matcher hasStatus(HabitFormStatus value) =>
      isA<HabitFormState>().having((s) => s.status, 'status', value);

  test('create mode starts with defaults and today as the start date', () {
    final state = createCubit().state;
    expect(state.isEditing, isFalse);
    expect(state.name, '');
    expect(state.frequencyType, HabitFrequencyType.daily);
    expect(state.startDate, '2026-11-16');
  });

  test('edit mode starts with the values of the habit', () {
    final state = createCubit(habit: existing).state;
    expect(state.isEditing, isTrue);
    expect(state.habitId, 'h1');
    expect(state.name, 'Read');
    expect(state.startDate, '2026-11-01');
  });

  blocTest<HabitFormCubit, HabitFormState>(
    'submit with an empty name shows the error under the field',
    build: createCubit,
    act: (cubit) => at(() => cubit.submit()),
    expect: () => [
      isA<HabitFormState>()
          .having((s) => s.nameError, 'nameError', isNotNull)
          .having((s) => s.status, 'status', HabitFormStatus.editing),
    ],
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'weekdays habit without a chosen day shows an error',
    build: createCubit,
    act: (cubit) => at(() async {
      cubit.nameChanged('Gym');
      cubit.frequencyChanged(HabitFrequencyType.weekdays);
      await cubit.submit();
    }),
    skip: 2,
    expect: () => [
      isA<HabitFormState>().having(
        (s) => s.weekdaysError,
        'weekdaysError',
        isNotNull,
      ),
    ],
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'times per week outside 1 to 7 shows an error',
    build: createCubit,
    act: (cubit) => at(() async {
      cubit.nameChanged('Gym');
      cubit.frequencyChanged(HabitFrequencyType.timesPerWeek);
      cubit.timesPerWeekChanged(8);
      await cubit.submit();
    }),
    skip: 3,
    expect: () => [
      isA<HabitFormState>().having(
        (s) => s.timesPerWeekError,
        'timesPerWeekError',
        isNotNull,
      ),
    ],
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'an active habit with the same name is rejected',
    build: createCubit,
    act: (cubit) => at(() async {
      cubit.nameChanged('  read ');
      await cubit.submit();
    }),
    skip: 1,
    expect: () => [
      hasStatus(HabitFormStatus.submitting),
      isA<HabitFormState>()
          .having((s) => s.nameError, 'nameError', isNotNull)
          .having((s) => s.status, 'status', HabitFormStatus.editing),
    ],
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'a valid new habit is saved',
    build: createCubit,
    act: (cubit) => at(() async {
      cubit.nameChanged('Meditate');
      await cubit.submit();
    }),
    skip: 1,
    expect: () => [
      hasStatus(HabitFormStatus.submitting),
      hasStatus(HabitFormStatus.saved),
    ],
    verify: (_) async {
      final habits = (await repository.getHabits()).dataOrNull!;
      expect(habits.map((habit) => habit.name), ['Read', 'Meditate']);
    },
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'editing a habit may keep its own name',
    build: () => createCubit(habit: existing),
    act: (cubit) => at(() => cubit.submit()),
    expect: () => [
      hasStatus(HabitFormStatus.submitting),
      hasStatus(HabitFormStatus.saved),
    ],
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'editing a habit updates it in the repository',
    build: () => createCubit(habit: existing),
    act: (cubit) => at(() async {
      cubit.nameChanged('Read more');
      await cubit.submit();
    }),
    skip: 1,
    expect: () => [
      hasStatus(HabitFormStatus.submitting),
      hasStatus(HabitFormStatus.saved),
    ],
    verify: (_) async {
      final habits = (await repository.getHabits()).dataOrNull!;
      expect(habits.single.name, 'Read more');
    },
  );

  blocTest<HabitFormCubit, HabitFormState>(
    'a failing save reports the failure',
    build: () => createCubit(repo: _FailingCreateRepository()),
    act: (cubit) => at(() async {
      cubit.nameChanged('Gym');
      await cubit.submit();
    }),
    skip: 1,
    expect: () => [
      hasStatus(HabitFormStatus.submitting),
      isA<HabitFormState>()
          .having((s) => s.status, 'status', HabitFormStatus.failed)
          .having((s) => s.failure, 'failure', const NetworkFailure()),
    ],
  );
}
