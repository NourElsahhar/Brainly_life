// GoogleSignInButton = the outlined "Continue with Google" button, with the
// coloured G drawn in code (no picture file needed).
//
// Usage:
//   GoogleSignInButton(
//     isLoading: isGoogleLoading,
//     onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
//   )

import 'dart:math' as math;

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canTap = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(AppRadius.button);

    return Semantics(
      button: true,
      enabled: canTap,
      label: AppStrings.authContinueWithGoogle,
      child: SizedBox(
        height: AppSizes.primaryButtonHeight,
        width: double.infinity,
        child: Material(
          color: p.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: canTap ? onPressed : null,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: p.border, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox.square(
                      dimension: AppSizes.iconStandard,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.primary,
                      ),
                    )
                  else ...[
                    const _GoogleLogo(size: 22),
                    const SizedBox(width: AppSpacing.s3),
                    Flexible(
                      child: Text(
                        AppStrings.authContinueWithGoogle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          color: canTap ? p.textPrimary : p.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Draws the G as 4 coloured arcs and the blue bar.
class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    Paint paintFor(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // 0 degrees = 3 o'clock, angles go clockwise.
    canvas.drawArc(rect, _rad(-140), _rad(95), false, paintFor(_red));
    canvas.drawArc(rect, _rad(140), _rad(80), false, paintFor(_yellow));
    canvas.drawArc(rect, _rad(45), _rad(95), false, paintFor(_green));
    canvas.drawArc(rect, _rad(0), _rad(45), false, paintFor(_blue));

    // The bar of the G, from the middle to the right edge.
    final center = size.height / 2;
    canvas.drawRect(
      Rect.fromLTRB(
        size.width / 2,
        center - stroke / 2,
        size.width,
        center + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
