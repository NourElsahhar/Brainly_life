// Tests that the app wiring works: AuthCubit -> RouterAuthState -> router.
// Run with: fvm flutter test test/app_test.dart
//
// Widget tests run in "fake time". Setting up and closing the dependencies
// needs REAL async, so we do both inside tester.runAsync.
// Each test has a 20 second limit, so a problem fails fast (no endless wait).

import 'package:brainly_life/app.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const limit = Timeout(Duration(seconds: 20));

  Finder appBarTitle(String title) => find.descendant(
        of: find.byType(AppBar),
        matching: find.text(title),
      );

  /// Starts the app with mocks and waits until it is ready.
  Future<void> startApp(WidgetTester tester) async {
    await tester.runAsync(() => configureDependencies(useMocks: true));
    await tester.pumpWidget(const BrainlyLifeApp());
    await tester.pumpAndSettle();
  }

  /// Removes the app and closes everything.
  Future<void> stopApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => getIt.reset());
  }

  testWidgets(
    'with mocks the demo user is signed in and sees Home',
    timeout: limit,
    (tester) async {
      await startApp(tester);

      expect(appBarTitle('Home'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await stopApp(tester);
    },
  );

  testWidgets(
    'signing out sends the user to Login',
    timeout: limit,
    (tester) async {
      await startApp(tester);

      getIt<AuthCubit>().signOut();
      await tester.pumpAndSettle();

      expect(appBarTitle('Login'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await stopApp(tester);
    },
  );
}