// Widget tests for RegisterScreen: live validation, the strength bar,
// the Terms box, an email already used, a good registration, the links.
// Run with: fvm flutter test test/features/auth/presentation/register_screen_test.dart

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/presentation/screens/legal_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_app.dart';

void main() {
  // Fields: 0 name, 1 email, 2 password, 3 confirm.
  const goodPassword = 'Shahd2026!';

  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Shahd Adel',
    String email = 'shahd@student.edu',
    String password = goodPassword,
    String confirm = goodPassword,
    bool acceptTerms = true,
  }) async {
    await tester.enterText(field(0), name);
    await tester.enterText(field(1), email);
    await tester.enterText(field(2), password);
    await tester.enterText(field(3), confirm);
    if (acceptTerms) await tapAndSettle(tester, find.byType(Checkbox));
    await tester.pump();
  }

  Future<void> tapCreate(WidgetTester tester) =>
      tapAndSettle(tester, find.text(AppStrings.registerAction));

  testWidgets('empty form shows every error', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.register);

    await tapCreate(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(find.text(AppStrings.registerTermsRequired), findsOneWidget);
  });

  testWidgets('the strength bar says Weak, Medium, then Strong', (
    tester,
  ) async {
    await pumpAuthScreen(tester, AppRoutes.register);

    await tester.enterText(field(2), 'password');
    await tester.pump();
    expect(find.text(AppStrings.passwordWeak), findsOneWidget);
    expect(find.text(AppStrings.passwordTooWeak), findsOneWidget);

    await tester.enterText(field(2), 'Password1');
    await tester.pump();
    expect(find.text(AppStrings.passwordMedium), findsOneWidget);
    expect(find.text(AppStrings.passwordTooWeak), findsNothing);

    await tester.enterText(field(2), goodPassword);
    await tester.pump();
    expect(find.text(AppStrings.passwordStrong), findsOneWidget);
  });

  testWidgets('the confirmation is checked live', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.register);

    await tester.enterText(field(2), goodPassword);
    await tester.enterText(field(3), 'Shahd2026');
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    await tester.enterText(field(3), goodPassword);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsNothing);
  });

  testWidgets('a weak password is refused', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.register);

    await fillForm(tester, password: 'password123', confirm: 'password123');
    await tapCreate(tester);

    expect(find.text(AppStrings.passwordTooWeak), findsOneWidget);
    expect(cubit.state, isNot(isA<Authenticated>()));
  });

  testWidgets('the Terms box must be ticked', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.register);

    await fillForm(tester, acceptTerms: false);
    await tapCreate(tester);

    expect(find.text(AppStrings.registerTermsRequired), findsOneWidget);
    expect(cubit.state, isNot(isA<Authenticated>()));
  });

  testWidgets('an email that is already used shows the banner', (
    tester,
  ) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.register);

    await fillForm(tester, email: MockAuthRepository.demoEmail);
    await tapCreate(tester);

    expect(cubit.state, isA<AuthError>());
    expect(find.byType(AuthBanner), findsOneWidget);
  });

  testWidgets('a valid form creates the account', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.register);

    await fillForm(tester, name: '  Shahd Adel  ');
    await tapCreate(tester);

    final state = cubit.state;
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).user.displayName, 'Shahd Adel');
  });

  testWidgets('Log in and the back arrow open Login', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.register);
    await tapAndSettle(tester, find.text(AppStrings.registerLoginLink));
    expect(find.byType(LoginScreen), findsOneWidget);

    await pumpAuthScreen(tester, AppRoutes.register);
    await tapAndSettle(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Terms and Privacy Policy open their pages', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.register);

    await tapAndSettle(tester, find.text(AppStrings.registerTerms));
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(find.byType(LegalScreen), findsOneWidget);

    await tapAndSettle(tester, find.byType(BackButton));
    await tapAndSettle(tester, find.text(AppStrings.registerPrivacy));
    expect(find.text('Privacy Policy'), findsWidgets);
  });
}
