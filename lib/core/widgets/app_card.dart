// AppCard = the one card used everywhere in the app.
// It gets its color, border and shadow from the theme, so light and dark
// mode work automatically.
//
// Usage:
//   AppCard(child: Text('Hello'))
//   AppCard(compact: true, child: ...)              // smaller padding (16)
//   AppCard(onTap: () => context.push('/tasks'), child: ...)   // tappable
//   AppCard(color: context.palette.primarySoft, child: ...)   // other color
//
// Rules:
//   - onTap: null -> a normal card. onTap set -> ripple effect on tap.
//   - Do not build your own Container with a border and shadow. Use this.
//   - In dark mode the card has no shadow, only a thin border.

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.compact = false,
    this.padding,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Smaller inner padding (16 instead of 20).
  final bool compact;

  /// Overrides the inner padding. Normally leave it empty.
  final EdgeInsetsGeometry? padding;

  /// Overrides the background color. Normally leave it empty.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = BorderRadius.circular(AppRadius.card);

    final content = Padding(
      padding:
          padding ??
          EdgeInsets.all(
            compact ? AppSpacing.compactCardPadding : AppSpacing.cardPadding,
          ),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: radius,
        border: Border.all(color: p.borderSubtle),
        boxShadow: AppShadows.card(context),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
            ),
    );
  }
}
