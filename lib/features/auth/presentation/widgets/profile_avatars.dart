// Profile avatars: the user picks one of these instead of uploading a
// photo (photo upload needs Firebase Storage, which needs the Blaze plan).
// Each avatar is a small cartoon person (4 girls, 4 boys) drawn in code by
// CartoonAvatarPainter, so there are no image files. Only the id ("girl2")
// is saved in users/{uid}.avatarId.
//
//   profileAvatars       -> the 8 avatars
//   CartoonAvatar        -> draws one avatar at any size
//   UserAvatar           -> draws a user's avatar:
//                           picked avatar > Google photo > first letter
//   showAvatarPicker     -> the sheet to pick one
//
// Usage:
//   UserAvatar(user: user, size: 96)
//
//   final picked = await showAvatarPicker(context, selected: user.avatarId);
//   // null -> closed, '' -> "Use my initial", else the avatar id
//
// Adding an avatar: add a line to profileAvatars with a NEW id. Never
// change or remove an id that users may already have saved. (An old id
// that is not in the list any more just shows the first letter.)

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';

/// How the hair (or the hijab) is drawn.
enum CartoonHair { short, curly, spiky, side, long, hijab, bun, puffs }

class ProfileAvatarOption {
  const ProfileAvatarOption(
    this.id,
    this.label, {
    required this.skin,
    required this.hair,
    required this.style,
    required this.shirt,
    required this.background,
    this.glasses = false,
  });

  final String id;

  /// Read by screen readers ("Girl with a hijab avatar").
  final String label;
  final Color skin;

  /// The hair colour, or the hijab colour for [CartoonHair.hijab].
  final Color hair;
  final CartoonHair style;
  final Color shirt;
  final Color background;
  final bool glasses;
}

// Skin tones.
const _light = Color(0xFFF6D2B8);
const _medium = Color(0xFFE0A77D);
const _tan = Color(0xFFC98A5E);
const _dark = Color(0xFF8D5A3B);

const List<ProfileAvatarOption> profileAvatars = [
  ProfileAvatarOption(
    'boy1',
    'Boy with short hair',
    skin: _light,
    hair: Color(0xFF3B2A20),
    style: CartoonHair.short,
    shirt: Color(0xFF2563EB),
    background: Color(0xFFDBEAFE),
  ),
  ProfileAvatarOption(
    'boy2',
    'Boy with curly hair',
    skin: _dark,
    hair: Color(0xFF1C1917),
    style: CartoonHair.curly,
    shirt: Color(0xFFEA580C),
    background: Color(0xFFFFEDD5),
  ),
  ProfileAvatarOption(
    'boy3',
    'Boy with spiky hair',
    skin: _medium,
    hair: Color(0xFF6B3F1F),
    style: CartoonHair.spiky,
    shirt: Color(0xFF16A34A),
    background: Color(0xFFDCFCE7),
  ),
  ProfileAvatarOption(
    'boy4',
    'Boy with glasses',
    skin: _tan,
    hair: Color(0xFF111827),
    style: CartoonHair.side,
    shirt: Color(0xFF7C3AED),
    background: Color(0xFFEDE9FE),
    glasses: true,
  ),
  ProfileAvatarOption(
    'girl1',
    'Girl with long hair',
    skin: _light,
    hair: Color(0xFF7C4A24),
    style: CartoonHair.long,
    shirt: Color(0xFFDB2777),
    background: Color(0xFFFCE7F3),
  ),
  ProfileAvatarOption(
    'girl2',
    'Girl with a hijab',
    skin: _medium,
    hair: Color(0xFF0F766E),
    style: CartoonHair.hijab,
    shirt: Color(0xFF115E59),
    background: Color(0xFFCCFBF1),
  ),
  ProfileAvatarOption(
    'girl3',
    'Girl with a bun and glasses',
    skin: _tan,
    hair: Color(0xFF1C1917),
    style: CartoonHair.bun,
    shirt: Color(0xFFCA8A04),
    background: Color(0xFFFEF9C3),
    glasses: true,
  ),
  ProfileAvatarOption(
    'girl4',
    'Girl with two puffs',
    skin: _dark,
    hair: Color(0xFF1C1917),
    style: CartoonHair.puffs,
    shirt: Color(0xFF9333EA),
    background: Color(0xFFF3E8FF),
  ),
];

/// One avatar as a circle of [size].
class CartoonAvatar extends StatelessWidget {
  const CartoonAvatar({super.key, required this.avatar, this.size = 96});

  final ProfileAvatarOption avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${avatar.label} avatar',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: CartoonAvatarPainter(avatar)),
      ),
    );
  }
}

/// Draws a cartoon person on a 100 x 100 grid, scaled to the canvas.
class CartoonAvatarPainter extends CustomPainter {
  const CartoonAvatarPainter(this.avatar);

  final ProfileAvatarOption avatar;

  static const _ink = Color(0xFF1F2937);

  /// A slightly darker skin for the neck and ears.
  static Color _shade(Color skin) =>
      Color.lerp(skin, const Color(0xFF000000), 0.12)!;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final a = avatar;
    final style = a.style;
    final hijab = style == CartoonHair.hijab;
    Paint fill(Color color) => Paint()
      ..color = color
      ..isAntiAlias = true;
    final hair = fill(a.hair);

    // Background, and everything else stays inside the circle.
    const circle = Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawOval(circle, fill(a.background));
    canvas.clipPath(Path()..addOval(circle));

    // Hair behind the head.
    switch (style) {
      case CartoonHair.long:
        canvas.drawPath(
          Path()
            ..moveTo(26, 44)
            ..quadraticBezierTo(26, 20, 50, 20)
            ..quadraticBezierTo(74, 20, 74, 44)
            ..lineTo(76, 82)
            ..quadraticBezierTo(50, 90, 24, 82)
            ..close(),
          hair,
        );
      case CartoonHair.puffs:
        canvas.drawCircle(const Offset(25, 34), 11, hair);
        canvas.drawCircle(const Offset(75, 34), 11, hair);
      case CartoonHair.bun:
        canvas.drawCircle(const Offset(50, 18), 10, hair);
      case CartoonHair.hijab:
        canvas.drawPath(
          Path()
            ..moveTo(22, 50)
            ..quadraticBezierTo(22, 18, 50, 18)
            ..quadraticBezierTo(78, 18, 78, 50)
            ..lineTo(80, 84)
            ..quadraticBezierTo(50, 96, 20, 84)
            ..close(),
          hair,
        );
      case CartoonHair.short:
      case CartoonHair.curly:
      case CartoonHair.spiky:
      case CartoonHair.side:
        break;
    }

    // Body (shirt), neck and collar.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 104), width: 76, height: 56),
      fill(a.shirt),
    );
    if (!hijab) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(43, 60, 14, 18),
          const Radius.circular(4),
        ),
        fill(_shade(a.skin)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(40, 78)
          ..quadraticBezierTo(50, 86, 60, 78),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.5),
      );
      // Ears.
      canvas.drawCircle(const Offset(30, 48), 4.5, fill(_shade(a.skin)));
      canvas.drawCircle(const Offset(70, 48), 4.5, fill(_shade(a.skin)));
    }

    // Head.
    canvas.drawOval(
      hijab
          ? Rect.fromCenter(center: const Offset(50, 49), width: 34, height: 38)
          : Rect.fromCenter(
              center: const Offset(50, 46),
              width: 40,
              height: 44,
            ),
      fill(a.skin),
    );

    // Hair in front of the head.
    final cap = Path()
      ..moveTo(29, 46)
      ..quadraticBezierTo(27, 22, 50, 22)
      ..quadraticBezierTo(73, 22, 71, 46)
      ..quadraticBezierTo(68, 34, 56, 31)
      ..quadraticBezierTo(44, 36, 31, 38)
      ..quadraticBezierTo(29, 41, 29, 46)
      ..close();
    switch (style) {
      case CartoonHair.short:
      case CartoonHair.bun:
      case CartoonHair.puffs:
        canvas.drawPath(cap, hair);
      case CartoonHair.side:
        canvas.drawPath(cap, hair);
        canvas.drawPath(
          Path()
            ..moveTo(31, 38)
            ..quadraticBezierTo(40, 26, 60, 28)
            ..quadraticBezierTo(48, 30, 40, 40)
            ..close(),
          hair,
        );
      case CartoonHair.long:
        canvas.drawPath(cap, hair);
        canvas.drawPath(
          Path()
            ..moveTo(29, 46)
            ..quadraticBezierTo(28, 30, 40, 26)
            ..quadraticBezierTo(34, 36, 33, 50)
            ..close(),
          hair,
        );
        canvas.drawPath(
          Path()
            ..moveTo(71, 46)
            ..quadraticBezierTo(72, 30, 60, 26)
            ..quadraticBezierTo(66, 36, 67, 50)
            ..close(),
          hair,
        );
      case CartoonHair.spiky:
        canvas.drawPath(
          Path()
            ..moveTo(29, 46)
            ..quadraticBezierTo(27, 30, 33, 26)
            ..lineTo(36, 16)
            ..lineTo(42, 24)
            ..lineTo(48, 13)
            ..lineTo(54, 23)
            ..lineTo(61, 14)
            ..lineTo(64, 25)
            ..lineTo(70, 22)
            ..quadraticBezierTo(73, 32, 71, 46)
            ..quadraticBezierTo(66, 34, 50, 33)
            ..quadraticBezierTo(36, 34, 29, 46)
            ..close(),
          hair,
        );
      case CartoonHair.curly:
        const curls = [
          (33.0, 36.0, 7.0),
          (38.0, 28.0, 7.0),
          (46.0, 24.0, 7.0),
          (54.0, 24.0, 7.0),
          (62.0, 28.0, 7.0),
          (67.0, 36.0, 7.0),
          (30.0, 43.0, 5.0),
          (70.0, 43.0, 5.0),
        ];
        for (final (x, y, r) in curls) {
          canvas.drawCircle(Offset(x, y), r, hair);
        }
      case CartoonHair.hijab:
        // A soft fold over the forehead and the wrap under the chin.
        canvas.drawPath(
          Path()
            ..moveTo(33, 40)
            ..quadraticBezierTo(36, 28, 50, 28)
            ..quadraticBezierTo(64, 28, 67, 40)
            ..quadraticBezierTo(60, 33, 50, 33)
            ..quadraticBezierTo(40, 33, 33, 40)
            ..close(),
          fill(Colors.black.withValues(alpha: 0.12)),
        );
        canvas.drawPath(
          Path()
            ..moveTo(30, 66)
            ..quadraticBezierTo(50, 80, 70, 66)
            ..lineTo(72, 74)
            ..quadraticBezierTo(50, 88, 28, 74)
            ..close(),
          hair,
        );
    }

    // Face: eyes, shine, brows, smile, cheeks.
    final ink = fill(_ink);
    canvas.drawCircle(const Offset(42.5, 48), 2.6, ink);
    canvas.drawCircle(const Offset(57.5, 48), 2.6, ink);
    canvas.drawCircle(const Offset(43.3, 47.2), 0.8, fill(Colors.white));
    canvas.drawCircle(const Offset(58.3, 47.2), 0.8, fill(Colors.white));
    canvas.drawPath(
      Path()
        ..moveTo(38.5, 42.5)
        ..quadraticBezierTo(42.5, 40.5, 46.5, 42.5)
        ..moveTo(53.5, 42.5)
        ..quadraticBezierTo(57.5, 40.5, 61.5, 42.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = _ink.withValues(alpha: 0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(44, 56)
        ..quadraticBezierTo(50, 61.5, 56, 56),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
    final cheek = fill(const Color(0xFFF472B6).withValues(alpha: 0.35));
    canvas.drawCircle(const Offset(37, 54), 3, cheek);
    canvas.drawCircle(const Offset(63, 54), 3, cheek);

    if (a.glasses) {
      final frame = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _ink;
      canvas.drawCircle(const Offset(42.5, 48), 5.5, frame);
      canvas.drawCircle(const Offset(57.5, 48), 5.5, frame);
      canvas.drawLine(const Offset(48, 48), const Offset(52, 48), frame);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CartoonAvatarPainter oldDelegate) =>
      oldDelegate.avatar != avatar;
}

/// The avatar with this id, or null (no id, or an id that no longer exists).
ProfileAvatarOption? profileAvatarById(String? id) {
  if (id == null) return null;
  for (final avatar in profileAvatars) {
    if (avatar.id == id) return avatar;
  }
  return null;
}

/// A round avatar: the picked avatar, else the Google photo, else the
/// first letter of the name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.size = 96});

  final UserProfile user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final avatar = profileAvatarById(user.avatarId);

    if (avatar != null) {
      return CartoonAvatar(
        key: ValueKey('user-avatar-${avatar.id}'),
        avatar: avatar,
        size: size,
      );
    }

    final source = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.email;
    final letter = source.isEmpty ? '?' : source[0].toUpperCase();
    final initial = Center(
      child: Text(
        letter,
        style: context.text.displayLarge?.copyWith(
          color: p.onPrimary,
          fontSize: size * 0.45,
        ),
      ),
    );
    final photoUrl = user.photoUrl;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: p.primaryCTA, shape: BoxShape.circle),
      child: photoUrl == null
          ? initial
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => initial,
            ),
    );
  }
}

/// Opens the avatar sheet. Returns null when closed, '' for "Use my
/// initial" (remove the avatar), or the picked avatar id.
Future<String?> showAvatarPicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _AvatarPicker(selected: selected),
  );
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          0,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.profileChooseAvatar,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.s4),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.s3,
              crossAxisSpacing: AppSpacing.s3,
              children: [
                for (final avatar in profileAvatars)
                  _AvatarTile(
                    avatar: avatar,
                    isSelected: avatar.id == selected,
                    onTap: () => Navigator.of(context).pop(avatar.id),
                  ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.s3),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(''),
                icon: Icon(Icons.person_outline_rounded, color: p.primary),
                label: Text(
                  AppStrings.profileUseInitial,
                  style: TextStyle(color: p.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatar,
    required this.isSelected,
    required this.onTap,
  });

  final ProfileAvatarOption avatar;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${avatar.label} avatar',
      child: InkWell(
        key: ValueKey('avatar-option-${avatar.id}'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? p.primary : Colors.transparent,
              width: 3,
            ),
          ),
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) => CartoonAvatar(
                avatar: avatar,
                size: constraints.biggest.shortestSide,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
