import 'package:brainly_life/core/ai/ai_failures.dart';
import 'package:brainly_life/core/ai/ai_widgets.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_state.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/plan_wizard_widgets.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/topic_tile.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The two-step "New study plan" wizard (Master Document B.2).
/// [subjectId] is set when it is opened from a subject page.
class PlanWizardScreen extends StatelessWidget {
  const PlanWizardScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlanWizardCubit>()..load(subjectId: subjectId),
      child: const PlanWizardView(),
    );
  }
}

class PlanWizardView extends StatelessWidget {
  const PlanWizardView({super.key});

  /// The most time one day offers in the hours picker.
  static const int pickerMaxMinutes = 8 * 60;

  void _onStateChanged(BuildContext context, PlanWizardState state) {
    if (state.status != PlanWizardStatus.generated) return;
    // The preview screen comes in the next step. Until then, say how many
    // sessions the AI planned and let the user change the time again.
    final count = state.result?.sessions.length ?? 0;
    AppSnackBar.success(
      context,
      'Your plan is ready: $count sessions. The preview comes next.',
    );
    context.read<PlanWizardCubit>().previewClosed();
  }

  void _back(BuildContext context) {
    if (!context.read<PlanWizardCubit>().back()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanWizardCubit, PlanWizardState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      builder: (context, state) {
        return PopScope(
          // On step 2, system back goes to step 1 instead of closing.
          canPop: state.step == 1 && !state.isBusy,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<PlanWizardCubit>().back();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: state.isBusy ? null : () => _back(context),
              ),
              title: const Text('New study plan'),
              centerTitle: true,
            ),
            body: switch (state.status) {
              PlanWizardStatus.loading => const LoadingView(),
              PlanWizardStatus.loadFailed => ErrorView(
                failure: state.failure!,
                onRetry: () => context.read<PlanWizardCubit>().load(),
              ),
              PlanWizardStatus.nothingToPlan => EmptyView(
                icon: Icons.event_note_rounded,
                title: 'Nothing to plan yet',
                message:
                    'Add a subject with an exam from tomorrow on, and the '
                    'topics you still need to study.',
                actionLabel: 'Back to subjects',
                onAction: () => context.pop(),
              ),
              _ =>
                state.step == 1
                    ? _ChooseStep(state: state)
                    : _TimeStep(state: state),
            },
          ),
        );
      },
    );
  }
}

/// Step 1: choose subjects and topics.
class _ChooseStep extends StatelessWidget {
  const _ChooseStep({required this.state});

  final PlanWizardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlanWizardCubit>();
    final p = context.palette;
    return _StepLayout(
      step: 1,
      title: 'Choose what to study',
      button: AppButton(
        label: 'Continue',
        onPressed: state.canContinue ? cubit.next : null,
      ),
      children: [
        for (final item in state.subjects) ...[
          WizardSection(
            title: item.subject.name,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam ${_examLabel(item.examDateKey)}',
                  style: context.text.bodySmall?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('All topics'),
                  tristate: true,
                  value: _subjectValue(item),
                  onChanged: (_) => cubit.toggleSubject(item.subject.id),
                ),
                for (final topic in item.topics)
                  CheckboxListTile(
                    contentPadding: const EdgeInsets.only(left: AppSpacing.s6),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(topic.title),
                    subtitle: Text(
                      '${topicStatusLabel(topic.status)} · '
                      'Est. ${formatStudyMinutes(topic.estimatedMinutes)}',
                    ),
                    value: state.isSelected(topic),
                    onChanged: (_) => cubit.toggleTopic(topic.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
      ],
    );
  }

  /// true = all topics, false = none, null = some.
  bool? _subjectValue(WizardSubject item) {
    final selected = item.topics.where(state.isSelected).length;
    if (selected == 0) return false;
    if (selected == item.topics.length) return true;
    return null;
  }
}

/// Step 2: exam dates, hours per day, session length, then Generate.
class _TimeStep extends StatelessWidget {
  const _TimeStep({required this.state});

  final PlanWizardState state;

  /// Saturday first, as in the design (and the Egyptian week).
  static const List<int> _weekOrder = [6, 7, 1, 2, 3, 4, 5];
  static const List<String> _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  Future<void> _pickHours(BuildContext context, int weekday) async {
    final cubit = context.read<PlanWizardCubit>();
    final minutes = await showDayHoursPicker(
      context,
      dayName: _dayNames[weekday - 1],
      current: state.minutesPerWeekday[weekday] ?? 0,
      maxMinutes: PlanWizardView.pickerMaxMinutes,
    );
    if (minutes != null) cubit.setDayMinutes(weekday, minutes);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlanWizardCubit>();
    final p = context.palette;
    final failure = state.failure;
    final generating = state.status == PlanWizardStatus.generating;

    return _StepLayout(
      step: 2,
      title: 'Set your time',
      button: AppButton(
        label: 'Generate plan',
        icon: Icons.auto_awesome_rounded,
        isLoading: generating,
        onPressed: generating || !state.hasStudyTime ? null : cubit.generate,
      ),
      children: [
        if (state.status == PlanWizardStatus.generateFailed &&
            failure != null) ...[
          AiErrorCard(
            failure: failure,
            onRetry: failure is AiGatewayFailure && !failure.canRetry
                ? null
                : cubit.generate,
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        WizardSection(
          title: 'Exam dates',
          child: Column(
            children: [
              for (final item in state.selectedSubjects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(item.subject.colorValue)
                        .withValues(alpha: 0.18),
                    child: Text(
                      item.subject.name.trim().isEmpty
                          ? '?'
                          : item.subject.name.trim()[0].toUpperCase(),
                      style: TextStyle(color: Color(item.subject.colorValue)),
                    ),
                  ),
                  title: Text(item.subject.name),
                  subtitle: Text(_examLabel(item.examDateKey)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        WizardSection(
          title: 'Hours per day',
          child: Row(
            children: [
              for (final weekday in _weekOrder)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s1 / 2,
                    ),
                    child: DayHoursTile(
                      dayName: _dayNames[weekday - 1],
                      minutes: state.minutesPerWeekday[weekday] ?? 0,
                      onTap: generating
                          ? () {}
                          : () => _pickHours(context, weekday),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!state.hasStudyTime) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Give at least one day some study time.',
            style: context.text.bodySmall?.copyWith(color: p.error),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        WizardSection(
          title: 'Session length',
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final minutes in PlanWizardCubit.sessionLengths)
                  ButtonSegment(value: minutes, label: Text('$minutes min')),
              ],
              selected: {state.maxSessionMinutes},
              onSelectionChanged: generating
                  ? null
                  : (value) => cubit.sessionLengthChanged(value.first),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: p.primary),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                'Your plan is generated by AI. You can edit it before saving.',
                style: context.text.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Header, scrolling content and a button pinned at the bottom.
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.step,
    required this.title,
    required this.children,
    required this.button,
  });

  final int step;
  final String title;
  final List<Widget> children;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              WizardStepHeader(step: step),
              const SizedBox(height: AppSpacing.s6),
              Text(
                title,
                style: context.text.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s6),
              ...children,
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.s2,
              AppSpacing.screenMargin,
              AppSpacing.s4,
            ),
            child: button,
          ),
        ),
      ],
    );
  }
}

/// "Thu, 26 Nov".
String _examLabel(String dateKey) =>
    DateFormat('EEE, d MMM').format(DateKeyUtils.parse(dateKey));
