// HabitRepository is the contract (interface) for reading and writing
// habits and their daily logs. Cubits depend on this, not on Firebase.

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';

/// The contract for reading and writing habits and their daily logs.
abstract class HabitRepository {
  /// Returns the user's habits. Archived ones are skipped unless
  /// [includeArchived] is true.
  Future<Result<List<Habit>>> getHabits({bool includeArchived = false});

  /// Saves a new habit and returns it with its final id.
  Future<Result<Habit>> createHabit(Habit habit);

  Future<Result<void>> updateHabit(Habit habit);

  Future<Result<void>> archiveHabit(String habitId);

  /// Deletes the habit and all of its logs.
  Future<Result<void>> deleteHabit(String habitId);

  /// Returns logs between [fromDate] and [toDate] (both included,
  /// dateKeys). Pass [habitId] to get the logs of one habit only.
  Future<Result<List<HabitLog>>> getLogs({
    required String fromDate,
    required String toDate,
    String? habitId,
  });

  /// Completes the habit for [dateKey], or removes the completion if it
  /// is already done. Returns true if the day is now completed.
  Future<Result<bool>> toggleCompletion({
    required String habitId,
    required String dateKey,
  });
}
