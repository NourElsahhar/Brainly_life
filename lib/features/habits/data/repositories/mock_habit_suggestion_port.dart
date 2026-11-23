// MockHabitSuggestionPort is a fake HabitSuggestionPort for development and
// tests. It can return sample tips, an empty list, or a failure, and it counts
// how many times it was called.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_suggestion_port.dart';

class MockHabitSuggestionPort implements HabitSuggestionPort {
  MockHabitSuggestionPort({
    this.suggestions = defaultSuggestions,
    this.failWith,
    this.delay = Duration.zero,
  });

  static const List<HabitSuggestion> defaultSuggestions = [
    HabitSuggestion(
      title: 'Try a 5-minute stretch after studying',
      reason: 'A short break helps you reset between study blocks.',
    ),
    HabitSuggestion(
      title: "Move 'Meditate' to the morning",
      reason: 'Morning habits are easier to keep while the day is quiet.',
    ),
  ];

  final List<HabitSuggestion> suggestions;

  /// When set, the port returns this failure instead of the suggestions.
  final Failure? failWith;

  /// A pause before answering, to see the loading state.
  final Duration delay;

  /// How many times getSuggestions was called.
  int callCount = 0;

  @override
  Future<Result<List<HabitSuggestion>>> getSuggestions() async {
    callCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final failure = failWith;
    if (failure != null) return Result.failure(failure);
    return Result.success(suggestions);
  }
}
