// DeleteAccountDialog = "Delete your account?" with a box where the user
// must type DELETE. The red button only works after that, so nobody deletes
// the account by mistake.
//
// Usage:
//   final confirmed = await DeleteAccountDialog.show(context);
//   if (confirmed) cubit.deleteAccount();

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  /// true only when the user typed DELETE and pressed "Delete account".
  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    return confirmed ?? false;
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();

  bool get _confirmed =>
      _controller.text.trim() == AppStrings.deleteConfirmWord;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
              controller: _controller,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: AppStrings.deleteHint,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.s5),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.deleteCancel,
                    type: AppButtonType.text,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: AppStrings.deleteAction,
                    type: AppButtonType.destructive,
                    onPressed: _confirmed
                        ? () => Navigator.of(context).pop(true)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
