import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:clock/clock.dart';

/// The real "Today's tasks" card for Home, built from [TaskRepository].
///
/// Uses [TaskProgressCalculator], so the numbers match the task list tabs.
class RepositoryTaskSummaryProvider implements TaskSummaryProvider {
  RepositoryTaskSummaryProvider(
    this._repository, {
    this._calculator = const TaskProgressCalculator(),
    DateTime Function()? now,
  }) : _now = now ?? clock.now;

  final TaskRepository _repository;
  final TaskProgressCalculator _calculator;
  final DateTime Function() _now;

  @override
  Future<Result<TaskSummary>> todaySummary() async {
    final now = _now();
    final activeResult = await _repository.watchActiveTasks().first;

    switch (activeResult) {
      case Failed(:final failure):
        return Result.failure(failure);
      case Success(:final data):
        return _summarize(data, now);
    }
  }

  Future<Result<TaskSummary>> _summarize(
    List<Task> active,
    DateTime now,
  ) async {
    final overdue = <Task>[];
    final dueToday = <Task>[];
    for (final task in active) {
      switch (_calculator.bucketOf(task, now)) {
        case TaskBucket.overdue:
          overdue.add(task);
        case TaskBucket.today:
          dueToday.add(task);
        case TaskBucket.upcoming || TaskBucket.completed:
          break;
      }
    }

    // The list comes earliest deadline first, so .first is the nearest one.
    final next = overdue.isNotEmpty ? overdue : dueToday;

    final completedResult = await _countCompletedToday(now);
    switch (completedResult) {
      case Failed(:final failure):
        return Result.failure(failure);
      case Success(:final data):
        return Result.success(
          TaskSummary(
            dueTodayCount: dueToday.length,
            overdueCount: overdue.length,
            completedTodayCount: data,
            nextTaskTitle: next.isEmpty ? null : next.first.title,
          ),
        );
    }
  }

  /// Goes through the completed pages (newest first) and stops at the
  /// first task completed before today.
  Future<Result<int>> _countCompletedToday(DateTime now) async {
    var count = 0;
    String? afterTaskId;

    while (true) {
      final page = await _repository.getCompletedTasks(
        afterTaskId: afterTaskId,
      );
      switch (page) {
        case Failed(:final failure):
          return Result.failure(failure);
        case Success(:final data):
          for (final task in data) {
            final completedAt = task.completedAt;
            if (completedAt == null) continue;
            if (!_isSameDay(completedAt, now)) return Result.success(count);
            count++;
          }
          if (data.length < TaskRepository.completedPageSize) {
            return Result.success(count);
          }
          afterTaskId = data.last.id;
      }
    }
  }

  /// Same day in the user's time zone, like the Today tab.
  static bool _isSameDay(DateTime time, DateTime now) {
    final offset = now.timeZoneOffset;
    final day = time.toUtc().add(offset);
    final today = now.toUtc().add(offset);
    return day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
  }
}
