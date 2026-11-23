// HabitSuggestionPort = the contract that gives the Habits screen its AI
// suggestions. The Habits feature only knows this contract, never the AI
// client. M5 writes the real one (it calls AiClient with AiFeature.habitSuggest
// and turns the answer into HabitSuggestion objects).
//
// Rules for the real one:
//   - Send nothing about the user. The server builds the habit statistics
//     from Firestore with the signed-in uid.
//   - Return Result.failure(failure) when the AI is off, unavailable or the
//     answer is not valid. The card shows "Suggestions are unavailable".
//   - Return at most 3 items (the cubit also cuts the list to 3).

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';

abstract class HabitSuggestionPort {
  Future<Result<List<HabitSuggestion>>> getSuggestions();
}
