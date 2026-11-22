// Widget test for the Pomodoro screen: it shows the focus time and the Start
// button, and Start / Stop change the buttons.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_timer_local_data_source.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_cubit.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    final cubit = FocusCubit(
      repository: MockFocusRepository(),
      localDataSource: MockFocusTimerLocalDataSource(),
      timezone: 'UTC',
    )..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const FocusView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows 25:00 and the Start button', (tester) async {
    await pumpScreen(tester);

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text(AppStrings.focusStartAction), findsOneWidget);
  });

  testWidgets('Start shows Pause and Stop, Stop goes back', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.focusStartAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.focusPauseAction), findsOneWidget);
    expect(find.text(AppStrings.focusStopAction), findsOneWidget);

    // Stop also cancels the one-second ticker, so no timer stays pending.
    await tester.tap(find.text(AppStrings.focusStopAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.focusStartAction), findsOneWidget);
  });
}
