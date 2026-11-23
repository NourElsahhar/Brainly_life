// States of the AI suggestions card: initial (shows "Get suggestions"),
// loading, empty (the AI had nothing new), error, and loaded (up to 3 tips).
// The AI is called only after the user taps the button, so there is no cost
// until then.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:equatable/equatable.dart';

sealed class HabitSuggestionState extends Equatable {
  const HabitSuggestionState();

  @override
  List<Object?> get props => [];
}

class HabitSuggestionInitial extends HabitSuggestionState {
  const HabitSuggestionInitial();
}

class HabitSuggestionLoading extends HabitSuggestionState {
  const HabitSuggestionLoading();
}

class HabitSuggestionEmpty extends HabitSuggestionState {
  const HabitSuggestionEmpty();
}

class HabitSuggestionError extends HabitSuggestionState {
  const HabitSuggestionError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class HabitSuggestionLoaded extends HabitSuggestionState {
  const HabitSuggestionLoaded(this.suggestions);

  final List<HabitSuggestion> suggestions;

  @override
  List<Object?> get props => [suggestions];
}
