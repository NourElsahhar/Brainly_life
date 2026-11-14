// Animation timings from the design system.
// Keep animations short and calm. Never bouncy for normal actions.
//
// Usage:
//   AnimatedContainer(duration: AppMotion.standard, ...)
//   AnimatedScale(scale: pressed ? AppMotion.pressedScale : 1, duration: AppMotion.fast, ...)

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 240);

  /// Buttons shrink very slightly when pressed.
  static const double pressedScale = 0.98;
}