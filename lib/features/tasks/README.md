# tasks feature

**Owner:** M3

Task management: tasks with priorities, categories, deadlines
and checklists (subtasks).

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

## Repository

`TaskRepository` (`data/repositories/task_repository.dart`) is the contract.
Every method returns a `Result`.

- `watchActiveTasks()`: live list of every task that is not done, earliest
  deadline first. The Cubit splits it into tabs with `TaskProgressCalculator`.
- `getCompletedTasks(afterTaskId:, limit:)`: completed tasks from the last
  30 days, newest first, 20 per page.
- `watchTask(id)`, `createTask`, `updateTask`, `deleteTask`.
- `restoreTask(task)`: saves a deleted task again with the same id and
  dates. Used by undo.

  - `clearCategory(categoryId)`: makes every task of that category
  Uncategorized. Called after the category is deleted.

`MockTaskRepository` keeps tasks in memory:

```dart
final tasks = MockTaskRepository.withSampleData(); // 5 sample tasks
final empty = MockTaskRepository(now: () => fixedTime); // for tests
empty.failWith = const NetworkFailure(); // simulate an error
```

`tasks_injection.dart` registers `TaskRepository` in get_it: the mock with
`USE_MOCKS=true`, and `FirestoreTaskRepository` otherwise.

## Firestore

The real repositories save to `users/{uid}/tasks` and
`users/{uid}/taskCategories`.

- `TaskRemoteDataSource` (`data/datasources/task_remote_data_source.dart`):
  the only file that calls Firestore. It reads the uid on every call,
  waits at most 15 seconds, and THROWS on errors.
- `FirestoreTaskRepository` and `FirestoreTaskCategoryRepository`: set
  `createdAt` / `updatedAt` and turn every error into a `Result`
  (`firestore_results.dart`). A stream error stays inside the stream as
  `Result.failure`, so the list keeps listening.
- `clearCategory` updates the tasks in batches of 400 (Firestore allows 500).
- Dates are client `Timestamp`s, never `FieldValue.serverTimestamp()`.
  `firestore.rules` (M1) checks the 10 task fields. M5's Analytics and AI
  chat read `status`, `dueAt`, `createdAt` and `completedAt`, so do not
  rename them.

Profile "tasks done" (`data/repositories/task_profile_source.dart`):
`FirestoreTaskProfileSource` counts `status == 'done'` tasks of all time
with a count query (no task is downloaded). `MockTaskProfileSource`
returns a fixed number. Both implement M1's `ProfileTasksSource`.

```dart
final count = await getIt<ProfileTasksSource>().tasksDone(); // Result<int>
```

Sample data for the Firebase Emulator: `tools/seed/seed.mjs` (3
categories, 10 tasks in every tab; the Profile shows 4 done).
## Categories repository

`TaskCategoryRepository` (`data/repositories/task_category_repository.dart`)
saves the user's categories. Names are at most
`TaskCategoryRepository.maxNameLength` (30) characters.

- `watchCategories()`: live list, sorted by name (case does not matter).
- `createCategory`, `updateCategory` (rename and recolour),
  `deleteCategory`.

Deleting a category does not touch its tasks. Call
`TaskRepository.clearCategory(id)` after it, so they become
Uncategorized. A task whose category is missing should still show as
Uncategorized.

```dart
final categories = MockTaskCategoryRepository.withSampleData();
// University (blue) and Personal (green)
```

## Task list Cubit

`TaskListCubit` (`logic/task_list_cubit.dart`) drives the task list
screen: the Today, Upcoming and Overdue tabs. The Completed tab has its
own Cubit (below).

States (`logic/task_list_state.dart`):

- `TaskListInitial`, then `TaskListLoading` while the first list loads.
- `TaskListLoaded`: the visible `tasks`, the selected `tab`, `counts`
  per tab, `query` and `sort`.
- `TaskListEmpty`: the user has no task left to do.
- `TaskListError`: the list could not load. Call `load()` again to retry.

`Loaded` and `Empty` also carry:

- `lastChange`: the last complete or delete. Show an Undo snackbar and
  call `undo()`.
- `actionFailure`: a complete, delete or undo that failed. Show
  `userMessage` in a snackbar. The list stays as it was.

```dart
final cubit = TaskListCubit(getIt<TaskRepository>())..load();
cubit.selectTab(TaskBucket.overdue);
cubit.search('report'); // waits 400 ms after the last key
cubit.sortBy(TaskSort.priority);
await cubit.completeTask(task);
await cubit.undo();
```
## Completed tab Cubit

`CompletedTasksCubit` (`logic/completed_tasks_cubit.dart`) shows done
tasks from the last 30 days, newest first, 20 at a time.

States (`logic/completed_tasks_state.dart`): `CompletedTasksInitial`,
`CompletedTasksLoading`, `CompletedTasksLoaded`, `CompletedTasksEmpty`,
`CompletedTasksError`.

`CompletedTasksLoaded` has:

- `tasks` and `hasMore` (there may be another page).
- `isLoadingMore`: show a small spinner under the list.
- `loadMoreFailure`: the next page failed. Keep the list and show Retry
  under it (it calls `loadMore()` again).

`Loaded` and `Empty` also carry `lastDeleted` (show an Undo snackbar)
and `actionFailure` (show `userMessage` in a snackbar).

```dart
final cubit = CompletedTasksCubit(getIt<TaskRepository>());
await cubit.load();          // every time the tab opens
await cubit.loadMore();      // when the user scrolls near the end
await cubit.reopenTask(task); // back to not done, leaves this tab
await cubit.deleteTask(task);
await cubit.undo();          // puts back the last deleted task
```

Calling `loadMore()` many times while scrolling is safe: it loads each
page once.

## Home summary

`RepositoryTaskSummaryProvider`
(`data/repositories/repository_task_summary_provider.dart`) is the real
`TaskSummaryProvider` for the "Today's tasks" card on Home. It is
registered in `tasks_injection.dart` for both modes.

- `dueTodayCount` and `overdueCount` use `TaskProgressCalculator`, so they
  match the task list tabs.
- `nextTaskTitle`: the oldest overdue task, otherwise the nearest task
  due today, otherwise null.
- `completedTodayCount`: tasks completed today in the user's time zone.
  It reads the completed pages until it reaches a task from before today.

```dart
final result = await getIt<TaskSummaryProvider>().todaySummary();
```

## Creating tasks from other features

`TaskCreationPort` (`data/repositories/task_creation_port.dart`) lets
other features create a task. M5's AI assistant uses it when the user
confirms a `create_task` action.

Other features import only this file. It also exports `TaskPriority`.

```dart
final result = await getIt<TaskCreationPort>().createTask(
  TaskDraft(
    title: 'Study physics',
    priority: TaskPriority.high,
    dueAt: tomorrowAt5pmUtc,
    subtaskTitles: ['Chapter 1', 'Chapter 2'],
  ),
);
// Success: the new task id. Failed: show failure.userMessage.
```

`RepositoryTaskCreationPort` is the real one, registered in
`tasks_injection.dart`. It trims the text, drops empty checklist items,
saves `dueAt` in UTC, and creates the task as not done and Uncategorized.
It returns a `ValidationFailure` when the title is empty or longer than
100 characters, the description is longer than 1000, or there are more
than 20 checklist items.

## Categories Cubit

`CategoryCubit` (`logic/category_cubit.dart`) drives the categories
screen. States (`logic/category_state.dart`): `CategoryInitial`,
`CategoryLoading`, `CategoryLoaded(categories)` (may be empty),
`CategoryError` (Retry calls `load()`).

Every action returns `null` when it worked, or the `Failure` to show:

```dart
final failure = await cubit.create(name, colorValue);
if (failure == null) {
  Navigator.pop(context); // close the dialog
} else {
  setState(() => error = failure.userMessage); // show it under the field
}
```

- `create` and `rename` trim the name and return a `ValidationFailure`
  when it is empty, longer than 30, or already used (case does not matter).
- `recolor(category, colorValue)`.
- `delete(category)` also makes its tasks Uncategorized. Ask the user to
  confirm first.

Registered with `registerFactory`, so every screen gets a new one.
## Task form Cubit

`TaskFormCubit` (`logic/task_form_cubit.dart`) drives the add / edit task
screen. It has one state class, `TaskFormState`
(`logic/task_form_state.dart`), with all the field values and a `status`:

- `loading`: loading the task to edit.
- `editing`: the user is filling the form.
- `saving`: disable the Save button.
- `saved`: close the screen.
- `notFound`: the task was deleted. Show "This task was deleted".
- `loadFailed`: show Retry, which calls `startEdit(id)` again.

```dart
final cubit = getIt<TaskFormCubit>()..startCreate(); // or ..startEdit(id)
cubit.titleChanged('Study physics');
cubit.priorityChanged(TaskPriority.high);
cubit.dueAtChanged(pickedDateTime); // null removes the deadline
cubit.addSubtask('Chapter 3');
await cubit.save();
```

- Field errors (`titleError`, `descriptionError`, `dueAtError`) show only
  after the first Save, then update while the user types. Put them in each
  field's `errorText`.
- The deadline must be in the future, unless it is an old deadline the
  user did not change.
- Editing keeps the task id, status, `completedAt` and `createdAt`.
- `hasChanges`: ask "Discard changes?" before leaving.
- `canAddSubtask` is false at 20 items.
- `failure` (save or load failed): show `userMessage` in a snackbar.

## Task detail Cubit

`TaskDetailCubit` (`logic/task_detail_cubit.dart`) drives the task detail
screen. It watches the task live, so edits made in the form show up when
the user comes back.

States (`logic/task_detail_state.dart`):

- `TaskDetailLoading`, then `TaskDetailLoaded`: the `task`, `progress`
  (0.0 to 1.0), `isOverdue` and `isDueSoon`.
- `TaskDetailNotFound`: the task was deleted somewhere else. Show "This
  task was deleted".
- `TaskDetailDeleted`: the user deleted it from this screen. Close the
  screen.
- `TaskDetailError`: Retry calls `load(id)` again.

```dart
final cubit = getIt<TaskDetailCubit>()..load(taskId);
await cubit.toggleSubtask(subtaskId);
await cubit.markDone(); // or cubit.reopen()
await cubit.delete();   // ask "Delete this task?" first
// "Start focus session":
context.push(AppRoutes.focusPath(taskId: taskId));
```

Every action returns `null` when it worked, or the `Failure` to show in a
snackbar.
## Screens

- `TasksScreen` (`presentation/screens/tasks_screen.dart`) at
  `AppRoutes.tasks`: tabs with counts, search, sort, swipe to delete,
  complete with Undo, Completed tab with "load more" while scrolling.
- `TaskTile` (`presentation/widgets/task_tile.dart`): one task row, used
  in every tab.
- `task_display.dart`: `formatDue`, `formatCompleted` and
  `TaskPriority.level` (for M1's `PriorityChip`).

## Status

Done: models, repositories (mock and Firestore), Cubits, screens, the
Home summary and the Profile "tasks done" source. Next: testing on a
real phone (docs/manual_test_sheet.md).