// Widget tests for the Habits tab: the progress ring and the list, marking a
// habit done, the "nothing due today" state, and the empty state with the
// quick-start habits.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habits_cubit.dart';
import 'package:brainly_life/features/habits/presentation/screens/habits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateKeyUtils.todayKey(timezone: 'UTC');

  Habit habit(String name, {String? startDate, int streak = 0}) {
    return Habit(
      id: name,
      name: name,
      icon: 'book',
      colorValue: 0xFF2196F3,
      startDate: startDate ?? '2026-01-01',
      currentStreak: streak,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    MockHabitRepository repository,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = HabitsCubit(
      repository: repository,
      timezone: 'UTC',
      userName: () => 'Shahd',
    )..loadHabits();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const HabitsView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the progress, the greeting and the habits', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      MockHabitRepository(
        habits: [habit('Read', streak: 12), habit('Walk')],
        logs: [
          HabitLog(
            habitId: 'Read',
            date: today,
            completedAt: DateTime.utc(2026, 11, 16, 8),
          ),
        ],
      ),
    );

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text(AppStrings.habitsDoneToday), findsOneWidget);
    expect(find.text(AppStrings.habitsKeepGoing('Shahd')), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text(AppStrings.habitStreakLabel(12)), findsOneWidget);
  });

  testWidgets('tapping the check marks the habit as done', (tester) async {
    await pumpScreen(tester, MockHabitRepository(habits: [habit('Read')]));
    expect(find.text('0/1'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.habitMarkDone));
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
    expect(find.text(AppStrings.habitsAllDone), findsOneWidget);
    expect(find.byTooltip(AppStrings.habitMarkUndone), findsOneWidget);
  });

  testWidgets('shows "nothing due today" when no habit is due', (tester) async {
    await pumpScreen(
      tester,
      MockHabitRepository(
        habits: [habit('Read', startDate: DateKeyUtils.addDays(today, 5))],
      ),
    );

    expect(find.text(AppStrings.habitsNothingDueTitle), findsOneWidget);
  });

  testWidgets('shows the empty state with the quick-start habits', (
    tester,
  ) async {
    await pumpScreen(tester, MockHabitRepository());

    expect(find.text(AppStrings.habitsEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.habitsEmptyCta), findsOneWidget);
    expect(find.text(AppStrings.habitTemplateRead), findsOneWidget);
    expect(find.text(AppStrings.habitTemplateWater), findsOneWidget);
    expect(find.text(AppStrings.habitTemplateWalk), findsOneWidget);
  });
}
