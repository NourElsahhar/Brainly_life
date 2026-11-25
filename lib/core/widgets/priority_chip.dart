// PriorityChip = a small pill showing a priority: Low, Medium or High.
// It always shows an ICON and a TEXT with the color (never color only).
//
// Usage (just showing it):
//   PriorityChip(level: PriorityLevel.high)
//
// Usage (choosing a priority in a form):
//   Row(children: [
//     for (final level in PriorityLevel.values)
//       PriorityChip(
//         level: level,
//         selected: level == state.priority,
//         onTap: () => cubit.priorityChanged(level),
//       ),
//   ])
//
// Rules:
//   - onTap: null -> display only (not tappable).
//   - selected: false -> grey look (an option you did not pick).
//   - PriorityLevel is only for the UI. Map it to your own model enum
//     (task priority is stored as 'low' / 'medium' / 'high').

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum PriorityLevel { low, medium, high }

class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.level,
    this.selected = true,
    this.onTap,
  });

  final PriorityLevel level;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, icon, color, softColor) = switch (level) {
      PriorityLevel.low => (
        'Low',
        Icons.keyboard_arrow_down_rounded,
        p.info,
        p.infoSoft,
      ),
      PriorityLevel.medium => (
        'Medium',
        Icons.drag_handle_rounded,
        p.warning,
        p.warningSoft,
      ),
      PriorityLevel.high => (
        'High',
        Icons.priority_high_rounded,
        p.error,
        p.errorSoft,
      ),
    };

    final foreground = selected ? color : p.textSecondary;
    final background = selected ? softColor : p.surfaceMuted;

    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1 + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: selected ? null : Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: foreground),
          const SizedBox(width: AppSpacing.s1),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: '$label priority', child: chip);
    }

    // Tappable chips get a 48 px tall touch area.
    return Semantics(
      button: true,
      selected: selected,
      label: '$label priority',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: chip,
          ),
        ),
      ),
    );
  }
}
