import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/home/logic/home_state.dart';
import 'package:flutter/material.dart';

/// One card of the Home dashboard: an icon and a title on top, then the
/// card's content. Shows a skeleton while loading and Retry on error, so
/// every card only builds its loaded content.
class HomeSectionCard<T> extends StatelessWidget {
  const HomeSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.card,
    required this.onRetry,
    required this.builder,
    this.onTap,
  });

  final String title;
  final IconData icon;

  /// The colour of the icon circle.
  final Color color;

  final HomeCard<T> card;
  final VoidCallback onRetry;

  /// Builds the content once the data is loaded.
  final Widget Function(BuildContext context, T data) builder;

  /// Opens the card's screen. null means the card can't be tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = this.card;

    return AppCard(
      onTap: card is HomeCardLoaded<T> ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.minTouchTarget - AppSpacing.s2,
                height: AppSizes.minTouchTarget - AppSpacing.s2,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: AppSizes.iconStandard),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(child: Text(title, style: context.text.titleMedium)),
              if (onTap != null && card is HomeCardLoaded<T>)
                Icon(Icons.chevron_right_rounded, color: p.iconMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          switch (card) {
            HomeCardLoading<T>() => const _Skeleton(),
            HomeCardError<T>(:final failure) => Row(
              children: [
                Expanded(
                  child: Text(
                    "Couldn't load. ${failure.userMessage}",
                    style: context.text.bodySmall?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
            HomeCardLoaded<T>(:final data) => builder(context, data),
          },
        ],
      ),
    );
  }
}

/// Two grey bars that stand in for the text while the card loads.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget bar(double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: AppSpacing.s3,
        decoration: BoxDecoration(
          color: p.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );

    return Semantics(
      label: 'Loading',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(0.7),
          const SizedBox(height: AppSpacing.s2),
          bar(0.4),
        ],
      ),
    );
  }
}
