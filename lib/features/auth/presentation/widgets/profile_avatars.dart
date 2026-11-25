// Profile avatars: the user picks one of these instead of uploading a
// photo (photo upload needs Firebase Storage, which needs the Blaze plan).
// Each avatar is an icon on a coloured circle, so there are no image files.
// Only the id ("rocket") is saved in users/{uid}.avatarId.
//
//   profileAvatars       -> the 12 avatars
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
// change or remove an id that users may already have saved.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:flutter/material.dart';

class ProfileAvatarOption {
  const ProfileAvatarOption(this.id, this.label, this.icon, this.color);

  final String id;

  /// Read by screen readers ("Rocket avatar").
  final String label;
  final IconData icon;
  final Color color;
}

const List<ProfileAvatarOption> profileAvatars = [
  ProfileAvatarOption(
    'rocket',
    'Rocket',
    Icons.rocket_launch_rounded,
    Color(0xFF6C5CE7),
  ),
  ProfileAvatarOption(
    'book',
    'Book',
    Icons.auto_stories_rounded,
    Color(0xFF14B8A6),
  ),
  ProfileAvatarOption(
    'brain',
    'Brain',
    Icons.psychology_rounded,
    Color(0xFFEC4899),
  ),
  ProfileAvatarOption(
    'idea',
    'Idea',
    Icons.lightbulb_rounded,
    Color(0xFFF59E0B),
  ),
  ProfileAvatarOption('star', 'Star', Icons.star_rounded, Color(0xFF3B82F6)),
  ProfileAvatarOption('bolt', 'Bolt', Icons.bolt_rounded, Color(0xFF9333EA)),
  ProfileAvatarOption(
    'coffee',
    'Coffee',
    Icons.local_cafe_rounded,
    Color(0xFFB45309),
  ),
  ProfileAvatarOption(
    'music',
    'Music',
    Icons.music_note_rounded,
    Color(0xFFEF4444),
  ),
  ProfileAvatarOption(
    'palette',
    'Palette',
    Icons.palette_rounded,
    Color(0xFF0891B2),
  ),
  ProfileAvatarOption(
    'plant',
    'Plant',
    Icons.local_florist_rounded,
    Color(0xFF16A34A),
  ),
  ProfileAvatarOption('pet', 'Pet', Icons.pets_rounded, Color(0xFF4F46E5)),
  ProfileAvatarOption(
    'game',
    'Game',
    Icons.sports_esports_rounded,
    Color(0xFF475569),
  ),
];

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
      return Container(
        key: ValueKey('user-avatar-${avatar.id}'),
        width: size,
        height: size,
        decoration: BoxDecoration(color: avatar.color, shape: BoxShape.circle),
        child: Icon(
          avatar.icon,
          size: size * 0.5,
          color: Colors.white,
          semanticLabel: '${avatar.label} avatar',
        ),
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
          child: Container(
            decoration: BoxDecoration(
              color: avatar.color,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Icon(avatar.icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}
