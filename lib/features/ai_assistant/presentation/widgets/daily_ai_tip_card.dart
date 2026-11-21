import 'package:brainly_life/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../../../../core/ai/ai_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/theme.dart';

class DailyAiTipCard extends StatelessWidget {
  const DailyAiTipCard({super.key, required this.tip});

  final Future<Result<String>> tip;

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<String>>(
    future: tip,
    builder: (context, snapshot) {
      final text = snapshot.data?.dataOrNull;
      if (text == null) return const SizedBox.shrink();
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.dailyTip, style: context.text.headlineSmall),
              Text(text),
              const AiDisclaimer(),
            ],
          ),
        ),
      );
    },
  );
}
