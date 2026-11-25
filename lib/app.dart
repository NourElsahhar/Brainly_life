// The root widget of the app: MaterialApp.router with our light and dark
// themes. The router comes from get_it (see injection.dart).
//
// AuthCubit is provided here once, for the whole app:
//   context.read<AuthCubit>().signOut();
//
// The BlocListener tells the router when the user signs in or out, and the
// router then redirects (see core/routes/app_router.dart).
// Someone who signs in never needs the onboarding, so we mark it as seen.

import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/onboarding_store.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/logic/auth_status_mapper.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BrainlyLifeApp extends StatelessWidget {
  const BrainlyLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routerAuthState = getIt<RouterAuthState>();

    return BlocProvider<AuthCubit>.value(
      value: getIt<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) getIt<OnboardingStore>().markSeen();
          routerAuthState.update(authStatusFor(state, routerAuthState.status));
        },
        // The theme follows the user's setting (Settings > Appearance).
        // Signed out -> the phone's theme.
        child: Builder(
          builder: (context) {
            final mode = context.select(
              (AuthCubit cubit) => cubit.currentUser?.settings.themeMode,
            );
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Baseet',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _toThemeMode(mode),
              routerConfig: getIt<GoRouter>(),
            );
          },
        ),
      ),
    );
  }
}

ThemeMode _toThemeMode(AppThemeMode? mode) => switch (mode) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
  AppThemeMode.system || null => ThemeMode.system,
};
