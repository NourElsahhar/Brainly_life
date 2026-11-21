// SplashScreen = the first screen of the app: logo, name and tagline.
//
// It plays a short animation (SplashScreen.duration) and then calls
// onFinished. The router leaves the splash only when BOTH are true:
//   1) the animation finished
//   2) we know if the user is signed in
// So even when the sign in check is instant, the splash never flashes away.
//
// The animation (inside the total duration):
//   logo      fades in and grows a little        (first)
//   name      fades in and slides up a little
//   tagline   fades in and slides up a little
//   spinner   fades in                           (last)
//
// To change the speed: change SplashScreen.duration.
// To change the texts or the logo files: change the constants below.
// The logo has a light and a dark version (it follows the theme).

import 'package:brainly_life/core/theme/theme.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  /// Called once, when the animation ends.
  final VoidCallback? onFinished;

  /// Total time of the animation. The splash stays at least this long.
  static const Duration duration = Duration(milliseconds: 3000);

  static const String appName = 'Baseet';
  static const String tagline = 'Your day, made simpler.';
  static const String lightLogo = 'assets/branding/baseet_logo_light.png';
  static const String darkLogo = 'assets/branding/baseet_logo_dark.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _logo;
  late final CurvedAnimation _name;
  late final CurvedAnimation _tagline;
  late final CurvedAnimation _spinner;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashScreen.duration,
    )..addStatusListener(_onStatus);

    // Each part starts and ends at a point of the total time (0 to 1).
    _logo = _stage(0.00, 0.38);
    _name = _stage(0.22, 0.55);
    _tagline = _stage(0.36, 0.68);
    _spinner = _stage(0.55, 0.80);

    _controller.forward();
  }

  CurvedAnimation _stage(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onFinished?.call();
  }

  @override
  void dispose() {
    _logo.dispose();
    _name.dispose();
    _tagline.dispose();
    _spinner.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Fades [child] in, and slides it up a little when [slide] is not 0.
  Widget _reveal(Animation<double> animation, Widget child,
      {double slide = 0}) {
    final faded = FadeTransition(opacity: animation, child: child);
    if (slide == 0) return faded;
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, slide), end: Offset.zero)
          .animate(animation),
      child: faded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = p.primaryCTA.withValues(alpha: isDark ? 0.28 : 0.14);

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          // Soft violet glow behind the logo.
          Positioned.fill(
            child: FadeTransition(
              opacity: _logo,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 0.9,
                    colors: [glow, glow.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _reveal(
                  _logo,
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(_logo),
                    child: _LogoTile(isDark: isDark),
                  ),
                ),
                const SizedBox(height: AppSpacing.s7),
                _reveal(
                  _name,
                  Text(
                    SplashScreen.appName,
                    textAlign: TextAlign.center,
                    style: context.text.displayLarge,
                  ),
                  slide: 0.4,
                ),
                const SizedBox(height: AppSpacing.s2),
                _reveal(
                  _tagline,
                  Text(
                    SplashScreen.tagline,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
                  slide: 0.6,
                ),
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.78),
            child: FadeTransition(
              opacity: _spinner,
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: p.primary,
                  backgroundColor: p.progressTrack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo inside a rounded square, with a violet shadow.
class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.isDark});

  final bool isDark;

  static const double _size = 148;
  static const double _radius = 36;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: p.primaryCTA.withValues(alpha: isDark ? 0.40 : 0.28),
            blurRadius: 40,
            spreadRadius: -6,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Image.asset(
          isDark ? SplashScreen.darkLogo : SplashScreen.lightLogo,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          semanticLabel: 'Baseet logo',
        ),
      ),
    );
  }
}