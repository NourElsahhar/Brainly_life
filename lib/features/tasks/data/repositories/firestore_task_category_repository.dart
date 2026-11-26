// FirestoreTaskCategoryRepository = the real TaskCategoryRepository
// (owner: M3). The Firestore calls are in TaskRemoteDataSource; every error
// becomes a Result (FirestoreResults). Names are checked by CategoryCubit
// (empty, too long, already used) before they get here.

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_results.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';

class FirestoreTaskCategoryRepository
    with FirestoreResults
    implements TaskCategoryRepository {
  FirestoreTaskCategoryRepository({required this._dataSource});

  final TaskRemoteDataSource _dataSource;

  @override
  Stream<Result<List<TaskCategory>>> watchCategories() => watchSafely(
    'Watch categories',
    () => _dataSource.watchCategories().map(
      // Sorted by name, like the mock (A and a together).
      (list) => list
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    ),
  );

  @override
  Future<Result<TaskCategory>> createCategory(TaskCategory category) =>
      runSafely('Create category', () => _dataSource.createCategory(category));

  @override
  Future<Result<void>> updateCategory(TaskCategory category) =>
      runSafely('Update category', () => _dataSource.updateCategory(category));

  @override
  Future<Result<void>> deleteCategory(String id) =>
      runSafely('Delete category', () => _dataSource.deleteCategory(id));
}
