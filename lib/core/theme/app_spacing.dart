// Standard gaps, corner sizes and control sizes from the design system.
// Use these instead of typing numbers like 16 or 24 inside widgets.
//
// Examples:
//   Padding(padding: const EdgeInsets.all(AppSpacing.cardPadding), ...)
//   const SizedBox(height: AppSpacing.s4)        // a 16 px gap
//   BorderRadius.circular(AppRadius.card)
//   SizedBox(height: AppSizes.primaryButtonHeight)

class AppSpacing {
  const AppSpacing._();

  // Gap scale. The number in the name is the design token, not the pixels.
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;

  // Layout rules
  static const double screenMargin = 20; // left and right of every screen
  static const double cardGap = 16; // space between two cards
  static const double cardPadding = 20; // inside a normal card
  static const double compactCardPadding = 16; // inside a small card
}

class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 9999; // fully rounded chips and toggles

  // Ready-made choices
  static const double card = 22;
  static const double button = 18;
  static const double input = 16;
}

class AppSizes {
  const AppSizes._();

  static const double primaryButtonHeight = 52;
  static const double inputHeight = 48;
  static const double checkboxDiameter = 22;

  /// Anything the user taps must be at least this big.
  /// (The design says 44, the Master Document says 48. We use 48.)
  static const double minTouchTarget = 48;

  static const double bottomNavCenterButton = 56;
  static const double progressTrackWidth = 6;
  static const double progressActiveStrokeWidth = 8;

  static const double iconSmall = 16;
  static const double iconStandard = 20;
  static const double iconNavigation = 24;
}