import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_cubit.dart';
import 'package:brainly_life/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 13);

  Task task(String id, String title, {Duration? dueIn, String? categoryId}) =>
      Task(
        id: id,
        title: title,
        categoryId: categoryId,
        dueAt: dueIn == null ? null : now.add(dueIn).toUtc(),
        createdAt: now,
        updatedAt: now,
      );

  late MockTaskRepository tasks;
  late MockTaskCategoryRepository categories;

  setUp(() {
    tasks = MockTaskRepository(
      now: () => now,
      tasks: [
        task(
          'slides',
          'Prepare slides',
          dueIn: const Duration(hours: 2),
          categoryId: 'uni',
        ),
        task('bill', 'Pay the bill', dueIn: const Duration(hours: -2)),
        task('study', 'Study physics', dueIn: const Duration(days: 2)),
        Task(
          id: 'books',
          title: 'Buy books',
          status: TaskStatus.done,
          completedAt: now.subtract(const Duration(hours: 1)).toUtc(),
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    categories = MockTaskCategoryRepository(
      categories: const [
        TaskCategory(id: 'uni', name: 'University', colorValue: 0xFF74B9FF),
      ],
    );
  });

  tearDown(() async {
    await tasks.dispose();
    await categories.dispose();
  });

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => TaskListCubit(
                tasks,
                now: () => now,
                searchDelay: Duration.zero,
              )..load(),
            ),
            BlocProvider(create: (_) => CompletedTasksCubit(tasks)),
            BlocProvider(
              create: (_) => CategoryCubit(categories, tasks)..load(),
            ),
          ],
          child: const TasksView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Today, with a count on every tab', (tester) async {
    await pumpView(tester);

    expect(find.text('Prepare slides'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('Today 1'), findsOneWidget);
    expect(find.text('Upcoming 1'), findsOneWidget);
    expect(find.text('Overdue 1'), findsOneWidget);
  });

  testWidgets('the Overdue tab shows the overdue task', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Overdue 1'));
    await tester.pumpAndSettle();

    expect(find.text('Pay the bill'), findsOneWidget);
    expect(find.text('Prepare slides'), findsNothing);
  });

  testWidgets('the Completed tab loads the done tasks', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Buy books'), findsOneWidget);
    expect(find.text('Reopen'), findsOneWidget);
    expect(find.byTooltip('Search'), findsNothing); // no search there
  });

  testWidgets('search with no match shows "No matching tasks"', (tester) async {
    await pumpView(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No matching tasks'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare slides'), findsOneWidget);
  });

  testWidgets('completing a task shows Undo, and Undo brings it back', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(find.bySemanticsLabel('Mark as done'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare slides'), findsNothing);
    expect(find.text('Task completed'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare slides'), findsOneWidget);
  });
}
