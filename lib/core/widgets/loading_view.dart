// LoadingView = the screen state "we are loading data".
//
// Usage:
//   if (state is TaskListLoading) return const LoadingView();
//   return const LoadingView(message: 'Generating your plan...');
//
// It is centered and fills the free space, so use it as the body of a screen
// or inside an Expanded.

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  /// Optional text under the spinner.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Center(
      child: Semantics(
        label: message ?? 'Loading',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: p.primary,
              backgroundColor: p.progressTrack,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}