// AppTextField = the one text input used everywhere in the app.
//
// Usage:
//   AppTextField(
//     label: 'Email',
//     hint: 'name@example.com',
//     controller: _emailController,
//     keyboardType: TextInputType.emailAddress,
//     prefixIcon: Icons.mail_outline,
//     errorText: state.emailError,      // shown UNDER the field
//     onChanged: cubit.emailChanged,
//   )
//
//   AppTextField(label: 'Password', obscureText: true, ...)   // adds a show/hide eye
//   AppTextField(label: 'Notes', maxLines: 4, maxLength: 1000)
//
// Rules:
//   - Validation errors go in errorText (under the field), never in a snackbar.
//   - errorText: null means "no error".
//   - maxLength stops the user from typing more (the counter is hidden).

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final Widget? eyeButton = widget.obscureText
        ? IconButton(
            tooltip: _hidden ? 'Show password' : 'Hide password',
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: p.iconMuted,
              size: AppSizes.iconStandard,
            ),
            onPressed: () => setState(() => _hidden = !_hidden),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.s2),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          // A hidden (password) field can only have one line.
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          cursorColor: p.primary,
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: context.text.bodyLarge?.copyWith(color: p.textTertiary),
            errorText: widget.errorText,
            errorMaxLines: 2,
            errorStyle: context.text.bodySmall?.copyWith(color: p.error),
            counterText: '',
            filled: true,
            fillColor: widget.enabled ? p.surfaceMuted : p.surfaceSubtle,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(
                    widget.prefixIcon,
                    color: p.iconMuted,
                    size: AppSizes.iconStandard,
                  ),
            suffixIcon: eyeButton,
            constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s3,
            ),
            border: border(p.border),
            enabledBorder: border(p.border),
            focusedBorder: border(p.primary, 1.5),
            errorBorder: border(p.error),
            focusedErrorBorder: border(p.error, 1.5),
            disabledBorder: border(p.borderSubtle),
          ),
        ),
      ],
    );
  }
}
