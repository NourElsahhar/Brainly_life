// HabitDetailCubit drives the habit detail screen. It loads all logs of the
// habit once, then calculates the streaks and completion numbers; the
// calendar month is changed locally. The user can mark or unmark a day up to
// 7 days back (toggleDay), and archive or delete the habit (the screen asks
// for confirmation first).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_state.dart';
import 'package:brainly_life/features/habits/logic/habit_schedule.dart';
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

  Future<void> load() => _fetch(showLoading: true);

  /// Marks the day as done, or removes the mark, then refreshes the numbers.
  /// Days that are not allowed (future, too old, before the start) are ignored.
  Future<void> toggleDay(String dateKey) async {
    final current = state;
    if (current is! HabitDetailLoaded || !current.canToggleDay(dateKey)) {
      return;
    }

    final result = await _repository.toggleCompletion(
      habitId: _habitId,
      dateKey: dateKey,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        await _fetch(showLoading: false, monthStart: current.monthStart);
      case Failed(:final failure):
        emit(current.copyWith(actionFailure: failure));
    }
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

  Future<void> _fetch({required bool showLoading, String? monthStart}) async {
    if (showLoading) emit(const HabitDetailLoading());
    final today = DateKeyUtils.todayKey(timezone: _timezone);

    final habitsResult = await _repository.getHabits(includeArchived: true);
    if (isClosed) return;
    if (habitsResult case Failed(:final failure)) {
      _fail(failure, showLoading: showLoading);
      return;
    }

    final habits = habitsResult.dataOrNull ?? const <Habit>[];
    final index = habits.indexWhere((habit) => habit.id == _habitId);
    if (index == -1) {
      _fail(const NotFoundFailure(), showLoading: showLoading);
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
      _fail(failure, showLoading: showLoading);
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
    final last7 = _lastSevenDays(habit, doneDates, today);

    emit(
      HabitDetailLoaded(
        habit: habit,
        doneDates: doneDates,
        today: today,
        monthStart: monthStart ?? firstDayOfMonthKey(today),
        currentStreak: streak.currentStreak,
        bestStreak: streak.bestStreak,
        rate7: rate(7),
        rate30: rate(30),
        doneLast7: last7.done,
        dueLast7: last7.due,
      ),
    );
  }

  /// Done and due days of the last 7 days (today included). Today is not
  /// counted as due until it is done, like in the streak. A times-per-week
  /// habit is due as many times as its target.
  ({int done, int due}) _lastSevenDays(
    Habit habit,
    Set<String> doneDates,
    String today,
  ) {
    final start = DateKeyUtils.addDays(today, -6);

    if (habit.frequencyType == HabitFrequencyType.timesPerWeek) {
      final target = habit.timesPerWeek ?? 1;
      final done = doneDates
          .where(
            (day) =>
                day.compareTo(start) >= 0 &&
                day.compareTo(today) <= 0 &&
                day.compareTo(habit.startDate) >= 0,
          )
          .length;
      return (done: done > target ? target : done, due: target);
    }

    final days = [for (var i = 0; i < 7; i++) DateKeyUtils.addDays(start, i)]
        .where((day) => HabitSchedule.isDueOn(habit, day))
        .toList();
    if (days.isNotEmpty && days.last == today && !doneDates.contains(today)) {
      days.removeLast();
    }
    return (done: days.where(doneDates.contains).length, due: days.length);
  }

  /// A failure while the screen is already loaded stays in the loaded state
  /// (a snackbar), otherwise it becomes the error state.
  void _fail(Failure failure, {required bool showLoading}) {
    final current = state;
    if (!showLoading && current is HabitDetailLoaded) {
      emit(current.copyWith(actionFailure: failure));
    } else {
      emit(HabitDetailError(failure));
    }
  }

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
