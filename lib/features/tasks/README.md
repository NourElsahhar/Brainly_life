# tasks feature

**Owner:** M3

Task management: tasks with priorities, categories, deadlines,
checklists (subtasks) and reminders.

## Models

- `Task` (`data/models/task_model.dart`): stored at `users/{uid}/tasks/{id}`.
  Also defines `TaskPriority` (low, medium, high) and `TaskStatus` (todo, done).
- `Subtask` (`data/models/subtask_model.dart`): stored inside the task
  document as a list of maps (max `Task.maxSubtasks` = 20).
- `TaskCategory` (`data/models/task_category_model.dart`): stored at
  `users/{uid}/taskCategories/{id}`. The colour is an ARGB `int`.

## Rules

- All dates are stored in UTC.
- `categoryId == null` means "Uncategorized".
- `copyWith` cannot set a field to null by passing null. Use the
  `clear...` flags instead:

```dart
task.copyWith(clearDueAt: true);    // remove the deadline
task.copyWith(clearCategory: true); // make it uncategorized
task.copyWith(clearReminder: true); // remove the reminder
```
## Task list tabs

`TaskProgressCalculator` (`logic/task_progress_calculator.dart`) decides
which tab a task appears in. Every task appears in exactly one tab:

1. **Completed**: the task is done.
2. **Overdue**: not done and the deadline has passed (even if it was today).
3. **Today**: the deadline is later today, in the user's time zone.
4. **Upcoming**: everything else, including tasks without a deadline.

It also gives `progress` (checked subtasks, 0.0 to 1.0) and `isDueSoon`
(less than 24 hours left). Pass `now` in, never call `DateTime.now()`
inside, so tests stay deterministic.
## Coming next

`TaskRepository` + `MockTaskRepository`, `TaskSummaryProvider` (for Home)
and `TaskCreationPort` (for the AI assistant).