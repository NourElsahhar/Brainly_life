import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_cubit.dart';
import 'package:brainly_life/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  final report = Task(
    id: 'report',
    title: 'Write report',
    description: 'For the physics lab',
    categoryId: 'uni',
    subtasks: const [
      Subtask(id: 'subtask_1', title: 'Outline', done: true),
      Subtask(id: 'subtask_2', title: 'Draft'),
    ],
    createdAt: now,
    updatedAt: now,
  );

  late MockTaskRepository tasks;
  late MockTaskCategoryRepository categories;

  setUp(() {
    tasks = MockTaskRepository(tasks: [report], now: () => now);
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

  /// Opens the detail on top of a "Home" page, so we can see it close.
  Future<void> pumpDetail(WidgetTester tester, String taskId) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    TaskDetailCubit(tasks, now: () => now)..load(taskId),
              ),
              BlocProvider(
                create: (_) => CategoryCubit(categories, tasks)..load(),
              ),
            ],
            child: TaskDetailView(taskId: taskId),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    router.push('/detail');
    await tester.pumpAndSettle();
  }

  Future<Task> savedReport() async =>
      (await tasks.watchTask('report').first).dataOrNull!;

  testWidgets('shows the task details', (tester) async {
    await pumpDetail(tester, 'report');

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('For the physics lab'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('1 of 2 done'), findsOneWidget);
    expect(find.text('Mark as done'), findsOneWidget);
  });

  testWidgets('ticking a checklist item saves it', (tester) async {
    await pumpDetail(tester, 'report');

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 2 done'), findsOneWidget);
    expect((await savedReport()).subtasks.every((s) => s.done), isTrue);
  });

  testWidgets('Mark as done, then Reopen', (tester) async {
    await pumpDetail(tester, 'report');

    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();
    expect(find.text('Reopen task'), findsOneWidget);
    expect((await savedReport()).isDone, isTrue);

    // Wait for the "Task completed" snackbar to go, so it does not cover
    // the button.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reopen task'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as done'), findsOneWidget);
    expect((await savedReport()).isDone, isFalse);
  });

  testWidgets('Delete asks first, then closes the screen', (tester) async {
    await pumpDetail(tester, 'report');

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);

    // The "Delete" button inside the dialog.
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect((await tasks.watchActiveTasks().first).dataOrNull, isEmpty);
  });

  testWidgets('a missing task shows "This task was deleted"', (tester) async {
    await pumpDetail(tester, 'missing');

    expect(find.text('This task was deleted'), findsOneWidget);
  });
}
