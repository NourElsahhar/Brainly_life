// HabitFormCubit drives the add/edit habit form. Pass an existing [habit] to
// edit it, or nothing to create a new one. Validation errors are put in the
// state so the screen shows them under each field (never in a snackbar).
// `timezone` is the user's timezone, used for the default start date (today).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitFormCubit extends Cubit<HabitFormState> {
  HabitFormCubit({
    required HabitRepository repository,
    required String timezone,
    Habit? habit,
  }) : _repository = repository,
       _original = habit,
       super(_initialState(habit, timezone));

  static const String defaultIcon = 'check';
  static const int defaultColorValue = 0xFF4CAF50;
  static const int _defaultTimesPerWeek = 3;

  // these messages move to core/constants/app_strings.dart.
  static const String _nameTakenMessage =
      'You already have an active habit with this name.';
  static const String _weekdaysMessage = 'Choose at least one day.';
  static const String _timesPerWeekMessage = 'Choose a number from 1 to 7.';

  final HabitRepository _repository;
  final Habit? _original;

  static HabitFormState _initialState(Habit? habit, String timezone) {
    if (habit == null) {
      return HabitFormState(
        name: '',
        icon: defaultIcon,
        colorValue: defaultColorValue,
        frequencyType: HabitFrequencyType.daily,
        weekdays: const [],
        timesPerWeek: _defaultTimesPerWeek,
        startDate: DateKeyUtils.todayKey(timezone: timezone),
      );
    }
    return HabitFormState(
      habitId: habit.id,
      name: habit.name,
      icon: habit.icon,
      colorValue: habit.colorValue,
      frequencyType: habit.frequencyType,
      weekdays: habit.weekdays,
      timesPerWeek: habit.timesPerWeek ?? _defaultTimesPerWeek,
      startDate: habit.startDate,
    );
  }

  void nameChanged(String value) =>
      _update((s) => s.copyWith(name: value, clearNameError: true));

  void iconChanged(String value) => _update((s) => s.copyWith(icon: value));

  void colorChanged(int value) => _update((s) => s.copyWith(colorValue: value));

  void frequencyChanged(HabitFrequencyType value) => _update(
    (s) => s.copyWith(
      frequencyType: value,
      clearWeekdaysError: true,
      clearTimesPerWeekError: true,
    ),
  );

  /// Adds the day if it is not selected, removes it if it is.
  void weekdayToggled(int day) => _update((s) {
    final days = [...s.weekdays];
    days.contains(day) ? days.remove(day) : days.add(day);
    days.sort();
    return s.copyWith(weekdays: days, clearWeekdaysError: true);
  });

  void timesPerWeekChanged(int value) => _update(
    (s) => s.copyWith(timesPerWeek: value, clearTimesPerWeekError: true),
  );

  void startDateChanged(String dateKey) =>
      _update((s) => s.copyWith(startDate: dateKey));

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final nameError = Validators.lengthBetween(
      state.name.trim(),
      min: 1,
      max: Habit.maxNameLength,
      fieldName: 'Name',
    );
    final weekdaysError =
        state.frequencyType == HabitFrequencyType.weekdays &&
            state.weekdays.isEmpty
        ? _weekdaysMessage
        : null;
    final timesPerWeekError =
        state.frequencyType == HabitFrequencyType.timesPerWeek &&
            (state.timesPerWeek < Habit.minTimesPerWeek ||
                state.timesPerWeek > Habit.maxTimesPerWeek)
        ? _timesPerWeekMessage
        : null;

    if (nameError != null ||
        weekdaysError != null ||
        timesPerWeekError != null) {
      emit(
        state.copyWith(
          nameError: nameError,
          weekdaysError: weekdaysError,
          timesPerWeekError: timesPerWeekError,
          clearNameError: nameError == null,
          clearWeekdaysError: weekdaysError == null,
          clearTimesPerWeekError: timesPerWeekError == null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: HabitFormStatus.submitting, clearFailure: true),
    );

    final habitsResult = await _repository.getHabits();
    if (isClosed) return;
    if (habitsResult case Failed(:final failure)) {
      emit(state.copyWith(status: HabitFormStatus.failed, failure: failure));
      return;
    }

    final name = state.name.trim().toLowerCase();
    final isTaken = (habitsResult.dataOrNull ?? const <Habit>[]).any(
      (habit) =>
          habit.id != state.habitId && habit.name.trim().toLowerCase() == name,
    );
    if (isTaken) {
      emit(
        state.copyWith(
          status: HabitFormStatus.editing,
          nameError: _nameTakenMessage,
        ),
      );
      return;
    }

    final habit = _buildHabit(clock.now().toUtc());
    final failure = state.isEditing
        ? (await _repository.updateHabit(habit)).failureOrNull
        : (await _repository.createHabit(habit)).failureOrNull;
    if (isClosed) return;

    if (failure != null) {
      emit(state.copyWith(status: HabitFormStatus.failed, failure: failure));
    } else {
      emit(state.copyWith(status: HabitFormStatus.saved));
    }
  }

  /// Applies a field change. Ignored while saving. Editing again after a
  /// failed save goes back to the editing status.
  void _update(HabitFormState Function(HabitFormState state) change) {
    if (state.isSubmitting) return;
    emit(
      change(state)
          .copyWith(status: HabitFormStatus.editing, clearFailure: true),
    );
  }

  Habit _buildHabit(DateTime now) {
    final isWeekdays = state.frequencyType == HabitFrequencyType.weekdays;
    final isWeekly = state.frequencyType == HabitFrequencyType.timesPerWeek;
    final weekdays = isWeekdays ? ([...state.weekdays]..sort()) : <int>[];
    final timesPerWeek = isWeekly ? state.timesPerWeek : null;

    final original = _original;
    if (original == null) {
      return Habit(
        id: '',
        name: state.name.trim(),
        icon: state.icon,
        colorValue: state.colorValue,
        frequencyType: state.frequencyType,
        weekdays: weekdays,
        timesPerWeek: timesPerWeek,
        startDate: state.startDate,
        createdAt: now,
        updatedAt: now,
      );
    }
    return original.copyWith(
      name: state.name.trim(),
      icon: state.icon,
      colorValue: state.colorValue,
      frequencyType: state.frequencyType,
      weekdays: weekdays,
      timesPerWeek: timesPerWeek,
      clearTimesPerWeek: timesPerWeek == null,
      startDate: state.startDate,
      updatedAt: now,
    );
  }
}
