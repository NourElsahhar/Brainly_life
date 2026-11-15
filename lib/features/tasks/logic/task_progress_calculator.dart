import 'package:brainly_life/features/tasks/data/models/task_model.dart';

/// Which tab of the task list a task belongs to.
enum TaskBucket { today, upcoming, overdue, completed }

/// Pure business rules for tasks. No Flutter, no Firebase.
///
/// Every method takes [now] as a parameter, so tests can use a fixed time.
class TaskProgressCalculator {
  const TaskProgressCalculator();

  /// A task is "due soon" when its deadline is less than this away.
  static const Duration dueSoonWindow = Duration(hours: 24);

  /// Progress from 0.0 to 1.0, based on the checked subtasks.
  /// A task without subtasks is 1.0 when done and 0.0 otherwise.
  double progress(Task task) {
    if (task.subtasks.isEmpty) return task.isDone ? 1 : 0;
    final doneCount = task.subtasks.where((subtask) => subtask.done).length;
    return doneCount / task.subtasks.length;
  }

  /// Not done, and the deadline has already passed.
  bool isOverdue(Task task, DateTime now) {
    final dueAt = task.dueAt;
    return !task.isDone && dueAt != null && dueAt.isBefore(now);
  }

  /// Not done, not overdue, and the deadline is within [dueSoonWindow].
  bool isDueSoon(Task task, DateTime now) {
    final dueAt = task.dueAt;
    if (task.isDone || dueAt == null || dueAt.isBefore(now)) return false;
    return dueAt.difference(now) <= dueSoonWindow;
  }

  /// The deadline falls on the same calendar day as [now]
  /// in the user's time zone.
  ///
  /// [utcOffset] is the user's offset from UTC (Cairo = 2 hours).
  /// When it is null, the offset of [now] is used.
  bool isDueToday(Task task, DateTime now, {Duration? utcOffset}) {
    final dueAt = task.dueAt;
    if (dueAt == null) return false;
    final offset = utcOffset ?? now.timeZoneOffset;
    final dueDay = dueAt.toUtc().add(offset);
    final today = now.toUtc().add(offset);
    return dueDay.year == today.year &&
        dueDay.month == today.month &&
        dueDay.day == today.day;
  }

  /// The tab this task appears in. Every task appears in exactly one tab:
  /// completed first, then overdue, then today, otherwise upcoming
  /// (including tasks without a deadline).
  TaskBucket bucketOf(Task task, DateTime now, {Duration? utcOffset}) {
    if (task.isDone) return TaskBucket.completed;
    if (isOverdue(task, now)) return TaskBucket.overdue;
    if (isDueToday(task, now, utcOffset: utcOffset)) return TaskBucket.today;
    return TaskBucket.upcoming;
  }
}
