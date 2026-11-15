import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 14, 10);
  final dueAt = DateTime.utc(2026, 11, 20, 18);

  Task buildTask() => Task(
    id: 't1',
    title: 'Finish report',
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  Task buildFullTask() => buildTask().copyWith(
    description: 'Chapter 3 and 4',
    priority: TaskPriority.high,
    categoryId: 'c1',
    dueAt: dueAt,
    subtasks: const [
      Subtask(id: 's1', title: 'Chapter 3', done: true),
      Subtask(id: 's2', title: 'Chapter 4'),
    ],
    reminderOffsetMinutes: 60,
    reminderId: 'task_t1',
  );

  group('Task defaults', () {
    test('a new task is medium priority, todo, with no subtasks', () {
      final task = buildTask();

      expect(task.priority, TaskPriority.medium);
      expect(task.status, TaskStatus.todo);
      expect(task.subtasks, isEmpty);
      expect(task.isDone, isFalse);
    });

    test('isDone is true when the status is done', () {
      final task = buildTask().copyWith(status: TaskStatus.done);

      expect(task.isDone, isTrue);
    });

    test('two tasks with the same values are equal', () {
      expect(buildFullTask(), equals(buildFullTask()));
    });
  });

  group('Task.copyWith', () {
    test('changes only the given field', () {
      final task = buildFullTask();

      final renamed = task.copyWith(title: 'New title');

      expect(renamed.title, 'New title');
      expect(renamed.dueAt, task.dueAt);
      expect(renamed.categoryId, task.categoryId);
      expect(task.title, 'Finish report');
    });

    test('passing null keeps the old value', () {
      final task = buildFullTask();

      final copy = task.copyWith(dueAt: null);

      expect(copy.dueAt, dueAt);
    });

    test('clearDueAt removes the deadline', () {
      final copy = buildFullTask().copyWith(clearDueAt: true);

      expect(copy.dueAt, isNull);
    });

    test('clearCategory makes the task uncategorized', () {
      final copy = buildFullTask().copyWith(clearCategory: true);

      expect(copy.categoryId, isNull);
    });

    test('clearReminder removes the offset and the reminder id together', () {
      final copy = buildFullTask().copyWith(clearReminder: true);

      expect(copy.reminderOffsetMinutes, isNull);
      expect(copy.reminderId, isNull);
    });
  });

  group('Task Firestore mapping', () {
    test('toFirestore stores enums as names, dates as Timestamps, no id', () {
      final map = buildFullTask().toFirestore();

      expect(map['priority'], 'high');
      expect(map['status'], 'todo');
      expect(map['dueAt'], Timestamp.fromDate(dueAt));
      expect(map['subtasks'], [
        {'id': 's1', 'title': 'Chapter 3', 'done': true},
        {'id': 's2', 'title': 'Chapter 4', 'done': false},
      ]);
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap(toFirestore()) gives back a full task', () {
      final task = buildFullTask();

      expect(Task.fromMap(task.id, task.toFirestore()), equals(task));
    });

    test('fromMap(toFirestore()) keeps empty fields empty', () {
      final task = buildTask();

      final restored = Task.fromMap(task.id, task.toFirestore());

      expect(restored, equals(task));
      expect(restored.dueAt, isNull);
      expect(restored.categoryId, isNull);
    });
  });
}
