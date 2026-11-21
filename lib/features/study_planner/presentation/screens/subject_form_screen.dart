import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_state.dart';
import 'package:brainly_life/injection.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "New subject" when [subjectId] is null, "Edit subject" otherwise.
/// Closes with `true` after a successful save.
class SubjectFormScreen extends StatelessWidget {
  const SubjectFormScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<SubjectFormCubit>();
        final id = subjectId;
        if (id == null) {
          cubit.startCreate(
            defaultColorValue: ColorPickerRow.defaultColors.first.toARGB32(),
          );
        } else {
          cubit.startEdit(id);
        }
        return cubit;
      },
      child: SubjectFormView(subjectId: subjectId),
    );
  }
}

class SubjectFormView extends StatelessWidget {
  const SubjectFormView({super.key, this.subjectId});

  final String? subjectId;

  void _onStateChanged(BuildContext context, SubjectFormState state) {
    if (state.status == SubjectFormStatus.saved) {
      context.pop(true);
      return;
    }
    final failure = state.failure;
    if (failure != null && state.status == SubjectFormStatus.editing) {
      AppSnackBar.error(context, failure.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = subjectId != null;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(isEdit ? 'Edit subject' : 'New subject'),
      ),
      body: BlocConsumer<SubjectFormCubit, SubjectFormState>(
        listener: _onStateChanged,
        builder: (context, state) => switch (state.status) {
          SubjectFormStatus.loading => const LoadingView(),
          SubjectFormStatus.notFound => EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Subject not found',
            message: 'It may have been deleted.',
            actionLabel: 'Back',
            onAction: () => context.pop(),
          ),
          SubjectFormStatus.loadFailed => ErrorView(
            failure: state.failure!,
            onRetry: () =>
                context.read<SubjectFormCubit>().startEdit(subjectId!),
          ),
          SubjectFormStatus.editing ||
          SubjectFormStatus.saving ||
          SubjectFormStatus.saved => _SubjectFormFields(state: state),
        },
      ),
    );
  }
}

/// The fields. Built once the subject is loaded, so the name field can
/// start with the saved name.
class _SubjectFormFields extends StatefulWidget {
  const _SubjectFormFields({required this.state});

  final SubjectFormState state;

  @override
  State<_SubjectFormFields> createState() => _SubjectFormFieldsState();
}

class _SubjectFormFieldsState extends State<_SubjectFormFields> {
  late final TextEditingController _name = TextEditingController(
    text: widget.state.name,
  );

  static const _priorities = [
    (PriorityLevel.low, SubjectPriority.low),
    (PriorityLevel.medium, SubjectPriority.medium),
    (PriorityLevel.high, SubjectPriority.high),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<SubjectFormCubit>();
    final p = context.palette;
    final examKey = state.examDateKey;
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSaving = state.status == SubjectFormStatus.saving;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        AppTextField(
          label: 'Subject name',
          hint: 'e.g. Physics',
          controller: _name,
          maxLength: SubjectFormCubit.maxNameLength,
          errorText: state.nameError,
          textInputAction: TextInputAction.done,
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        ColorPickerRow(
          label: 'Color',
          selectedColorValue: state.colorValue,
          onChanged: cubit.colorChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        DateTimePickerField(
          label: 'Exam date',
          mode: DateTimePickerMode.date,
          value: examKey == null ? null : DateKeyUtils.parse(examKey),
          errorText: state.examDateError,
          // A new exam cannot be in the past. An old one may stay.
          firstDate: state.isEdit ? null : today,
          onChanged: cubit.examDateChanged,
        ),
        const SizedBox(height: AppSpacing.s5),
        Text('Priority', style: context.text.titleSmall),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          children: [
            for (final (level, value) in _priorities)
              PriorityChip(
                level: level,
                selected: state.priority == value,
                onTap: () => cubit.priorityChanged(value),
              ),
          ],
        ),
        if (!state.isEdit) ...[
          const SizedBox(height: AppSpacing.s6),
          AppCard(
            color: p.primarySoft,
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: p.primary),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    'Add topics after saving, then generate your study plan.',
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s6),
        AppButton(
          label: state.isEdit ? 'Save changes' : 'Save subject',
          isLoading: isSaving,
          onPressed: isSaving ? null : cubit.save,
        ),
      ],
    );
  }
}
