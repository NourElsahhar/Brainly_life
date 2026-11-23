// HabitSuggestionCubit drives the AI suggestions card. fetch() asks the port
// for suggestions (only when the user taps the button) and keeps at most 3.
// dismiss() removes one tip; when the last one is dismissed the card goes back
// to the "Get suggestions" button.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HabitSuggestionCubit extends Cubit<HabitSuggestionState> {
  HabitSuggestionCubit({required HabitSuggestionPort port})
    : _port = port,
      super(const HabitSuggestionInitial());

  static const int maxSuggestions = 3;

  final HabitSuggestionPort _port;

  Future<void> fetch() async {
    if (state is HabitSuggestionLoading) return;
    emit(const HabitSuggestionLoading());

    final result = await _port.getSuggestions();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final tips = data.take(maxSuggestions).toList();
        emit(
          tips.isEmpty
              ? const HabitSuggestionEmpty()
              : HabitSuggestionLoaded(tips),
        );
      case Failed(:final failure):
        emit(HabitSuggestionError(failure));
    }
  }

  void dismiss(HabitSuggestion suggestion) {
    final current = state;
    if (current is! HabitSuggestionLoaded) return;
    final left = current.suggestions
        .where((item) => item != suggestion)
        .toList();
    emit(
      left.isEmpty
          ? const HabitSuggestionInitial()
          : HabitSuggestionLoaded(left),
    );
  }
}
