// ProfileScreen = the Profile tab.
//
//   - the photo (or the first letter of the name), the name, the email
//   - "Edit profile" -> a sheet to change the name
//   - 3 cards: day streak, hours studied, tasks done (ProfileStatsProvider)
//   - a menu: Weekly analytics, Weekly AI report, Study preferences, Settings
//
// The user comes from AuthCubit (context.select), so a new name or a new
// setting shows here at once.
// [repository] and [statsProvider] can be given in tests; the app takes
// them from get_it.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/profile_cubit.dart';
import 'package:brainly_life/features/auth/presentation/widgets/profile_avatars.dart';
import 'package:brainly_life/features/auth/presentation/widgets/settings_widgets.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.repository, this.statsProvider});

  final AuthRepository? repository;
  final ProfileStatsProvider? statsProvider;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit cubit) => cubit.currentUser);

    return Scaffold(
      appBar: BaseetAppBar.inner(
        title: AppStrings.profileTitle,
        actions: [
          AppBarIconButton(
            icon: Icons.settings_outlined,
            tooltip: AppStrings.profileSettings,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      // Nobody signed in (only for a moment, while signing out).
      body: user == null
          ? const SizedBox.shrink()
          : BlocProvider(
              create: (context) {
                final auth = context.read<AuthCubit>();
                return ProfileCubit(
                  repository: repository ?? getIt<AuthRepository>(),
                  statsProvider: statsProvider ?? getIt<ProfileStatsProvider>(),
                  currentUser: () => auth.currentUser,
                  onProfileUpdated: auth.profileUpdated,
                )..loadStats();
              },
              child: _ProfileBody(user: user),
            ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          current.failureId != previous.failureId && current.failure != null,
      listener: (context, state) =>
          AppSnackBar.error(context, state.failure!.userMessage),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.s4,
          AppSpacing.screenMargin,
          AppSpacing.s8,
        ),
        children: [
          _Header(user: user),
          const SizedBox(height: AppSpacing.s6),
          const _StatsRow(),
          const SizedBox(height: AppSpacing.s6),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SettingsRow(
                  icon: Icons.bar_chart_rounded,
                  label: AppStrings.profileWeeklyAnalytics,
                  onTap: () =>
                      showComingSoon(context, AppStrings.profileComingSoon),
                ),
                const _MenuDivider(),
                SettingsRow(
                  icon: Icons.article_outlined,
                  iconColor: context.palette.teal,
                  label: AppStrings.profileWeeklyReport,
                  onTap: () =>
                      showComingSoon(context, AppStrings.profileComingSoon),
                ),
                const _MenuDivider(),
                SettingsRow(
                  icon: Icons.tune_rounded,
                  iconColor: context.palette.warning,
                  label: AppStrings.profileStudyPreferences,
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const _MenuDivider(),
                SettingsRow(
                  icon: Icons.settings_outlined,
                  label: AppStrings.profileSettings,
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: AppSpacing.s4,
    endIndent: AppSpacing.s4,
    color: context.palette.borderSubtle,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = user.displayName.isEmpty ? user.email : user.displayName;

    return Row(
      children: [
        _Avatar(user: user, onEdit: () => _pickAvatar(context)),
        const SizedBox(width: AppSpacing.s5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: AppStrings.profileEdit,
                type: AppButtonType.secondary,
                expanded: false,
                onPressed: () => _editName(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final picked = await showAvatarPicker(context, selected: user.avatarId);
    if (picked == null) return; // closed

    final saved = await cubit.updateAvatar(picked.isEmpty ? null : picked);
    if (saved && context.mounted) {
      AppSnackBar.success(context, AppStrings.profileAvatarSaved);
    }
  }

  Future<void> _editName(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _EditNameSheet(initialName: user.displayName),
      ),
    );
    if (saved == true && context.mounted) {
      AppSnackBar.success(context, AppStrings.profileNameSaved);
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.onEdit});

  final UserProfile user;
  final VoidCallback onEdit;

  static const double size = 96;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox.square(
      dimension: size + 8,
      child: Stack(
        children: [
          UserAvatar(user: user, size: size),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: p.primary,
              shape: CircleBorder(side: BorderSide(color: p.surface, width: 3)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: p.onPrimary,
                    semanticLabel: AppStrings.profileChangeAvatar,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final stats = context.select((ProfileCubit cubit) => cubit.state.stats);
    String show(String Function(ProfileStats s) value) =>
        stats == null ? '–' : value(stats);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department_rounded,
              color: p.primary,
              value: show((s) => '${s.streakDays}'),
              label: AppStrings.profileStreak,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: _StatCard(
              icon: Icons.schedule_rounded,
              color: p.teal,
              value: show((s) => '${s.studiedMinutes ~/ 60} h'),
              label: AppStrings.profileStudied,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              color: p.warning,
              value: show((s) => '${s.tasksDone}'),
              label: AppStrings.profileTasksDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: AppSpacing.s2),
          Text(
            value,
            style: context.text.headlineSmall?.copyWith(color: color),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initialName});

  final String initialName;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _check(String value) => Validators.lengthBetween(
    value,
    min: 1,
    max: ProfileCubit.maxNameLength,
    fieldName: 'Name',
  );

  Future<void> _save() async {
    final error = _check(_controller.text);
    setState(() => _error = error);
    if (error != null) return;

    final saved = await context.read<ProfileCubit>().updateName(
      _controller.text,
    );
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.select(
      (ProfileCubit cubit) => cubit.state.isSavingName,
    );

    return Padding(
      // Moves the sheet above the keyboard.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5,
        0,
        AppSpacing.s5,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.profileEditTitle, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.s4),
          AppTextField(
            label: AppStrings.authNameLabel,
            hint: AppStrings.authNameHint,
            controller: _controller,
            prefixIcon: Icons.person_outline_rounded,
            maxLength: ProfileCubit.maxNameLength,
            textInputAction: TextInputAction.done,
            errorText: _error,
            enabled: !isSaving,
            onChanged: (value) => setState(() => _error = _check(value)),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(
            label: AppStrings.profileSave,
            isLoading: isSaving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
