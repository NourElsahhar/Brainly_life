// M4 integration flows (written by the QA lead):
//   1. Create a habit and complete it on three days in a row (fake clock),
//      then see the 3-day streak on the detail screen.
//   2. A full Pomodoro cycle: focus, short break, focus, long break.
// They use the real screens, Cubits and routes with the mock repositories, so
// they do not need Firebase.
//
// Run:  fvm flutter test integration_test/m4_flows_test.dart
// If it asks for a device, add:  -d windows   (or an Android device id)

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/auth_injection.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_timer_local_data_source.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_cubit.dart';
import 'package:brainly_life/features/focus/presentation/screens/focus_screen.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/habits_injection.dart';
import 'package:brainly_life/features/habits/presentation/habits_routes.dart';
import 'package:brainly_life/injection.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final firstDay = DateTime.utc(2026, 11, 16, 10);

  /// Runs [body] as if it were [dayOffset] days after the first day.
  Future<T> at<T>(int dayOffset, Future<T> Function() body) =>
      withClock(Clock.fixed(firstDay.add(Duration(days: dayOffset))), body);

  Future<void> pumpHabits(WidgetTester tester) async {
    // Remove the old screen first, so every day starts with a fresh Cubit.
    await tester.pumpWidget(const SizedBox.shrink());
    final router = GoRouter(
      initialLocation: AppRoutes.habits,
      routes: [...habitsRoutes, ...habitsFullScreenRoutes],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('create a habit and complete it three days in a row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await getIt.reset();
    registerAuthFeature(getIt, useMocks: true);
    registerHabitsFeature(getIt, useMocks: true);
    // Start with no habits.
    await getIt.unregister<HabitRepository>();
    getIt.registerLazySingleton<HabitRepository>(() => MockHabitRepository());
    addTearDown(getIt.reset);

    // Day 1: create the habit and complete it.
    await at(0, () async {
      await pumpHabits(tester);
      await tester.tap(find.text(AppStrings.habitsEmptyCta));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Read 20 pages');
      await tester.tap(find.text(AppStrings.habitSaveHabit));
      await tester.pumpAndSettle();

      expect(find.text('Read 20 pages'), findsOneWidget);
      expect(find.text('0/1'), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.habitMarkDone));
      await tester.pumpAndSettle();
      expect(find.text('1/1'), findsOneWidget);
    });

    // Day 2.
    await at(1, () async {
      await pumpHabits(tester);
      expect(find.text('0/1'), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.habitMarkDone));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.habitStreakLabel(2)), findsOneWidget);
    });

    // Day 3, then the detail screen shows the streak.
    await at(2, () async {
      await pumpHabits(tester);
      await tester.tap(find.byTooltip(AppStrings.habitMarkDone));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.habitStreakLabel(3)), findsOneWidget);

      await tester.tap(find.text('Read 20 pages'));
      await tester.pumpAndSettle();
      final streak = tester.widget<Text>(
        find.byKey(const Key('habit_current_streak')),
      );
      expect(streak.data, '3');
    });
  });

  testWidgets('a full pomodoro cycle: focus, short break, focus, long break', (
    tester,
  ) async {
    // Sound and vibration use the platform channel. Answer it with nothing.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    // Short blocks, so the cycle is quick: 5 / 1 / 5 minutes, long break
    // after 2 focus blocks.
    final repository = MockFocusRepository(
      settings: const FocusSettings(
        focusMinutes: 5,
        shortBreakMinutes: 1,
        longBreakMinutes: 5,
        sessionsBeforeLong: 2,
      ),
    );
    final cubit = FocusCubit(
      repository: repository,
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
    expect(find.text('05:00'), findsOneWidget);

    /// Starts a block and lets its time run out.
    Future<void> runBlock(String startLabel, Duration length) async {
      await tester.tap(find.text(startLabel));
      await tester.pump();
      await tester.pump(length + const Duration(seconds: 2));
    }

    // Focus block 1 -> the short break is offered.
    await runBlock(AppStrings.focusStartAction, const Duration(minutes: 5));
    expect(find.text(AppStrings.focusFocusDone), findsOneWidget);
    expect(find.text(AppStrings.focusStartShortBreak), findsOneWidget);

    // Short break -> focus again.
    await runBlock(AppStrings.focusStartShortBreak, const Duration(minutes: 1));
    expect(find.text(AppStrings.focusBreakDone), findsOneWidget);

    // Focus block 2 -> the long break is offered.
    await runBlock(AppStrings.focusStartAction, const Duration(minutes: 5));
    expect(find.text(AppStrings.focusStartLongBreak), findsOneWidget);

    final saved = (await repository.getSessions(
      fromDate: '2000-01-01',
      toDate: '2099-12-31',
    )).dataOrNull!;
    expect(saved, hasLength(2));
    expect(saved.every((session) => session.actualMinutes == 5), isTrue);

    // Long break, skipped: back to a ready timer.
    await tester.tap(find.text(AppStrings.focusStartLongBreak));
    await tester.pump();
    await tester.tap(find.text(AppStrings.focusSkipBreakAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.focusStartAction), findsOneWidget);
  });
}
