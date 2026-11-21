// Tests for the router.
// Run with: fvm flutter test test/core/routes/app_router_test.dart

import 'package:brainly_life/core/routes/app_router.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/home/home_injection.dart';
import 'package:brainly_life/features/tasks/tasks_injection.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('appRedirect', () {
    test('unknown: everything goes to splash', () {
      expect(appRedirect(AuthStatus.unknown, AppRoutes.splash), isNull);
      expect(appRedirect(AuthStatus.unknown, AppRoutes.login), AppRoutes.splash);
      expect(appRedirect(AuthStatus.unknown, AppRoutes.home), AppRoutes.splash);
    });

    test('signed out: only the auth screens are allowed', () {
      for (final page in [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(appRedirect(AuthStatus.signedOut, page), isNull, reason: page);
      }
      expect(appRedirect(AuthStatus.signedOut, AppRoutes.splash), AppRoutes.login);
      expect(appRedirect(AuthStatus.signedOut, AppRoutes.home), AppRoutes.login);
      expect(appRedirect(AuthStatus.signedOut, '/tasks/abc'), AppRoutes.login);
    });

    test('signed in: the auth screens go to home', () {
      for (final page in [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ]) {
        expect(appRedirect(AuthStatus.signedIn, page), AppRoutes.home, reason: page);
      }
      expect(appRedirect(AuthStatus.signedIn, AppRoutes.home), isNull);
      expect(appRedirect(AuthStatus.signedIn, '/tasks/abc'), isNull);
    });
  });

  group('AppRoutes', () {
    test('builds paths with parameters', () {
      expect(AppRoutes.taskPath('abc'), '/tasks/abc');
      expect(AppRoutes.focusPath(), '/focus');
      expect(AppRoutes.focusPath(taskId: 't1'), '/focus?taskId=t1');
      expect(
        AppRoutes.focusPath(taskId: 't1', studySessionId: 's1'),
        '/focus?taskId=t1&studySessionId=s1',
      );
    });
  });

  group('router screens', () {
        // The real tasks and home screens get their Cubits from getIt.
    setUp(() {
      registerTasksFeature(getIt, useMocks: true);
      registerHomeFeature(getIt, useMocks: true);
    });
    tearDown(() => getIt.reset());
    Finder appBarTitle(String title) => find.descendant(
          of: find.byType(AppBar),
          matching: find.text(title),
        );

    Future<GoRouter> pumpApp(
      WidgetTester tester,
      RouterAuthState authState,
    ) async {
      final router = createAppRouter(authState);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );
      await tester.pumpAndSettle();
      return router;
    }

    testWidgets('signed in: shows Home and the 5 tabs', (tester) async {
      await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      expect(appBarTitle('Home'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(appTabs.map((tab) => tab.label).toList(), [
        'Home',
        'Plan',
        'Brainly AI',
        'Habits',
        'Profile',
      ]);
      for (final tab in appTabs) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab.label),
          ),
          findsOneWidget,
        );
      }
    });

    testWidgets('tapping a tab opens its screen', (tester) async {
      await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Plan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(appBarTitle('Plan'), findsOneWidget);
    });

    testWidgets('settings opens inside the Profile tab', (tester) async {
      final router = await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();

      expect(appBarTitle('Settings'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tasks and focus are full screen (no bottom bar)',
        (tester) async {
      final router = await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      router.go(AppRoutes.taskPath('abc'));
      await tester.pumpAndSettle();
      expect(appBarTitle('Task'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      router.go(AppRoutes.focusPath(taskId: 'abc'));
      await tester.pumpAndSettle();
      expect(appBarTitle('Focus'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('signed in cannot open the login screen', (tester) async {
      final router = await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(appBarTitle('Home'), findsOneWidget);
    });

    testWidgets('signed out goes to login', (tester) async {
      await pumpApp(tester, RouterAuthState(AuthStatus.signedOut));

      expect(appBarTitle('Login'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('unknown stays on the splash screen', (tester) async {
      await pumpApp(tester, RouterAuthState());

      expect(appBarTitle('Splash'), findsOneWidget);
    });

    testWidgets('the router reacts when the auth state changes',
        (tester) async {
      final authState = RouterAuthState(AuthStatus.signedOut);
      await pumpApp(tester, authState);
      expect(appBarTitle('Login'), findsOneWidget);

      authState.update(AuthStatus.signedIn);
      await tester.pumpAndSettle();

      expect(appBarTitle('Home'), findsOneWidget);
    });
  });
}