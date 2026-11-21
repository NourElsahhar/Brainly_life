// Widget tests for the focus settings screen: it shows the saved values,
// the plus button changes a value, and a switch can be toggled.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_cubit.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FocusSettingsCubit> pumpScreen(WidgetTester tester) async {
    final cubit = FocusSettingsCubit(repository: MockFocusRepository())..load();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: const FocusSettingsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('shows the default timer values', (tester) async {
    await pumpScreen(tester);

    expect(find.text(AppStrings.focusMinutesValue(25)), findsOneWidget);
    expect(find.text(AppStrings.focusMinutesValue(5)), findsOneWidget);
    expect(find.text(AppStrings.focusMinutesValue(15)), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('the plus button raises the focus minutes', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip(AppStrings.focusIncrease).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.focusMinutesValue(30)), findsOneWidget);
  });

    testWidgets('a switch can be turned on', (tester) async {
    final cubit = await pumpScreen(tester);

    final label = find.text(AppStrings.focusKeepScreenOn);
    await tester.ensureVisible(label);
    await tester.pumpAndSettle();
    await tester.tap(label);
    await tester.pumpAndSettle();

    final state = cubit.state as dynamic;
    expect(state.settings.keepScreenOn, isTrue);
  });
}
