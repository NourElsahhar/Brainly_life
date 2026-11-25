// ProfileCubit = the logic of the Profile screen:
//   - loads the 3 numbers (streak, hours studied, tasks done)
//   - changes the name ("Edit profile")
//   - changes the avatar (the camera button)
//
// The profile itself (name, email, photo) is NOT kept here: it lives in
// AuthCubit (one place for the whole app). After a save we give the new
// profile to AuthCubit with onProfileUpdated, and every screen updates.
//
// Usage (the screen creates it):
//   ProfileCubit(
//     repository: getIt<AuthRepository>(),
//     statsProvider: getIt<ProfileStatsProvider>(),
//     currentUser: () => authCubit.currentUser,
//     onProfileUpdated: authCubit.profileUpdated,
//   )..loadStats();

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.stats,
    this.isSavingName = false,
    this.failure,
    this.failureId = 0,
  });

  /// null while loading (the cards show "–").
  final ProfileStats? stats;

  /// true while the name OR the avatar is being saved.
  final bool isSavingName;

  /// The last error, shown once in a snackbar. failureId changes every
  /// time, so the same error twice is shown twice.
  final Failure? failure;
  final int failureId;

  ProfileState copyWith({
    ProfileStats? stats,
    bool? isSavingName,
    Failure? failure,
    int? failureId,
  }) {
    return ProfileState(
      stats: stats ?? this.stats,
      isSavingName: isSavingName ?? this.isSavingName,
      failure: failure ?? this.failure,
      failureId: failureId ?? this.failureId,
    );
  }

  @override
  List<Object?> get props => [stats, isSavingName, failure, failureId];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required AuthRepository repository,
    required ProfileStatsProvider statsProvider,
    required UserProfile? Function() currentUser,
    required void Function(UserProfile profile) onProfileUpdated,
  }) : _repository = repository,
       _statsProvider = statsProvider,
       _currentUser = currentUser,
       _onProfileUpdated = onProfileUpdated,
       super(const ProfileState());

  final AuthRepository _repository;
  final ProfileStatsProvider _statsProvider;
  final UserProfile? Function() _currentUser;
  final void Function(UserProfile profile) _onProfileUpdated;

  static const int maxNameLength = 60;

  Future<void> loadStats() async {
    final result = await _statsProvider.load();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(stats: data));
      case Failed():
        // The numbers are not important enough for an error: show zeros.
        emit(state.copyWith(stats: ProfileStats.empty));
    }
  }

  /// Saves a new name. Returns true when it worked (the sheet closes).
  Future<bool> updateName(String name) async {
    final user = _currentUser();
    final trimmed = name.trim();
    if (user == null || state.isSavingName) return false;
    if (trimmed.isEmpty || trimmed.length > maxNameLength) return false;
    if (trimmed == user.displayName) return true;

    emit(state.copyWith(isSavingName: true));
    final result = await _repository.updateDisplayName(trimmed);
    if (isClosed) return false;

    switch (result) {
      case Success():
        _onProfileUpdated(user.copyWith(displayName: trimmed));
        emit(state.copyWith(isSavingName: false));
        return true;
      case Failed(:final failure):
        _fail(failure);
        return false;
    }
  }

  /// Saves the picked avatar (null = remove it). Returns true when it
  /// worked. The new profile goes to AuthCubit, so the header updates.
  Future<bool> updateAvatar(String? avatarId) async {
    final user = _currentUser();
    if (user == null || state.isSavingName) return false;
    if (avatarId == user.avatarId) return true;

    emit(state.copyWith(isSavingName: true));
    final result = await _repository.updateAvatar(avatarId);
    if (isClosed) return false;

    switch (result) {
      case Success():
        _onProfileUpdated(
          avatarId == null
              ? user.copyWith(clearAvatarId: true)
              : user.copyWith(avatarId: avatarId),
        );
        emit(state.copyWith(isSavingName: false));
        return true;
      case Failed(:final failure):
        _fail(failure);
        return false;
    }
  }

  void _fail(Failure failure) {
    emit(
      state.copyWith(
        isSavingName: false,
        failure: failure,
        failureId: state.failureId + 1,
      ),
    );
  }
}
