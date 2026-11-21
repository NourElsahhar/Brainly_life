// DefaultHabitSummaryProvider feeds the "Habits" card on the Home dashboard:
// how many habits are due today, how many are done, and the longest current
// streak. Home only knows the HabitSummaryProvider contract.
// `timezone` returns the user's timezone (settings.timezone).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_schedule.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';

class DefaultHabitSummaryProvider implements HabitSummaryProvider {
  DefaultHabitSummaryProvider({
    required HabitRepository repository,
    required String Function() timezone,
  }) : _repository = repository,
       _timezone = timezone;

  final HabitRepository _repository;
  final String Function() _timezone;

  @override
  Future<Result<HabitSummary>> todaySummary() async {
    final today = DateKeyUtils.todayKey(timezone: _timezone());

    final habitsResult = await _repository.getHabits();
    if (habitsResult case Failed(:final failure)) {
      return Result.failure(failure);
    }
    final logsResult = await _repository.getLogs(
      fromDate: today,
      toDate: today,
    );
    if (logsResult case Failed(:final failure)) {
      return Result.failure(failure);
    }

    final habits = habitsResult.dataOrNull ?? const <Habit>[];
    final doneIds = {
      for (final log in logsResult.dataOrNull ?? const <HabitLog>[])
        log.habitId,
    };

    final dueHabits = habits
        .where((habit) => HabitSchedule.isDueOn(habit, today))
        .toList();
    final doneCount = dueHabits
        .where((habit) => doneIds.contains(habit.id))
        .length;

    // Stays null when no active habit has a streak yet.
    Habit? best;
    for (final habit in habits) {
      if (habit.currentStreak > (best?.currentStreak ?? 0)) best = habit;
    }

    return Result.success(
      HabitSummary(
        doneTodayCount: doneCount,
        dueTodayCount: dueHabits.length,
        bestCurrentStreak: best?.currentStreak ?? 0,
        bestStreakHabitName: best?.name,
      ),
    );
  }
}
