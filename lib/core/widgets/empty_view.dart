// EmptyView = the screen state "there is nothing here yet".
//
// Usage:
//   EmptyView(
//     icon: Icons.menu_book_outlined,
//     title: 'Add your first subject',
//     message: 'Subjects help us build your study plan.',
//     actionLabel: 'Add subject',
//     onAction: () => context.push('/study/subjects/new'),
//   )
//
// Rules:
//   - The button appears only when BOTH actionLabel and onAction are given.
//   - Write a helpful title ("No tasks today"), not just "Empty".

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_button.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasAction = actionLabel != null && onAction != null;

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
                color: p.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: p.primary),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ],
            if (hasAction) ...[
              const SizedBox(height: AppSpacing.s6),
              AppButton(
                label: actionLabel!,
                expanded: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}