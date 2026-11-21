import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:flutter/material.dart';

/// One topic on the subject detail page: title, difficulty dots,
/// estimated time and status.

/// One topic on the subject detail page: title, difficulty dots,
/// estimated time and status. Tap to edit; the menu has Edit and Delete.
class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.onEdit,
    required this.onDelete,
  });

  final Topic topic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      compact: true,
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: context.text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    DifficultyDots(
                      difficulty: topic.difficulty,
                      color: statusColor(context, topic.status),
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Flexible(
                      child: Text(
                        'Est. ${formatStudyMinutes(topic.estimatedMinutes)}',
                        style: context.text.bodySmall?.copyWith(
                          color: p.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          TopicStatusChip(status: topic.status),
          PopupMenuButton<_TopicAction>(
            tooltip: 'Topic options',
            icon: Icon(Icons.more_vert_rounded, color: p.textSecondary),
            onSelected: (action) {
              switch (action) {
                case _TopicAction.edit:
                  onEdit();
                case _TopicAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: _TopicAction.edit, child: Text('Edit')),
              PopupMenuItem(value: _TopicAction.delete, child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TopicAction { edit, delete }

/// The colour of a topic status: green when done, blue in progress,
/// grey when not started.
Color statusColor(BuildContext context, TopicStatus status) {
  final p = context.palette;
  return switch (status) {
    TopicStatus.done => p.success,
    TopicStatus.inProgress => p.info,
    TopicStatus.notStarted => p.textSecondary,
  };
}

String topicStatusLabel(TopicStatus status) {
  return switch (status) {
    TopicStatus.done => 'Done',
    TopicStatus.inProgress => 'In progress',
    TopicStatus.notStarted => 'Not started',
  };
}

/// "45 min", "1 h", "1.5 h", "2 h 20 min".
String formatStudyMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours h';
  if (rest == 30) return '$hours.5 h';
  return '$hours h $rest min';
}

/// Five dots; the first [difficulty] of them are filled.
class DifficultyDots extends StatelessWidget {
  const DifficultyDots({
    super.key,
    required this.difficulty,
    required this.color,
  });

  static const int maxDifficulty = 5;

  final int difficulty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Difficulty $difficulty of $maxDifficulty',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= maxDifficulty; i++)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s1),
                child: Container(
                  width: AppSpacing.s3,
                  height: AppSpacing.s3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= difficulty ? color : p.progressTrack,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A pill with the status name, in the status colour.
class TopicStatusChip extends StatelessWidget {
  const TopicStatusChip({super.key, required this.status});

  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = statusColor(context, status);
    final background = switch (status) {
      TopicStatus.done => p.successSoft,
      TopicStatus.inProgress => p.infoSoft,
      TopicStatus.notStarted => p.surfaceMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        topicStatusLabel(status),
        style: context.text.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
