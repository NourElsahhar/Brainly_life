// The contract other features use to create a habit (owner: M4).
//
// Used by M5's AI assistant: when the user confirms a create_habit action,
// it fills a HabitDraft and calls createHabit.
//
//   final result = await getIt<HabitCreationPort>().createHabit(
//     const HabitDraft(name: 'Drink water'),
//   );
//
// Other features may import this file, but not habit_model.dart, so
// HabitFrequencyType is exported from here.

import 'package:brainly_life/core/errors/result.dart';
import 'package:equatable/equatable.dart';

import 'package:brainly_life/features/habits/data/models/habit_model.dart'
    show HabitFrequencyType;

export 'package:brainly_life/features/habits/data/models/habit_model.dart'
    show HabitFrequencyType;

/// What another feature knows about a habit it wants to create.
///
/// The habits feature fills in the rest: id, icon, color, start date
/// (today in the user's timezone) and the dates.
class HabitDraft extends Equatable {
  const HabitDraft({
    required this.name,
    this.frequencyType = HabitFrequencyType.daily,
    this.weekdays = const [],
    this.timesPerWeek,
  });

  /// Required. At most 50 characters. Must not match an active habit.
  final String name;

  final HabitFrequencyType frequencyType;

  /// 1 = Monday ... 7 = Sunday. Required (not empty) for `weekdays`.
  final List<int> weekdays;

  /// 1 to 7. Required for `timesPerWeek`.
  final int? timesPerWeek;

  @override
  List<Object?> get props => [name, frequencyType, weekdays, timesPerWeek];
}

abstract class HabitCreationPort {
  /// Creates a habit from [draft] and returns the new habit's id.
  ///
  /// Returns a ValidationFailure when the draft breaks a rule (empty or too
  /// long name, a name already used, no weekdays, times per week not 1-7).
  Future<Result<String>> createHabit(HabitDraft draft);
}
