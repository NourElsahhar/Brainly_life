// Tests for HabitSuggestionCubit: the AI is not called by itself, fetch keeps
// at most 3 tips, an empty answer, a failure, and dismissing tips.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_state.dart';
import 'package:flutter_test/flutter_test.dart';

HabitSuggestion tip(String title) =>
    HabitSuggestion(title: title, reason: 'because');

void main() {
  test('starts idle and does not call the AI by itself', () {
    final port = MockHabitSuggestionPort();
    final cubit = HabitSuggestionCubit(port: port);
    addTearDown(cubit.close);

    expect(cubit.state, const HabitSuggestionInitial());
    expect(port.callCount, 0);
  });

  blocTest<HabitSuggestionCubit, HabitSuggestionState>(
    'fetch emits loading then at most 3 suggestions',
    build: () => HabitSuggestionCubit(
      port: MockHabitSuggestionPort(
        suggestions: [tip('a'), tip('b'), tip('c'), tip('d')],
      ),
    ),
    act: (cubit) => cubit.fetch(),
    expect: () => [
      const HabitSuggestionLoading(),
      HabitSuggestionLoaded([tip('a'), tip('b'), tip('c')]),
    ],
  );

  blocTest<HabitSuggestionCubit, HabitSuggestionState>(
    'fetch emits empty when the AI has nothing new',
    build: () =>
        HabitSuggestionCubit(port: MockHabitSuggestionPort(suggestions: [])),
    act: (cubit) => cubit.fetch(),
    expect: () => [
      const HabitSuggestionLoading(),
      const HabitSuggestionEmpty(),
    ],
  );

  blocTest<HabitSuggestionCubit, HabitSuggestionState>(
    'fetch emits an error when the AI fails',
    build: () => HabitSuggestionCubit(
      port: MockHabitSuggestionPort(failWith: const AiFailure()),
    ),
    act: (cubit) => cubit.fetch(),
    expect: () => [
      const HabitSuggestionLoading(),
      const HabitSuggestionError(AiFailure()),
    ],
  );

  blocTest<HabitSuggestionCubit, HabitSuggestionState>(
    'dismiss removes one tip, the last one goes back to the button',
    build: () => HabitSuggestionCubit(
      port: MockHabitSuggestionPort(suggestions: [tip('a'), tip('b')]),
    ),
    act: (cubit) async {
      await cubit.fetch();
      cubit.dismiss(tip('a'));
      cubit.dismiss(tip('b'));
    },
    skip: 2,
    expect: () => [
      HabitSuggestionLoaded([tip('b')]),
      const HabitSuggestionInitial(),
    ],
  );
}
