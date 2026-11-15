// ConfirmDialog = a "Are you sure?" popup with Cancel and Confirm buttons.
// It returns true if the user confirmed, false if they cancelled or tapped
// outside. So you never get null.
//
// Usage:
//   final confirmed = await ConfirmDialog.show(
//     context,
//     title: 'Delete task?',
//     message: 'This cannot be undone.',
//     confirmLabel: 'Delete',
//     isDestructive: true,
//   );
//   if (confirmed) cubit.deleteTask(id);
//
// Rules:
//   - Always ask before deleting anything.
//   - isDestructive: true -> the confirm button is red.

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_button.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Shows the dialog and returns true only if the user confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.s6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: context.text.headlineSmall),
            const SizedBox(height: AppSpacing.s2),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    type: isDestructive
                        ? AppButtonType.destructive
                        : AppButtonType.primary,
                    onPressed: () => Navigator.of(context).pop(true),
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