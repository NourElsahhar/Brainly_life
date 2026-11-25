// Tests for the router.
// Run with: fvm flutter test test/core/routes/app_router_test.dart
//
// These tests use simple placeholder screens (testTabs and
// testFullScreenRoutes) instead of the real screens of the other features.
// So they keep working when someone replaces a placeholder with a real screen
// that needs get_it, Firebase, etc.

import 'package:brainly_life/core/routes/app_router.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/main_shell.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/presentation/auth_routes.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

AppTab _placeholderTab(String label, String path) {
  return AppTab(
    label: label,
    icon: Icons.circle_outlined,
    selectedIcon: Icons.circle,
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => PlaceholderScreen(title: label),
      ),
    ],
  );
}

/// The same 5 tabs as the app, but every screen is a simple placeholder.
/// (Profile keeps the real list, because it is a placeholder too.)
List<AppTab> testTabs() => [
  _placeholderTab('Home', AppRoutes.home),
  _placeholderTab('Plan', AppRoutes.plan),
  _placeholderTab('Brainly AI', AppRoutes.assistant),
  _placeholderTab('Habits', AppRoutes.habits),
  AppTab(
    label: 'Profile',
    icon: Icons.circle_outlined,
    selectedIcon: Icons.circle,
    routes: profileRoutes,
  ),
];

final List<RouteBase> testFullScreenRoutes = [
  GoRoute(
    path: AppRoutes.tasks,
    builder: (context, state) => const PlaceholderScreen(title: 'Tasks'),
  ),
  GoRoute(
    path: AppRoutes.taskDetail,
    builder: (context, state) =>
        PlaceholderScreen(title: 'Task ${state.pathParameters['id']}'),
  ),
  GoRoute(
    path: AppRoutes.focus,
    builder: (context, state) => const PlaceholderScreen(title: 'Focus'),
  ),
];

void main() {
  group('appRedirect', () {
    test('Terms and Privacy are open signed in and signed out', () {
      for (final page in [AppRoutes.terms, AppRoutes.privacy]) {
        expect(appRedirect(AuthStatus.signedOut, page), isNull);
        expect(appRedirect(AuthStatus.signedIn, page), isNull);
        expect(appRedirect(AuthStatus.unknown, page), AppRoutes.splash);
      }
    });

    test('unknown: everything goes to splash', () {
      expect(appRedirect(AuthStatus.unknown, AppRoutes.splash), isNull);
      expect(
        appRedirect(AuthStatus.unknown, AppRoutes.login),
        AppRoutes.splash,
      );
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
      expect(
        appRedirect(AuthStatus.signedOut, AppRoutes.splash),
        AppRoutes.login,
      );
      expect(
        appRedirect(AuthStatus.signedOut, AppRoutes.home),
        AppRoutes.login,
      );
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
        expect(
          appRedirect(AuthStatus.signedIn, page),
          AppRoutes.home,
          reason: page,
        );
      }
      expect(appRedirect(AuthStatus.signedIn, AppRoutes.home), isNull);
      expect(appRedirect(AuthStatus.signedIn, '/tasks/abc'), isNull);
    });

    test('while the splash is not done, only the splash is allowed', () {
      for (final status in AuthStatus.values) {
        expect(
          appRedirect(status, AppRoutes.splash, splashDone: false),
          isNull,
          reason: '$status',
        );
        expect(
          appRedirect(status, AppRoutes.home, splashDone: false),
          AppRoutes.splash,
          reason: '$status',
        );
        expect(
          appRedirect(status, AppRoutes.login, splashDone: false),
          AppRoutes.splash,
          reason: '$status',
        );
      }
    });
  });

  group('RouterAuthState', () {
    test('a normal one has no splash to wait for', () {
      expect(RouterAuthState().splashDone, isTrue);
      expect(RouterAuthState().status, AuthStatus.unknown);
    });

    test('withSplash waits until finishSplash is called', () {
      final state = RouterAuthState.withSplash();
      var notified = 0;
      state.addListener(() => notified++);

      expect(state.splashDone, isFalse);

      state.finishSplash();
      expect(state.splashDone, isTrue);
      expect(notified, 1);

      state.finishSplash();
      expect(notified, 1);
    });

    test('update only notifies when the status changes', () {
      final state = RouterAuthState();
      var notified = 0;
      state.addListener(() => notified++);

      state.update(AuthStatus.signedIn);
      state.update(AuthStatus.signedIn);

      expect(notified, 1);
    });
  });

  group('AppRoutes and appTabs', () {
    test('builds paths with parameters', () {
      expect(AppRoutes.taskPath('abc'), '/tasks/abc');
      expect(AppRoutes.focusPath(), '/focus');
      expect(AppRoutes.focusPath(taskId: 't1'), '/focus?taskId=t1');
      expect(
        AppRoutes.focusPath(taskId: 't1', studySessionId: 's1'),
        '/focus?taskId=t1&studySessionId=s1',
      );
    });

    test('the app has the 5 agreed tabs', () {
      expect(appTabs.map((tab) => tab.label).toList(), [
        'Home',
        'Plan',
        'Brainly AI',
        'Habits',
        'Profile',
      ]);
    });
  });

  group('router screens', () {
    Finder appBarTitle(String title) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(title));

    Future<GoRouter> pumpApp(
      WidgetTester tester,
      RouterAuthState authState, {
      bool settle = true,
    }) async {
      final router = createAppRouter(
        authState,
        tabs: testTabs(),
        fullScreenRoutes: testFullScreenRoutes,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        // The auth screens need the AuthCubit (app.dart gives it in the app).
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(MockAuthRepository()),
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump(const Duration(milliseconds: 300));
      }
      return router;
    }

    testWidgets('signed in: shows Home and the 5 tabs', (tester) async {
      await pumpApp(tester, RouterAuthState(AuthStatus.signedIn));

      expect(appBarTitle('Home'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['Home', 'Plan', 'Brainly AI', 'Habits', 'Profile']) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
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

    testWidgets('settings is full screen (no bottom bar)', (tester) async {
      final router = await pumpApp(
        tester,
        RouterAuthState(AuthStatus.signedIn),
      );

      router.go(AppRoutes.settings);
      await tester.pumpAndSettle();

      expect(appBarTitle('Settings'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('settings pushed from a tab goes back to that tab', (
      tester,
    ) async {
      final router = await pumpApp(
        tester,
        RouterAuthState(AuthStatus.signedIn),
      );
      router.go(AppRoutes.plan);
      await tester.pumpAndSettle();

      router.push(AppRoutes.settings);
      await tester.pumpAndSettle();
      expect(appBarTitle('Settings'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(appBarTitle('Plan'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('tasks and focus are full screen (no bottom bar)', (
      tester,
    ) async {
      final router = await pumpApp(
        tester,
        RouterAuthState(AuthStatus.signedIn),
      );

      router.go(AppRoutes.taskPath('abc'));
      await tester.pumpAndSettle();
      expect(appBarTitle('Task abc'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      router.go(AppRoutes.focusPath(taskId: 'abc'));
      await tester.pumpAndSettle();
      expect(appBarTitle('Focus'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('signed in cannot open the login screen', (tester) async {
      final router = await pumpApp(
        tester,
        RouterAuthState(AuthStatus.signedIn),
      );

      router.go(AppRoutes.login);
      await tester.pumpAndSettle();

      expect(appBarTitle('Home'), findsOneWidget);
    });

    testWidgets('signed out goes to login', (tester) async {
      await pumpApp(tester, RouterAuthState(AuthStatus.signedOut));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('unknown stays on the splash screen', (tester) async {
      await pumpApp(tester, RouterAuthState(), settle: false);

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the splash stays until it finishes, then the app opens', (
      tester,
    ) async {
      final authState = RouterAuthState.withSplash(AuthStatus.signedIn);
      await pumpApp(tester, authState, settle: false);

      // We already know the user, but the splash is still playing.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(authState.splashDone, isFalse);

      await tester.pump(SplashScreen.duration);
      await tester.pumpAndSettle();

      expect(authState.splashDone, isTrue);
      expect(find.byType(SplashScreen), findsNothing);
      expect(appBarTitle('Home'), findsOneWidget);
    });

    testWidgets('the router reacts when the auth state changes', (
      tester,
    ) async {
      final authState = RouterAuthState(AuthStatus.signedOut);
      await pumpApp(tester, authState);
      expect(find.byType(LoginScreen), findsOneWidget);

      authState.update(AuthStatus.signedIn);
      await tester.pumpAndSettle();

      expect(appBarTitle('Home'), findsOneWidget);
    });
  });
}
