import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/logic/subject_overview.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The top card of the subject detail page: name, exam date, topics done
/// and a progress ring.
class SubjectHeaderCard extends StatelessWidget {
  const SubjectHeaderCard({super.key, required this.overview});

  final SubjectOverview overview;

  static const double _ringSize = 96;

  /// "Exam on Thu, 26 Nov · in 6 days", "Exam today", ...
  static String examLabel(SubjectOverview overview) {
    final days = overview.daysUntilExam;
    final date = DateFormat('EEE, d MMM')
        .format(DateKeyUtils.parse(overview.examDateKey));
    if (days < 0) return 'Exam was on $date';
    if (days == 0) return 'Exam today · $date';
    if (days == 1) return 'Exam on $date · tomorrow';
    return 'Exam on $date · in $days days';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = Color(overview.subject.colorValue);
    final percent = (overview.progress * 100).round();

    return AppCard(
      // A light tint of the subject colour, readable in light and dark mode.
      color: Color.alphaBlend(color.withValues(alpha: 0.14), p.surface),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.subject.name,
                  style: context.text.headlineMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  examLabel(overview),
                  style: context.text.bodyMedium?.copyWith(
                    color: overview.isExamOver ? p.textSecondary : color,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '${overview.doneTopicCount} of ${overview.topicCount} '
                  'topics done',
                  style: context.text.bodyMedium?.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Semantics(
            label: '$percent percent done',
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: _ringSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: overview.progress,
                      strokeWidth: AppSizes.progressActiveStrokeWidth,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: p.progressTrack,
                    ),
                    Center(
                      child: Text(
                        '$percent%',
                        style: context.text.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
