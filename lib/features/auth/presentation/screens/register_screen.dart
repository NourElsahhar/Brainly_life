// RegisterScreen = create a new account (or continue with Google).
//
// Field rules (checked LIVE, while the user types):
//   Full name -> required, at most 60 characters
//   Email     -> a valid email
//   Password  -> at least 8 characters AND not weak (see PasswordStrength)
//                The 4 bars under it show Weak / Medium / Strong.
//   Confirm   -> the same as the password (checked again when the
//                password changes)
//   Terms     -> the box must be ticked
//
// Then AuthCubit.register(...). The repository creates the Firebase
// account AND users/{uid} with the default settings. The password goes
// only to Firebase Authentication, which keeps a salted hash of it
// (never the password itself). It is never written to Firestore.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/logic/password_strength.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:brainly_life/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:brainly_life/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  /// The longest display name allowed (same limit as the Firestore rules).
  static const int maxNameLength = 60;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;
  String? _banner;
  bool _acceptedTerms = false;
  bool _googlePending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _checkName(String value) => Validators.lengthBetween(
    value,
    min: 1,
    max: RegisterScreen.maxNameLength,
    fieldName: 'Name',
  );

  String? _checkPassword(String value) =>
      PasswordStrength.validateNew(value, tooWeak: AppStrings.passwordTooWeak);

  String? _checkConfirm(String value) =>
      Validators.confirmPassword(value, _passwordController.text);

  void _submit() {
    FocusScope.of(context).unfocus();

    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _banner = null;
      _nameError = _checkName(name);
      _emailError = Validators.email(email);
      _passwordError = _checkPassword(password);
      _confirmError = _checkConfirm(_confirmController.text);
      _termsError = _acceptedTerms ? null : AppStrings.registerTermsRequired;
    });
    final hasError = [
      _nameError,
      _emailError,
      _passwordError,
      _confirmError,
      _termsError,
    ].any((error) => error != null);
    if (hasError) return;

    _googlePending = false;
    context.read<AuthCubit>().register(
      displayName: name.trim(),
      email: email.trim(),
      password: password,
    );
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
        onBack: () => context.go(AppRoutes.login),
        title: AppStrings.registerTitle,
        subtitle: AppStrings.registerSubtitle,
        children: [
          if (_banner != null) ...[
            AuthBanner(message: _banner!),
            const SizedBox(height: AppSpacing.s5),
          ],
          AppTextField(
            label: AppStrings.authNameLabel,
            hint: AppStrings.authNameHint,
            controller: _nameController,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline_rounded,
            maxLength: RegisterScreen.maxNameLength,
            errorText: _nameError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _banner = null;
              _nameError = _checkName(value);
            }),
          ),
          const SizedBox(height: AppSpacing.s4),
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
            hint: AppStrings.authNewPasswordHint,
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline_rounded,
            errorText: _passwordError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _banner = null;
              _passwordError = _checkPassword(value);
              // The confirmation must follow the new password.
              if (_confirmController.text.isNotEmpty) {
                _confirmError = _checkConfirm(_confirmController.text);
              }
            }),
          ),
          const SizedBox(height: AppSpacing.s3),
          PasswordStrengthMeter(password: _passwordController.text),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(
            label: AppStrings.authConfirmPasswordLabel,
            hint: AppStrings.authConfirmPasswordHint,
            controller: _confirmController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline_rounded,
            errorText: _confirmError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _banner = null;
              _confirmError = _checkConfirm(value);
            }),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s3),
          _TermsCheckbox(
            value: _acceptedTerms,
            errorText: _termsError,
            onChanged: isLoading
                ? null
                : (value) => setState(() {
                    _acceptedTerms = value;
                    _termsError = null;
                  }),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: AppStrings.registerAction,
            isLoading: isLoading && !_googlePending,
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
            prompt: AppStrings.registerHaveAccount,
            linkLabel: AppStrings.registerLoginLink,
            onTap: isLoading ? null : () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}

/// "☐ I agree to the Terms and Privacy Policy", with its error under it.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? errorText;

  /// A tappable word that opens the Terms or the Privacy page on top.
  InlineSpan _link(
    BuildContext context,
    String text,
    TextStyle style,
    String route,
  ) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Text(text, style: context.text.bodyMedium?.merge(style)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final linkStyle = TextStyle(color: p.primary, fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (checked) => onChanged!(checked ?? false),
                activeColor: p.primary,
                side: BorderSide(
                  color: errorText != null ? p.error : p.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: context.text.bodyMedium?.copyWith(
                      color: p.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: AppStrings.registerAgreePrefix),
                      _link(
                        context,
                        AppStrings.registerTerms,
                        linkStyle,
                        AppRoutes.terms,
                      ),
                      const TextSpan(text: AppStrings.registerAgreeMiddle),
                      _link(
                        context,
                        AppStrings.registerPrivacy,
                        linkStyle,
                        AppRoutes.privacy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: AppSpacing.s3),
            child: Text(
              errorText!,
              style: context.text.bodySmall?.copyWith(color: p.error),
            ),
          ),
      ],
    );
  }
}
