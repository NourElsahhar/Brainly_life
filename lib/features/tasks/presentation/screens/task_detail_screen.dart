import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_state.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/task_detail_content.dart';
import 'package:brainly_life/injection.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The task detail screen. Creates its Cubits, then shows [TaskDetailView].
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TaskDetailCubit>()..load(taskId)),
        BlocProvider(create: (_) => getIt<CategoryCubit>()..load()),
      ],
      child: TaskDetailView(taskId: taskId),
    );
  }
}

/// One task: details, checklist, Mark as done / Reopen, Focus, Edit and
/// Delete. Needs [TaskDetailCubit] and [CategoryCubit] above it.
class TaskDetailView extends StatelessWidget {
  const TaskDetailView({super.key, required this.taskId});

  /// Used by "Try again".
  final String taskId;

  /// Shows the failure of an action, if there is one.
  void _showFailure(BuildContext context, Failure? failure) {
    if (failure != null) AppSnackBar.error(context, failure.userMessage);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete task?',
      message: 'This task and its checklist will be deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final failure = await context.read<TaskDetailCubit>().delete();
    if (!context.mounted) return;
    _showFailure(context, failure);
  }

  Future<void> _markDone(BuildContext context) async {
    final failure = await context.read<TaskDetailCubit>().markDone();
    if (!context.mounted) return;
    if (failure == null) {
      AppSnackBar.success(context, 'Task completed');
    } else {
      _showFailure(context, failure);
    }
  }

  Future<void> _reopen(BuildContext context) async {
    final failure = await context.read<TaskDetailCubit>().reopen();
    if (!context.mounted) return;
    _showFailure(context, failure);
  }

  Future<void> _toggleSubtask(BuildContext context, String subtaskId) async {
    final failure = await context.read<TaskDetailCubit>().toggleSubtask(
      subtaskId,
    );
    if (!context.mounted) return;
    _showFailure(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskDetailCubit, TaskDetailState>(
      listenWhen: (_, current) => current is TaskDetailDeleted,
      listener: (context, _) {
        AppSnackBar.success(context, 'Task deleted');
        context.pop();
      },
      builder: (context, state) {
        final loaded = state is TaskDetailLoaded ? state : null;
        return Scaffold(
                    appBar: BaseetAppBar.inner(
            title: 'Task',
            actions: [
              if (loaded != null) ...[
                AppBarIconButton(
                  tooltip: 'Edit',
                  icon: Icons.edit_outlined,
                  filled: false,
                  onPressed: () =>
                      context.push(AppRoutes.editTaskPath(loaded.task.id)),
                ),
                AppBarIconButton(
                  tooltip: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  filled: false,
                  onPressed: () => _delete(context),
                ),
              ],
            ],
          ),
          body: SafeArea(child: _body(context, state)),
        );
      },
    );
  }

  Widget _body(BuildContext context, TaskDetailState state) {
    switch (state) {
      case TaskDetailInitial():
      case TaskDetailLoading():
      case TaskDetailDeleted():
        return const LoadingView();
      case TaskDetailNotFound():
        return EmptyView(
          icon: Icons.search_off_rounded,
          title: 'This task was deleted',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        );
      case TaskDetailError(:final failure):
        return ErrorView(
          failure: failure,
          onRetry: () => context.read<TaskDetailCubit>().load(taskId),
        );
      case TaskDetailLoaded():
        return _loaded(context, state);
    }
  }

  Widget _loaded(BuildContext context, TaskDetailLoaded state) {
    final task = state.task;
    final category = context.select<CategoryCubit, TaskCategory?>(
      (cubit) => switch (cubit.state) {
        CategoryLoaded(:final categories) =>
          categories.where((c) => c.id == task.categoryId).firstOrNull,
        _ => null,
      },
    );

    return Column(
      children: [
        Expanded(
          child: TaskDetailContent(
            state: state,
            now: clock.now(),
            category: category,
            onToggleSubtask: (id) => _toggleSubtask(context, id),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.s2,
            AppSpacing.screenMargin,
            AppSpacing.s4,
          ),
          child: task.isDone
              ? AppButton(
                  label: 'Reopen task',
                  icon: Icons.replay_rounded,
                  type: AppButtonType.secondary,
                  onPressed: () => _reopen(context),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Start focus',
                      icon: Icons.timer_outlined,
                      onPressed: () =>
                          context.push(AppRoutes.focusPath(taskId: task.id)),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    AppButton(
                      label: 'Mark as done',
                      icon: Icons.check_rounded,
                      type: AppButtonType.secondary,
                      onPressed: () => _markDone(context),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
