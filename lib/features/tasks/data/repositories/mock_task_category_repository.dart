import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';

/// Keeps categories in memory. For tests and for running the app
/// without Firebase.
class MockTaskCategoryRepository implements TaskCategoryRepository {
  MockTaskCategoryRepository({List<TaskCategory> categories = const []}) {
    for (final category in categories) {
      _categories[category.id] = category;
    }
  }

  /// Two ready categories: University (blue) and Personal (green).
  factory MockTaskCategoryRepository.withSampleData() {
    return MockTaskCategoryRepository(
      categories: const [
        TaskCategory(
          id: 'sample_university',
          name: 'University',
          colorValue: 0xFF2196F3,
        ),
        TaskCategory(
          id: 'sample_personal',
          name: 'Personal',
          colorValue: 0xFF4CAF50,
        ),
      ],
    );
  }

  final Map<String, TaskCategory> _categories = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();
  int _counter = 0;

  /// When set, every method returns this failure.
  Failure? failWith;

  @override
  Stream<Result<List<TaskCategory>>> watchCategories() {
    StreamSubscription<void>? changes;
    late final StreamController<Result<List<TaskCategory>>> controller;
    controller = StreamController<Result<List<TaskCategory>>>(
      onListen: () {
        controller.add(_sorted());
        changes = _changes.stream.listen(
          (_) => controller.add(_sorted()),
          onDone: controller.close,
        );
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Result<TaskCategory>> createCategory(TaskCategory category) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    _counter++;
    final saved = category.copyWith(id: 'mock_category_$_counter');
    _categories[saved.id] = saved;
    _changes.add(null);
    return Result.success(saved);
  }

  @override
  Future<Result<void>> updateCategory(TaskCategory category) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    if (!_categories.containsKey(category.id)) {
      return const Result.failure(NotFoundFailure());
    }
    _categories[category.id] = category;
    _changes.add(null);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteCategory(String id) async {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    if (_categories.remove(id) != null) _changes.add(null);
    return const Result.success(null);
  }

  /// Closes the stream of changes. Call it at the end of a test.
  Future<void> dispose() => _changes.close();

  Result<List<TaskCategory>> _sorted() {
    final failure = failWith;
    if (failure != null) return Result.failure(failure);

    final list = _categories.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Result.success(list);
  }
}
