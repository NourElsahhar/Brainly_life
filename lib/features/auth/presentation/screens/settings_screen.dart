// SettingsScreen = the user's settings, in 4 sections:
//
//   Study preferences -> daily hours, preferred time, week start, time zone
//                        (each row opens a sheet to pick a value)
//   Appearance        -> Light / Dark / System (the whole app follows)
//   AI                -> "Use AI features" switch
//   Account           -> Sign out, Delete account (typed DELETE + password,
//                        then the Sign up screen)
//
// studyOnly: true shows only Study preferences (AppRoutes.studyPreferences).
//
// Every change is saved at once (see SettingsCubit). Errors show in a
// snackbar and the old value comes back.
// [repository] can be given in tests; the app takes it from get_it.

import 'package:brainly_life/core/constants/app_strings.dart';
import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/logic/settings_cubit.dart';
import 'package:brainly_life/features/auth/presentation/widgets/delete_account_dialog.dart';
import 'package:brainly_life/features/auth/presentation/widgets/settings_widgets.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.repository, this.studyOnly = false});

  final AuthRepository? repository;

  /// Only the "Study preferences" section (Profile -> Study preferences).
  final bool studyOnly;

  @override
  Widget build(BuildContext context) {
    final hasUser = context.select(
      (AuthCubit cubit) => cubit.currentUser != null,
    );

    return Scaffold(
      appBar: BaseetAppBar.inner(
        title: studyOnly
            ? AppStrings.settingsStudySection
            : AppStrings.settingsTitle,
      ),
      body: !hasUser
          ? const SizedBox.shrink()
          : BlocProvider(
              create: (context) {
                final auth = context.read<AuthCubit>();
                return SettingsCubit(
                  repository: repository ?? getIt<AuthRepository>(),
                  currentUser: () => auth.currentUser,
                  onProfileUpdated: auth.profileUpdated,
                );
              },
              child: _SettingsBody(studyOnly: studyOnly),
            ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.studyOnly});

  final bool studyOnly;

  // The values offered in the sheets.
  static const List<double> hourOptions = [1, 2, 3, 4, 5, 6, 7, 8, 10, 12];
  static const List<int> weekStartOptions = [
    DateTime.saturday,
    DateTime.sunday,
    DateTime.monday,
  ];
  static const List<String> timezoneOptions = [
    'Africa/Cairo',
    'Asia/Riyadh',
    'Asia/Dubai',
    'Asia/Amman',
    'Asia/Kuwait',
    'Europe/London',
    'Europe/Berlin',
    'America/New_York',
    'UTC',
  ];

  static String hoursLabel(double hours) => hours == hours.roundToDouble()
      ? '${hours.toInt()} h'
      : '${hours.toStringAsFixed(1)} h';

  static String studyTimeLabel(StudyTime time) => switch (time) {
    StudyTime.morning => AppStrings.studyTimeMorning,
    StudyTime.afternoon => AppStrings.studyTimeAfternoon,
    StudyTime.evening => AppStrings.studyTimeEvening,
    StudyTime.night => AppStrings.studyTimeNight,
  };

  static String dayLabel(int day) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][(day - 1) % 7]; // always 0..6

  /// After "Delete account": wait until the user is signed out, then show
  /// Sign up (the router would otherwise show Login).
  static Future<void> _openRegister(AuthCubit auth, GoRouter router) async {
    if (auth.state is! Unauthenticated) {
      await auth.stream
          .firstWhere((state) => state is Unauthenticated)
          .timeout(const Duration(seconds: 5), onTimeout: () => auth.state);
    }
    router.go(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cubit = context.read<SettingsCubit>();
    final state = context.watch<SettingsCubit>().state;
    final s = state.settings;
    final busy = state.isDeleting;

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          current.failureId != previous.failureId && current.failure != null,
      listener: (context, state) =>
          AppSnackBar.error(context, state.failure!.userMessage),
      child: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.s2,
            AppSpacing.screenMargin,
            AppSpacing.s8,
          ),
          children: [
            if (busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.s4),
            ],
            SettingsSection(
              title: AppStrings.settingsStudySection,
              children: [
                SettingsRow(
                  label: AppStrings.settingsDailyHours,
                  value: hoursLabel(s.dailyStudyHours),
                  onTap: () async {
                    final options = {...hourOptions, s.dailyStudyHours}.toList()
                      ..sort();
                    final picked = await showOptionSheet<double>(
                      context,
                      title: AppStrings.settingsDailyHours,
                      selected: s.dailyStudyHours,
                      options: [for (final h in options) (h, hoursLabel(h))],
                    );
                    if (picked != null) cubit.setDailyStudyHours(picked);
                  },
                ),
                SettingsRow(
                  label: AppStrings.settingsStudyTime,
                  value: studyTimeLabel(s.preferredStudyTime),
                  onTap: () async {
                    final picked = await showOptionSheet<StudyTime>(
                      context,
                      title: AppStrings.settingsStudyTime,
                      selected: s.preferredStudyTime,
                      options: [
                        for (final t in StudyTime.values)
                          (t, studyTimeLabel(t)),
                      ],
                    );
                    if (picked != null) cubit.setPreferredStudyTime(picked);
                  },
                ),
                SettingsRow(
                  label: AppStrings.settingsWeekStart,
                  value: dayLabel(s.weekStartDay),
                  onTap: () async {
                    final options = {...weekStartOptions, s.weekStartDay};
                    final picked = await showOptionSheet<int>(
                      context,
                      title: AppStrings.settingsWeekStart,
                      selected: s.weekStartDay,
                      options: [for (final d in options) (d, dayLabel(d))],
                    );
                    if (picked != null) cubit.setWeekStartDay(picked);
                  },
                ),
                SettingsRow(
                  label: AppStrings.settingsTimezone,
                  value: s.timezone,
                  onTap: () async {
                    final options = {s.timezone, ...timezoneOptions};
                    final picked = await showOptionSheet<String>(
                      context,
                      title: AppStrings.settingsTimezone,
                      selected: s.timezone,
                      options: [for (final tz in options) (tz, tz)],
                    );
                    if (picked != null) cubit.setTimezone(picked);
                  },
                ),
              ],
            ),
            if (!studyOnly) ...[
              const SizedBox(height: AppSpacing.s6),
              SettingsSection(
                title: AppStrings.settingsAppearanceSection,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.settingsTheme,
                          style: context.text.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        SegmentedButton<AppThemeMode>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: AppThemeMode.light,
                              label: Text(AppStrings.settingsThemeLight),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.dark,
                              label: Text(AppStrings.settingsThemeDark),
                            ),
                            ButtonSegment(
                              value: AppThemeMode.system,
                              label: Text(AppStrings.settingsThemeSystem),
                            ),
                          ],
                          selected: {s.themeMode},
                          onSelectionChanged: (selection) =>
                              cubit.setThemeMode(selection.first),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s6),
              SettingsSection(
                title: AppStrings.settingsAiSection,
                children: [
                  MergeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.settingsAiSwitch,
                                  style: context.text.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s1),
                                Text(
                                  AppStrings.settingsAiNote,
                                  style: context.text.bodySmall?.copyWith(
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Switch(
                            value: s.aiEnabled,
                            onChanged: cubit.setAiEnabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s6),
              SettingsSection(
                title: AppStrings.settingsAccountSection,
                children: [
                  SettingsRow(
                    label: AppStrings.settingsSignOut,
                    labelColor: p.primary,
                    onTap: () => context.read<AuthCubit>().signOut(),
                  ),
                  SettingsRow(
                    label: AppStrings.settingsDeleteAccount,
                    labelColor: p.error,
                    onTap: () async {
                      // Taken now: after the delete this screen is gone.
                      final auth = context.read<AuthCubit>();
                      final router = GoRouter.of(context);
                      final password = await DeleteAccountDialog.show(context);
                      if (password == null) return;
                      final deleted = await cubit.deleteAccount(
                        password: password.isEmpty ? null : password,
                      );
                      if (deleted) await _openRegister(auth, router);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
