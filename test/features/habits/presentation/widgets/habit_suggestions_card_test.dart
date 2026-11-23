// Widget tests for the AI suggestions card: only the button at first (no AI
// call), the tips after a tap, Add, dismissing, and the unavailable message.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/habits/data/models/habit_suggestion_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_cubit.dart';
import 'package:brainly_life/features/habits/presentation/widgets/habit_suggestions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tipA = HabitSuggestion(title: 'Tip A', reason: 'Reason A');
  const tipB = HabitSuggestion(title: 'Tip B', reason: 'Reason B');

  Future<void> pumpCard(
    WidgetTester tester,
    MockHabitSuggestionPort port, {
    void Function(HabitSuggestion suggestion)? onAdd,
  }) async {
    final cubit = HabitSuggestionCubit(port: port);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider.value(
              value: cubit,
              child: HabitSuggestionsCard(onAdd: onAdd ?? (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows only the button at first and does not call the AI', (
    tester,
  ) async {
    final port = MockHabitSuggestionPort(suggestions: [tipA, tipB]);
    await pumpCard(tester, port);

    expect(find.text(AppStrings.habitsAiTitle), findsOneWidget);
    expect(find.text(AppStrings.habitsAiGet), findsOneWidget);
    expect(find.text('Tip A'), findsNothing);
    expect(port.callCount, 0);
  });

  testWidgets('tapping the button shows the tips and the disclaimer', (
    tester,
  ) async {
    await pumpCard(tester, MockHabitSuggestionPort(suggestions: [tipA, tipB]));

    await tester.tap(find.text(AppStrings.habitsAiGet));
    await tester.pumpAndSettle();

    expect(find.text('Tip A'), findsOneWidget);
    expect(find.text('Reason A'), findsOneWidget);
    expect(find.text('Tip B'), findsOneWidget);
    expect(find.text(AppStrings.habitsAiDisclaimer), findsOneWidget);
  });

  testWidgets('Add gives the tip to onAdd', (tester) async {
    HabitSuggestion? added;
    await pumpCard(
      tester,
      MockHabitSuggestionPort(suggestions: [tipA, tipB]),
      onAdd: (suggestion) => added = suggestion,
    );
    await tester.tap(find.text(AppStrings.habitsAiGet));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.habitsAiAdd).first);
    await tester.pumpAndSettle();

    expect(added, tipA);
  });

  testWidgets('dismissing the tips removes them, then the button returns', (
    tester,
  ) async {
    await pumpCard(tester, MockHabitSuggestionPort(suggestions: [tipA, tipB]));
    await tester.tap(find.text(AppStrings.habitsAiGet));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.habitsAiDismiss).first);
    await tester.pumpAndSettle();
    expect(find.text('Tip A'), findsNothing);
    expect(find.text('Tip B'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.habitsAiDismiss));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitsAiGet), findsOneWidget);
  });

  testWidgets('a failing AI shows the unavailable message and Try again', (
    tester,
  ) async {
    final port = MockHabitSuggestionPort(failWith: const AiFailure());
    await pumpCard(tester, port);

    await tester.tap(find.text(AppStrings.habitsAiGet));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitsAiUnavailable), findsOneWidget);

    await tester.tap(find.text(AppStrings.habitsAiRetry));
    await tester.pumpAndSettle();
    expect(port.callCount, 2);
  });
}
