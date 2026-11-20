import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_state.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the task detail screen: shows one task live, ticks checklist
/// items, marks it done or not done, and deletes it.
///
/// Every action returns null when it worked, or the [Failure] to show in
/// a snackbar.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  TaskDetailCubit(
    this._repository, {
    this._calculator = const TaskProgressCalculator(),
    DateTime Function()? now,
  }) : _now = now ?? clock.now,
       super(const TaskDetailInitial());

  final TaskRepository _repository;
  final TaskProgressCalculator _calculator;
  final DateTime Function() _now;
  StreamSubscription<Result<Task>>? _subscription;

  /// The task on screen. null before it loads or after it is gone.
  Task? _task;

  /// True while deleting, so the stream's "not found" is ignored.
  bool _deleting = false;

  /// Starts watching the task. Call it again to retry.
  Future<void> load(String taskId) async {
    emit(const TaskDetailLoading());
    await _subscription?.cancel();
    _subscription = _repository.watchTask(taskId).listen((result) {
      if (_deleting) return;
      switch (result) {
        case Success(:final data):
          _task = data;
          final now = _now();
          emit(
            TaskDetailLoaded(
              task: data,
              progress: _calculator.progress(data),
              isOverdue: _calculator.isOverdue(data, now),
              isDueSoon: _calculator.isDueSoon(data, now),
            ),
          );
        case Failed(:final failure):
          _task = null;
          emit(
            failure is NotFoundFailure
                ? const TaskDetailNotFound()
                : TaskDetailError(failure),
          );
      }
    });
  }

  Future<Failure?> toggleSubtask(String subtaskId) async {
    final task = _task;
    if (task == null) return null;

    final subtasks = [
      for (final s in task.subtasks)
        s.id == subtaskId ? s.copyWith(done: !s.done) : s,
    ];
    return _save(task.copyWith(subtasks: subtasks));
  }

  Future<Failure?> markDone() async {
    final task = _task;
    if (task == null || task.isDone) return null;

    return _save(
      task.copyWith(status: TaskStatus.done, completedAt: _now().toUtc()),
    );
  }

  /// Marks a done task as not done again.
  Future<Failure?> reopen() async {
    final task = _task;
    if (task == null || !task.isDone) return null;

    return _save(
      task.copyWith(status: TaskStatus.todo, clearCompletedAt: true),
    );
  }

  /// Deletes the task. Ask the user to confirm first.
  /// When it works, the state becomes [TaskDetailDeleted].
  Future<Failure?> delete() async {
    final task = _task;
    if (task == null) return null;

    _deleting = true;
    final result = await _repository.deleteTask(task.id);
    if (result case Failed(:final failure)) {
      _deleting = false;
      return failure;
    }

    // Tell the screen first, then stop listening. `_deleting` stays true,
    // so a late "not found" from the stream is ignored.
    final subscription = _subscription;
    _subscription = null;
    _task = null;
    if (!isClosed) emit(const TaskDetailDeleted());
    await subscription?.cancel();
    return null;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  /// The stream brings the new task back, so no emit is needed here.
  Future<Failure?> _save(Task task) async {
    final result = await _repository.updateTask(task);
    return result.failureOrNull;
  }
}
