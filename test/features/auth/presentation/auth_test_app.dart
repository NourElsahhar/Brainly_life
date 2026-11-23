// A small test app for the auth screens: a real AuthCubit on the
// MockAuthRepository, and simple pages for the places the screens go to.
//
// Usage:
//   final cubit = await pumpAuthScreen(tester, AppRoutes.login);
//   expect(find.text('register page'), findsOneWidget);

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/presentation/auth_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<AuthCubit> pumpAuthScreen(
  WidgetTester tester,
  String location, {
  MockAuthRepository? repository,
}) async {
  // Tall enough to show the whole Register form.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final cubit = AuthCubit(repository ?? MockAuthRepository());
  addTearDown(cubit.close);

  final router = GoRouter(
    initialLocation: location,
    routes: [
      ...authRoutes,
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Text('home page'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: cubit,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

/// The text field number [index] on the screen (0 = the first one).
Finder field(int index) => find.byType(TextField).at(index);

/// Scrolls to [finder] if needed, taps it and waits for the animations.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
