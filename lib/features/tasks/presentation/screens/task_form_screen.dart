import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_state.dart';
import 'package:brainly_life/features/tasks/presentation/task_display.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/category_picker.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/field_label.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/subtasks_editor.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The "New task" and "Edit task" screen.
///
/// No [taskId] means a new task. With a [taskId] it loads that task first.
class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context) {
    final id = taskId;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = getIt<TaskFormCubit>();
            id == null ? cubit.startCreate() : cubit.startEdit(id);
            return cubit;
          },
        ),
        BlocProvider(create: (_) => getIt<CategoryCubit>()..load()),
      ],
      child: TaskFormView(taskId: id),
    );
  }
}

/// The form itself. Needs [TaskFormCubit] and [CategoryCubit] above it.
class TaskFormView extends StatefulWidget {
  const TaskFormView({super.key, this.taskId});

  /// Used by "Try again" when loading the task failed.
  final String? taskId;

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  /// true after the loaded task's text was put in the boxes.
  bool _filled = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, TaskFormState state) {
    if (state.status == TaskFormStatus.editing && state.isEdit && !_filled) {
      // The task just loaded: put its text in the boxes (only once).
      _filled = true;
      _title.text = state.title;
      _description.text = state.description;
    }
    if (state.status == TaskFormStatus.saved) {
      AppSnackBar.success(
        context,
        state.isEdit ? 'Task updated' : 'Task added',
      );
      context.pop();
      return;
    }
    final failure = state.failure;
    if (failure != null && state.status == TaskFormStatus.editing) {
      AppSnackBar.error(context, failure.userMessage);
    }
  }

  /// Back button / back gesture with unsaved changes.
  Future<void> _confirmDiscard(BuildContext context) async {
    final discard = await ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'Your changes to this task will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    if (discard && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskFormCubit, TaskFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failure != current.failure,
      listener: _onStateChanged,
      builder: (context, state) {
        final busy =
            state.status == TaskFormStatus.saving ||
            state.status == TaskFormStatus.saved;
        return PopScope(
          canPop: !state.hasChanges || busy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard(context);
          },
          child: Scaffold(
            appBar: BaseetAppBar.inner(
              title: state.isEdit ? 'Edit task' : 'New task',
            ),
            body: SafeArea(child: _body(context, state)),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, TaskFormState state) {
    switch (state.status) {
      case TaskFormStatus.loading:
        return const LoadingView();
      case TaskFormStatus.notFound:
        return EmptyView(
          icon: Icons.search_off_rounded,
          title: 'Task not found',
          message: 'This task was deleted.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        );
      case TaskFormStatus.loadFailed:
        final id = widget.taskId;
        return ErrorView(
          failure: state.failure!,
          onRetry: id == null
              ? null
              : () => context.read<TaskFormCubit>().startEdit(id),
        );
      case TaskFormStatus.editing:
      case TaskFormStatus.saving:
      case TaskFormStatus.saved:
        return _form(context, state);
    }
  }

  Widget _form(BuildContext context, TaskFormState state) {
    final cubit = context.read<TaskFormCubit>();
    final enabled = state.status == TaskFormStatus.editing;

    return Column(
      children: [
        Expanded(
          // A short form, so build it all at once (not lazily).
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Title',
                  hint: 'What do you need to do?',
                  controller: _title,
                  errorText: state.titleError,
                  maxLength: Task.maxTitleLength,
                  textInputAction: TextInputAction.next,
                  autofocus: !state.isEdit,
                  enabled: enabled,
                  onChanged: cubit.titleChanged,
                ),
                const SizedBox(height: AppSpacing.s5),
                AppTextField(
                  label: 'Description (optional)',
                  hint: 'Add details',
                  controller: _description,
                  errorText: state.descriptionError,
                  maxLength: Task.maxDescriptionLength,
                  maxLines: 4,
                  enabled: enabled,
                  onChanged: cubit.descriptionChanged,
                ),
                const SizedBox(height: AppSpacing.s5),
                const FieldLabel('Priority'),
                Wrap(
                  spacing: AppSpacing.s2,
                  children: [
                    for (final priority in TaskPriority.values)
                      PriorityChip(
                        level: priority.level,
                        selected: priority == state.priority,
                        onTap: enabled
                            ? () => cubit.priorityChanged(priority)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s5),
                const FieldLabel('Category'),
                CategoryPicker(
                  selectedId: state.categoryId,
                  onChanged: enabled ? cubit.categoryChanged : null,
                ),
                const SizedBox(height: AppSpacing.s5),
                DateTimePickerField(
                  label: 'Due date (optional)',
                  mode: DateTimePickerMode.dateTime,
                  value: state.dueAt?.toLocal(),
                  errorText: state.dueAtError,
                  firstDate: DateTime.now(),
                  clearable: true,
                  enabled: enabled,
                  onChanged: cubit.dueAtChanged,
                ),
                const SizedBox(height: AppSpacing.s5),
                SubtasksEditor(
                  subtasks: state.subtasks,
                  canAdd: state.canAddSubtask,
                  enabled: enabled,
                  onAdd: cubit.addSubtask,
                  onToggle: cubit.toggleSubtask,
                  onRemove: cubit.removeSubtask,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.s2,
            AppSpacing.screenMargin,
            AppSpacing.s4,
          ),
          child: AppButton(
            label: state.isEdit ? 'Save changes' : 'Add task',
            isLoading: !enabled,
            onPressed: cubit.save,
          ),
        ),
      ],
    );
  }
}
