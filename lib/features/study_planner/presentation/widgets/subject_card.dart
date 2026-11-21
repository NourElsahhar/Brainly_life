import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One subject in the subjects list: colour, name, exam date, and the
/// progress of its topics.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.overview,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final SubjectOverview overview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final subject = overview.subject;
    final color = Color(subject.colorValue);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubjectBadge(name: subject.name, color: color),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: context.text.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    _ExamChip(overview: overview),
                  ],
                ),
              ),
              PopupMenuButton<_CardAction>(
                tooltip: 'More',
                icon: Icon(Icons.more_horiz_rounded, color: p.textSecondary),
                onSelected: (action) {
                  switch (action) {
                    case _CardAction.edit:
                      onEdit();
                    case _CardAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: _CardAction.edit, child: Text('Edit')),
                  PopupMenuItem(
                    value: _CardAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: overview.progress,
              minHeight: AppSpacing.s2,
              color: color,
              backgroundColor: p.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '${overview.doneTopicCount} of ${overview.topicCount} topics',
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}

enum _CardAction { edit, delete }

/// A rounded square in the subject colour with the first letter of its name.
/// (The design shows an icon per subject, but subjects have no icon field.)
class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: AppSizes.minTouchTarget,
      height: AppSizes.minTouchTarget,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        letter,
        style: context.text.headlineSmall?.copyWith(color: color),
      ),
    );
  }
}

/// "Exam in 6 days · 26 Nov", "Exam 3 Dec", "Exam today", "Exam is over".
class _ExamChip extends StatelessWidget {
  const _ExamChip({required this.overview});

  final SubjectOverview overview;

  /// Within this many days the chip also says how many days are left.
  static const int _soonDays = 7;

  String _label() {
    final days = overview.daysUntilExam;
    final date = DateFormat('d MMM')
        .format(DateKeyUtils.parse(overview.examDateKey));
    if (days < 0) return 'Exam is over · $date';
    if (days == 0) return 'Exam today';
    if (days == 1) return 'Exam tomorrow · $date';
    if (days <= _soonDays) return 'Exam in $days days · $date';
    return 'Exam $date';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final foreground = overview.isExamOver ? p.textSecondary : p.warning;
    final background = overview.isExamOver ? p.surfaceMuted : p.warningSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: AppSpacing.s4,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.s1),
          Flexible(
            child: Text(
              _label(),
              style: context.text.labelMedium?.copyWith(color: foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
