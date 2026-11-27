// SettingsCubit = the logic of the Settings screen.
//
// Every change is shown AT ONCE and saved in the background
// ("optimistic update"). If the save fails, the old value comes back and
// an error is shown. Real life: like ticking a box on paper and erasing it
// if the teacher says no.
//
// The new settings are also given to AuthCubit (onProfileUpdated), so the
// whole app follows right away: the theme changes, the planner sees the new
// study hours, the AI screens see the AI switch.
//
// Delete account is here too (it is on this screen).
//
// Usage (the screen creates it):
//   SettingsCubit(
//     repository: getIt<AuthRepository>(),
//     currentUser: () => authCubit.currentUser,
//     onProfileUpdated: authCubit.profileUpdated,
//   )
//   cubit.setThemeMode(AppThemeMode.dark);

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.settings,
    this.isDeleting = false,
    this.failure,
    this.failureId = 0,
  });

  final UserSettings settings;
  final bool isDeleting;

  /// The last error, shown once in a snackbar (failureId changes each time).
  final Failure? failure;
  final int failureId;

  SettingsState copyWith({
    UserSettings? settings,
    bool? isDeleting,
    Failure? failure,
    int? failureId,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isDeleting: isDeleting ?? this.isDeleting,
      failure: failure ?? this.failure,
      failureId: failureId ?? this.failureId,
    );
  }

  @override
  List<Object?> get props => [settings, isDeleting, failure, failureId];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required AuthRepository repository,
    required UserProfile? Function() currentUser,
    required void Function(UserProfile profile) onProfileUpdated,
  }) : _repository = repository,
       _currentUser = currentUser,
       _onProfileUpdated = onProfileUpdated,
       super(
         SettingsState(
           settings: currentUser()?.settings ?? UserSettings.defaults(),
         ),
       );

  final AuthRepository _repository;
  final UserProfile? Function() _currentUser;
  final void Function(UserProfile profile) _onProfileUpdated;

  Future<void> setDailyStudyHours(double hours) =>
      _update((s) => s.copyWith(dailyStudyHours: hours));

  Future<void> setPreferredStudyTime(StudyTime time) =>
      _update((s) => s.copyWith(preferredStudyTime: time));

  /// [day] is DateTime.monday ... DateTime.sunday (1 ... 7).
  Future<void> setWeekStartDay(int day) =>
      _update((s) => s.copyWith(weekStartDay: day));

  Future<void> setTimezone(String timezone) =>
      _update((s) => s.copyWith(timezone: timezone));

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setAiEnabled(bool enabled) =>
      _update((s) => s.copyWith(aiEnabled: enabled));

  /// Deletes the account. Returns true when it worked; then AuthCubit gets
  /// "signed out" from the repository and the router opens Login.
  /// [password] confirms who the user is (password accounts). Google
  /// accounts pass null and confirm with Google.
  Future<bool> deleteAccount({String? password}) async {
    if (state.isDeleting) return false;
    emit(state.copyWith(isDeleting: true));

    final result = await _repository.deleteAccount(password: password);
    if (isClosed) return result is Success;

    switch (result) {
      case Success():
        emit(state.copyWith(isDeleting: false));
        return true;
      case Failed(:final failure):
        emit(
          state.copyWith(
            isDeleting: false,
            failure: failure,
            failureId: state.failureId + 1,
          ),
        );
        return false;
    }
  }

  Future<void> _update(UserSettings Function(UserSettings) change) async {
    final user = _currentUser();
    if (user == null) return;

    final before = state.settings;
    final after = change(before);
    if (after == before) return;

    // 1. Show it now (here and in the whole app).
    emit(state.copyWith(settings: after));
    _onProfileUpdated(user.copyWith(settings: after));

    // 2. Save it.
    final result = await _repository.updateSettings(after);
    if (isClosed) return;

    // 3. If it failed, put the old value back (only if nothing newer came).
    if (result case Failed(:final failure)) {
      if (state.settings != after) return;
      emit(
        state.copyWith(
          settings: before,
          failure: failure,
          failureId: state.failureId + 1,
        ),
      );
      final latest = _currentUser();
      if (latest != null) _onProfileUpdated(latest.copyWith(settings: before));
    }
  }
}
