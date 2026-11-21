import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/home/data/repositories/mock_home_summary_providers.dart';
import 'package:brainly_life/features/home/logic/home_cubit.dart';
import 'package:brainly_life/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockTaskSummaryProvider tasks;
  late MockStudySummaryProvider study;
  late MockHabitSummaryProvider habits;
  late MockFocusSummaryProvider focus;
  late MockAiTipProvider tip;

  setUp(() {
    tasks = MockTaskSummaryProvider();
    study = MockStudySummaryProvider.withSampleData();
    habits = MockHabitSummaryProvider();
    focus = MockFocusSummaryProvider();
    tip = MockAiTipProvider();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => HomeCubit(
            tasks: tasks,
            study: study,
            habits: habits,
            focus: focus,
            tip: tip,
          )..load(),
          child: const HomeView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows every card with its data', (tester) async {
    await pumpHome(tester);

    expect(find.text("Today's tasks"), findsOneWidget);
    expect(find.text('due today'), findsOneWidget);
    expect(
      find.text('Next: Email the supervisor', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mathematics · Differential equations'), findsOneWidget);
    expect(find.text('1 of 3 done today'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Tip of the day'), 200);
    expect(find.text('50'), findsOneWidget); // focus minutes
    expect(
      find.text('Start with the hardest task while your energy is high.'),
      findsOneWidget,
    );
  });

  testWidgets('empty cards show a short message', (tester) async {
    tasks = MockTaskSummaryProvider(
      summary: const TaskSummary(
        dueTodayCount: 0,
        overdueCount: 0,
        completedTodayCount: 0,
      ),
    );
    study = MockStudySummaryProvider(); // no session
    await pumpHome(tester);

    expect(find.text('No tasks for today. Tap to add one.'), findsOneWidget);
    expect(
      find.text('No study session planned. Make a plan first.'),
      findsOneWidget,
    );
  });

  testWidgets('a failing card shows Retry, the others still show', (
    tester,
  ) async {
    habits = MockHabitSummaryProvider(failWith: const NetworkFailure());
    await pumpHome(tester);

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('due today'), findsOneWidget); // tasks card is fine

    habits.failWith = null;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsNothing);
    expect(find.text('1 of 3 done today'), findsOneWidget);
  });
}
