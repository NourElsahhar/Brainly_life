// HabitProfileStreakSource = the habits side of the Profile "day streak".
// It is the best current streak among the active habits (the same number
// the habit cards show).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';

class HabitProfileStreakSource implements ProfileStreakSource {
  HabitProfileStreakSource(HabitRepository repository)
    : _repository = repository;

  final HabitRepository _repository;

  @override
  Future<Result<int>> streakDays() async {
    final result = await _repository.getHabits();
    return result.fold(
      onSuccess: (habits) => Result.success(
        habits.fold<int>(
          0,
          (best, habit) =>
              habit.currentStreak > best ? habit.currentStreak : best,
        ),
      ),
      onFailure: (failure) => Result.failure(failure),
    );
  }
}
