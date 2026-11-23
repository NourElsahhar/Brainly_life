// Routes of the auth feature (owner: M1).
// It exposes two lists:
//   authRoutes    -> the screens before sign in (no bottom bar)
//   profileRoutes  -> the Profile tab (inside the bottom bar)
//   settingsRoutes -> Settings, full screen (no bottom bar). Open it with
//                     context.push(AppRoutes.settings) from any tab.
//                     It is NOT inside the Profile tab: each tab remembers
//                     its last page, so Profile would reopen on Settings.
// The splash and onboarding screens are not here. They live in
// app_router.dart because they control when the app opens.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/profile_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/register_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppRoutes.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
];

final List<RouteBase> profileRoutes = [
  GoRoute(
    path: AppRoutes.profile,
    builder: (context, state) => const ProfileScreen(),
  ),
];

final List<RouteBase> settingsRoutes = [
  GoRoute(
    path: AppRoutes.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
];
