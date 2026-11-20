import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:equatable/equatable.dart';

/// What the task detail screen shows.
sealed class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

final class TaskDetailInitial extends TaskDetailState {
  const TaskDetailInitial();
}

final class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

final class TaskDetailLoaded extends TaskDetailState {
  const TaskDetailLoaded({
    required this.task,
    required this.progress,
    required this.isOverdue,
    required this.isDueSoon,
  });

  final Task task;

  /// Checked checklist items, from 0.0 to 1.0.
  final double progress;

  /// Show the red "Overdue" chip.
  final bool isOverdue;

  /// Show the amber "Due soon" chip.
  final bool isDueSoon;

  @override
  List<Object?> get props => [task, progress, isOverdue, isDueSoon];
}

/// The task does not exist (deleted somewhere else).
/// Show "This task was deleted".
final class TaskDetailNotFound extends TaskDetailState {
  const TaskDetailNotFound();
}

/// The user deleted the task from this screen. Close the screen.
final class TaskDetailDeleted extends TaskDetailState {
  const TaskDetailDeleted();
}

/// The task could not load. Show Retry, which calls `load(id)` again.
final class TaskDetailError extends TaskDetailState {
  const TaskDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
