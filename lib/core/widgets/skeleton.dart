// Skeletons = grey bars that stand in for content while it loads
// (design: Canva "UI components sheet" -> Skeleton loading card).
// Nicer than a spinner when you already know the shape of what is coming.
//
// Usage:
//   const SkeletonLines()                         // two bars, inside your own card
//   const SkeletonLines(widths: [0.9, 0.6, 0.3])  // three bars
//   const SkeletonCard()                          // a whole card, e.g. in a list
//
// Rules:
//   - Use it for parts of a screen that load on their own (a card, a list).
//   - For a whole screen that is loading, use LoadingView.

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_card.dart';

/// Grey bars, one under the other. Each width is a part of the full width
/// (0.5 = half).
class SkeletonLines extends StatelessWidget {
  const SkeletonLines({super.key, this.widths = const [0.7, 0.4]});

  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      label: 'Loading',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widths.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s2),
            FractionallySizedBox(
              widthFactor: widths[i],
              child: Container(
                height: AppSpacing.s3,
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A card-shaped placeholder: a round "icon", then three bars.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.s10,
            height: AppSpacing.s10,
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          const Expanded(child: SkeletonLines(widths: [0.8, 0.55, 0.3])),
        ],
      ),
    );
  }
}
