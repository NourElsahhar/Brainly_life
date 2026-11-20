import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:equatable/equatable.dart';

enum TaskFormStatus {
  /// Loading the task to edit.
  loading,

  /// The user is filling the form.
  editing,

  /// Saving. Disable the Save button.
  saving,

  /// Saved. Close the screen.
  saved,

  /// The task to edit does not exist anymore.
  notFound,

  /// The task to edit could not load. Show Retry.
  loadFailed,
}

/// Everything the add / edit task screen shows.
class TaskFormState extends Equatable {
  const TaskFormState({
    required this.status,
    required this.isEdit,
    this.title = '',
    this.description = '',
    this.priority = TaskPriority.medium,
    this.categoryId,
    this.dueAt,
    this.subtasks = const [],
    this.hasChanges = false,
    this.titleError,
    this.descriptionError,
    this.dueAtError,
    this.failure,
  });

  final TaskFormStatus status;

  /// true for "Edit task", false for "New task".
  final bool isEdit;

  final String title;
  final String description;
  final TaskPriority priority;

  /// null means Uncategorized.
  final String? categoryId;

  /// UTC. null means no deadline.
  final DateTime? dueAt;

  final List<Subtask> subtasks;

  /// The user changed something. Ask "Discard changes?" before leaving.
  final bool hasChanges;

  /// Shown under the fields, only after the user taps Save once.
  final String? titleError;
  final String? descriptionError;
  final String? dueAtError;

  /// Loading or saving failed. Show `userMessage` in a snackbar.
  final Failure? failure;

  bool get canAddSubtask => subtasks.length < Task.maxSubtasks;

  @override
  List<Object?> get props => [
    status,
    isEdit,
    title,
    description,
    priority,
    categoryId,
    dueAt,
    subtasks,
    hasChanges,
    titleError,
    descriptionError,
    dueAtError,
    failure,
  ];
}
