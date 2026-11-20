import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/debouncer.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_list_state.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the task list screen: the today, upcoming and overdue tabs,
/// search, sort, and complete or delete with undo.
///
/// The completed tab (paginated) has its own Cubit.
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(
    this._repository, {
    this._calculator = const TaskProgressCalculator(),
    DateTime Function()? now,
    Duration searchDelay = const Duration(milliseconds: 400),
  }) : _now = now ?? clock.now,
       _debouncer = Debouncer(delay: searchDelay),
       super(const TaskListInitial());

  final TaskRepository _repository;
  final TaskProgressCalculator _calculator;
  final DateTime Function() _now;
  final Debouncer _debouncer;
  StreamSubscription<Result<List<Task>>>? _subscription;

  List<Task> _active = const [];
  TaskBucket _tab = TaskBucket.today;
  String _query = '';
  TaskSort _sort = TaskSort.dueDate;
  TaskChange? _lastChange;

  /// Starts listening to the user's tasks. Call it again to retry.
  Future<void> load() async {
    emit(const TaskListLoading());
    await _subscription?.cancel();
    _subscription = _repository.watchActiveTasks().listen((result) {
      result.fold(
        onSuccess: (tasks) {
          _active = tasks;
          _emitList();
        },
        onFailure: (failure) => emit(TaskListError(failure)),
      );
    });
  }

  void selectTab(TaskBucket tab) {
    _tab = tab;
    _refresh();
  }

  void sortBy(TaskSort sort) {
    _sort = sort;
    _refresh();
  }

  /// Filters by title, 400 ms after the user stops typing.
  void search(String text) {
    _debouncer.run(() {
      _query = text.trim().toLowerCase();
      _refresh();
    });
  }

  Future<void> completeTask(Task task) async {
    _hideNow(task);
    final done = task.copyWith(
      status: TaskStatus.done,
      completedAt: _now().toUtc(),
    );
    final result = await _repository.updateTask(done);
    _afterAction(
      result,
      TaskChange(type: TaskChangeType.completed, task: task),
      original: task,
    );
  }

  Future<void> deleteTask(Task task) async {
    _hideNow(task);
    final result = await _repository.deleteTask(task.id);
    _afterAction(
      result,
      TaskChange(type: TaskChangeType.deleted, task: task),
      original: task,
    );
  }

  /// Puts back the task of the last complete or delete.
  Future<void> undo() async {
    final change = _lastChange;
    if (change == null) return;
    _lastChange = null;

    final result = switch (change.type) {
      TaskChangeType.completed => await _repository.updateTask(change.task),
      TaskChangeType.deleted => await _repository.restoreTask(change.task),
    };
    _afterAction(result, null);
  }

  @override
  Future<void> close() async {
    _debouncer.dispose();
    await _subscription?.cancel();
    return super.close();
  }

  /// [original] is put back on screen when the action failed.
  void _afterAction(Result<void> result, TaskChange? change, {Task? original}) {
    switch (result) {
      case Success():
        _lastChange = change;
        _emitList();
      case Failed(:final failure):
        if (original != null && !_active.any((t) => t.id == original.id)) {
          _active = [..._active, original];
        }
        _emitList(actionFailure: failure);
    }
  }

  /// Takes the task off the screen right away, before the repository
  /// answers. Swipe to delete needs this.
  void _hideNow(Task task) {
    _active = [
      for (final t in _active)
        if (t.id != task.id) t,
    ];
    _emitList();
  }

  /// Emits again only when the list is already on screen.
  void _refresh() {
    if (state is TaskListLoaded || state is TaskListEmpty) _emitList();
  }

  void _emitList({Failure? actionFailure}) {
    if (isClosed) return;
    if (_active.isEmpty) {
      emit(
        TaskListEmpty(lastChange: _lastChange, actionFailure: actionFailure),
      );
      return;
    }

    final now = _now();
    final counts = <TaskBucket, int>{};
    final visible = <Task>[];
    for (final task in _active) {
      final bucket = _calculator.bucketOf(task, now);
      counts[bucket] = (counts[bucket] ?? 0) + 1;
      final matches =
          _query.isEmpty || task.title.toLowerCase().contains(_query);
      if (bucket == _tab && matches) visible.add(task);
    }
    visible.sort(_sort == TaskSort.priority ? _byPriority : _byDueAt);

    emit(
      TaskListLoaded(
        tasks: visible,
        tab: _tab,
        counts: counts,
        query: _query,
        sort: _sort,
        lastChange: _lastChange,
        actionFailure: actionFailure,
      ),
    );
  }

  /// Earliest deadline first; tasks without a deadline go last.
  static int _byDueAt(Task a, Task b) {
    final aDue = a.dueAt;
    final bDue = b.dueAt;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  /// High priority first; same priority by deadline.
  static int _byPriority(Task a, Task b) {
    final byPriority = b.priority.index.compareTo(a.priority.index);
    return byPriority != 0 ? byPriority : _byDueAt(a, b);
  }
}
