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
//   secondary   -> second action (soft violet).
//   text        -> small actions like "Forgot password?".
//   destructive -> deleting things (red).

import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum AppButtonType { primary, secondary, text, destructive }

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

    return Semantics(
      button: true,
      enabled: canTap,
      label: label,
      child: Opacity(
        // Disabled looks faded. Loading keeps full color.
        opacity: onPressed == null ? 0.5 : 1,
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
              ),
              child: InkWell(
                onTap: canTap ? onPressed : null,
                borderRadius: radius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6,
                  ),
                  child: Center(child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonLook _lookFor(BuildContext context) {
    final p = context.palette;

    switch (type) {
      case AppButtonType.primary:
        return _ButtonLook(
          gradient: AppColors.primaryGradient,
          foreground: p.onPrimary,
        );
      case AppButtonType.secondary:
        return _ButtonLook(background: p.primarySoft, foreground: p.primary);
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
  });

  final Color foreground;
  final Color? background;
  final Gradient? gradient;
}