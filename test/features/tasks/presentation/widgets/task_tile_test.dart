import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 15, 13);
  const uni = TaskCategory(
    id: 'uni',
    name: 'University',
    colorValue: 0xFF74B9FF,
  );

  final task = Task(
    id: 'slides',
    title: 'Prepare slides',
    priority: TaskPriority.high,
    dueAt: DateTime(2026, 11, 15, 15).toUtc(),
    subtasks: const [
      Subtask(id: 'subtask_1', title: 'A', done: true),
      Subtask(id: 'subtask_2', title: 'B', done: true),
      Subtask(id: 'subtask_3', title: 'C'),
    ],
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pumpTile(WidgetTester tester, TaskTile tile) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: tile),
      ),
    );
  }

  testWidgets('shows title, priority, category and checklist progress', (
    tester,
  ) async {
    await pumpTile(tester, TaskTile(task: task, now: now, category: uni));

    expect(find.text('Prepare slides'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('no category shows "Uncategorized"', (tester) async {
    await pumpTile(tester, TaskTile(task: task, now: now));

    expect(find.text('Uncategorized'), findsOneWidget);
  });

  testWidgets('overdue and due soon show their labels', (tester) async {
    await pumpTile(tester, TaskTile(task: task, now: now, isOverdue: true));
    expect(find.textContaining('Overdue ·'), findsOneWidget);

    await pumpTile(tester, TaskTile(task: task, now: now, isDueSoon: true));
    expect(find.textContaining('Due soon ·'), findsOneWidget);
  });

  testWidgets('tapping the circle and the card call their callbacks', (
    tester,
  ) async {
    var toggled = 0;
    var opened = 0;
    await pumpTile(
      tester,
      TaskTile(
        task: task,
        now: now,
        onToggleDone: () => toggled++,
        onTap: () => opened++,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Mark as done'));
    await tester.tap(find.text('Prepare slides'));

    expect(toggled, 1);
    expect(opened, 1);
  });

  testWidgets('a done task shows when it was completed, no priority', (
    tester,
  ) async {
    final done = task.copyWith(
      status: TaskStatus.done,
      completedAt: DateTime(2026, 11, 15, 9, 40).toUtc(),
    );

    await pumpTile(
      tester,
      TaskTile(task: done, now: now, trailing: const Text('Reopen')),
    );

    expect(find.textContaining('Completed today'), findsOneWidget);
    expect(find.text('High'), findsNothing);
    expect(find.text('Reopen'), findsOneWidget);
  });
}
