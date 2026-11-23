// Widget tests for the habit form: the fields, a template filling the name,
// the errors shown under the fields, saving, the weekday row, the times per
// week stepper, and edit mode.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_form_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';
import 'package:brainly_life/features/habits/presentation/screens/habit_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late MockHabitRepository repository;

  setUp(() {
    repository = MockHabitRepository();
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    Habit? habit,
    HabitTemplate? template,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = HabitFormCubit(
      repository: repository,
      timezone: 'UTC',
      habit: habit,
      template: template,
    );
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: AppRoutes.newHabit,
      routes: [
        GoRoute(
          path: AppRoutes.newHabit,
          builder: (_, _) =>
              BlocProvider.value(value: cubit, child: const HabitFormView()),
        ),
        GoRoute(
          path: AppRoutes.habits,
          builder: (_, _) => const Text('habits page'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the new habit form', (tester) async {
    await pumpForm(tester);

    expect(find.text(AppStrings.habitNewTitle), findsOneWidget);
    expect(find.text(AppStrings.habitFormIconLabel), findsOneWidget);
    expect(find.text(AppStrings.habitFormFrequencyLabel), findsOneWidget);
    expect(find.text(AppStrings.habitFormStartDate), findsOneWidget);
    expect(find.text(AppStrings.habitSaveHabit), findsOneWidget);
  });

  testWidgets('a template fills the name', (tester) async {
    await pumpForm(tester, template: habitTemplates.first);

    expect(find.text(AppStrings.habitTemplateRead), findsOneWidget);
  });

  testWidgets('saving an empty name shows the error under the field', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text(AppStrings.habitSaveHabit));
    await tester.pumpAndSettle();

    final field = tester.widget<AppTextField>(find.byType(AppTextField));
    expect(field.errorText, isNotNull);
  });

  testWidgets('weekdays without a chosen day shows an error', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), 'Gym');
    await tester.tap(find.text(AppStrings.habitFrequencyWeekdays));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.habitSaveHabit));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.habitWeekdaysRequired), findsOneWidget);
  });

  testWidgets('a valid habit is saved and the form closes', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField), 'Meditate');
    await tester.tap(find.text(AppStrings.habitSaveHabit));
    await tester.pumpAndSettle();

    final habits = (await repository.getHabits()).dataOrNull!;
    expect(habits.map((habit) => habit.name), ['Meditate']);
    expect(find.text('habits page'), findsOneWidget);
  });

  testWidgets('times per week can be raised with the plus button', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text(AppStrings.habitFrequencyTimesPerWeek));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitFormTimesPerWeekValue(3)), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.habitFormIncrease));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitFormTimesPerWeekValue(4)), findsOneWidget);
  });

  testWidgets('edit mode shows the title and the old name', (tester) async {
    final habit = Habit(
      id: 'h1',
      name: 'Read',
      icon: 'book',
      colorValue: 0xFF2196F3,
      startDate: '2026-11-01',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    await pumpForm(tester, habit: habit);

    expect(find.text(AppStrings.habitEditTitle), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });
}
