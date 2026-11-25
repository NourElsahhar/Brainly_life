// Widget tests for the habit detail screen: the header and the numbers, marking
// today in the calendar, archive and delete with confirmation, an archived
// habit, and a habit that does not exist.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/habits/data/models/habit_log_model.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_cubit.dart';
import 'package:brainly_life/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final today = DateKeyUtils.todayKey(timezone: 'UTC');

  Habit habit({bool archived = false}) {
    return Habit(
      id: 'h1',
      name: 'Read 20 pages',
      icon: 'book',
      colorValue: 0xFF00CEC9,
      startDate: DateKeyUtils.addDays(today, -20),
      archived: archived,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  // Done yesterday and the two days before: a streak of 3.
  MockHabitRepository buildRepository({bool archived = false}) {
    return MockHabitRepository(
      habits: [habit(archived: archived)],
      logs: [
        for (final offset in [1, 2, 3])
          HabitLog(
            habitId: 'h1',
            date: DateKeyUtils.addDays(today, -offset),
            completedAt: DateTime.utc(2026, 1, 1, 8),
          ),
      ],
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester,
    MockHabitRepository repository, {
    String habitId = 'h1',
  }) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = HabitDetailCubit(
      repository: repository,
      habitId: habitId,
      timezone: 'UTC',
    )..load();
    addTearDown(cubit.close);
    final router = GoRouter(
      initialLocation: AppRoutes.habitPath(habitId),
      routes: [
        GoRoute(
          path: AppRoutes.habitDetail,
          builder: (_, _) =>
              BlocProvider.value(value: cubit, child: const HabitDetailView()),
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

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  testWidgets('shows the header, the streaks and the completion', (
    tester,
  ) async {
    await pumpDetail(tester, buildRepository());

    expect(find.text('Read 20 pages'), findsOneWidget);
    expect(find.text(AppStrings.habitEveryDay), findsOneWidget);
    expect(textOf(tester, const Key('habit_current_streak')), '3');
    expect(textOf(tester, const Key('habit_best_streak')), '3');
    expect(textOf(tester, const Key('habit_rate_30')), '15%');
    expect(find.text('3/6'), findsOneWidget);
    expect(find.byTooltip(AppStrings.habitDetailEditTooltip), findsOneWidget);
  });

  testWidgets('tapping today in the calendar marks it as done', (tester) async {
    final repository = buildRepository();
    await pumpDetail(tester, repository);

    await tester.tap(find.byKey(ValueKey('habit_day_$today')));
    await tester.pumpAndSettle();

    final logs = (await repository.getLogs(
      fromDate: today,
      toDate: today,
    )).dataOrNull!;
    expect(logs, hasLength(1));
    expect(textOf(tester, const Key('habit_current_streak')), '4');
  });

  testWidgets('archive asks first, then archives and closes', (tester) async {
    final repository = buildRepository();
    await pumpDetail(tester, repository);

    await tester.tap(find.text(AppStrings.habitArchiveAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitArchiveConfirmTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.habitArchiveAction).last);
    await tester.pumpAndSettle();

    expect((await repository.getHabits()).dataOrNull, isEmpty);
    expect(find.text('habits page'), findsOneWidget);
  });

  testWidgets('delete asks first, then deletes and closes', (tester) async {
    final repository = buildRepository();
    await pumpDetail(tester, repository);

    await tester.tap(find.text(AppStrings.habitDeleteAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.habitDeleteConfirmTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.habitDeleteAction).last);
    await tester.pumpAndSettle();

    expect(
      (await repository.getHabits(includeArchived: true)).dataOrNull,
      isEmpty,
    );
    expect(find.text('habits page'), findsOneWidget);
  });

  testWidgets('cancelling the delete keeps the habit', (tester) async {
    final repository = buildRepository();
    await pumpDetail(tester, repository);

    await tester.tap(find.text(AppStrings.habitDeleteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect((await repository.getHabits()).dataOrNull, hasLength(1));
  });

  testWidgets('an archived habit has the badge and no Archive button', (
    tester,
  ) async {
    await pumpDetail(tester, buildRepository(archived: true));

    expect(find.text(AppStrings.habitDetailArchivedBadge), findsOneWidget);
    expect(find.text(AppStrings.habitArchiveAction), findsNothing);
    expect(find.text(AppStrings.habitDeleteAction), findsOneWidget);
  });

  testWidgets('a habit that does not exist shows the error with retry', (
    tester,
  ) async {
    await pumpDetail(tester, MockHabitRepository(), habitId: 'nope');

    expect(find.text('Try again'), findsOneWidget);
  });
}
