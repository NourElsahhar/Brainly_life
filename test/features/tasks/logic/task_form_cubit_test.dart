import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_form_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);
  final created = now.subtract(const Duration(days: 2));

  // An overdue task with a description, a category and two checklist items.
  final report = Task(
    id: 'report',
    title: 'Write report',
    description: 'Chapter 1',
    priority: TaskPriority.high,
    categoryId: 'uni',
    dueAt: now.subtract(const Duration(hours: 1)),
    subtasks: const [
      Subtask(id: 'subtask_1', title: 'Intro'),
      Subtask(id: 'subtask_3', title: 'Results', done: true),
    ],
    createdAt: created,
    updatedAt: created,
  );

  // A task that is already done.
  final doneTask = Task(
    id: 'done',
    title: 'Buy books',
    status: TaskStatus.done,
    completedAt: now.subtract(const Duration(hours: 3)),
    createdAt: created,
    updatedAt: created,
  );

  late MockTaskRepository repository;
  late TaskFormCubit cubit;

  TaskFormState get() => cubit.state;

  Future<Task> saved(String id) async =>
      (await repository.watchTask(id).first).dataOrNull!;

  setUp(() {
    repository = MockTaskRepository(tasks: [report, doneTask], now: () => now);
    cubit = TaskFormCubit(repository, now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('starts loading', () {
    expect(get().status, TaskFormStatus.loading);
  });

  group('new task', () {
    setUp(() => cubit.startCreate());

    test('starts empty, with no errors and no changes', () {
      expect(get().status, TaskFormStatus.editing);
      expect(get().isEdit, isFalse);
      expect(get().title, '');
      expect(get().priority, TaskPriority.medium);
      expect(get().hasChanges, isFalse);
      expect(get().titleError, isNull);
    });

    test('typing marks changes but shows no errors before Save', () {
      cubit.titleChanged('');
      cubit.descriptionChanged('Notes');

      expect(get().hasChanges, isTrue);
      expect(get().titleError, isNull);
    });

    test(
      'Save with an empty title shows the error and saves nothing',
      () async {
        await cubit.save();

        expect(get().status, TaskFormStatus.editing);
        expect(get().titleError, 'Please enter a task title.');
        final active = await repository.watchActiveTasks().first;
        expect(active.dataOrNull!.length, 1); // only "report"
      },
    );

    test('after the first Save, errors update while typing', () async {
      await cubit.save();
      cubit.titleChanged('Study');

      expect(get().titleError, isNull);
    });

    test('a too long title or description shows an error', () async {
      cubit.titleChanged('a' * 101);
      cubit.descriptionChanged('b' * 1001);
      await cubit.save();

      expect(get().titleError, isNotNull);
      expect(get().descriptionError, isNotNull);
    });

    test('a deadline in the past shows an error', () async {
      cubit.titleChanged('Study');
      cubit.dueAtChanged(now.subtract(const Duration(minutes: 1)));
      await cubit.save();

      expect(get().dueAtError, 'Pick a time in the future.');
      expect(get().status, TaskFormStatus.editing);
    });

    test('Save creates the task with clean values', () async {
      final due = now.add(const Duration(days: 1));
      cubit
        ..titleChanged('  Study physics  ')
        ..descriptionChanged('   ')
        ..priorityChanged(TaskPriority.high)
        ..categoryChanged('uni')
        ..dueAtChanged(due)
        ..addSubtask(' Chapter 3 ')
        ..addSubtask('Chapter 4');

      await cubit.save();

      expect(get().status, TaskFormStatus.saved);
      final task = await saved('mock_task_1');
      expect(task.title, 'Study physics');
      expect(task.description, isNull);
      expect(task.priority, TaskPriority.high);
      expect(task.categoryId, 'uni');
      expect(task.dueAt, due);
      expect(task.status, TaskStatus.todo);
      expect(task.subtasks.map((s) => s.id), ['subtask_1', 'subtask_2']);
      expect(task.subtasks.map((s) => s.title), ['Chapter 3', 'Chapter 4']);
    });

    test('a failed save keeps the form and shows the failure', () async {
      repository.failWith = const NetworkFailure();
      cubit.titleChanged('Study');

      await cubit.save();

      expect(get().status, TaskFormStatus.editing);
      expect(get().failure, const NetworkFailure());
      expect(get().title, 'Study');
    });
  });

  group('checklist', () {
    setUp(() => cubit.startCreate());

    test('empty items are ignored', () {
      cubit.addSubtask('   ');

      expect(get().subtasks, isEmpty);
    });

    test('rename, toggle and remove work on the right item', () {
      cubit
        ..addSubtask('A')
        ..addSubtask('B')
        ..renameSubtask('subtask_1', 'A2')
        ..toggleSubtask('subtask_2')
        ..removeSubtask('subtask_1');

      expect(get().subtasks, const [
        Subtask(id: 'subtask_2', title: 'B', done: true),
      ]);
    });

    test('stops at 20 items', () {
      for (var i = 0; i < 25; i++) {
        cubit.addSubtask('Item $i');
      }

      expect(get().subtasks.length, 20);
      expect(get().canAddSubtask, isFalse);
    });
  });

  group('edit task', () {
    test('fills the form from the task, with no changes yet', () async {
      await cubit.startEdit('report');

      expect(get().status, TaskFormStatus.editing);
      expect(get().isEdit, isTrue);
      expect(get().title, 'Write report');
      expect(get().description, 'Chapter 1');
      expect(get().categoryId, 'uni');
      expect(get().subtasks.length, 2);
      expect(get().hasChanges, isFalse);
    });

    test('changing a field and changing it back clears hasChanges', () async {
      await cubit.startEdit('report');

      cubit.titleChanged('Write the report');
      expect(get().hasChanges, isTrue);

      cubit.titleChanged('Write report');
      expect(get().hasChanges, isFalse);
    });

    test('an old deadline that was not changed can be saved', () async {
      await cubit.startEdit('report'); // overdue
      cubit.titleChanged('Write final report');

      await cubit.save();

      expect(get().status, TaskFormStatus.saved);
      expect((await saved('report')).title, 'Write final report');
    });

    test('changing to another past deadline shows an error', () async {
      await cubit.startEdit('report');
      cubit.dueAtChanged(now.subtract(const Duration(hours: 5)));

      await cubit.save();

      expect(get().dueAtError, isNotNull);
    });

    test('clearing fields saves them as empty and keeps the rest', () async {
      await cubit.startEdit('report');
      cubit
        ..descriptionChanged('')
        ..categoryChanged(null)
        ..dueAtChanged(null);

      await cubit.save();

      final task = await saved('report');
      expect(task.id, 'report');
      expect(task.description, isNull);
      expect(task.categoryId, isNull);
      expect(task.dueAt, isNull);
      expect(task.createdAt, created);
    });

    test('a done task stays done after editing', () async {
      await cubit.startEdit('done');
      cubit.titleChanged('Buy two books');

      await cubit.save();

      final task = await saved('done');
      expect(task.status, TaskStatus.done);
      expect(task.completedAt, doneTask.completedAt);
    });

    test('new checklist items continue after the highest id', () async {
      await cubit.startEdit('report'); // has subtask_1 and subtask_3
      cubit.addSubtask('Conclusion');

      expect(get().subtasks.last.id, 'subtask_4');
    });

    test('a missing task shows notFound', () async {
      await cubit.startEdit('missing');

      expect(get().status, TaskFormStatus.notFound);
    });

    test('a failing load shows loadFailed with the failure', () async {
      repository.failWith = const NetworkFailure();

      await cubit.startEdit('report');

      expect(get().status, TaskFormStatus.loadFailed);
      expect(get().failure, const NetworkFailure());
    });
  });
}
