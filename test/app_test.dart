// Tests that the app wiring works: AuthCubit -> RouterAuthState -> router.
// Run with: fvm flutter test test/app_test.dart
//
// It checks OUR parts (splash, bottom bar, login). It does not check what is
// inside the Home screen, because that screen belongs to M3.

// ignore_for_file: unused_element

import 'package:brainly_life/app.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/splash_screen.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => getIt.reset());

  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  Future<void> openApp(WidgetTester tester) async {
    await configureDependencies(useMocks: true);
    await tester.pumpWidget(const BrainlyLifeApp());
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> waitForSplash(WidgetTester tester) async {
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
  }

  testWidgets('the splash is shown first, even if the user is known', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('with mocks the demo user sees the app after the splash', (
    tester,
  ) async {
    await openApp(tester);
    await waitForSplash(tester);

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('signing out sends the user to Login', (tester) async {
    await openApp(tester);
    await waitForSplash(tester);

    getIt<AuthCubit>().signOut();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
