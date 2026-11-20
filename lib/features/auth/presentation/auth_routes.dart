// Routes of the auth feature (owner: M1).
// It exposes two lists:
//   authRoutes    -> the screens before sign in (no bottom bar)
//   profileRoutes -> the Profile tab and Settings (M1 builds them too)
// Replace each PlaceholderScreen with the real screen when it is ready.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const PlaceholderScreen(title: 'Splash'),
  ),
  GoRoute(
    path: AppRoutes.onboarding,
    builder: (context, state) => const PlaceholderScreen(title: 'Onboarding'),
  ),
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) => const PlaceholderScreen(title: 'Login'),
  ),
  GoRoute(
    path: AppRoutes.register,
    builder: (context, state) => const PlaceholderScreen(title: 'Register'),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (context, state) =>
        const PlaceholderScreen(title: 'Forgot password'),
  ),
];

final List<RouteBase> profileRoutes = [
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => const PlaceholderScreen(title: 'Profile'),
    routes: [
      // 'settings' is the last part of AppRoutes.settings (/profile/settings).
      GoRoute(
        path: 'settings',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Settings'),
      ),
    ],
  ),
];