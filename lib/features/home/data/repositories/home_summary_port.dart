// The contracts behind the Home dashboard cards (owner: M3).
//
// Each feature owner implements their provider and registers it in their
// own <feature>_injection.dart. Home only knows these contracts.
//
//   TaskSummaryProvider  -> M3 (tasks)
//   StudySummaryProvider -> M2 (study planner)
//   HabitSummaryProvider -> M4 (habits)
//   FocusSummaryProvider -> M4 (focus)
//   AiTipProvider        -> M5 (AI)

import 'package:brainly_life/core/errors/result.dart';
import 'package:equatable/equatable.dart';

/// "Today's tasks" card.
class TaskSummary extends Equatable {
  const TaskSummary({
    required this.dueTodayCount,
    required this.overdueCount,
    required this.completedTodayCount,
    this.nextTaskTitle,
  });

  /// Not done, due later today.
  final int dueTodayCount;

  /// Not done, deadline already passed.
  final int overdueCount;

  /// Marked as done today.
  final int completedTodayCount;

  /// The task to do next (overdue first, then today). Null if there is none.
  final String? nextTaskTitle;

  bool get isEmpty =>
      dueTodayCount == 0 && overdueCount == 0 && completedTodayCount == 0;

  @override
  List<Object?> get props => [
    dueTodayCount,
    overdueCount,
    completedTodayCount,
    nextTaskTitle,
  ];
}

/// "Next study session" card.
class StudySummary extends Equatable {
  const StudySummary({
    required this.sessionId,
    required this.subjectName,
    required this.topicTitle,
    required this.startAt,
    required this.plannedMinutes,
  });

  final String sessionId;

  final String subjectName;

  final String topicTitle;

  /// Start time in UTC.
  final DateTime startAt;

  final int plannedMinutes;

  @override
  List<Object?> get props => [
    sessionId,
    subjectName,
    topicTitle,
    startAt,
    plannedMinutes,
  ];
}

/// "Habits" card.
class HabitSummary extends Equatable {
  const HabitSummary({
    required this.doneTodayCount,
    required this.dueTodayCount,
    required this.bestCurrentStreak,
    this.bestStreakHabitName,
  });

  /// Habits due today that are already done.
  final int doneTodayCount;

  /// Habits due today (done or not).
  final int dueTodayCount;

  /// The longest current streak among active habits.
  final int bestCurrentStreak;

  /// Name of the habit with [bestCurrentStreak]. Null if there is none.
  final String? bestStreakHabitName;

  bool get isEmpty => dueTodayCount == 0;

  @override
  List<Object?> get props => [
    doneTodayCount,
    dueTodayCount,
    bestCurrentStreak,
    bestStreakHabitName,
  ];
}

/// "Focus" card.
class FocusSummary extends Equatable {
  const FocusSummary({required this.minutesToday, required this.sessionsToday});

  /// Focus minutes completed today (breaks not counted).
  final int minutesToday;

  final int sessionsToday;

  bool get isEmpty => sessionsToday == 0;

  @override
  List<Object?> get props => [minutesToday, sessionsToday];
}

abstract class TaskSummaryProvider {
  Future<Result<TaskSummary>> todaySummary();
}

abstract class StudySummaryProvider {
  /// The next planned session, or null when there is none.
  Future<Result<StudySummary?>> nextSession();
}

abstract class HabitSummaryProvider {
  Future<Result<HabitSummary>> todaySummary();
}

abstract class FocusSummaryProvider {
  Future<Result<FocusSummary>> todaySummary();
}

abstract class AiTipProvider {
  /// One short productivity tip, the same for the whole day.
  Future<Result<String>> dailyTip();
}
