// HabitSuggestionPort = the contract that gives the Habits screen its AI
// suggestions. The Habits feature only knows this contract, never the AI
// client. The real one is GatewayHabitSuggestionPort (it calls the aiGateway
// function with the feature habitSuggest).
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
