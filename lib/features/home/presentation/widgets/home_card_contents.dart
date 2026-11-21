import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/tasks/presentation/task_display.dart';
import 'package:flutter/material.dart';

// What the loaded Home cards show. Each one gets the card's data and only
// draws it; HomeSectionCard handles loading and errors.

/// "Today's tasks": three numbers and the next task.
class TasksCardContent extends StatelessWidget {
  const TasksCardContent({super.key, required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (summary.isEmpty) {
      return const _Muted('No tasks for today. Tap to add one.');
    }
    final next = summary.nextTaskTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Number(
              value: summary.dueTodayCount,
              label: 'due today',
              color: p.primary,
            ),
            _Number(
              value: summary.overdueCount,
              label: 'overdue',
              color: summary.overdueCount > 0 ? p.error : p.textSecondary,
            ),
            _Number(
              value: summary.completedTodayCount,
              label: 'done',
              color: p.success,
            ),
          ],
        ),
        if (next != null) ...[
          const SizedBox(height: AppSpacing.s3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Next: ',
                  style: TextStyle(color: p.textSecondary),
                ),
                TextSpan(text: next),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// "Next study session": subject, topic and when it starts.
class StudyCardContent extends StatelessWidget {
  const StudyCardContent({super.key, required this.session, required this.now});

  /// null means no session is planned.
  final StudySummary? session;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = this.session;
    if (session == null) {
      return const _Muted('No study session planned. Make a plan first.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${session.subjectName} · ${session.topicTitle}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          '${formatDue(session.startAt, now)} · '
          '${session.plannedMinutes} min',
          style: context.text.bodySmall?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

/// "Habits": done today and the best streak.
class HabitsCardContent extends StatelessWidget {
  const HabitsCardContent({super.key, required this.summary});

  final HabitSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (summary.isEmpty) return const _Muted('No habits due today.');
    final streakHabit = summary.bestStreakHabitName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${summary.doneTodayCount} of ${summary.dueTodayCount} done today',
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.s2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: summary.doneTodayCount / summary.dueTodayCount,
            minHeight: AppSizes.progressTrackWidth,
            color: p.teal,
            backgroundColor: p.progressTrack,
          ),
        ),
        if (summary.bestCurrentStreak > 0 && streakHabit != null) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            '🔥 ${summary.bestCurrentStreak}-day streak · $streakHabit',
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// "Focus": minutes and sessions today.
class FocusCardContent extends StatelessWidget {
  const FocusCardContent({super.key, required this.summary});

  final FocusSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (summary.isEmpty) {
      return const _Muted('No focus sessions yet today. Tap to start one.');
    }

    return Row(
      children: [
        _Number(
          value: summary.minutesToday,
          label: 'minutes',
          color: p.primary,
        ),
        _Number(
          value: summary.sessionsToday,
          label: summary.sessionsToday == 1 ? 'session' : 'sessions',
          color: p.teal,
        ),
      ],
    );
  }
}

/// "Tip of the day".
class TipCardContent extends StatelessWidget {
  const TipCardContent({super.key, required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Text(tip, style: context.text.bodyMedium);
  }
}

/// A big number with a small label under it.
class _Number extends StatelessWidget {
  const _Number({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: context.text.headlineMedium?.copyWith(color: color),
          ),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey text for an empty card.
class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.bodyMedium?.copyWith(
        color: context.palette.textSecondary,
      ),
    );
  }
}
