// app_router.dart = builds the GoRouter. It only COMBINES the routes that
// every feature exposes (features/<name>/presentation/<name>_routes.dart).
//
// To change the bottom bar tabs: edit the appTabs list below.
// To make a screen full screen (no bottom bar): put its routes in the
// list after the shell, like tasksRoutes and focusRoutes.
//
// The redirect rules (appRedirect):
//   unknown    -> splash
//   signedOut  -> only splash/onboarding/login/register/forgot-password
//                 are allowed, everything else goes to login
//   signedIn   -> the auth screens are not allowed, they go to home

import 'package:brainly_life/features/ai_assistant/presentation/ai_assistant_routes.dart';
import 'package:brainly_life/features/auth/presentation/auth_routes.dart';
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
String? appRedirect(AuthStatus status, String location) {
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

GoRouter createAppRouter(RouterAuthState authState) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authState,
    redirect: (context, state) =>
        appRedirect(authState.status, state.matchedLocation),
    routes: [
      ...authRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell, tabs: appTabs),
        branches: [
          for (final tab in appTabs) StatefulShellBranch(routes: tab.routes),
        ],
      ),
      // Full screen (open on top of the bottom bar).
      ...tasksRoutes,
      ...focusRoutes,
    ],
  );
}
