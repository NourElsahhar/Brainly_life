import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_form_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the add / edit task screen.
///
/// Call [startCreate] for a new task, or [startEdit] with the task id.
/// Field errors show only after the first [save].
class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? clock.now,
      super(const TaskFormState(status: TaskFormStatus.loading, isEdit: false));

  final TaskRepository _repository;
  final DateTime Function() _now;

  /// The task as it was before editing. null when creating.
  Task? _original;
  bool _isEdit = false;
  TaskFormStatus _status = TaskFormStatus.loading;
  bool _showErrors = false;
  int _nextSubtaskNumber = 1;

  String _title = '';
  String _description = '';
  TaskPriority _priority = TaskPriority.medium;
  String? _categoryId;
  DateTime? _dueAt;
  List<Subtask> _subtasks = const [];

  void startCreate() {
    _isEdit = false;
    _original = null;
    _status = TaskFormStatus.editing;
    _emitForm();
  }

  /// Loads the task and fills the form. Call it again to retry.
  Future<void> startEdit(String taskId) async {
    _isEdit = true;
    _status = TaskFormStatus.loading;
    _emitForm();

    final result = await _repository.watchTask(taskId).first;
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        _fillFrom(data);
        _status = TaskFormStatus.editing;
        _emitForm();
      case Failed(:final failure):
        _status = failure is NotFoundFailure
            ? TaskFormStatus.notFound
            : TaskFormStatus.loadFailed;
        _emitForm(failure: failure);
    }
  }

  void titleChanged(String value) => _update(() => _title = value);

  void descriptionChanged(String value) => _update(() => _description = value);

  void priorityChanged(TaskPriority value) => _update(() => _priority = value);

  /// null means Uncategorized.
  void categoryChanged(String? categoryId) =>
      _update(() => _categoryId = categoryId);

  /// null removes the deadline.
  void dueAtChanged(DateTime? value) => _update(() => _dueAt = value?.toUtc());

  void addSubtask(String title) {
    final clean = title.trim();
    if (clean.isEmpty || _subtasks.length >= Task.maxSubtasks) return;
    final subtask = Subtask(id: 'subtask_$_nextSubtaskNumber', title: clean);
    _nextSubtaskNumber++;
    _update(() => _subtasks = [..._subtasks, subtask]);
  }

  void renameSubtask(String id, String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    _update(
      () => _subtasks = [
        for (final s in _subtasks) s.id == id ? s.copyWith(title: clean) : s,
      ],
    );
  }

  void toggleSubtask(String id) {
    _update(
      () => _subtasks = [
        for (final s in _subtasks) s.id == id ? s.copyWith(done: !s.done) : s,
      ],
    );
  }

  void removeSubtask(String id) {
    _update(
      () => _subtasks = [
        for (final s in _subtasks)
          if (s.id != id) s,
      ],
    );
  }

  /// Checks the fields, then creates or updates the task.
  Future<void> save() async {
    if (_status != TaskFormStatus.editing) return;
    _showErrors = true;
    if (_titleError != null ||
        _descriptionError != null ||
        _dueAtError != null) {
      _emitForm();
      return;
    }

    _status = TaskFormStatus.saving;
    _emitForm();

    final task = _buildTask();
    final Failure? failure = _original == null
        ? (await _repository.createTask(task)).failureOrNull
        : (await _repository.updateTask(task)).failureOrNull;
    if (isClosed) return;

    _status = failure == null ? TaskFormStatus.saved : TaskFormStatus.editing;
    _emitForm(failure: failure);
  }

  void _update(void Function() change) {
    if (_status != TaskFormStatus.editing) return;
    change();
    _emitForm();
  }

  void _fillFrom(Task task) {
    _original = task;
    _title = task.title;
    _description = task.description ?? '';
    _priority = task.priority;
    _categoryId = task.categoryId;
    _dueAt = task.dueAt;
    _subtasks = task.subtasks;
    _nextSubtaskNumber = _highestSubtaskNumber(task.subtasks) + 1;
  }

  Task _buildTask() {
    final now = _now().toUtc();
    final title = _title.trim();
    final description = _description.trim();
    final original = _original;

    if (original == null) {
      return Task(
        id: '', // the repository gives the real id
        title: title,
        description: description.isEmpty ? null : description,
        priority: _priority,
        categoryId: _categoryId,
        dueAt: _dueAt,
        subtasks: _subtasks,
        createdAt: now,
        updatedAt: now,
      );
    }
    // Keeps id, status, completedAt and createdAt.
    return original.copyWith(
      title: title,
      description: description,
      clearDescription: description.isEmpty,
      priority: _priority,
      categoryId: _categoryId,
      clearCategory: _categoryId == null,
      dueAt: _dueAt,
      clearDueAt: _dueAt == null,
      subtasks: _subtasks,
      updatedAt: now,
    );
  }

  String? get _titleError {
    final title = _title.trim();
    if (title.isEmpty) return 'Please enter a task title.';
    if (title.length > Task.maxTitleLength) {
      return 'The title can be at most ${Task.maxTitleLength} characters.';
    }
    return null;
  }

  String? get _descriptionError {
    if (_description.trim().length <= Task.maxDescriptionLength) return null;
    return 'The description can be at most '
        '${Task.maxDescriptionLength} characters.';
  }

  String? get _dueAtError {
    final dueAt = _dueAt;
    if (dueAt == null) return null;
    // An old deadline the user did not change is fine.
    if (_original != null && dueAt == _original!.dueAt) return null;
    return dueAt.isAfter(_now()) ? null : 'Pick a time in the future.';
  }

  bool get _hasChanges {
    final original = _original;
    if (original == null) {
      return _title.trim().isNotEmpty ||
          _description.trim().isNotEmpty ||
          _priority != TaskPriority.medium ||
          _categoryId != null ||
          _dueAt != null ||
          _subtasks.isNotEmpty;
    }
    return _title.trim() != original.title ||
        _description.trim() != (original.description ?? '') ||
        _priority != original.priority ||
        _categoryId != original.categoryId ||
        _dueAt != original.dueAt ||
        !listEquals(_subtasks, original.subtasks);
  }

  void _emitForm({Failure? failure}) {
    if (isClosed) return;
    emit(
      TaskFormState(
        status: _status,
        isEdit: _isEdit,
        title: _title,
        description: _description,
        priority: _priority,
        categoryId: _categoryId,
        dueAt: _dueAt,
        subtasks: _subtasks,
        hasChanges: _hasChanges,
        titleError: _showErrors ? _titleError : null,
        descriptionError: _showErrors ? _descriptionError : null,
        dueAtError: _showErrors ? _dueAtError : null,
        failure: failure,
      ),
    );
  }

  /// The biggest N in ids like "subtask_N", so new ids never repeat.
  static int _highestSubtaskNumber(List<Subtask> subtasks) {
    var highest = 0;
    for (final subtask in subtasks) {
      final number = int.tryParse(subtask.id.replaceFirst('subtask_', ''));
      if (number != null && number > highest) highest = number;
    }
    return highest;
  }
}
