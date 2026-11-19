import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:equatable/equatable.dart';

/// How the visible tasks are ordered.
enum TaskSort { dueDate, priority }

/// What the user just did to a task, so the screen can offer "Undo".
enum TaskChangeType { completed, deleted }

class TaskChange extends Equatable {
  const TaskChange({required this.type, required this.task});

  final TaskChangeType type;

  /// The task as it was before the change. Undo puts it back.
  final Task task;

  @override
  List<Object?> get props => [type, task];
}

sealed class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => [];
}

final class TaskListInitial extends TaskListState {
  const TaskListInitial();
}

final class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

/// The user has no task left to do.
final class TaskListEmpty extends TaskListState {
  const TaskListEmpty({this.lastChange, this.actionFailure});

  /// Set right after a task was completed or deleted, to show "Undo".
  final TaskChange? lastChange;

  /// Set when completing, deleting or undoing failed, to show a snackbar.
  final Failure? actionFailure;

  @override
  List<Object?> get props => [lastChange, actionFailure];
}

final class TaskListLoaded extends TaskListState {
  const TaskListLoaded({
    required this.tasks,
    required this.tab,
    required this.counts,
    this.query = '',
    this.sort = TaskSort.dueDate,
    this.lastChange,
    this.actionFailure,
  });

  /// The tasks of [tab], after search and sort.
  final List<Task> tasks;

  final TaskBucket tab;

  /// How many tasks each tab has (search not applied), for the tab badges.
  final Map<TaskBucket, int> counts;

  final String query;

  final TaskSort sort;

  /// Set right after a task was completed or deleted, to show "Undo".
  final TaskChange? lastChange;

  /// Set when completing, deleting or undoing failed, to show a snackbar.
  final Failure? actionFailure;

  int countOf(TaskBucket bucket) => counts[bucket] ?? 0;

  @override
  List<Object?> get props => [
    tasks,
    tab,
    counts,
    query,
    sort,
    lastChange,
    actionFailure,
  ];
}

final class TaskListError extends TaskListState {
  const TaskListError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
