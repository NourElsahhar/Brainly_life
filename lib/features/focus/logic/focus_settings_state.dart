// States of the focus settings screen: initial, loading, error, and loaded
// (the current settings). There is no empty state: when nothing is saved yet
// the defaults are shown.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:equatable/equatable.dart';

sealed class FocusSettingsState extends Equatable {
  const FocusSettingsState();

  @override
  List<Object?> get props => [];
}

class FocusSettingsInitial extends FocusSettingsState {
  const FocusSettingsInitial();
}

class FocusSettingsLoading extends FocusSettingsState {
  const FocusSettingsLoading();
}

class FocusSettingsError extends FocusSettingsState {
  const FocusSettingsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

class FocusSettingsLoaded extends FocusSettingsState {
  const FocusSettingsLoaded({required this.settings, this.saveFailure});

  final FocusSettings settings;

  /// Set when saving a change failed and the change was undone.
  /// The screen shows it in a snackbar from a BlocListener.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [settings, saveFailure];
}
