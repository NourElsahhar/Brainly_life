import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:equatable/equatable.dart';

/// The state of ONE card. Every card loads and fails on its own.
sealed class HomeCard<T> extends Equatable {
  const HomeCard();

  @override
  List<Object?> get props => [];
}

/// Show a skeleton card.
final class HomeCardLoading<T> extends HomeCard<T> {
  const HomeCardLoading();
}

final class HomeCardLoaded<T> extends HomeCard<T> {
  const HomeCardLoaded(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

/// Show "Couldn't load" with a Retry button that calls `retry(card)`.
final class HomeCardError<T> extends HomeCard<T> {
  const HomeCardError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The cards of the Home screen, top to bottom.
enum HomeSection { tasks, study, habits, focus, tip }

class HomeState extends Equatable {
  const HomeState({
    this.tasks = const HomeCardLoading(),
    this.study = const HomeCardLoading(),
    this.habits = const HomeCardLoading(),
    this.focus = const HomeCardLoading(),
    this.tip = const HomeCardLoading(),
  });

  final HomeCard<TaskSummary> tasks;

  /// Loaded with null means "no study session planned".
  final HomeCard<StudySummary?> study;

  final HomeCard<HabitSummary> habits;
  final HomeCard<FocusSummary> focus;
  final HomeCard<String> tip;

  HomeState copyWith({
    HomeCard<TaskSummary>? tasks,
    HomeCard<StudySummary?>? study,
    HomeCard<HabitSummary>? habits,
    HomeCard<FocusSummary>? focus,
    HomeCard<String>? tip,
  }) {
    return HomeState(
      tasks: tasks ?? this.tasks,
      study: study ?? this.study,
      habits: habits ?? this.habits,
      focus: focus ?? this.focus,
      tip: tip ?? this.tip,
    );
  }

  @override
  List<Object?> get props => [tasks, study, habits, focus, tip];
}
