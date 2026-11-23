// ForgotPasswordScreen = send a "reset your password" email.
//
//   LIVE check of the email while typing
//   "Send reset link" -> AuthCubit.sendPasswordReset(...)
//   AuthPasswordResetSent -> green banner "Check your inbox. We sent a link
//                            to x@y.com". The user stays here and can go
//                            back with "Back to log in".
//   AuthError             -> red banner with failure.userMessage
//
// Security: Firebase sends the same answer for every valid email, so the
// screen does not tell anybody which emails have an account.
// The link in the email opens a Firebase page where the new password is
// typed; the app never sees it.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/presentation/widgets/auth_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  String? _errorBanner;

  /// The email the link was sent to (shown in the green banner).
  String? _sentTo;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final email = _emailController.text;
    setState(() {
      _errorBanner = null;
      _sentTo = null;
      _emailError = Validators.email(email);
    });
    if (_emailError != null) return;

    context.read<AuthCubit>().sendPasswordReset(email: email.trim());
  }

  void _backToLogin() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select(
      (AuthCubit cubit) => cubit.state is AuthLoading,
    );

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthError || current is AuthPasswordResetSent,
      listener: (context, state) {
        setState(() {
          if (state is AuthPasswordResetSent) {
            _sentTo = _emailController.text.trim();
          } else if (state is AuthError) {
            _errorBanner = state.failure.userMessage;
          }
        });
      },
      child: AuthLayout(
        onBack: _backToLogin,
        header: const _LockPicture(),
        centered: true,
        title: AppStrings.forgotTitle,
        subtitle: AppStrings.forgotSubtitle,
        children: [
          if (_errorBanner != null) ...[
            AuthBanner(message: _errorBanner!),
            const SizedBox(height: AppSpacing.s5),
          ],
          AppTextField(
            label: AppStrings.authEmailLabel,
            hint: AppStrings.authEmailHint,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.mail_outline_rounded,
            errorText: _emailError,
            enabled: !isLoading,
            onChanged: (value) => setState(() {
              _errorBanner = null;
              _emailError = Validators.email(value);
            }),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: AppStrings.forgotAction,
            isLoading: isLoading,
            onPressed: _submit,
          ),
          if (_sentTo != null) ...[
            const SizedBox(height: AppSpacing.s5),
            AuthBanner(
              message: AppStrings.forgotSent(_sentTo!),
              type: AuthBannerType.success,
            ),
          ],
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: AppStrings.forgotBackToLogin,
            type: AppButtonType.text,
            onPressed: isLoading ? null : _backToLogin,
          ),
        ],
      ),
    );
  }
}

/// The soft violet circle with a lock and a key.
class _LockPicture extends StatelessWidget {
  const _LockPicture();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: p.primarySoft,
          shape: BoxShape.circle,
          border: Border.all(color: p.primary.withValues(alpha: 0.25)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 72, color: p.primary),
            Positioned(
              right: 22,
              bottom: 30,
              child: Transform.rotate(
                angle: -0.6,
                child: Icon(Icons.key_rounded, size: 40, color: p.primary),
              ),
            ),
            Positioned(
              top: 26,
              left: 40,
              child: Icon(Icons.auto_awesome, size: 14, color: p.primary),
            ),
          ],
        ),
      ),
    );
  }
}
