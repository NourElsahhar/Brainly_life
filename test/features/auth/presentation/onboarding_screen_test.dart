// Widget tests for OnboardingScreen: the first page, Next, Skip, the last
// page buttons, and that it marks the onboarding as seen when it appears.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/data/repositories/onboarding_store.dart';
import 'package:brainly_life/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<MockOnboardingStore> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = MockOnboardingStore();
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => OnboardingScreen(store: store),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, _) => const Text('login page'),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, _) => const Text('register page'),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('shows the first page and marks it as seen', (tester) async {
    final store = await pumpScreen(tester);

    expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
    expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
    expect(find.text(AppStrings.onboardingNext), findsOneWidget);
    expect(store.hasSeen, isTrue);
  });

  testWidgets('Next goes to the second page', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingTitle2), findsOneWidget);
  });

  testWidgets('Skip goes to login', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.onboardingSkip));
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });

  testWidgets('the last page has Get started and no Skip', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.onboardingTitle3), findsOneWidget);
    expect(find.text(AppStrings.onboardingSkip), findsNothing);
    expect(find.text(AppStrings.onboardingGetStarted), findsOneWidget);
    expect(find.text(AppStrings.onboardingHaveAccount), findsOneWidget);

    await tester.tap(find.text(AppStrings.onboardingGetStarted));
    await tester.pumpAndSettle();
    expect(find.text('register page'), findsOneWidget);
  });

  testWidgets('"I already have an account" goes to login', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.onboardingHaveAccount));
    await tester.pumpAndSettle();

    expect(find.text('login page'), findsOneWidget);
  });
}
