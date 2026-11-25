// Tests for the onboarding in the router: a new user sees it once, a user who
// already saw it (or who is signed in) never sees it.
// Run with: fvm flutter test test/core/routes/onboarding_flow_test.dart

import 'package:brainly_life/core/routes/app_router.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/routes/main_shell.dart';
import 'package:brainly_life/core/routes/placeholder_screen.dart';
import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/core/theme/app_theme.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/onboarding_store.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

List<AppTab> _tabs() {
  AppTab tab(String label, String path) => AppTab(
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

  return [tab('Home', AppRoutes.home), tab('Plan', AppRoutes.plan)];
}

void main() {
  group('appRedirect with the onboarding', () {
    test('a new user goes from the splash to the onboarding', () {
      expect(
        appRedirect(
          AuthStatus.signedOut,
          AppRoutes.splash,
          onboardingSeen: false,
        ),
        AppRoutes.onboarding,
      );
    });

    test('a user who already saw it goes to login', () {
      expect(
        appRedirect(AuthStatus.signedOut, AppRoutes.splash),
        AppRoutes.login,
      );
    });

    test('signed out and new: other pages go to the onboarding', () {
      expect(
        appRedirect(
          AuthStatus.signedOut,
          AppRoutes.home,
          onboardingSeen: false,
        ),
        AppRoutes.onboarding,
      );
    });

    test('the auth screens stay where they are while signed out', () {
      for (final seen in [true, false]) {
        for (final page in [
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.forgotPassword,
        ]) {
          expect(
            appRedirect(AuthStatus.signedOut, page, onboardingSeen: seen),
            isNull,
            reason: '$page seen=$seen',
          );
        }
      }
    });

    test('signed in never sees the onboarding, even if not seen', () {
      expect(
        appRedirect(
          AuthStatus.signedIn,
          AppRoutes.splash,
          onboardingSeen: false,
        ),
        AppRoutes.home,
      );
      expect(
        appRedirect(
          AuthStatus.signedIn,
          AppRoutes.onboarding,
          onboardingSeen: false,
        ),
        AppRoutes.home,
      );
      expect(
        appRedirect(AuthStatus.signedIn, AppRoutes.home, onboardingSeen: false),
        isNull,
      );
    });
  });

  group('onboarding in the router', () {
    late MockOnboardingStore store;

    setUp(() {
      store = MockOnboardingStore();
      getIt.registerSingleton<OnboardingStore>(store);
    });

    tearDown(() => getIt.reset());

    Finder appBarTitle(String title) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(title));

    Future<RouterAuthState> pumpApp(
      WidgetTester tester, {
      required AuthStatus status,
    }) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final authState = RouterAuthState.app(
        hasSeenOnboarding: () => store.hasSeen,
        status: status,
        splashDone: true,
      );
      final router = createAppRouter(
        authState,
        tabs: _tabs(),
        fullScreenRoutes: const [],
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
      await tester.pumpAndSettle();
      return authState;
    }

    testWidgets('a new user sees the onboarding and it is marked as seen', (
      tester,
    ) async {
      await pumpApp(tester, status: AuthStatus.signedOut);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(store.hasSeen, isTrue);
    });

    testWidgets('the next time the app opens, the user goes to login', (
      tester,
    ) async {
      await store.markSeen();

      await pumpApp(tester, status: AuthStatus.signedOut);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('signed in goes to Home and never sees the onboarding', (
      tester,
    ) async {
      await pumpApp(tester, status: AuthStatus.signedIn);

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(appBarTitle('Home'), findsOneWidget);
      expect(store.hasSeen, isFalse);
    });

    testWidgets('signing in while on the onboarding opens the app', (
      tester,
    ) async {
      final authState = await pumpApp(tester, status: AuthStatus.signedOut);
      expect(find.byType(OnboardingScreen), findsOneWidget);

      authState.update(AuthStatus.signedIn);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(appBarTitle('Home'), findsOneWidget);
    });

    testWidgets('Skip goes to login', (tester) async {
      await pumpApp(tester, status: AuthStatus.signedOut);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
