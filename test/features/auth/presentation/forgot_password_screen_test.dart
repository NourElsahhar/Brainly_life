// Widget tests for ForgotPasswordScreen: live email check, the green
// banner with the email, and the ways back to Login.
// Run with: fvm flutter test test/features/auth/presentation/forgot_password_screen_test.dart

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/login_screen.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_app.dart';

void main() {
  Future<void> tapSend(WidgetTester tester) =>
      tapAndSettle(tester, find.text(AppStrings.forgotAction));

  testWidgets('an empty email shows an error on send', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.forgotPassword);

    await tapSend(tester);

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.byType(AuthBanner), findsNothing);
  });

  testWidgets('the email is checked live', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.forgotPassword);

    await tester.enterText(field(0), 'shahd@');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('a valid email shows the green banner and stays here', (
    tester,
  ) async {
    await pumpAuthScreen(tester, AppRoutes.forgotPassword);

    await tester.enterText(field(0), '  shahd@student.edu ');
    await tapSend(tester);

    expect(
      find.text(AppStrings.forgotSent('shahd@student.edu')),
      findsOneWidget,
    );
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('Back to log in opens the Login screen', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.forgotPassword);

    await tapAndSettle(tester, find.text(AppStrings.forgotBackToLogin));

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('the back arrow opens the Login screen', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.forgotPassword);

    await tapAndSettle(tester, find.byIcon(Icons.arrow_back_rounded));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
