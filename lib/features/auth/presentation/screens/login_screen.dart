// LoginScreen = sign in with email and password, or with Google.
//
// How it works:
//   1. LIVE validation: every time the user types, the field is checked
//      and the problem is shown UNDER the field right away.
//   2. "Log in" checks all the fields again. If one is wrong nothing is sent.
//   3. Then it calls AuthCubit.signIn(...).
//        AuthLoading   -> the pressed button shows a spinner
//        AuthError     -> the red banner at the top ("Incorrect email or
//                         password."). It goes away when the user types.
//        Authenticated -> nothing to do here: the router opens Home.
//
// Security: the password is only sent to Firebase Authentication (over
// HTTPS). The app never saves it. The error never says WHICH of the two
// was wrong, so nobody can find out which emails have an account.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:brainly_life/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _banner;

  /// true while the Google button (not "Log in") is the one loading.
  bool _googlePending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // On login we only ask for a password: the strength rules are for NEW
  // passwords (Register), not for accounts that already exist.
  String? _checkPassword(String value) =>
      Validators.nonEmpty(value, fieldName: AppStrings.authPasswordLabel);

  void _submit() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _banner = null;
      _emailError = Validators.email(email);
      _passwordError = _checkPassword(password);
    });
    if (_emailError != null || _passwordError != null) return;

    _googlePending = false;
    context.read<AuthCubit>().signIn(email: email.trim(), password: password);
  }

  void _google() {
    FocusScope.of(context).unfocus();
    setState(() {
      _banner = null;
      _googlePending = true;
    });
    context.read<AuthCubit>().signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (AuthCubit cubit) => cubit.state is AuthLoading,
    );

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() => _banner = state.failure.userMessage);
        }
        if (state is! AuthLoading && _googlePending) {
          setState(() => _googlePending = false);
        }
      },
      child: AuthLayout(
        header: const BaseetWordmark(),
        centered: true,
        title: AppStrings.loginTitle,
        subtitle: AppStrings.loginSubtitle,
        children: [
          if (_banner != null) ...[
            AuthBanner(message: _banner!),
            const SizedBox(height: AppSpacing.s5),
          ],
          AppTextField(
            label: AppStrings.authEmailLabel,
            hint: AppStrings.authEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.mail_outline_rounded,
            errorText: _emailError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _banner = null;
              _emailError = Validators.email(value);
            }),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(
            label: AppStrings.authPasswordLabel,
            hint: AppStrings.authPasswordHint,
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline_rounded,
            errorText: _passwordError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _banner = null;
              _passwordError = _checkPassword(value);
            }),
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: AppStrings.loginForgotPassword,
              type: AppButtonType.text,
              expanded: false,
              onPressed: isLoading
                  ? null
                  : () => context.go(AppRoutes.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: AppStrings.loginAction,
            isLoading: isLoading && !_googlePending,
            // Grey only while the OTHER button (Google) is loading.
            onPressed: isLoading && _googlePending ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.s5),
          const AuthDivider(label: AppStrings.authOr),
          const SizedBox(height: AppSpacing.s5),
          GoogleSignInButton(
            isLoading: isLoading && _googlePending,
            onPressed: isLoading && !_googlePending ? null : _google,
          ),
          const SizedBox(height: AppSpacing.s4),
          AuthSwitchLink(
            prompt: AppStrings.loginNoAccount,
            linkLabel: AppStrings.loginSignUpLink,
            onTap: isLoading ? null : () => context.go(AppRoutes.register),
          ),
        ],
      ),
    );
  }
}
