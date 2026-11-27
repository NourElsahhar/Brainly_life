// DeleteAccountDialog = "Delete your account?" with a box where the user
// must type DELETE. The red button only works after that, so nobody deletes
// the account by mistake.
//
// Firebase only deletes an account right after a sign in, so the dialog
// also asks for the password. Google accounts leave it empty: Google asks
// them to confirm instead.
//
// Usage:
//   final password = await DeleteAccountDialog.show(context);
//   // null -> cancelled, '' -> confirmed without a password (Google)
//   if (password != null) cubit.deleteAccount(password: password);

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static const Key confirmFieldKey = ValueKey('delete-confirm-field');
  static const Key passwordFieldKey = ValueKey('delete-password-field');

  /// null when cancelled, else the typed password ('' when none).
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirm = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;

  bool get _confirmed => _confirm.text.trim() == AppStrings.deleteConfirmWord;

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: p.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: p.error,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              AppStrings.deleteTitle,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              AppStrings.deleteMessage,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: AppSpacing.s5),
            TextField(
              key: DeleteAccountDialog.confirmFieldKey,
              controller: _confirm,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: AppStrings.deleteHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              key: DeleteAccountDialog.passwordFieldKey,
              controller: _password,
              obscureText: _hidePassword,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: AppStrings.deletePasswordHint,
                helperText: AppStrings.deletePasswordHelper,
                helperMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _hidePassword
                      ? AppStrings.deleteShowPassword
                      : AppStrings.deleteHidePassword,
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            // One button per line, so the labels are never cut.
            AppButton(
              label: AppStrings.deleteAction,
              type: AppButtonType.destructive,
              onPressed: _confirmed
                  ? () => Navigator.of(context).pop(_password.text)
                  : null,
            ),
            const SizedBox(height: AppSpacing.s2),
            AppButton(
              label: AppStrings.deleteCancel,
              type: AppButtonType.text,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
