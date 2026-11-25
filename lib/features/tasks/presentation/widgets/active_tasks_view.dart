import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/task_list_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_state.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/task_tile.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/tasks_loading_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The Today, Upcoming or Overdue list (whichever tab [TaskListCubit] has),
/// with swipe to delete and the Undo snackbar.
class ActiveTasksView extends StatelessWidget {
  const ActiveTasksView({
    super.key,
    required this.categories,
    required this.now,
    required this.onClearSearch,
  });

  /// The user's categories by id, to show each task's chip.
  final Map<String, TaskCategory> categories;
  final DateTime now;

  /// Clears the search box (the screen owns it).
  final VoidCallback onClearSearch;

  static const _calculator = TaskProgressCalculator();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskListCubit>();

    return BlocConsumer<TaskListCubit, TaskListState>(
      listenWhen: (before, now) =>
          _changeOf(before) != _changeOf(now) ||
          _failureOf(before) != _failureOf(now),
      listener: (context, state) {
        final failure = _failureOf(state);
        if (failure != null) {
          AppSnackBar.error(context, failure.userMessage);
          return;
        }
        final change = _changeOf(state);
        if (change == null) return;
        AppSnackBar.info(
          context,
          change.type == TaskChangeType.completed
              ? 'Task completed'
              : 'Task deleted',
          actionLabel: 'Undo',
          onAction: cubit.undo,
        );
      },
      builder: (context, state) => switch (state) {
        TaskListInitial() || TaskListLoading() => const TasksLoadingList(),
        TaskListError(:final failure) => ErrorView(
          failure: failure,
          onRetry: cubit.load,
        ),
        TaskListEmpty() => EmptyView(
          icon: Icons.assignment_outlined,
          title: 'No tasks yet',
          message: 'Add your first task and plan your day.',
          actionLabel: 'Add your first task',
          onAction: () => context.push(AppRoutes.newTask),
        ),
        TaskListLoaded(:final tasks, :final tab, :final query)
            when tasks.isEmpty =>
          _emptyTab(tab, query),
        TaskListLoaded(:final tasks, :final tab) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.s3,
            AppSpacing.screenMargin,
            // Room for the + button.
            AppSpacing.s12 + AppSpacing.s8,
          ),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _SwipeToDelete(
              key: ValueKey(task.id),
              onDelete: () => cubit.deleteTask(task),
              child: TaskTile(
                task: task,
                now: now,
                category: categories[task.categoryId],
                isOverdue: tab == TaskBucket.overdue,
                isDueSoon: _calculator.isDueSoon(task, now),
                onTap: () => context.push(AppRoutes.taskPath(task.id)),
                onToggleDone: () => cubit.completeTask(task),
              ),
            );
          },
        ),
      },
    );
  }

  Widget _emptyTab(TaskBucket tab, String query) {
    if (query.isNotEmpty) {
      return EmptyView(
        icon: Icons.search_rounded,
        title: 'No matching tasks',
        message: 'Try another word, or check the other tabs.',
        actionLabel: 'Clear search',
        onAction: onClearSearch,
      );
    }
    return switch (tab) {
      TaskBucket.today => const EmptyView(
        icon: Icons.celebration_outlined,
        title: 'Nothing due today 🎉',
        message: 'Enjoy your day, or plan something new.',
      ),
      TaskBucket.overdue => const EmptyView(
        icon: Icons.verified_outlined,
        title: 'Nothing overdue',
        message: "You're on track. Nice work!",
      ),
      _ => const EmptyView(
        icon: Icons.event_available_outlined,
        title: 'Nothing coming up',
        message: 'Tasks with a later deadline, or no deadline, show here.',
      ),
    };
  }

  static TaskChange? _changeOf(TaskListState state) => switch (state) {
    TaskListLoaded(:final lastChange) => lastChange,
    TaskListEmpty(:final lastChange) => lastChange,
    _ => null,
  };

  static Failure? _failureOf(TaskListState state) => switch (state) {
    TaskListLoaded(:final actionFailure) => actionFailure,
    TaskListEmpty(:final actionFailure) => actionFailure,
    _ => null,
  };
}

/// Swipe a task to the left to delete it (with Undo in the snackbar).
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.onDelete,
    required this.child,
  });

  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        decoration: BoxDecoration(
          color: p.error,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: p.onPrimary),
            Text(
              'Delete',
              style: context.text.labelMedium?.copyWith(color: p.onPrimary),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
