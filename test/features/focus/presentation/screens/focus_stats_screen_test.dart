// Widget tests for the focus stats screen: it shows the numbers and the chart
// for sample sessions, and the empty state with the Start focus button when
// there are no sessions.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_cubit.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    MockFocusRepository repository,
  ) async {
    // A tall screen, so the whole list is built.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = FocusStatsCubit(repository: repository, timezone: 'UTC')
      ..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const FocusStatsView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the numbers, the chart and the history', (tester) async {
    await pumpScreen(tester, MockFocusRepository.withSampleData());

    expect(find.text(AppStrings.focusMinutesValue(50)), findsOneWidget);
    expect(find.text(AppStrings.focusStatsLast7Days), findsOneWidget);
    expect(find.text(AppStrings.focusStatsBestTime), findsOneWidget);
    expect(find.text(AppStrings.focusStatsTotalSessions), findsOneWidget);
    expect(find.text(AppStrings.focusStatsHistory), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no sessions', (
    tester,
  ) async {
    await pumpScreen(tester, MockFocusRepository());

    expect(find.text(AppStrings.focusStatsEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.focusStatsStartFocus), findsOneWidget);
    expect(find.text(AppStrings.focusStatsLast7Days), findsNothing);
  });
}
