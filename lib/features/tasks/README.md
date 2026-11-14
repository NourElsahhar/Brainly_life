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

## Coming next

`TaskRepository` + `MockTaskRepository`, `TaskSummaryProvider` (for Home)
and `TaskCreationPort` (for the AI assistant).