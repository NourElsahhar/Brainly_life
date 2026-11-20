// States of the "today's habits" screen: initial, loading, empty (no habits
// at all), error, and loaded (the habits due today with their done flag).

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:equatable/equatable.dart';

sealed class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {
  const HabitsInitial();
}

class HabitsLoading extends HabitsState {
  const HabitsLoading();
}

/// The user has no habits at all.
class HabitsEmpty extends HabitsState {
  const HabitsEmpty();
}

class HabitsError extends HabitsState {
  const HabitsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// One habit due today and whether it is done.
class HabitTodayItem extends Equatable {
  const HabitTodayItem({required this.habit, required this.isDone});

  final Habit habit;
  final bool isDone;

  HabitTodayItem copyWith({Habit? habit, bool? isDone}) {
    return HabitTodayItem(
      habit: habit ?? this.habit,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [habit, isDone];
}

class HabitsLoaded extends HabitsState {
  const HabitsLoaded({
    required this.items,
    required this.today,
    this.toggleFailure,
  });

  final List<HabitTodayItem> items;

  /// Today as a dateKey.
  final String today;

  /// Set when a toggle failed and was rolled back. The screen shows it from
  /// a BlocListener (snackbar).
  final Failure? toggleFailure;

  int get totalCount => items.length;

  int get completedCount => items.where((item) => item.isDone).length;

  /// 0 to 1, for the progress ring.
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;

  @override
  List<Object?> get props => [items, today, toggleFailure];
}
