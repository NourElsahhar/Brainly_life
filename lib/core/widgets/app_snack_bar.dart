// AppSnackBar = the small message at the bottom of the screen.
//
// Usage:
//   AppSnackBar.success(context, 'Task saved');
//   AppSnackBar.error(context, failure.userMessage);
//   AppSnackBar.info(context, 'Task deleted', actionLabel: 'Undo', onAction: cubit.undoDelete);
//
// Rules:
//   - Use it for the result of an action (saved, deleted, failed).
//   - Do NOT use it for form validation. Those errors go under the field.
//   - Call it from a BlocListener, never from inside build().
//   - A new message replaces the one still on screen.

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum _SnackType { success, error, info }

class AppSnackBar {
  const AppSnackBar._();

  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, message, _SnackType.success, actionLabel, onAction);

  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, message, _SnackType.error, actionLabel, onAction);

  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, message, _SnackType.info, actionLabel, onAction);

   static void _show(
    BuildContext context,
    String message,
    _SnackType type,
    String? actionLabel,
    VoidCallback? onAction,
  ) {
    // The design: a dark bar for success and info (in light and dark mode),
    // a red bar for errors. Text and icons are light on both.
    const dark = AppPalette.dark;
    final p = context.palette;
    final isError = type == _SnackType.error;
    final background = isError ? p.error : dark.surfaceRaised;
    const foreground = Color(0xFFFFFFFF);
    final (icon, iconColor) = switch (type) {
      _SnackType.success => (Icons.check_circle_rounded, dark.success),
      _SnackType.error => (Icons.error_rounded, foreground),
      _SnackType.info => (Icons.info_rounded, dark.info),
    };
    final hasAction = actionLabel != null && onAction != null;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            0,
            AppSpacing.screenMargin,
            AppSpacing.s4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          duration: Duration(seconds: hasAction ? 5 : 3),
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: AppSizes.iconStandard),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  message,
                  style: context.text.bodyMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
          action: hasAction
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: isError ? foreground : dark.primary,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}
