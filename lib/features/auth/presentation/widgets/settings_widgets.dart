// Small pieces of the Settings and Profile screens.
//
//   SettingsSection -> a title ("Study preferences") and a card with rows
//   SettingsRow     -> "Daily study hours ........ 4 h  >"
//   showOptionSheet -> a bottom sheet to pick one value from a list
//
// Usage:
//   SettingsSection(
//     title: 'Study preferences',
//     children: [
//       SettingsRow(label: 'Daily study hours', value: '4 h', onTap: ...),
//     ],
//   )
//
//   final hours = await showOptionSheet<double>(
//     context,
//     title: 'Daily study hours',
//     selected: 4,
//     options: [(1, '1 h'), (2, '2 h')],
//   );

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(
            height: 1,
            indent: AppSpacing.s4,
            endIndent: AppSpacing.s4,
            color: p.borderSubtle,
          ),
        );
      }
      rows.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.s1,
            bottom: AppSpacing.s3,
          ),
          child: Text(title, style: context.text.titleLarge),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.iconColor,
    this.labelColor,
    this.showChevron = true,
    this.onTap,
  });

  final String label;

  /// Shown in grey on the right, like "4 h".
  final String? value;

  /// An icon on the left (the Profile menu uses one).
  final IconData? icon;
  final Color? iconColor;

  /// For "Sign out" (violet) and "Delete account" (red).
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = this.value;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? p.primary),
                const SizedBox(width: AppSpacing.s4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge?.copyWith(
                    color: labelColor ?? p.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AppSpacing.s3),
                Flexible(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.s2),
                Icon(Icons.chevron_right_rounded, color: p.iconMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a bottom sheet with [options] (value + label). Returns the picked
/// value, or null if the sheet was closed.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required T selected,
  required List<(T, String)> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final p = sheetContext.palette;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  0,
                  AppSpacing.s5,
                  AppSpacing.s3,
                ),
                child: Text(title, style: sheetContext.text.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (value, label) in options)
                      ListTile(
                        title: Text(label),
                        selected: value == selected,
                        selectedColor: p.primary,
                        trailing: value == selected
                            ? Icon(Icons.check_rounded, color: p.primary)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
          ),
        ),
      );
    },
  );
}

/// Small helper so screens can show "coming soon" in one line.
void showComingSoon(BuildContext context, String message) =>
    AppSnackBar.info(context, message);
