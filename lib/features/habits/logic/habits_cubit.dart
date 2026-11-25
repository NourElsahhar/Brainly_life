// HabitsCubit drives the "today's habits" screen: loads the habits due today
// and toggles them done/undone. The toggle is optimistic: the check shows
// immediately, and is rolled back (with a failure) if saving fails.
//
// `timezone` is the user's timezone (settings.timezone), for example
// 'Africa/Cairo'. `userName` gives the first name for the greeting (it is a
// function so this feature never imports the auth Cubit).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_schedule.dart';
import 'package:brainly_life/features/habits/logic/habits_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitsCubit extends Cubit<HabitsState> {
  HabitsCubit({
    required HabitRepository repository,
    required String timezone,
    String? Function()? userName,
  }) : _repository = repository,
       _timezone = timezone,
       _userName = userName,
       super(const HabitsInitial());

  final HabitRepository _repository;
  final String _timezone;
  final String? Function()? _userName;

  /// Loads today's habits. With [silent] true there is no loading state and
  /// errors are ignored (used to refresh after a toggle or after coming back
  /// from another screen).
  Future<void> loadHabits({bool silent = false}) async {
    if (!silent) emit(const HabitsLoading());
    final today = DateKeyUtils.todayKey(timezone: _timezone);

    final habitsResult = await _repository.getHabits();
    if (isClosed) return;
    if (habitsResult case Failed(:final failure)) {
      if (!silent) emit(HabitsError(failure));
      return;
    }

    final logsResult = await _repository.getLogs(
      fromDate: today,
      toDate: today,
    );
    if (isClosed) return;
    if (logsResult case Failed(:final failure)) {
      if (!silent) emit(HabitsError(failure));
      return;
    }

    final habits = habitsResult.dataOrNull ?? const <Habit>[];
    final doneIds = {
      for (final log in logsResult.dataOrNull ?? const <HabitLog>[])
        log.habitId,
    };

    if (habits.isEmpty) {
      emit(const HabitsEmpty());
      return;
    }
    emit(
      HabitsLoaded(
        today: today,
        userName: _userName?.call(),
        items: [
          for (final habit in habits)
            if (HabitSchedule.isDueOn(habit, today))
              HabitTodayItem(habit: habit, isDone: doneIds.contains(habit.id)),
        ],
      ),
    );
  }

  Future<void> toggleHabit(String habitId) async {
    final current = state;
    if (current is! HabitsLoaded) return;
    final index = current.items.indexWhere((item) => item.habit.id == habitId);
    if (index == -1) return;

    final flipped = [...current.items];
    flipped[index] = flipped[index].copyWith(isDone: !flipped[index].isDone);
    emit(
      HabitsLoaded(
        items: flipped,
        today: current.today,
        userName: current.userName,
      ),
    );

    final result = await _repository.toggleCompletion(
      habitId: habitId,
      dateKey: current.today,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        await loadHabits(silent: true);
      case Failed(:final failure):
        emit(
          HabitsLoaded(
            items: current.items,
            today: current.today,
            userName: current.userName,
            toggleFailure: failure,
          ),
        );
    }
  }
}
