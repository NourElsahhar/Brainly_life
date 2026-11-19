import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the Completed tab: done tasks from the last 30 days, 20 at a
/// time, with reopen, and delete with undo.
///
/// Call [load] every time the tab opens, so tasks completed in the other
/// tabs show up.
class CompletedTasksCubit extends Cubit<CompletedTasksState> {
  CompletedTasksCubit(this._repository) : super(const CompletedTasksInitial());

  static const int _pageSize = TaskRepository.completedPageSize;

  final TaskRepository _repository;

  List<Task> _tasks = const [];
  bool _hasMore = false;
  bool _isLoadingMore = false;
  Task? _lastDeleted;

  /// Goes up on every [load], so answers from an older load are ignored.
  int _generation = 0;

  /// Loads the first page. Call it again to refresh or retry.
  Future<void> load() async {
    final generation = ++_generation;
    _isLoadingMore = false;
    _lastDeleted = null;
    emit(const CompletedTasksLoading());

    final result = await _repository.getCompletedTasks();
    if (isClosed || generation != _generation) return;

    switch (result) {
      case Success(:final data):
        _tasks = data;
        _hasMore = data.length == _pageSize;
        _emitList();
      case Failed(:final failure):
        emit(CompletedTasksError(failure));
    }
  }

  /// Loads the next page. Call it when the user scrolls near the end.
  Future<void> loadMore() async {
    if (state is! CompletedTasksLoaded || !_hasMore || _isLoadingMore) return;

    final generation = _generation;
    _isLoadingMore = true;
    _emitList();

    final result = await _repository.getCompletedTasks(
      afterTaskId: _tasks.isEmpty ? null : _tasks.last.id,
    );
    if (isClosed || generation != _generation) return;
    _isLoadingMore = false;

    switch (result) {
      case Success(:final data):
        _tasks = [..._tasks, ...data];
        _hasMore = data.length == _pageSize;
        _emitList();
      case Failed(:final failure):
        _emitList(loadMoreFailure: failure);
    }
  }

  /// Marks a done task as not done. It leaves this tab.
  Future<void> reopenTask(Task task) async {
    final reopened = task.copyWith(
      status: TaskStatus.todo,
      clearCompletedAt: true,
    );
    final result = await _repository.updateTask(reopened);
    if (isClosed) return;

    switch (result) {
      case Success():
        _removeLocally(task);
        _lastDeleted = null;
        _emitList();
      case Failed(:final failure):
        _emitList(actionFailure: failure);
    }
  }

  Future<void> deleteTask(Task task) async {
    final result = await _repository.deleteTask(task.id);
    if (isClosed) return;

    switch (result) {
      case Success():
        _removeLocally(task);
        _lastDeleted = task;
        _emitList();
      case Failed(:final failure):
        _emitList(actionFailure: failure);
    }
  }

  /// Puts back the last deleted task.
  Future<void> undo() async {
    final task = _lastDeleted;
    if (task == null) return;

    final result = await _repository.restoreTask(task);
    if (isClosed) return;

    switch (result) {
      case Success():
        _lastDeleted = null;
        _tasks = [..._tasks, task]..sort(_newestFirst);
        _emitList();
      case Failed(:final failure):
        _emitList(actionFailure: failure);
    }
  }

  void _removeLocally(Task task) {
    _tasks = _tasks.where((t) => t.id != task.id).toList();
  }

  void _emitList({Failure? loadMoreFailure, Failure? actionFailure}) {
    if (_tasks.isEmpty && !_hasMore) {
      emit(
        CompletedTasksEmpty(
          lastDeleted: _lastDeleted,
          actionFailure: actionFailure,
        ),
      );
      return;
    }
    emit(
      CompletedTasksLoaded(
        tasks: _tasks,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
        loadMoreFailure: loadMoreFailure,
        lastDeleted: _lastDeleted,
        actionFailure: actionFailure,
      ),
    );
  }

  /// Latest completion first.
  static int _newestFirst(Task a, Task b) {
    final aDone = a.completedAt ?? a.updatedAt;
    final bDone = b.completedAt ?? b.updatedAt;
    return bDone.compareTo(aDone);
  }
}
