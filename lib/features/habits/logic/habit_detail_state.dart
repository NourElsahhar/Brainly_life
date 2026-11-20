// States of the habit detail screen: initial, loading, error, loaded (calendar
// month, streaks and completion rates), and removed (archived or deleted, so
// the screen closes). There is no empty state: a missing habit is an error.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:equatable/equatable.dart';

/// First day of the month of [dateKey], as a dateKey.
String firstDayOfMonthKey(String dateKey) => '${dateKey.substring(0, 8)}01';

sealed class HabitDetailState extends Equatable {
  const HabitDetailState();

  @override
  List<Object?> get props => [];
}

class HabitDetailInitial extends HabitDetailState {
  const HabitDetailInitial();
}

class HabitDetailLoading extends HabitDetailState {
  const HabitDetailLoading();
}

class HabitDetailError extends HabitDetailState {
  const HabitDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The habit was archived or deleted. The screen should close.
class HabitDetailRemoved extends HabitDetailState {
  const HabitDetailRemoved();
}

class HabitDetailLoaded extends HabitDetailState {
  const HabitDetailLoaded({
    required this.habit,
    required this.doneDates,
    required this.today,
    required this.monthStart,
    required this.currentStreak,
    required this.bestStreak,
    required this.rate7,
    required this.rate30,
    this.actionFailure,
  });

  final Habit habit;

  /// Every day the habit was completed (dateKeys).
  final Set<String> doneDates;

  final String today;

  /// First day of the month shown in the calendar, as a dateKey.
  final String monthStart;

  final int currentStreak;
  final int bestStreak;

  /// Completion rate of the last 7 and 30 days, from 0 to 1.
  final double rate7;
  final double rate30;

  /// Set when archive or delete failed. The screen shows it in a snackbar.
  final Failure? actionFailure;

  bool get canGoPrevious =>
      monthStart.compareTo(firstDayOfMonthKey(habit.startDate)) > 0;

  bool get canGoNext => monthStart.compareTo(firstDayOfMonthKey(today)) < 0;

  /// Every day of the shown month, as dateKeys.
  List<String> get monthDateKeys {
    final first = DateKeyUtils.parse(monthStart);
    final count = DateTime.utc(first.year, first.month + 1, 0).day;
    return [
      for (var i = 0; i < count; i++) DateKeyUtils.addDays(monthStart, i),
    ];
  }

  HabitDetailLoaded copyWith({
    String? monthStart,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return HabitDetailLoaded(
      habit: habit,
      doneDates: doneDates,
      today: today,
      monthStart: monthStart ?? this.monthStart,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      rate7: rate7,
      rate30: rate30,
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? this.actionFailure),
    );
  }

  @override
  List<Object?> get props => [
    habit,
    doneDates,
    today,
    monthStart,
    currentStreak,
    bestStreak,
    rate7,
    rate30,
    actionFailure,
  ];
}
