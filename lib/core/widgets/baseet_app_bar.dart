// BaseetAppBar = the one top bar of the whole app (design: Canva
// "Baseet App Bar", light + dark).
//
// Two kinds:
//   - BaseetAppBar.main(): the 5 main tabs. Baseet logo + Settings button.
//   - BaseetAppBar.inner(title: 'Task'): every other screen. Back arrow
//     (added by Flutter when there is a page to go back to) + title + actions.
//
// Usage:
//   Scaffold(appBar: const BaseetAppBar.main(), ...)
//   Scaffold(
//     appBar: BaseetAppBar.inner(
//       title: 'Task',
//       actions: [
//         AppBarIconButton(icon: Icons.edit_outlined, tooltip: 'Edit', onPressed: ...),
//       ],
//     ),
//   )

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BaseetAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The bar of the 5 main tabs: logo on the left, Settings on the right.
  const BaseetAppBar.main({super.key, this.onSettings})
    : title = null,
      titleWidget = null,
      actions = const [],
      bottom = null;

  /// The bar of every other screen: back arrow, [title] and [actions].
  const BaseetAppBar.inner({
    super.key,
    required String this.title,
    this.titleWidget,
    this.actions = const [],
    this.bottom,
  }) : onSettings = null;

  /// The height of the bar, from the design.
  static const double height = 64;

  /// Path of the logo for each theme.
  static const String lightLogo =
      'assets/branding/baseet_app_bar_logo_light.png';
  static const String darkLogo = 'assets/branding/baseet_app_bar_logo_dark.png';

  /// null means this is the main bar (logo instead of a title).
  final String? title;
  
  /// Shown instead of [title] when set, like a search box.
  final Widget? titleWidget;

  final List<Widget> actions;

  /// Something under the bar, like the tabs of the Tasks screen.
  final PreferredSizeWidget? bottom;

  /// What the Settings button does. Defaults to opening Settings.
  final VoidCallback? onSettings;

  bool get _isMain => title == null;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final title = this.title;

    return AppBar(
      toolbarHeight: height,
      titleSpacing: _isMain ? AppSpacing.s4 : null,
      title: title == null ? const _Logo() : titleWidget ?? Text(title),
      actions: [
        if (_isMain)
          AppBarIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: onSettings ?? () => context.go(AppRoutes.settings),
          )
        else
          ...actions,
        const SizedBox(width: AppSpacing.s2),
      ],
      bottom: bottom,
    );
  }
}

/// A round icon button for the app bar. The main bar shows it on a light
/// purple circle ([filled]); inner screens use the plain one.
class AppBarIconButton extends StatelessWidget {
  const AppBarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = true,
  });

  final IconData icon;

  /// Read by screen readers, and shown on long press.
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconStandard + 2),
      color: p.textPrimary,
      style: filled
          ? IconButton.styleFrom(
              backgroundColor: p.primarySoft,
              fixedSize: const Size.square(AppSpacing.s10), // 40 in the design
            )
          : null,
    );
  }
}

/// The Baseet logo, in the right colours for light and dark mode.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDark ? BaseetAppBar.darkLogo : BaseetAppBar.lightLogo,
      height: AppSpacing.s7, // 28 in the design
      semanticLabel: 'Baseet',
      // Tests and a missing file show the name instead of a red box.
      errorBuilder: (context, _, _) =>
          Text('Baseet', style: context.text.headlineSmall),
    );
  }
}
