// Widget tests for LoginScreen: live validation, the error banner,
// a good sign in, Google, and the links.
// Run with: fvm flutter test test/features/auth/presentation/login_screen_test.dart

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:brainly_life/features/auth/presentation/screens/register_screen.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_app.dart';

void main() {
  Finder loginButton() => find.text(AppStrings.loginAction);

  testWidgets('empty fields show errors under the fields', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.login);

    await tapAndSettle(tester, loginButton());

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.byType(AuthBanner), findsNothing);
    expect(cubit.state, isNot(isA<Authenticated>()));
  });

  testWidgets('the email is checked live, while typing', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.login);

    await tester.enterText(field(0), 'shahd@');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(field(0), 'shahd@student.edu');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsNothing);
  });

  testWidgets('a wrong password shows the red banner', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.login);

    await tester.enterText(field(0), MockAuthRepository.demoEmail);
    await tester.enterText(field(1), 'wrong-password');
    await tapAndSettle(tester, loginButton());

    expect(cubit.state, isA<AuthError>());
    expect(find.byType(AuthBanner), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsOneWidget);

    // Typing again hides the banner.
    await tester.enterText(field(1), 'password12');
    await tester.pump();
    expect(find.byType(AuthBanner), findsNothing);
  });

  testWidgets('the demo account signs in', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.login);

    await tester.enterText(field(0), '  ${MockAuthRepository.demoEmail}  ');
    await tester.enterText(field(1), MockAuthRepository.demoPassword);
    await tapAndSettle(tester, loginButton());

    expect(cubit.state, isA<Authenticated>());
    expect(find.byType(AuthBanner), findsNothing);
  });

  testWidgets('Continue with Google signs in', (tester) async {
    final cubit = await pumpAuthScreen(tester, AppRoutes.login);

    await tapAndSettle(tester, find.text(AppStrings.authContinueWithGoogle));

    final state = cubit.state;
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).user.email, MockAuthRepository.googleEmail);
  });

  testWidgets('closing the Google picker shows no error', (tester) async {
    final cubit = await pumpAuthScreen(
      tester,
      AppRoutes.login,
      repository: MockAuthRepository(googleCancels: true),
    );

    await tapAndSettle(tester, find.text(AppStrings.authContinueWithGoogle));

    expect(cubit.state, isA<Unauthenticated>());
    expect(find.byType(AuthBanner), findsNothing);
  });

  testWidgets('Sign up opens Register', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.login);

    await tapAndSettle(tester, find.text(AppStrings.loginSignUpLink));

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('Forgot password? opens the reset screen', (tester) async {
    await pumpAuthScreen(tester, AppRoutes.login);

    await tapAndSettle(tester, find.text(AppStrings.loginForgotPassword));

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });
}
