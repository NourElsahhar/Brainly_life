// StreakCalculator counts how many days (or weeks) in a row the user
// completed a habit, and how often they completed it.
//
// Input:  the habit, the days it was completed, and today's date.
// Output: current streak, best streak, and completion rate.
//
// Pure Dart: no Firebase, no Flutter, and it never reads the clock.
// All dates are dateKeys ('yyyy-MM-dd') handled by DateKeyUtils/WeekUtils.

import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:equatable/equatable.dart';

class StreakResult extends Equatable {
  const StreakResult({required this.currentStreak, required this.bestStreak});

  /// Days in a row (weeks in a row for `timesPerWeek` habits).
  final int currentStreak;
  final int bestStreak;

  @override
  List<Object?> get props => [currentStreak, bestStreak];
}

/// Rules:
/// - A daily habit breaks on a missed day.
/// - A weekdays habit ignores days that are not scheduled.
/// - A timesPerWeek habit succeeds when the week reaches its target.
/// - Today (or the current week) never breaks a streak before it ends.
class StreakCalculator {
  const StreakCalculator({this.weekStartDay = DateTime.monday});

  /// First day of the week (1 = Monday ... 7 = Sunday).
  final int weekStartDay;

  static const StreakResult _empty = StreakResult(
    currentStreak: 0,
    bestStreak: 0,
  );

  StreakResult calculate({
    required Habit habit,
    required Set<String> completedDates,
    required String today,
  }) {
    if (habit.startDate.compareTo(today) > 0) return _empty;
    if (habit.frequencyType == HabitFrequencyType.timesPerWeek) {
      return _calculateWeekly(habit, completedDates, today);
    }
    return _calculateDaily(habit, completedDates, today);
  }

  /// Share of due days that were completed in the last [windowDays] days
  /// (today included). Returns a value between 0 and 1.
  double completionRate({
    required Habit habit,
    required Set<String> completedDates,
    required String today,
    required int windowDays,
  }) {
    final windowStart = DateKeyUtils.addDays(today, -(windowDays - 1));
    final start = windowStart.compareTo(habit.startDate) > 0
        ? windowStart
        : habit.startDate;
    if (start.compareTo(today) > 0) return 0;

    if (habit.frequencyType == HabitFrequencyType.timesPerWeek) {
      final target = habit.timesPerWeek ?? 1;
      final days = _keysBetween(start, today);
      final due = target * days.length / 7;
      final done = days.where(completedDates.contains).length;
      return due == 0 ? 0 : (done / due).clamp(0.0, 1.0).toDouble();
    }

    final days = _scheduledDays(habit, start, today, completedDates);
    if (days.isEmpty) return 0;
    final done = days.where(completedDates.contains).length;
    return done / days.length;
  }

  StreakResult _calculateDaily(
    Habit habit,
    Set<String> completedDates,
    String today,
  ) {
    final days = _scheduledDays(habit, habit.startDate, today, completedDates);

    var run = 0;
    var best = 0;
    for (final day in days) {
      if (completedDates.contains(day)) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return StreakResult(currentStreak: run, bestStreak: best);
  }

  StreakResult _calculateWeekly(
    Habit habit,
    Set<String> completedDates,
    String today,
  ) {
    final target = habit.timesPerWeek ?? 1;

    final weeks = <String>[];
    var week = WeekUtils.weekStartDateKey(
      habit.startDate,
      weekStartDay: weekStartDay,
    );
    while (week.compareTo(today) <= 0) {
      weeks.add(week);
      week = DateKeyUtils.addDays(week, 7);
    }

    int countIn(String weekStart) {
      var count = 0;
      for (var i = 0; i < 7; i++) {
        final day = DateKeyUtils.addDays(weekStart, i);
        if (day.compareTo(habit.startDate) >= 0 &&
            completedDates.contains(day)) {
          count++;
        }
      }
      return count;
    }

    // The current week is not over yet, so it cannot break the streak.
    if (weeks.isNotEmpty && countIn(weeks.last) < target) {
      weeks.removeLast();
    }

    var run = 0;
    var best = 0;
    for (final weekStart in weeks) {
      if (countIn(weekStart) >= target) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    return StreakResult(currentStreak: run, bestStreak: best);
  }

  /// Days the habit is due, from [from] to [to]. Today is left out if it
  /// is not completed yet, because the day is not over.
  List<String> _scheduledDays(
    Habit habit,
    String from,
    String to,
    Set<String> completedDates,
  ) {
    final days = _keysBetween(from, to).where((day) {
      if (habit.frequencyType == HabitFrequencyType.daily) return true;
      return habit.weekdays.contains(DateKeyUtils.parse(day).weekday);
    }).toList();

    if (days.isNotEmpty && days.last == to && !completedDates.contains(to)) {
      days.removeLast();
    }
    return days;
  }

  /// Every dateKey from [from] to [to], both included.
  List<String> _keysBetween(String from, String to) {
    final count = DateKeyUtils.daysBetween(from, to);
    return [for (var i = 0; i <= count; i++) DateKeyUtils.addDays(from, i)];
  }
}
