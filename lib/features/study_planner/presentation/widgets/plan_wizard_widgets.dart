import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// "Step 1 of 2" with two progress bars, under the wizard title.
class WizardStepHeader extends StatelessWidget {
  const WizardStepHeader({super.key, required this.step, this.steps = 2});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Step $step of $steps',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              'Step $step of $steps',
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= steps; i++)
                  Container(
                    width: AppSpacing.s12 * 2,
                    height: AppSpacing.s1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s1,
                    ),
                    decoration: BoxDecoration(
                      color: i <= step ? p.primary : p.progressTrack,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A white card with a section title, like "Hours per day".
class WizardSection extends StatelessWidget {
  const WizardSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      // A see-through Material inside the card, so list tiles and their
      // ink splashes paint on top of the card's background.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            child,
          ],
        ),
      ),
    );
  }
}

/// One weekday in "Hours per day": the day name and its hours.
/// 0 hours shows "Day off" on a grey tile.
class DayHoursTile extends StatelessWidget {
  const DayHoursTile({
    super.key,
    required this.dayName,
    required this.minutes,
    required this.onTap,
  });

  final String dayName;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isOff = minutes == 0;
    final hours = hoursLabel(minutes);
    return Semantics(
      button: true,
      label: isOff ? '$dayName, day off' : '$dayName, $hours',
      child: ExcludeSemantics(
        child: Material(
          color: isOff ? p.surfaceMuted : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: p.progressTrack),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dayName, style: context.text.labelMedium),
                    const SizedBox(height: AppSpacing.s1),
                    FittedBox(
                      child: Text(
                        hours,
                        style: context.text.titleMedium?.copyWith(
                          color: isOff ? p.textSecondary : p.primary,
                        ),
                      ),
                    ),
                    if (isOff)
                      FittedBox(
                        child: Text(
                          'Day off',
                          style: context.text.labelSmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 0 -> "0h", 120 -> "2h", 90 -> "1.5h".
  static String hoursLabel(int minutes) {
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${(minutes / 60).toStringAsFixed(1)}h';
  }
}

/// Bottom sheet to pick the study time of one day. Returns the minutes, or
/// null when the user closes it.
Future<int?> showDayHoursPicker(
  BuildContext context, {
  required String dayName,
  required int current,
  required int maxMinutes,
}) {
  final options = [for (var m = 0; m <= maxMinutes; m += 30) m];
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Study time on $dayName', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.s4),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (final minutes in options)
                  ChoiceChip(
                    label: Text(
                      minutes == 0
                          ? 'Day off'
                          : DayHoursTile.hoursLabel(minutes),
                    ),
                    selected: minutes == current,
                    onSelected: (_) => Navigator.of(context).pop(minutes),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
