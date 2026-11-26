// FirestoreTaskRepository = the real TaskRepository (owner: M3).
// The Firestore calls are in TaskRemoteDataSource. Here the dates
// (createdAt, updatedAt) are set, like the mock does, and every error
// becomes a Result (FirestoreResults).

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_results.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:clock/clock.dart';

class FirestoreTaskRepository with FirestoreResults implements TaskRepository {
  FirestoreTaskRepository({required this._dataSource, DateTime Function()? now})
    : _now = now ?? (() => clock.now().toUtc());

  final TaskRemoteDataSource _dataSource;
  final DateTime Function() _now;

  /// Completed tasks older than this are not shown.
  static const Duration completedWindow = Duration(days: 30);

  @override
  Stream<Result<List<Task>>> watchActiveTasks() =>
      watchSafely('Watch tasks', _dataSource.watchActiveTasks);

  @override
  Future<Result<List<Task>>> getCompletedTasks({
    String? afterTaskId,
    int limit = TaskRepository.completedPageSize,
  }) => runSafely(
    'Load completed tasks',
    () => _dataSource.getCompletedTasks(
      since: _now().subtract(completedWindow),
      limit: limit,
      afterTaskId: afterTaskId,
    ),
  );

  @override
  Stream<Result<Task>> watchTask(String id) =>
      watchSafely('Watch task', () => _dataSource.watchTask(id)).map(
        (result) => switch (result) {
          Success(data: final task?) => Result.success(task),
          Success() => const Result.failure(NotFoundFailure()),
          Failed(:final failure) => Result.failure(failure),
        },
      );

  @override
  Future<Result<Task>> createTask(Task task) => runSafely('Create task', () {
    final now = _now();
    return _dataSource.createTask(
      task.copyWith(createdAt: now, updatedAt: now),
    );
  });

  @override
  Future<Result<void>> updateTask(Task task) => runSafely(
    'Update task',
    () => _dataSource.updateTask(task.copyWith(updatedAt: _now())),
  );

  @override
  Future<Result<void>> deleteTask(String id) =>
      runSafely('Delete task', () => _dataSource.deleteTask(id));

  @override
  Future<Result<void>> restoreTask(Task task) =>
      runSafely('Restore task', () => _dataSource.restoreTask(task));

  @override
  Future<Result<void>> clearCategory(String categoryId) => runSafely(
    'Clear category',
    () => _dataSource.clearCategory(categoryId, _now()),
  );
}
