// RepositoryHabitCreationPort = HabitCreationPort on top of HabitRepository.
// It checks the draft with the same rules as the habit form, then saves it.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_creation_port.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_form_cubit.dart';
import 'package:clock/clock.dart';

class RepositoryHabitCreationPort implements HabitCreationPort {
  RepositoryHabitCreationPort(
    this._repository, {
    required String Function() timezone,
    DateTime Function()? now,
  }) : _timezone = timezone,
       _now = now ?? clock.now;

  final HabitRepository _repository;
  final String Function() _timezone;
  final DateTime Function() _now;

  @override
  Future<Result<String>> createHabit(HabitDraft draft) async {
    final name = draft.name.trim();
    final weekdays = draft.weekdays.toSet().toList()..sort();

    final problem = _check(
      name,
      draft.frequencyType,
      weekdays,
      draft.timesPerWeek,
    );
    if (problem != null) {
      return Result.failure(ValidationFailure(userMessage: problem));
    }

    // Same rule as the form: no two active habits with the same name.
    final existing = await _repository.getHabits();
    if (existing case Failed(:final failure)) return Result.failure(failure);
    final lower = name.toLowerCase();
    final taken = (existing.dataOrNull ?? const <Habit>[]).any(
      (habit) => habit.name.trim().toLowerCase() == lower,
    );
    if (taken) {
      return const Result.failure(
        ValidationFailure(
          userMessage: 'You already have a habit with this name.',
        ),
      );
    }

    final now = _now().toUtc();
    final habit = Habit(
      id: '', // the repository gives the real id
      name: name,
      icon: HabitFormCubit.defaultIcon,
      colorValue: HabitFormCubit.defaultColorValue,
      frequencyType: draft.frequencyType,
      weekdays: draft.frequencyType == HabitFrequencyType.weekdays
          ? weekdays
          : const [],
      timesPerWeek: draft.frequencyType == HabitFrequencyType.timesPerWeek
          ? draft.timesPerWeek
          : null,
      startDate: DateKeyUtils.toDateKey(now, timezone: _timezone()),
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createHabit(habit);
    return result.fold(
      onSuccess: (saved) => Result.success(saved.id),
      onFailure: (failure) => Result.failure(failure),
    );
  }

  /// A message for the user when the draft breaks a rule, otherwise null.
  static String? _check(
    String name,
    HabitFrequencyType type,
    List<int> weekdays,
    int? timesPerWeek,
  ) {
    if (name.isEmpty) return 'Please enter a habit name.';
    if (name.length > Habit.maxNameLength) {
      return 'The name can be at most ${Habit.maxNameLength} characters.';
    }
    switch (type) {
      case HabitFrequencyType.daily:
        return null;
      case HabitFrequencyType.weekdays:
        if (weekdays.isEmpty) return 'Please choose at least one day.';
        if (weekdays.any((day) => day < 1 || day > 7)) {
          return 'Days must be between Monday and Sunday.';
        }
        return null;
      case HabitFrequencyType.timesPerWeek:
        final times = timesPerWeek;
        if (times == null ||
            times < Habit.minTimesPerWeek ||
            times > Habit.maxTimesPerWeek) {
          return 'Times per week must be between '
              '${Habit.minTimesPerWeek} and ${Habit.maxTimesPerWeek}.';
        }
        return null;
    }
  }
}
