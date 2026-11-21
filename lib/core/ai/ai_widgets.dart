import 'package:brainly_life/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../errors/failure.dart';
import '../theme/theme.dart';

class AiLoadingBubble extends StatelessWidget {
  const AiLoadingBubble({super.key, this.label = AppStrings.aiTyping});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: AppSpacing.s4,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    ),
  );
}

class AiErrorCard extends StatelessWidget {
  const AiErrorCard({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    color: context.palette.errorSoft,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Row(
        children: [
          Expanded(child: Text(failure.userMessage)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    ),
  );
}

class AiDisclaimer extends StatelessWidget {
  const AiDisclaimer({super.key});

  @override
  Widget build(BuildContext context) => Text(
    AppStrings.aiDisclaimer,
    style: context.text.bodySmall?.copyWith(
      color: context.palette.textSecondary,
    ),
  );
}

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({
    super.key,
    required this.title,
    required this.text,
    this.onDismiss,
  });

  final String title;
  final String text;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => AppCard(
    child: ListTile(
      title: Text(title),
      subtitle: Text(text),
      trailing: onDismiss == null ? null : CloseButton(onPressed: onDismiss),
    ),
  );
}
