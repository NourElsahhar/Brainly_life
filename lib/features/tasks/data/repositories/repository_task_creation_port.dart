import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_creation_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:clock/clock.dart';

/// The real [TaskCreationPort]: checks the draft, turns it into a [Task]
/// and saves it with [TaskRepository].
class RepositoryTaskCreationPort implements TaskCreationPort {
  RepositoryTaskCreationPort(this._repository, {DateTime Function()? now})
    : _now = now ?? clock.now;

  final TaskRepository _repository;
  final DateTime Function() _now;

  @override
  Future<Result<String>> createTask(TaskDraft draft) async {
    final title = draft.title.trim();
    final description = draft.description?.trim();
    final subtaskTitles = [
      for (final subtask in draft.subtaskTitles)
        if (subtask.trim().isNotEmpty) subtask.trim(),
    ];

    final problem = _check(title, description, subtaskTitles);
    if (problem != null) {
      return Result.failure(ValidationFailure(userMessage: problem));
    }

    final now = _now().toUtc();
    final task = Task(
      id: '', // the repository gives the real id
      title: title,
      description: description == null || description.isEmpty
          ? null
          : description,
      priority: draft.priority,
      dueAt: draft.dueAt?.toUtc(),
      subtasks: [
        for (var i = 0; i < subtaskTitles.length; i++)
          Subtask(id: 'subtask_${i + 1}', title: subtaskTitles[i]),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createTask(task);
    return result.fold(
      onSuccess: (saved) => Result.success(saved.id),
      onFailure: (failure) => Result.failure(failure),
    );
  }

  /// A message for the user when the draft breaks a limit, otherwise null.
  static String? _check(
    String title,
    String? description,
    List<String> subtaskTitles,
  ) {
    if (title.isEmpty) return 'Please enter a task title.';
    if (title.length > Task.maxTitleLength) {
      return 'The title can be at most ${Task.maxTitleLength} characters.';
    }
    if (description != null && description.length > Task.maxDescriptionLength) {
      return 'The description can be at most '
          '${Task.maxDescriptionLength} characters.';
    }
    if (subtaskTitles.length > Task.maxSubtasks) {
      return 'A task can have at most ${Task.maxSubtasks} checklist items.';
    }
    return null;
  }
}
