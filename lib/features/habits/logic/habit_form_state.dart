// State of the add/edit habit form: the field values, the error shown under
// each field, and the submit status (editing, submitting, saved, failed).

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:equatable/equatable.dart';

enum HabitFormStatus { editing, submitting, saved, failed }

class HabitFormState extends Equatable {
  const HabitFormState({
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.frequencyType,
    required this.weekdays,
    required this.timesPerWeek,
    required this.startDate,
    this.habitId,
    this.nameError,
    this.weekdaysError,
    this.timesPerWeekError,
    this.status = HabitFormStatus.editing,
    this.failure,
  });

  /// Null when creating a new habit.
  final String? habitId;

  final String name;
  final String icon;
  final int colorValue;
  final HabitFrequencyType frequencyType;

  /// Days of the week (1 = Monday ... 7 = Sunday).
  final List<int> weekdays;

  final int timesPerWeek;

  /// First day of the habit, as a dateKey.
  final String startDate;

  /// Errors shown below the matching field.
  final String? nameError;
  final String? weekdaysError;
  final String? timesPerWeekError;

  final HabitFormStatus status;

  /// Set when saving failed.
  final Failure? failure;

  bool get isEditing => habitId != null;

  bool get isSubmitting => status == HabitFormStatus.submitting;

  HabitFormState copyWith({
    String? name,
    String? icon,
    int? colorValue,
    HabitFrequencyType? frequencyType,
    List<int>? weekdays,
    int? timesPerWeek,
    String? startDate,
    String? nameError,
    String? weekdaysError,
    String? timesPerWeekError,
    HabitFormStatus? status,
    Failure? failure,
    bool clearNameError = false,
    bool clearWeekdaysError = false,
    bool clearTimesPerWeekError = false,
    bool clearFailure = false,
  }) {
    return HabitFormState(
      habitId: habitId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      frequencyType: frequencyType ?? this.frequencyType,
      weekdays: weekdays ?? this.weekdays,
      timesPerWeek: timesPerWeek ?? this.timesPerWeek,
      startDate: startDate ?? this.startDate,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      weekdaysError: clearWeekdaysError
          ? null
          : (weekdaysError ?? this.weekdaysError),
      timesPerWeekError: clearTimesPerWeekError
          ? null
          : (timesPerWeekError ?? this.timesPerWeekError),
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    habitId,
    name,
    icon,
    colorValue,
    frequencyType,
    weekdays,
    timesPerWeek,
    startDate,
    nameError,
    weekdaysError,
    timesPerWeekError,
    status,
    failure,
  ];
}
