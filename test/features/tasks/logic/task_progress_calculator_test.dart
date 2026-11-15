import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = TaskProgressCalculator();
  const cairo = Duration(hours: 2);

  // 15 Nov 2026, 13:00 UTC = 3:00 PM in Cairo.
  final now = DateTime.utc(2026, 11, 15, 13);

  Task buildTask({
    DateTime? dueAt,
    TaskStatus status = TaskStatus.todo,
    List<Subtask> subtasks = const [],
  }) {
    return Task(
      id: 't1',
      title: 'Task',
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
      dueAt: dueAt,
      status: status,
      subtasks: subtasks,
    );
  }

  group('progress', () {
    test('is 0 for a task without subtasks that is not done', () {
      expect(calculator.progress(buildTask()), 0);
    });

    test('is 1 for a task without subtasks that is done', () {
      expect(calculator.progress(buildTask(status: TaskStatus.done)), 1);
    });

    test('is the share of checked subtasks', () {
      final task = buildTask(
        subtasks: const [
          Subtask(id: 's1', title: 'A', done: true),
          Subtask(id: 's2', title: 'B', done: true),
          Subtask(id: 's3', title: 'C'),
          Subtask(id: 's4', title: 'D'),
        ],
      );

      expect(calculator.progress(task), 0.5);
    });
  });

  group('isOverdue', () {
    test('is true when the deadline passed and the task is not done', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 7));

      expect(calculator.isOverdue(task, now), isTrue);
    });

    test('is false when the task is done', () {
      final task = buildTask(
        dueAt: DateTime.utc(2026, 11, 15, 7),
        status: TaskStatus.done,
      );

      expect(calculator.isOverdue(task, now), isFalse);
    });

    test('is false when there is no deadline', () {
      expect(calculator.isOverdue(buildTask(), now), isFalse);
    });
  });

  group('isDueSoon', () {
    test('is true when the deadline is within 24 hours', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 18));

      expect(calculator.isDueSoon(task, now), isTrue);
    });

    test('is false when the deadline is more than 24 hours away', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 17, 13));

      expect(calculator.isDueSoon(task, now), isFalse);
    });

    test('is false when the task is already overdue', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 7));

      expect(calculator.isDueSoon(task, now), isFalse);
    });
  });

  group('isDueToday (Cairo, UTC+2)', () {
    test('is true for 10:00 PM Cairo today', () {
      // 20:00 UTC = 10:00 PM Cairo, still 15 Nov.
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 20));

      expect(calculator.isDueToday(task, now, utcOffset: cairo), isTrue);
    });

    test(
      'is false for 12:30 AM Cairo tomorrow, even if it is today in UTC',
      () {
        // 22:30 UTC on 15 Nov = 12:30 AM on 16 Nov in Cairo.
        final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 22, 30));

        expect(calculator.isDueToday(task, now, utcOffset: cairo), isFalse);
      },
    );
  });

  group('bucketOf', () {
    TaskBucket bucket(Task task) =>
        calculator.bucketOf(task, now, utcOffset: cairo);

    test('a done task is completed', () {
      final task = buildTask(
        dueAt: DateTime.utc(2026, 11, 15, 7),
        status: TaskStatus.done,
      );

      expect(bucket(task), TaskBucket.completed);
    });

    test('a task due earlier today is overdue, not today', () {
      // 07:00 UTC = 9:00 AM Cairo today, already passed.
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 7));

      expect(bucket(task), TaskBucket.overdue);
    });

    test('a task due later today is today', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 15, 18));

      expect(bucket(task), TaskBucket.today);
    });

    test('a task due tomorrow is upcoming', () {
      final task = buildTask(dueAt: DateTime.utc(2026, 11, 16, 10));

      expect(bucket(task), TaskBucket.upcoming);
    });

    test('a task without a deadline is upcoming', () {
      expect(bucket(buildTask()), TaskBucket.upcoming);
    });
  });
}
