import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_cubit.dart';
import 'package:brainly_life/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  final report = Task(
    id: 'report',
    title: 'Write report',
    priority: TaskPriority.low,
    subtasks: const [Subtask(id: 'subtask_1', title: 'Outline')],
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

  /// Opens the form on top of a "Home" page, so we can see it close.
  Future<void> pumpForm(WidgetTester tester, {String? taskId}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/form',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) {
                  final cubit = TaskFormCubit(tasks, now: () => now);
                  taskId == null
                      ? cubit.startCreate()
                      : cubit.startEdit(taskId);
                  return cubit;
                },
              ),
              BlocProvider(
                create: (_) => CategoryCubit(categories, tasks)..load(),
              ),
            ],
            child: TaskFormView(taskId: taskId),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    router.push('/form');
    await tester.pumpAndSettle();
  }

  Future<List<Task>> activeTasks() async =>
      (await tasks.watchActiveTasks().first).dataOrNull!;

  /// The first box of the form is the title.
  Finder titleField() => find.byType(TextField).first;

  testWidgets('new task: Save with no title shows the error', (tester) async {
    await pumpForm(tester);

    expect(find.text('New task'), findsOneWidget);
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a task title.'), findsOneWidget);
    expect(find.text('Home'), findsNothing); // still on the form
  });

  testWidgets('new task: fills the form, saves and closes', (tester) async {
    await pumpForm(tester);

    await tester.enterText(titleField(), 'Study physics');
    await tester.ensureVisible(find.text('University'));
    await tester.tap(find.text('University'));
    final newSubtask = find.widgetWithText(TextField, 'Add a subtask');
    await tester.ensureVisible(newSubtask);
    await tester.enterText(newSubtask, 'Ch 3');
    await tester.tap(find.byTooltip('Add subtask'));
    await tester.pumpAndSettle();
    expect(find.text('Ch 3'), findsOneWidget);

    await tester.ensureVisible(find.text('Add task'));
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final created = (await activeTasks()).firstWhere(
      (t) => t.title == 'Study physics',
    );
    expect(created.categoryId, 'uni');
    expect(created.subtasks.single.title, 'Ch 3');
  });

  testWidgets('edit: loads the task, saves the new title', (tester) async {
    await pumpForm(tester, taskId: 'report');

    expect(find.text('Edit task'), findsOneWidget);
    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Outline'), findsOneWidget);

    await tester.enterText(titleField(), 'Write final report');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect((await activeTasks()).single.title, 'Write final report');
  });

  testWidgets('back with changes asks "Discard changes?"', (tester) async {
    await pumpForm(tester);
    await tester.enterText(titleField(), 'Something');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(await activeTasks(), [report]); // nothing was saved
  });

  testWidgets('back with no changes closes right away', (tester) async {
    await pumpForm(tester);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('edit a deleted task shows "Task not found"', (tester) async {
    await pumpForm(tester, taskId: 'missing');

    expect(find.text('Task not found'), findsOneWidget);
  });
}
