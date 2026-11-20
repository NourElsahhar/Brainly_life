import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';

/// Saves and loads the user's task categories.
///
/// Stored at `users/{uid}/taskCategories/{id}`. Every method returns a
/// [Result] and never throws.
abstract class TaskCategoryRepository {
  /// Category names are short, because they show in a small chip.
  static const int maxNameLength = 30;

  /// Live list of the user's categories, sorted by name.
  Stream<Result<List<TaskCategory>>> watchCategories();

  /// Saves a new category. The repository sets the id.
  Future<Result<TaskCategory>> createCategory(TaskCategory category);

  /// Saves a new name or colour.
  Future<Result<void>> updateCategory(TaskCategory category);

  /// Deletes the category only. Call `TaskRepository.clearCategory`
  /// after it, so its tasks become Uncategorized.
  Future<Result<void>> deleteCategory(String id);
}
