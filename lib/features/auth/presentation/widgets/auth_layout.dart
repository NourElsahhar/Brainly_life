// The common pieces of the Login, Register and Forgot password screens.
//
//   AuthLayout      -> the page: back arrow, a header (logo or picture),
//                      title, subtitle, then the form. It scrolls, so the
//                      keyboard never hides a field.
//   AuthBanner      -> the coloured box at the top of the form:
//                      red for "Wrong email or password", green for
//                      "Check your inbox".
//   AuthDivider     -> the "──── or ────" line before Google.
//   AuthSwitchLink  -> "Don't have an account? Sign up".
//   BaseetWordmark  -> the Baseet logo (light or dark, by the theme).
//
// Usage:
//   AuthLayout(
//     header: const BaseetWordmark(),
//     centered: true,
//     title: AppStrings.loginTitle,
//     subtitle: AppStrings.loginSubtitle,
//     children: [ ...fields and buttons... ],
//   )

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.header,
    this.centered = false,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Shown above the title (the logo, or the lock picture).
  final Widget? header;

  /// true -> the header, title and subtitle are in the middle.
  final bool centered;

  /// When set, a back arrow is shown at the top left.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.s2,
            AppSpacing.screenMargin,
            AppSpacing.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    icon: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
                    onPressed: onBack,
                  ),
                )
              else
                const SizedBox(height: AppSpacing.s6),
              if (header != null) ...[
                const SizedBox(height: AppSpacing.s4),
                Center(child: header),
              ],
              const SizedBox(height: AppSpacing.s6),
              Text(
                title,
                textAlign: textAlign,
                style: context.text.displayMedium,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                subtitle,
                textAlign: textAlign,
                style: context.text.bodyLarge?.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

enum AuthBannerType { error, success }

class AuthBanner extends StatelessWidget {
  const AuthBanner({
    super.key,
    required this.message,
    this.type = AuthBannerType.error,
  });

  final String message;
  final AuthBannerType type;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isError = type == AuthBannerType.error;
    final color = isError ? p.error : p.success;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: isError ? p.errorSoft : p.successSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: color,
              size: AppSizes.iconNavigation,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message,
                style: context.text.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Divider(color: p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Text(
            label,
            style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: p.border)),
      ],
    );
  }
}

class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onTap,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            style: context.text.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
        AppButton(
          label: linkLabel,
          type: AppButtonType.text,
          expanded: false,
          onPressed: onTap,
        ),
      ],
    );
  }
}

class BaseetWordmark extends StatelessWidget {
  const BaseetWordmark({super.key, this.height = 40});

  final double height;

  static const String light = 'assets/branding/baseet_app_bar_logo_light.png';
  static const String dark = 'assets/branding/baseet_app_bar_logo_dark.png';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? dark : light,
      height: height,
      semanticLabel: 'Baseet',
      // A missing picture must never crash the screen.
      errorBuilder: (_, _, _) => SizedBox(height: height),
    );
  }
}
