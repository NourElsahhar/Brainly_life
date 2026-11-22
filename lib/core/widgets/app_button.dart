// AppButton = the one button used everywhere in the app.
//
// Usage:
//   AppButton(label: 'Save', onPressed: _save)
//   AppButton(label: 'Cancel', type: AppButtonType.secondary, onPressed: _cancel)
//   AppButton(label: 'Delete', type: AppButtonType.destructive, onPressed: _delete)
//   AppButton(label: 'Add task', icon: Icons.add, onPressed: _add)
//   AppButton(label: 'Save', isLoading: state is Submitting, onPressed: _save)
//
// Rules:
//   - onPressed: null  -> the button looks disabled and does nothing.
//   - isLoading: true  -> shows a spinner and ignores taps (no double submit).
//   - expanded: false  -> the button is only as wide as its content.
//
// Types:
//   primary     -> main action of a screen (violet gradient). Use once per screen.
//   secondary   -> second action (violet outline).
//   teal        -> focus / study actions (teal outline), like "Mark done".
//   text        -> small actions like "Forgot password?".
//   destructive -> deleting things (red).
//
// Disabled buttons (onPressed: null) are grey, as in the design.

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum AppButtonType { primary, secondary, teal, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final look = _lookFor(context);
    final canTap = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(AppRadius.button);

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: AppSizes.iconStandard,
            height: AppSizes.iconStandard,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: look.foreground,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconStandard, color: look.foreground),
            const SizedBox(width: AppSpacing.s2),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.button.copyWith(color: look.foreground),
            ),
          ),
        ],
      ],
    );

    final border = look.border;

    return Semantics(
      button: true,
      enabled: canTap,
      label: label,
      child: SizedBox(
        height: AppSizes.primaryButtonHeight,
        width: expanded ? double.infinity : null,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: look.gradient,
              color: look.background,
              borderRadius: radius,
              border: border == null
                  ? null
                  : Border.all(color: border, width: 1.5),
            ),
            child: InkWell(
              onTap: canTap ? onPressed : null,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                child: Center(widthFactor: expanded ? null : 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonLook _lookFor(BuildContext context) {
    final p = context.palette;

    // Disabled (not loading): grey, whatever the type.
    if (onPressed == null && type != AppButtonType.text) {
      return _ButtonLook(
        background: p.surfaceMuted,
        foreground: p.textTertiary,
      );
    }
    if (onPressed == null) return _ButtonLook(foreground: p.textTertiary);

    switch (type) {
      case AppButtonType.primary:
        return _ButtonLook(
          gradient: AppColors.primaryGradient,
          foreground: p.onPrimary,
        );
      case AppButtonType.secondary:
        return _ButtonLook(border: p.primary, foreground: p.primary);
      case AppButtonType.teal:
        return _ButtonLook(border: p.teal, foreground: p.tealStrong);
      case AppButtonType.text:
        return _ButtonLook(foreground: p.primary);
      case AppButtonType.destructive:
        return _ButtonLook(
          background: p.error,
          foreground: Theme.of(context).colorScheme.onError,
        );
    }
  }
}

class _ButtonLook {
  const _ButtonLook({
    required this.foreground,
    this.background,
    this.gradient,
    this.border,
  });

  final Color foreground;
  final Color? background;
  final Gradient? gradient;

  /// Outline colour for the outlined types (secondary, teal).
  final Color? border;
}
