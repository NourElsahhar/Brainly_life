// The contract other features use to create a task (owner: M3).
//
// Used by M5's AI assistant: when the user confirms a create_task action,
// it fills a TaskDraft and calls createTask.
//
//   final result = await getIt<TaskCreationPort>().createTask(
//     TaskDraft(title: 'Study physics', dueAt: tomorrowAt5pmUtc),
//   );
//
// Other features may import this file, but not task_model.dart, so
// TaskPriority is exported from here.

import 'package:brainly_life/core/errors/result.dart';
import 'package:equatable/equatable.dart';

import 'package:brainly_life/features/tasks/data/models/task_model.dart'
    show TaskPriority;

export 'package:brainly_life/features/tasks/data/models/task_model.dart'
    show TaskPriority;

/// What another feature knows about a task it wants to create.
///
/// The tasks feature fills in the rest: id, status, dates and
/// category (Uncategorized).
class TaskDraft extends Equatable {
  const TaskDraft({
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.subtaskTitles = const [],
  });

  /// Required. At most 100 characters.
  final String title;

  /// At most 1000 characters.
  final String? description;

  final TaskPriority priority;

  /// The deadline in UTC. Null means no deadline.
  final DateTime? dueAt;

  /// One title per checklist item. At most 20.
  final List<String> subtaskTitles;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    dueAt,
    subtaskTitles,
  ];
}

abstract class TaskCreationPort {
  /// Creates a task from [draft] and returns the new task's id.
  ///
  /// Returns a ValidationFailure when the draft breaks a limit
  /// (empty or too long title, too long description, too many subtasks).
  Future<Result<String>> createTask(TaskDraft draft);
}
