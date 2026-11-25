// OnboardingScreen = the 3 welcome pages shown once, the first time the app
// opens. Each page has an illustration (light or dark version), a title and
// a subtitle. Pages 1 and 2 have Skip and Next. The last page has Get started
// (Register) and "I already have an account" (Login).
// It tells OnboardingStore it was shown, so it never appears again.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/data/repositories/onboarding_store.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _PageData {
  const _PageData({
    required this.lightImage,
    required this.darkImage,
    required this.title,
    required this.subtitle,
  });

  final String lightImage;
  final String darkImage;
  final String title;
  final String subtitle;
}

const List<_PageData> _pages = [
  _PageData(
    lightImage: 'assets/onboarding/onboarding_1_light.png',
    darkImage: 'assets/onboarding/onboarding_1_dark.png',
    title: AppStrings.onboardingTitle1,
    subtitle: AppStrings.onboardingSubtitle1,
  ),
  _PageData(
    lightImage: 'assets/onboarding/onboarding_2_light.png',
    darkImage: 'assets/onboarding/onboarding_2_dark.png',
    title: AppStrings.onboardingTitle2,
    subtitle: AppStrings.onboardingSubtitle2,
  ),
  _PageData(
    lightImage: 'assets/onboarding/onboarding_3_light.png',
    darkImage: 'assets/onboarding/onboarding_3_dark.png',
    title: AppStrings.onboardingTitle3,
    subtitle: AppStrings.onboardingSubtitle3,
  ),
];

const String _lightLogo = 'assets/branding/baseet_wordmark_light.png';
const String _darkLogo = 'assets/branding/baseet_wordmark_dark.png';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.store});

  /// Only for tests. Normally the store comes from getIt.
  final OnboardingStore? store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Duration _pageDuration = Duration(milliseconds: 300);

  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Shown once: remember it right away, even if the user closes the app.
    (widget.store ?? getIt<OnboardingStore>()).markSeen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() =>
      _controller.nextPage(duration: _pageDuration, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin,
          ),
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.minTouchTarget,
                child: Row(
                  children: [
                    Image.asset(
                      isDark ? _darkLogo : _lightLogo,
                      height: 26,
                      semanticLabel: 'Baseet',
                      // A missing picture must never crash the screen.
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    const Spacer(),
                    if (!isLast)
                      AppButton(
                        label: AppStrings.onboardingSkip,
                        type: AppButtonType.text,
                        expanded: false,
                        onPressed: () => context.go(AppRoutes.login),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) =>
                      _OnboardingPage(data: _pages[index], isDark: isDark),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              _Dots(count: _pages.length, index: _index),
              const SizedBox(height: AppSpacing.s6),
              AppButton(
                label: isLast
                    ? AppStrings.onboardingGetStarted
                    : AppStrings.onboardingNext,
                onPressed: isLast
                    ? () => context.go(AppRoutes.register)
                    : _next,
              ),
              // Always takes its space, so the buttons do not jump between
              // pages.
              Visibility(
                visible: isLast,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: AppButton(
                  label: AppStrings.onboardingHaveAccount,
                  type: AppButtonType.text,
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.isDark});

  final _PageData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Image.asset(
              isDark ? data.darkImage : data.lightImage,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
              // A missing picture must never crash the screen.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: context.text.displayMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: context.text.bodyLarge?.copyWith(color: p.textSecondary),
        ),
      ],
    );
  }
}

/// The page dots: the current page is a long pill, the others are small dots.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
            width: i == index ? AppSpacing.s8 : AppSpacing.s2,
            height: AppSpacing.s2,
            decoration: BoxDecoration(
              color: i == index ? p.primary : p.iconMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
