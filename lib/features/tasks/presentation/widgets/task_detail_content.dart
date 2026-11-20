import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_state.dart';
import 'package:brainly_life/features/tasks/presentation/task_display.dart';
import 'package:brainly_life/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';

/// Everything the task detail screen shows once the task is loaded:
/// chips, title, deadline, description and the checklist.
class TaskDetailContent extends StatelessWidget {
  const TaskDetailContent({
    super.key,
    required this.state,
    required this.now,
    required this.category,
    required this.onToggleSubtask,
  });

  final TaskDetailLoaded state;
  final DateTime now;

  /// null means Uncategorized.
  final TaskCategory? category;
  final ValueChanged<String> onToggleSubtask;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final task = state.task;
    final dueAt = task.dueAt;
    final completedAt = task.completedAt;
    final description = task.description;
    final doneCount = task.subtasks.where((s) => s.done).length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TaskCategoryChip(category: category),
            PriorityChip(level: task.priority.level, selected: true),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          task.title,
          style: context.text.headlineSmall?.copyWith(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        if (task.isDone && completedAt != null)
          _InfoRow(
            icon: Icons.check_circle_rounded,
            color: p.success,
            text: formatCompleted(completedAt, now),
          )
        else if (dueAt != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TaskDueLabel(
              text: formatDue(dueAt, now),
              isOverdue: state.isOverdue,
              isDueSoon: state.isDueSoon,
            ),
          )
        else
          _InfoRow(
            icon: Icons.event_busy_outlined,
            color: p.textSecondary,
            text: 'No deadline',
          ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.s2),
                Text(description, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Checklist', style: context.text.titleSmall),
                    ),
                    Text(
                      '$doneCount of ${task.subtasks.length} done',
                      style: context.text.labelMedium?.copyWith(
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: AppSizes.progressTrackWidth,
                    color: p.primary,
                    backgroundColor: p.progressTrack,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                // The card paints a color, so the ticks need their own
                // Material to show the tap ripple.
                Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (final subtask in task.subtasks)
                        CheckboxListTile(
                          value: subtask.done,
                          onChanged: (_) => onToggleSubtask(subtask.id),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            subtask.title,
                            style: context.text.bodyMedium?.copyWith(
                              color: subtask.done
                                  ? p.textTertiary
                                  : p.textPrimary,
                              decoration: subtask.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: color),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: context.text.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
