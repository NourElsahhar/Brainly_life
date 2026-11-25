// HabitSuggestion = one short habit tip from the AI: a title and the reason.
// The AI returns at most 3 of them (see HabitSuggestionPort).

import 'package:equatable/equatable.dart';

class HabitSuggestion extends Equatable {
  const HabitSuggestion({required this.title, required this.reason});

  final String title;

  /// One short sentence that explains why this is suggested.
  final String reason;

  @override
  List<Object?> get props => [title, reason];
}
