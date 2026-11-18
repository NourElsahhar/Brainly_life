// MockTaskRepository is a fake TaskRepository that keeps tasks in memory.
// Used for development, Home and the AI assistant while Firestore is not ready.

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:clock/clock.dart';

/// In-memory [TaskRepository] for development and tests.
class MockTaskRepository implements TaskRepository {
  MockTaskRepository({List<Task> tasks = const [], DateTime Function()? now})
    : _tasks = {for (final task in tasks) task.id: task},
      _now = now ?? (() => clock.now().toUtc());

  /// A repository with realistic sample tasks around the current time:
  /// one due in 3 hours, one overdue, one tomorrow, one without a deadline,
  /// and one completed yesterday.
  factory MockTaskRepository.withSampleData({DateTime Function()? now}) {
    final readNow = now ?? (() => clock.now().toUtc());
    final current = readNow();
    final created = current.subtract(const Duration(days: 3));

    Task sample(
      String id,
      String title, {
      DateTime? dueAt,
      TaskPriority priority = TaskPriority.medium,
      TaskStatus status = TaskStatus.todo,
      DateTime? completedAt,
      List<Subtask> subtasks = const [],
    }) {
      return Task(
        id: id,
        title: title,
        dueAt: dueAt,
        priority: priority,
        status: status,
        completedAt: completedAt,
        subtasks: subtasks,
        createdAt: created,
        updatedAt: created,
      );
    }

    return MockTaskRepository(
      now: readNow,
      tasks: [
        sample(
          'sample_report',
          'Finish the lab report',
          dueAt: current.add(const Duration(hours: 3)),
          priority: TaskPriority.high,
          subtasks: const [
            Subtask(id: 's1', title: 'Write the introduction', done: true),
            Subtask(id: 's2', title: 'Add the results'),
          ],
        ),
        sample(
          'sample_email',
          'Email the supervisor',
          dueAt: current.subtract(const Duration(hours: 5)),
        ),
        sample(
          'sample_slides',
          'Prepare presentation slides',
          dueAt: current.add(const Duration(days: 1)),
          priority: TaskPriority.low,
        ),
        sample('sample_books', 'Return library books'),
        sample(
          'sample_groceries',
          'Buy groceries',
          status: TaskStatus.done,
          completedAt: current.subtract(const Duration(days: 1)),
        ),
      ],
    );
  }

  final Map<String, Task> _tasks;
  final DateTime Function() _now;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _counter = 0;

  /// When set, every method returns this failure instead of succeeding.
  /// Use it in tests to check how a Cubit handles errors.
  Failure? failWith;

   @override
  Stream<Result<List<Task>>> watchActiveTasks() => _watch(_activeTasks);

  @override
  Future<Result<List<Task>>> getCompletedTasks({
    String? afterTaskId,
    int limit = TaskRepository.completedPageSize,
  }) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    final since = _now().subtract(const Duration(days: 30));
    final completed =
        _tasks.values
            .where(
              (task) =>
                  task.isDone &&
                  task.completedAt != null &&
                  task.completedAt!.isAfter(since),
            )
            .toList()
          ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    var start = 0;
    if (afterTaskId != null) {
      final index = completed.indexWhere((task) => task.id == afterTaskId);
      if (index == -1) return Result.success(const <Task>[]);
      start = index + 1;
    }
    return Result.success(completed.skip(start).take(limit).toList());
  }

  @override
  Stream<Result<Task>> watchTask(String id) => _watch(() => _taskById(id));

  @override
  Future<Result<Task>> createTask(Task task) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    _counter++;
    final now = _now();
    final saved = task.copyWith(
      id: 'mock_task_$_counter',
      createdAt: now,
      updatedAt: now,
    );
    _tasks[saved.id] = saved;
    _changes.add(null);
    return Result.success(saved);
  }

  @override
  Future<Result<void>> updateTask(Task task) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    if (!_tasks.containsKey(task.id)) {
      return const Result.failure(NotFoundFailure());
    }
    _tasks[task.id] = task.copyWith(updatedAt: _now());
    _changes.add(null);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    if (_tasks.remove(id) != null) _changes.add(null);
    return const Result.success(null);
  }

  /// Closes the stream of changes. Call it at the end of a test.
  Future<void> dispose() => _changes.close();
    /// A stream that sends [read]'s value right away, then again after
  /// every change. Cancelling it stops listening immediately.
  Stream<T> _watch<T>(T Function() read) {
    StreamSubscription<void>? changes;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        changes = _changes.stream.listen(
          (_) => controller.add(read()),
          onDone: controller.close,
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  Result<List<Task>> _activeTasks() {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    final active = _tasks.values.where((task) => !task.isDone).toList()
      ..sort(_byDueAt);
    return Result.success(active);
  }

  Result<Task> _taskById(String id) {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    final task = _tasks[id];
    if (task == null) return const Result.failure(NotFoundFailure());
    return Result.success(task);
  }

  /// Earliest deadline first; tasks without a deadline go last.
  static int _byDueAt(Task a, Task b) {
    final aDue = a.dueAt;
    final bDue = b.dueAt;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }
}
