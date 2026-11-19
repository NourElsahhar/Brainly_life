import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';

/// Reads and writes the user's tasks.
///
/// Owned by M3. Other features may depend on this contract.
/// Every method returns a [Result]; implementations never throw.
abstract class TaskRepository {
  /// How many completed tasks one page returns.
  static const int completedPageSize = 20;

  /// Live list of every task that is not done yet.
  ///
  /// The Cubit sorts them into today, upcoming and overdue
  /// with `TaskProgressCalculator`.
  Stream<Result<List<Task>>> watchActiveTasks();

  /// One page of completed tasks from the last 30 days, newest first.
  ///
  /// To get the next page, pass the id of the last task
  /// of the previous page in [afterTaskId].
  Future<Result<List<Task>>> getCompletedTasks({
    String? afterTaskId,
    int limit = TaskRepository.completedPageSize,
  });

  /// Live updates of one task, for the detail screen.
  /// Emits a `NotFoundFailure` if the task does not exist.
  Stream<Result<Task>> watchTask(String id);

  /// Saves a new task.
  /// The repository sets the id, `createdAt` and `updatedAt`,
  /// and returns the saved task.
  Future<Result<Task>> createTask(Task task);

  /// Saves changes to an existing task and refreshes `updatedAt`.
  Future<Result<void>> updateTask(Task task);

  /// Deletes the task. Does nothing if it does not exist.
  Future<Result<void>> deleteTask(String id);

  /// Saves [task] again with its original id and dates.
  /// Used to undo a delete.
  Future<Result<void>> restoreTask(Task task);

  /// Makes every task of category [categoryId] Uncategorized.
  /// Called after the category is deleted.
  Future<Result<void>> clearCategory(String categoryId);
}
