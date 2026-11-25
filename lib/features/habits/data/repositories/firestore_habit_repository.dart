// FirestoreHabitRepository = the real HabitRepository (owner: M4).
// The logic lives here; the Firestore calls are in HabitRemoteDataSource.
// Every exception becomes a Result.failure with a friendly message
// (FirebaseErrorMapper).
//
// Toggling a day:
//   1. read the habit and every day it was done
//   2. add or remove [dateKey]
//   3. calculate the streak again (StreakCalculator, the user's week start)
//   4. ONE transaction writes the log and the new numbers on the habit
//
// "today" for the streak is the user's day (settings.timezone). A day in the
// future (should not happen) counts as today, like the mock.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/datasources/habit_remote_data_source.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/streak_calculator.dart';
import 'package:clock/clock.dart';

class FirestoreHabitRepository implements HabitRepository {
  FirestoreHabitRepository({
    required HabitRemoteDataSource dataSource,
    required String Function() timezone,
    required int Function() weekStartDay,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _timezone = timezone,
       _weekStartDay = weekStartDay,
       _now = now ?? (() => clock.now().toUtc());

  final HabitRemoteDataSource _dataSource;
  final String Function() _timezone;
  final int Function() _weekStartDay;
  final DateTime Function() _now;

  @override
  Future<Result<List<Habit>>> getHabits({bool includeArchived = false}) =>
      _run('Load habits', () async {
        final habits = await _dataSource.getHabits();
        return habits
            .where((habit) => includeArchived || !habit.archived)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

  @override
  Future<Result<Habit>> createHabit(Habit habit) => _run('Create habit', () {
    final now = _now();
    return _dataSource.createHabit(
      habit.copyWith(createdAt: now, updatedAt: now),
    );
  });

  @override
  Future<Result<void>> updateHabit(Habit habit) => _run(
    'Update habit',
    () => _dataSource.updateHabit(habit.copyWith(updatedAt: _now())),
  );

  @override
  Future<Result<void>> archiveHabit(String habitId) =>
      _run('Archive habit', () => _dataSource.archiveHabit(habitId, _now()));

  @override
  Future<Result<void>> deleteHabit(String habitId) =>
      _run('Delete habit', () => _dataSource.deleteHabit(habitId));

  @override
  Future<Result<List<HabitLog>>> getLogs({
    required String fromDate,
    required String toDate,
    String? habitId,
  }) => _run(
    'Load habit logs',
    () => _dataSource.getLogs(
      fromDate: fromDate,
      toDate: toDate,
      habitId: habitId,
    ),
  );

  @override
  Future<Result<bool>> toggleCompletion({
    required String habitId,
    required String dateKey,
  }) => _run('Toggle habit', () async {
    final habit = await _dataSource.getHabit(habitId);
    if (habit == null) throw const NotFoundFailure();

    final dates = await _dataSource.completedDates(habitId);
    final done = !dates.contains(dateKey);
    if (done) {
      dates.add(dateKey);
    } else {
      dates.remove(dateKey);
    }

    final realToday = DateKeyUtils.todayKey(timezone: _timezone());
    final today = dateKey.compareTo(realToday) > 0 ? dateKey : realToday;
    final streak = StreakCalculator(weekStartDay: _weekStartDay())
        .calculate(habit: habit, completedDates: dates, today: today);
    final lastDone = dates.isEmpty ? null : (dates.toList()..sort()).last;

    await _dataSource.writeToggle(
      habitId: habitId,
      dateKey: dateKey,
      done: done,
      now: _now(),
      currentStreak: streak.currentStreak,
      bestStreak: streak.bestStreak,
      lastCompletedDate: lastDone,
    );
    return done;
  });

  /// Runs [action]; any exception becomes a Failure.
  Future<Result<T>> _run<T>(String name, Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } catch (error) {
      final failure = FirebaseErrorMapper.map(error);
      AppLogger.warning(
        '$name failed (${failure.code ?? failure.runtimeType})',
        tag: 'Habits',
      );
      return Result.failure(failure);
    }
  }
}
