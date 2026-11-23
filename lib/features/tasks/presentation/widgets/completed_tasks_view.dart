import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_cubit.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_state.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/task_tile.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/tasks_loading_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Completed tab: done tasks from the last 30 days, 20 at a time.
/// Loads the next page when the user scrolls near the end.
class CompletedTasksView extends StatelessWidget {
  const CompletedTasksView({
    super.key,
    required this.categories,
    required this.now,
    required this.onOpen,
  });

  final Map<String, TaskCategory> categories;
  final DateTime now;

  /// Opens the task detail screen.
  final void Function(Task task) onOpen;

  /// Start loading the next page this many pixels before the end.
  static const double _loadMoreDistance = 300;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompletedTasksCubit>();

    return BlocConsumer<CompletedTasksCubit, CompletedTasksState>(
      listenWhen: (before, now) =>
          _deletedOf(before) != _deletedOf(now) ||
          _failureOf(before) != _failureOf(now),
      listener: (context, state) {
        final failure = _failureOf(state);
        if (failure != null) {
          AppSnackBar.error(context, failure.userMessage);
          return;
        }
        if (_deletedOf(state) != null) {
          AppSnackBar.info(
            context,
            'Task deleted',
            actionLabel: 'Undo',
            onAction: cubit.undo,
          );
        }
      },
      builder: (context, state) => switch (state) {
        CompletedTasksInitial() ||
        CompletedTasksLoading() => const TasksLoadingList(),
        CompletedTasksError(:final failure) => ErrorView(
          failure: failure,
          onRetry: cubit.load,
        ),
        CompletedTasksEmpty() => const EmptyView(
          icon: Icons.emoji_events_outlined,
          title: 'No completed tasks yet',
          message: 'Tasks you finish in the last 30 days show up here.',
        ),
        CompletedTasksLoaded() => NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < _loadMoreDistance) {
              cubit.loadMore(); // safe to call many times
            }
            return false;
          },
          child: _CompletedList(
            state: state,
            categories: categories,
            now: now,
            onOpen: onOpen,
          ),
        ),
      },
    );
  }

  static Task? _deletedOf(CompletedTasksState state) => switch (state) {
    CompletedTasksLoaded(:final lastDeleted) => lastDeleted,
    CompletedTasksEmpty(:final lastDeleted) => lastDeleted,
    _ => null,
  };

  static Failure? _failureOf(CompletedTasksState state) => switch (state) {
    CompletedTasksLoaded(:final actionFailure) => actionFailure,
    CompletedTasksEmpty(:final actionFailure) => actionFailure,
    _ => null,
  };
}

class _CompletedList extends StatelessWidget {
  const _CompletedList({
    required this.state,
    required this.categories,
    required this.now,
    required this.onOpen,
  });

  final CompletedTasksLoaded state;
  final Map<String, TaskCategory> categories;
  final DateTime now;
  final void Function(Task task) onOpen;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CompletedTasksCubit>();
    final p = context.palette;
    final tasks = state.tasks;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      // The header, the tasks, then the footer.
      itemCount: tasks.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Last 30 days',
            style: context.text.labelMedium?.copyWith(color: p.textSecondary),
          );
        }
        if (index == tasks.length + 1) return _footer(context, cubit);

        final task = tasks[index - 1];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => cubit.deleteTask(task),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            decoration: BoxDecoration(
              color: p.error,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Icon(Icons.delete_outline_rounded, color: p.onPrimary),
          ),
          child: TaskTile(
            task: task,
            now: now,
            category: categories[task.categoryId],
            onTap: () => onOpen(task),
            trailing: TextButton(
              onPressed: () => cubit.reopenTask(task),
              child: const Text('Reopen'),
            ),
          ),
        );
      },
    );
  }

  Widget _footer(BuildContext context, CompletedTasksCubit cubit) {
    final failure = state.loadMoreFailure;
    if (failure != null) {
      return AppCard(
        compact: true,
        child: Row(
          children: [
            Expanded(
              child: Text("Couldn't load more", style: context.text.bodyMedium),
            ),
            AppButton(
              label: 'Retry',
              expanded: false,
              onPressed: cubit.loadMore,
            ),
          ],
        ),
      );
    }
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.s4),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}
