// PasswordStrengthMeter = the 4 bars under the password on Register,
// with "Weak", "Medium" or "Strong" and the rule "At least 8 characters".
// It only shows; the rules are in PasswordStrength (auth/logic).
//
// Usage:
//   PasswordStrengthMeter(password: _passwordController.text)

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/logic/password_strength.dart';
import 'package:flutter/material.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final strength = PasswordStrength.of(password);

    final (Color color, String? label) = switch (strength.level) {
      PasswordLevel.none => (p.progressTrack, null),
      PasswordLevel.weak => (p.error, AppStrings.passwordWeak),
      PasswordLevel.medium => (p.warning, AppStrings.passwordMedium),
      PasswordLevel.strong => (p.success, AppStrings.passwordStrong),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < PasswordStrength.maxBars; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: AppSizes.progressTrackWidth,
                  decoration: BoxDecoration(
                    color: i < strength.bars ? color : p.progressTrack,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.passwordRule,
                style: context.text.bodySmall?.copyWith(
                  color: p.textSecondary,
                ),
              ),
            ),
            if (label != null)
              Text(
                label,
                style: context.text.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
