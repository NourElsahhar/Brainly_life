import 'package:brainly_life/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// A small bold label above a form part, the same look as the label of
/// M1's AppTextField.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Text(
        text,
        style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
