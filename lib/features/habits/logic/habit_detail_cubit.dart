// HabitDetailCubit drives the habit detail screen. It loads all logs of the
// habit once, then calculates the streaks and completion rates, and the
// calendar month is changed locally. It also archives or deletes the habit
// (the screen asks for confirmation with ConfirmDialog first).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_state.dart';
import 'package:brainly_life/features/habits/logic/streak_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitDetailCubit extends Cubit<HabitDetailState> {
  HabitDetailCubit({
    required HabitRepository repository,
    required String habitId,
    required String timezone,
    int weekStartDay = DateTime.monday,
  }) : _repository = repository,
       _habitId = habitId,
       _timezone = timezone,
       _calculator = StreakCalculator(weekStartDay: weekStartDay),
       super(const HabitDetailInitial());

  final HabitRepository _repository;
  final String _habitId;
  final String _timezone;
  final StreakCalculator _calculator;

  Future<void> load() async {
    emit(const HabitDetailLoading());
    final today = DateKeyUtils.todayKey(timezone: _timezone);

    final habitsResult = await _repository.getHabits(includeArchived: true);
    if (isClosed) return;
    if (habitsResult case Failed(:final failure)) {
      emit(HabitDetailError(failure));
      return;
    }

    final habits = habitsResult.dataOrNull ?? const <Habit>[];
    final index = habits.indexWhere((habit) => habit.id == _habitId);
    if (index == -1) {
      emit(const HabitDetailError(NotFoundFailure()));
      return;
    }
    final habit = habits[index];

    final logsResult = await _repository.getLogs(
      fromDate: habit.startDate,
      toDate: today,
      habitId: _habitId,
    );
    if (isClosed) return;
    if (logsResult case Failed(:final failure)) {
      emit(HabitDetailError(failure));
      return;
    }

    final doneDates = {for (final log in logsResult.dataOrNull!) log.date};
    final streak = _calculator.calculate(
      habit: habit,
      completedDates: doneDates,
      today: today,
    );
    double rate(int days) => _calculator.completionRate(
      habit: habit,
      completedDates: doneDates,
      today: today,
      windowDays: days,
    );

    emit(
      HabitDetailLoaded(
        habit: habit,
        doneDates: doneDates,
        today: today,
        monthStart: firstDayOfMonthKey(today),
        currentStreak: streak.currentStreak,
        bestStreak: streak.bestStreak,
        rate7: rate(7),
        rate30: rate(30),
      ),
    );
  }

  void previousMonth() {
    final current = state;
    if (current is! HabitDetailLoaded || !current.canGoPrevious) return;
    emit(
      current.copyWith(
        monthStart: _shiftMonth(current.monthStart, -1),
        clearActionFailure: true,
      ),
    );
  }

  void nextMonth() {
    final current = state;
    if (current is! HabitDetailLoaded || !current.canGoNext) return;
    emit(
      current.copyWith(
        monthStart: _shiftMonth(current.monthStart, 1),
        clearActionFailure: true,
      ),
    );
  }

  Future<void> archive() => _remove(_repository.archiveHabit);

  Future<void> delete() => _remove(_repository.deleteHabit);

  Future<void> _remove(
    Future<Result<void>> Function(String habitId) action,
  ) async {
    final current = state;
    if (current is! HabitDetailLoaded) return;

    final result = await action(_habitId);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(const HabitDetailRemoved());
      case Failed(:final failure):
        emit(current.copyWith(actionFailure: failure));
    }
  }

  String _shiftMonth(String monthStart, int delta) {
    final date = DateKeyUtils.parse(monthStart);
    return DateKeyUtils.fromCalendarDate(
      DateTime.utc(date.year, date.month + delta, 1),
    );
  }
}
