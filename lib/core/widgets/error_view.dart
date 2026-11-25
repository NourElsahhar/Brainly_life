// ErrorView = the screen state "something went wrong".
// It shows failure.userMessage (a friendly text) and an optional retry button.
//
// Usage:
//   if (state is TaskListError) {
//     return ErrorView(failure: state.failure, onRetry: cubit.loadTasks);
//   }
//
// Rules:
//   - Always pass the Failure. Never show raw exception text.
//   - onRetry: null -> no retry button.
//   - A NetworkFailure gets a "No connection" title and a wifi icon.

import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../theme/theme.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isNetwork = failure is NetworkFailure;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.errorSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 32,
                color: p.error,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              isNetwork ? 'No connection' : 'Something went wrong',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              failure.userMessage,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s6),
              AppButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                expanded: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
