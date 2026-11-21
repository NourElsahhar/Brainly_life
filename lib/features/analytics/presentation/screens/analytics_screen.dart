import 'package:intl/intl.dart';

import '../../../../core/widgets/app_button.dart';

import 'package:brainly_life/core/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ai/ai_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/theme.dart';
import '../../logic/analytics_cubit.dart';
import '../../logic/analytics_state.dart';
import '../widgets/weekly_analytics_charts.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(AppStrings.analytics)),
    body: SafeArea(
      child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
        builder: (context, state) {
          final cubit = context.read<AnalyticsCubit>();
          final week = switch (state) {
            AnalyticsEmpty(:final week) ||
            AnalyticsError(:final week) ||
            AnalyticsLoaded(:final week) ||
            AnalyticsLoading(:final week) => week,
            _ => null,
          };
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              if (week != null)
                Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.previousWeek,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => cubit.move(-1),
                    ),
                    Expanded(
                      child: Text(
                        '${DateFormat('d MMM').format(DateTime.parse(week.days.first))} – ${DateFormat('d MMM').format(DateTime.parse(week.days.last))}',
                        textAlign: TextAlign.center,
                        style: context.text.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.nextWeek,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: cubit.canGoNext ? () => cubit.move(1) : null,
                    ),
                  ],
                ),
              ...switch (state) {
                AnalyticsInitial() || AnalyticsLoading() => [
                  const Center(child: CircularProgressIndicator()),
                ],
                AnalyticsEmpty() => [
                  const SizedBox(height: 48),
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: context.palette.primarySoft,
                    child: Icon(
                      Icons.insights,
                      size: 80,
                      color: context.palette.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Not enough data yet',
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Use the app for a few days and your weekly analytics will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ],
                AnalyticsError(:final failure) => [
                  AiErrorCard(failure: failure, onRetry: cubit.load),
                ],
                AnalyticsLoaded() => _sections(context, state, cubit),
              },
            ],
          );
        },
      ),
    ),
  );

  List<Widget> _sections(
    BuildContext context,
    AnalyticsLoaded state,
    AnalyticsCubit cubit,
  ) {
    final stats = state.stats;
    final previous = state.previousStats;
    final delta = state.score != null && state.previousScore != null
        ? state.score! - state.previousScore!
        : null;
    return [
      AppCard(
        child: Row(
          children: [
            SizedBox.square(
              dimension: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (state.score ?? 0) / 100,
                      strokeWidth: 7,
                      backgroundColor: context.palette.progressTrack,
                      color: context.palette.primary,
                    ),
                  ),
                  Text(
                    state.score?.toString() ?? '—',
                    style: context.text.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.productivityScore,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delta == null
                        ? AppStrings.noComparison
                        : '${delta >= 0 ? '+' : ''}$delta vs last week',
                    style: context.text.bodySmall?.copyWith(
                      color: context.palette.success,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Score formula',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text(AppStrings.productivityScore),
                  content: Text(AppStrings.scoreFormula),
                ),
              ),
              icon: const Icon(Icons.info_outline, size: 18),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _metric(
              context,
              Icons.task_alt,
              'Tasks',
              '${stats.tasksCompleted} done',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              context,
              Icons.menu_book_outlined,
              'Study',
              '${(stats.studyActual / 60).toStringAsFixed(1)} h',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _metric(
              context,
              Icons.local_fire_department_outlined,
              'Habits',
              '${(stats.habitRate * 100).round()}%',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              context,
              Icons.timer_outlined,
              'Focus',
              '${(stats.focusMinutes / 60).toStringAsFixed(1)} h',
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _Section(
        title: AppStrings.tasks,
        children: [
          Text(
            '${AppStrings.created} ${stats.tasksCreated} · ${AppStrings.completed} ${stats.tasksCompleted} · ${AppStrings.overdue} ${stats.tasksOverdue}',
          ),
          _comparison(
            '${(stats.taskRate * 100).round()}%',
            previous == null ? null : '${(previous.taskRate * 100).round()}%',
          ),
          const SizedBox(height: AppSpacing.s2),
          WeeklyTaskChart(days: stats.tasksByDay),
        ],
      ),
      _Section(
        title: AppStrings.study,
        children: [
          Text(
            '${AppStrings.planned} ${stats.studyPlanned} ${AppStrings.minutes} · ${AppStrings.actual} ${stats.studyActual} ${AppStrings.minutes}',
          ),
          _comparison(
            '${stats.studyActual} ${AppStrings.minutes}',
            previous == null
                ? null
                : '${previous.studyActual} ${AppStrings.minutes}',
          ),
          const SizedBox(height: 16),
          WeeklyStudyChart(
            days: stats.studyByDay,
            previous: previous?.studyByDay ?? const {},
          ),
          const Text('This week · Last week (dashed)'),
          for (final entry in stats.studyBySubject.entries)
            Text('${entry.key} · ${entry.value} ${AppStrings.minutes}'),
        ],
      ),
      _Section(
        title: AppStrings.habits,
        children: [
          Row(
            children: [
              Semantics(
                label:
                    '${AppStrings.habits} ${(stats.habitRate * 100).round()}%',
                child: ExcludeSemantics(
                  child: CircularProgressIndicator(value: stats.habitRate),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: _comparison(
                  '${stats.habitsCompleted}/${stats.habitsDue} · ${(stats.habitRate * 100).round()}%',
                  previous == null
                      ? null
                      : '${(previous.habitRate * 100).round()}%',
                ),
              ),
            ],
          ),
          if (stats.bestHabit != null)
            Text('${AppStrings.bestHabit} · ${stats.bestHabit}'),
        ],
      ),
      _Section(
        title: AppStrings.focus,
        children: [
          Text(
            '${stats.focusMinutes} ${AppStrings.minutes} · ${stats.focusSessions} ${AppStrings.sessions}',
          ),
          _comparison(
            '${stats.focusMinutes} ${AppStrings.minutes}',
            previous == null
                ? null
                : '${previous.focusMinutes} ${AppStrings.minutes}',
          ),
          const SizedBox(height: AppSpacing.s2),
          WeeklyFocusChart(days: stats.focusByDay),
        ],
      ),
      const SizedBox(height: 16),
      AppButton(
        label: 'View AI report',
        icon: Icons.auto_awesome,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const WeeklyReportScreen(),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _metric(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => AppCard(
    compact: true,
    child: Row(
      children: [
        Icon(icon, color: context.palette.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.bodySmall),
              Text(value, style: context.text.titleMedium),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _comparison(String value, String? previous) => Text(
    previous == null ? value : '$value · ${AppStrings.previousWeek} $previous',
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.headlineSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          ...children,
        ],
      ),
    ),
  );
}

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});
  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AnalyticsCubit>();
    final state = cubit.state;
    if (state is AnalyticsLoaded && !state.isCurrent && state.report == null) {
      cubit.generateReport();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Weekly AI report')),
    body: BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        if (state is! AnalyticsLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = state.report;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            Text(
              '${state.week.days.first} – ${state.week.days.last}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (state.isCurrent)
              const AppCard(child: Text(AppStrings.reportAfterWeek)),
            if (state.isGenerating)
              AppCard(
                color: context.palette.primarySoft,
                child: const Column(
                  children: [
                    Icon(Icons.auto_awesome, size: 48),
                    SizedBox(height: 16),
                    Text('Writing your weekly report...'),
                    SizedBox(height: 24),
                    LinearProgressIndicator(),
                    SizedBox(height: 16),
                    Text('This is generated once and saved.'),
                  ],
                ),
              ),
            if (state.reportFailure case final failure?)
              AiErrorCard(
                failure: failure,
                onRetry: context.read<AnalyticsCubit>().generateReport,
              ),
            if (report != null) ...[
              AppCard(
                color: context.palette.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: context.palette.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your week in review',
                      style: context.text.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(report.summary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Recommendations', style: context.text.titleLarge),
              const SizedBox(height: 16),
              for (var i = 0; i < report.recommendations.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    compact: true,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: context.palette.primarySoft,
                          child: Text('${i + 1}'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(report.recommendations[i])),
                      ],
                    ),
                  ),
                ),
              const Center(child: AiDisclaimer()),
            ],
          ],
        );
      },
    ),
  );
}
