import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:equatable/equatable.dart';

/// What the Completed tab shows: done tasks from the last 30 days,
/// newest first, loaded 20 at a time.
sealed class CompletedTasksState extends Equatable {
  const CompletedTasksState();

  @override
  List<Object?> get props => [];
}

final class CompletedTasksInitial extends CompletedTasksState {
  const CompletedTasksInitial();
}

/// Loading the first page.
final class CompletedTasksLoading extends CompletedTasksState {
  const CompletedTasksLoading();
}

/// No task was completed in the last 30 days.
final class CompletedTasksEmpty extends CompletedTasksState {
  const CompletedTasksEmpty({this.lastDeleted, this.actionFailure});

  /// The task that was just deleted. Show an Undo snackbar.
  final Task? lastDeleted;

  /// A reopen, delete or undo that failed. Show it in a snackbar.
  final Failure? actionFailure;

  @override
  List<Object?> get props => [lastDeleted, actionFailure];
}

final class CompletedTasksLoaded extends CompletedTasksState {
  const CompletedTasksLoaded({
    required this.tasks,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.lastDeleted,
    this.actionFailure,
  });

  final List<Task> tasks;

  /// There may be another page after this one.
  final bool hasMore;

  /// The next page is loading. Show a small spinner under the list.
  final bool isLoadingMore;

  /// The next page failed. Keep the list and show a Retry under it.
  final Failure? loadMoreFailure;

  /// The task that was just deleted. Show an Undo snackbar.
  final Task? lastDeleted;

  /// A reopen, delete or undo that failed. Show it in a snackbar.
  final Failure? actionFailure;

  @override
  List<Object?> get props => [
    tasks,
    hasMore,
    isLoadingMore,
    loadMoreFailure,
    lastDeleted,
    actionFailure,
  ];
}

/// The first page failed. Show a Retry button that calls `load()`.
final class CompletedTasksError extends CompletedTasksState {
  const CompletedTasksError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
