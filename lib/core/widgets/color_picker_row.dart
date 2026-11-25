// ColorPickerRow = a row of color circles. The user picks one.
// The color is stored as an int (colorValue), like in the Firestore schema.
//
// Usage:
//   ColorPickerRow(
//     label: 'Color',
//     selectedColorValue: state.colorValue,        // null = nothing selected
//     onChanged: cubit.colorChanged,               // gets the new colorValue
//   )
//
// Reading it back as a color:
//   Color(subject.colorValue)
//
// Rules:
//   - Do not show the color only. Always show the name of the thing too.
//   - Different colors? pass colors: [...] (a list of Color).

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
    this.label,
    this.colors,
  });

  final int? selectedColorValue;
  final ValueChanged<int> onChanged;
  final String? label;

  /// Leave empty to use [defaultColors].
  final List<Color>? colors;

  /// The colors offered by default (from the design system).
  static final List<Color> defaultColors = [
    AppColors.mathematics.accent,
    AppColors.physics.accent,
    AppColors.biology.accent,
    AppColors.personal.accent,
    AppColors.rewards.accent,
    AppColors.alertAccent,
    AppColors.teal,
    AppColors.reflectiveLilac,
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final options = colors ?? defaultColors;

    final swatches = Wrap(
      spacing: AppSpacing.s1,
      runSpacing: AppSpacing.s1,
      children: [
        for (var i = 0; i < options.length; i++) _buildSwatch(p, options[i], i),
      ],
    );

    if (label == null) return swatches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.s1),
        swatches,
      ],
    );
  }

  Widget _buildSwatch(AppPalette p, Color color, int index) {
    final value = color.toARGB32();
    final isSelected = value == selectedColorValue;
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? AppPalette.light.onPrimary
        : AppPalette.light.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Color option ${index + 1}',
      child: InkResponse(
        key: ValueKey(value),
        onTap: () => onChanged(value),
        radius: 26,
        child: SizedBox(
          width: AppSizes.minTouchTarget,
          height: AppSizes.minTouchTarget,
          child: Center(
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? p.textPrimary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, size: 18, color: checkColor)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
