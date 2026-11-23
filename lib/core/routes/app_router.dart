// app_router.dart = builds the GoRouter. It only COMBINES the routes that
// every feature exposes (features/<name>/presentation/<name>_routes.dart).
//
// To change the bottom bar tabs: edit the appTabs list below.
// To make a screen full screen (no bottom bar): put its routes in the
// list after the shell, like tasksRoutes and focusRoutes.
//
// The redirect rules (appRedirect):
//   splash not finished -> always the splash screen
//   unknown    -> splash
//   signedOut  -> only onboarding/login/register/forgot-password
//                 are allowed, everything else goes to login
//   signedIn   -> the auth screens are not allowed, they go to home
//
// createAppRouter has two optional parameters (tabs and fullScreenRoutes).
// They are only for tests, so a router test can use simple placeholder
// screens and does not break when another feature builds its real screen.

import 'package:brainly_life/features/ai_assistant/presentation/ai_assistant_routes.dart';
import 'package:brainly_life/features/auth/presentation/auth_routes.dart';
import 'package:brainly_life/features/auth/presentation/screens/splash_screen.dart';
import 'package:brainly_life/features/focus/presentation/focus_routes.dart';
import 'package:brainly_life/features/habits/presentation/habits_routes.dart';
import 'package:brainly_life/features/home/presentation/home_routes.dart';
import 'package:brainly_life/features/study_planner/presentation/study_planner_routes.dart';
import 'package:brainly_life/features/tasks/presentation/tasks_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import 'main_shell.dart';
import 'router_auth_state.dart';

/// The tabs of the bottom bar, in order.
final List<AppTab> appTabs = [
  AppTab(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    routes: homeRoutes,
  ),
  AppTab(
    label: 'Plan',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month_rounded,
    routes: studyPlannerRoutes,
  ),
  AppTab(
    label: 'Brainly AI',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome_rounded,
    routes: aiAssistantRoutes,
  ),
  AppTab(
    label: 'Habits',
    icon: Icons.check_circle_outline_rounded,
    selectedIcon: Icons.check_circle_rounded,
    routes: habitsRoutes,
  ),
  AppTab(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    routes: profileRoutes,
  ),
];

const Set<String> _publicPages = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

/// Where should the user go? Returns null to stay where they are.
String? appRedirect(
  AuthStatus status,
  String location, {
  bool splashDone = true,
}) {
  // The splash screen stays until its animation has finished.
  if (!splashDone) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  return switch (status) {
    AuthStatus.unknown =>
      location == AppRoutes.splash ? null : AppRoutes.splash,
    AuthStatus.signedOut =>
      _publicPages.contains(location) && location != AppRoutes.splash
          ? null
          : AppRoutes.login,
    AuthStatus.signedIn =>
      _publicPages.contains(location) ? AppRoutes.home : null,
  };
}

/// [tabs] and [fullScreenRoutes] are only for tests. Leave them empty in the app.
GoRouter createAppRouter(
  RouterAuthState authState, {
  List<AppTab>? tabs,
  List<RouteBase>? fullScreenRoutes,
}) {
  final shellTabs = tabs ?? appTabs;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authState,
    redirect: (context, state) => appRedirect(
      authState.status,
      state.matchedLocation,
      splashDone: authState.splashDone,
    ),
    routes: [
      // The splash fades out smoothly when the app opens.
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          child: SplashScreen(onFinished: authState.finishSplash),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      ...authRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell, tabs: shellTabs),
        branches: [
          for (final tab in shellTabs) StatefulShellBranch(routes: tab.routes),
        ],
      ),
      // Full screen (open on top of the bottom bar).
            ...(fullScreenRoutes ??
          [...tasksRoutes, ...focusRoutes, ...habitsFullScreenRoutes]),
    ],
  );
}