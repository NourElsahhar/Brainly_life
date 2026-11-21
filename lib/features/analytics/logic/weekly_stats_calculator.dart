import 'dart:math' as math;

import '../data/models/analytics_models.dart';

class WeeklyStatsCalculator {
  const WeeklyStatsCalculator();

  WeeklyStats calculate(
    AnalyticsInput input,
    AnalyticsWeek week, {
    required DateTime now,
    required String Function(DateTime instant) dateKey,
  }) {
    final observedEnd = now.isBefore(week.endUtc) ? now : week.endUtc;
    final createdDaily = {for (final day in week.days) day: 0};
    final completedDaily = {...createdDaily};
    final focusDaily = {...createdDaily};
    final studyDaily = {...createdDaily};
    final bySubject = <String, int>{};
    var created = 0;
    var completed = 0;
    var overdue = 0;
    var taskCount = 0;
    var studyPlanned = 0;
    var studyActual = 0;
    var habitsDue = 0;
    var habitsCompleted = 0;
    var bestRate = -1.0;
    String? bestHabit;
    var focusMinutes = 0;
    var focusPlanned = 0;
    var focusSessions = 0;

    for (final task in input.tasks) {
      final wasCreated =
          week.contains(task.createdAt) && !task.createdAt!.isAfter(now);
      final wasCompleted =
          week.contains(task.completedAt) && !task.completedAt!.isAfter(now);
      final wasDue =
          week.contains(task.dueAt) && task.dueAt!.isBefore(observedEnd);
      if (wasCreated || wasCompleted || wasDue) taskCount++;
      if (wasCreated) {
        created++;
        final day = dateKey(task.createdAt!);
        createdDaily.update(day, (count) => count + 1);
      }
      if (wasCompleted) {
        completed++;
        final day = dateKey(task.completedAt!);
        completedDaily.update(day, (count) => count + 1);
      }
      if (wasDue &&
          (task.completedAt == null ||
              !task.completedAt!.isBefore(observedEnd))) {
        overdue++;
      }
    }

    for (final session in input.study) {
      final minutes = math.max(0, session.actual);
      studyPlanned += math.max(0, session.planned);
      studyActual += minutes;
      if (studyDaily.containsKey(session.day)) {
        studyDaily.update(session.day!, (value) => value + minutes);
      }
      bySubject.update(
        session.subject,
        (value) => value + minutes,
        ifAbsent: () => minutes,
      );
    }

    for (final habit in input.habits) {
      if (habit.due <= 0) continue;
      final done = habit.completed.clamp(0, habit.due);
      habitsDue += habit.due;
      habitsCompleted += done;
      final rate = done / habit.due;
      if (rate > bestRate ||
          (rate == bestRate && habit.name.compareTo(bestHabit!) < 0)) {
        bestRate = rate;
        bestHabit = habit.name;
      }
    }

    for (final session in input.focus) {
      if (!focusDaily.containsKey(session.day)) continue;
      final minutes = math.max(0, session.actual);
      focusMinutes += minutes;
      focusPlanned += math.max(0, session.planned);
      focusSessions++;
      focusDaily.update(session.day, (value) => value + minutes);
    }

    return WeeklyStats(
      tasksCreated: created,
      tasksCompleted: completed,
      tasksOverdue: overdue,
      tasksCount: taskCount,
      studyPlanned: studyPlanned,
      studyActual: studyActual,
      habitsDue: habitsDue,
      habitsCompleted: habitsCompleted,
      bestHabit: bestHabit,
      focusMinutes: focusMinutes,
      focusPlanned: focusPlanned,
      focusSessions: focusSessions,
      tasksByDay: {
        for (final day in week.days)
          day: TaskDayStats(
            created: createdDaily[day]!,
            completed: completedDaily[day]!,
          ),
      },
      focusByDay: focusDaily,
      studyBySubject: bySubject,
      studyByDay: studyDaily,
    );
  }
}
