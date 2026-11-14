// Shadows from the design system (soft, tinted, never heavy black).
//
// Usage:
//   Container(
//     decoration: BoxDecoration(
//       color: context.palette.surface,
//       borderRadius: BorderRadius.circular(AppRadius.card),
//       boxShadow: AppShadows.card(context),
//     ),
//   )
//
// In dark mode cards get NO shadow: they are separated by their surface
// color and a thin border (context.palette.border) instead.

import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Normal cards (design: Elevation 1).
  static List<BoxShadow> card(BuildContext context) {
    if (_isDark(context)) return const [];
    return const [
      BoxShadow(
        color: Color.fromRGBO(108, 92, 231, 0.05),
        offset: Offset(0, 4),
        blurRadius: 20,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: Color.fromRGBO(45, 52, 54, 0.03),
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
    ];
  }

  /// Floating things like the bottom bar (design: Elevation 2).
  static List<BoxShadow> floating(BuildContext context) {
    if (_isDark(context)) {
      // Dark mode: one soft violet glow, nothing bright.
      return const [
        BoxShadow(
          color: Color.fromRGBO(108, 92, 231, 0.18),
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color.fromRGBO(72, 52, 212, 0.16),
        offset: Offset(0, 12),
        blurRadius: 32,
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.04),
        offset: Offset(0, 4),
        blurRadius: 12,
      ),
    ];
  }

  /// Dialogs and bottom sheets (design: Elevation 3).
  static List<BoxShadow> modal(BuildContext context) {
    final color = _isDark(context)
        ? const Color.fromRGBO(0, 0, 0, 0.40)
        : const Color.fromRGBO(18, 17, 26, 0.22);
    return [
      BoxShadow(
        color: color,
        offset: const Offset(0, 24),
        blurRadius: 48,
        spreadRadius: -8,
      ),
    ];
  }
}