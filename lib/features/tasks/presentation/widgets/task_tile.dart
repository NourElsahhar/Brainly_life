import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/presentation/task_display.dart';
import 'package:flutter/material.dart';

/// One task in a list: check circle, title, priority, category, deadline
/// and checklist progress. Same look in every tab.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    this.category,
    this.isOverdue = false,
    this.isDueSoon = false,
    this.onTap,
    this.onToggleDone,
    this.trailing,
  });

  final Task task;
  final DateTime now;

  /// null means Uncategorized (or the category was deleted).
  final TaskCategory? category;

  final bool isOverdue;
  final bool isDueSoon;
  final VoidCallback? onTap;

  /// Tapping the circle. null hides the tap (display only).
  final VoidCallback? onToggleDone;

  /// Extra widget on the right, like the "Reopen" button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final doneCount = task.subtasks.where((s) => s.done).length;
    final total = task.subtasks.length;
    final dueAt = task.dueAt;
    final completedAt = task.completedAt;

    return AppCard(
      compact: true,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CheckCircle(done: task.isDone, onTap: onToggleDone),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyLarge?.copyWith(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone ? p.textSecondary : null,
                        ),
                      ),
                    ),
                    if (!task.isDone) ...[
                      const SizedBox(width: AppSpacing.s2),
                      PriorityChip(level: task.priority.level),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s2),
                Wrap(
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _CategoryChip(category: category),
                    if (!task.isDone && dueAt != null)
                      _DueLabel(
                        text: formatDue(dueAt, now),
                        isOverdue: isOverdue,
                        isDueSoon: isDueSoon,
                      ),
                    if (task.isDone && completedAt != null)
                      Text(
                        formatCompleted(completedAt, now),
                        style: context.text.labelSmall?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Row(
                    children: [
                      Text(
                        '$doneCount/$total',
                        style: context.text.labelSmall?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: doneCount / total,
                            minHeight: AppSizes.progressTrackWidth,
                            color: p.primary,
                            backgroundColor: p.progressTrack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, this.onTap});

  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final circle = Container(
      width: AppSizes.checkboxDiameter,
      height: AppSizes.checkboxDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? p.success : null,
        border: done ? null : Border.all(color: p.iconMuted, width: 2),
      ),
      child: done
          ? Icon(Icons.check_rounded, size: AppSpacing.s4, color: p.onPrimary)
          : null,
    );

    return Semantics(
      button: onTap != null,
      checked: done,
      label: done ? 'Mark as not done' : 'Mark as done',
      child: InkResponse(
        onTap: onTap,
        radius: AppSizes.minTouchTarget / 2,
        child: SizedBox.square(
          dimension: AppSizes.minTouchTarget,
          child: Center(child: circle),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({this.category});

  final TaskCategory? category;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final category = this.category;
    // The category colour is the user's own data, not a design value.
    final dotColor = category == null
        ? p.iconMuted
        : Color(category.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.s2,
            height: AppSpacing.s2,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s1 + 2),
          Text(
            category?.name ?? 'Uncategorized',
            style: context.text.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _DueLabel extends StatelessWidget {
  const _DueLabel({
    required this.text,
    required this.isOverdue,
    required this.isDueSoon,
  });

  final String text;
  final bool isOverdue;
  final bool isDueSoon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, icon, color, background) = isOverdue
        ? ('Overdue · $text', Icons.error_outline_rounded, p.error, p.errorSoft)
        : isDueSoon
        ? ('Due soon · $text', Icons.schedule_rounded, p.warning, p.warningSoft)
        : (text, Icons.calendar_today_rounded, p.textSecondary, null);

    return Container(
      padding: background == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: AppSpacing.s1,
            ),
      decoration: background == null
          ? null
          : BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.s4, color: color),
          const SizedBox(width: AppSpacing.s1),
          Text(label, style: context.text.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
