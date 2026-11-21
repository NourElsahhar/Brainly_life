import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_state.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/topic_tile.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "New topic" when [topicId] is null, "Edit topic" otherwise.
/// Closes with a [TopicFormResult] after a save or a delete.
class TopicFormScreen extends StatelessWidget {
  const TopicFormScreen({super.key, required this.subjectId, this.topicId});

  final String subjectId;
  final String? topicId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<TopicFormCubit>();
        final id = topicId;
        if (id == null) {
          cubit.startCreate(subjectId);
        } else {
          cubit.startEdit(id);
        }
        return cubit;
      },
      child: TopicFormView(topicId: topicId),
    );
  }
}

class TopicFormView extends StatelessWidget {
  const TopicFormView({super.key, this.topicId});

  final String? topicId;

  void _onStateChanged(BuildContext context, TopicFormState state) {
    switch (state.status) {
      case TopicFormStatus.saved:
        context.pop(TopicFormResult.saved);
      case TopicFormStatus.deleted:
        context.pop(TopicFormResult.deleted);
      case TopicFormStatus.editing:
        final failure = state.failure;
        if (failure != null) AppSnackBar.error(context, failure.userMessage);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = topicId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? 'Edit topic' : 'New topic'),
      ),
      body: BlocConsumer<TopicFormCubit, TopicFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.failure != current.failure,
        listener: _onStateChanged,
        builder: (context, state) => switch (state.status) {
          TopicFormStatus.loading => const LoadingView(),
          TopicFormStatus.notFound => EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Topic not found',
            message: 'It may have been deleted.',
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
          TopicFormStatus.loadFailed => ErrorView(
            failure: state.failure!,
            onRetry: () => context.read<TopicFormCubit>().startEdit(topicId!),
          ),
          TopicFormStatus.editing ||
          TopicFormStatus.saving ||
          TopicFormStatus.saved ||
          TopicFormStatus.deleted => _TopicFormFields(state: state),
        },
      ),
    );
  }
}

/// The fields. Built once the topic is loaded, so the text fields can
/// start with the saved values.
class _TopicFormFields extends StatefulWidget {
  const _TopicFormFields({required this.state});

  final TopicFormState state;

  @override
  State<_TopicFormFields> createState() => _TopicFormFieldsState();
}

class _TopicFormFieldsState extends State<_TopicFormFields> {
  late final TextEditingController _title = TextEditingController(
    text: widget.state.title,
  );
  late final TextEditingController _hours = TextEditingController(
    text: widget.state.hoursText,
  );

  @override
  void dispose() {
    _title.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<TopicFormCubit>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete "${widget.state.title.trim()}"?',
      message: 'Its planned sessions will be deleted too.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok) await cubit.delete();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<TopicFormCubit>();
    final p = context.palette;
    final isBusy = state.status != TopicFormStatus.editing;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppTextField(
          label: 'Topic title',
          hint: 'e.g. Newton\'s laws',
          controller: _title,
          maxLength: TopicFormCubit.maxTitleLength,
          errorText: state.titleError,
          textInputAction: TextInputAction.next,
          onChanged: cubit.titleChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        _FieldLabel(
          label: 'Difficulty',
          helper: '1 = easy, 5 = hard',
          errorText: state.difficultyError,
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (
              var level = TopicFormCubit.minDifficulty;
              level <= TopicFormCubit.maxDifficulty;
              level++
            )
              ChoiceChip(
                label: Text('$level'),
                tooltip: 'Difficulty $level of ${TopicFormCubit.maxDifficulty}',
                selected: state.difficulty == level,
                onSelected: (_) => cubit.difficultyChanged(level),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s5),
        AppTextField(
          label: 'Estimated hours',
          hint: 'e.g. 1.5',
          controller: _hours,
          errorText: state.hoursError,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onChanged: cubit.hoursChanged,
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          'Between 0.5 and 200 hours.',
          style: context.text.bodySmall?.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s5),
        const _FieldLabel(label: 'Status'),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final status in TopicStatus.values)
              ChoiceChip(
                label: Text(topicStatusLabel(status)),
                selected: state.topicStatus == status,
                onSelected: (_) => cubit.statusChanged(status),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton(
          label: state.isEdit ? 'Save changes' : 'Save topic',
          isLoading: state.status == TopicFormStatus.saving,
          onPressed: isBusy ? null : cubit.save,
        ),
        if (state.isEdit) ...[
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: 'Delete topic',
            type: AppButtonType.destructive,
            onPressed: isBusy ? null : () => _confirmDelete(context),
          ),
        ],
      ],
    );
  }
}

/// A field title with an optional helper line and error line.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.helper, this.errorText});

  final String label;
  final String? helper;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.titleSmall),
        if (helper != null)
          Text(
            helper!,
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        if (error != null)
          Text(error, style: context.text.bodySmall?.copyWith(color: p.error)),
      ],
    );
  }
}
