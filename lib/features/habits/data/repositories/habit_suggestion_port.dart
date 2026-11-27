// HabitSuggestionPort = the contract that gives the Habits screen its AI
// suggestions. The real one is AiHabitSuggestionPort (habit statistics of
// the last 30 days -> the shared AiClient, feature habitSuggest); the mock
// is MockHabitSuggestionPort.
//
// Rules for the real one:
//   - Send only habit statistics: no uid, name or e-mail.
//   - Return Result.failure(failure) when the AI is off, unavailable or the
//     answer is not valid. The card shows "Suggestions are unavailable".
//   - Return at most 3 items (the cubit also cuts the list to 3).

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';

abstract class HabitSuggestionPort {
  Future<Result<List<HabitSuggestion>>> getSuggestions();
}
