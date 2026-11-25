// FocusSettingsCubit drives the focus settings screen: it loads the saved
// settings and saves every change right away (the design has no Save button).
// Values stay inside the limits below. If saving fails, the change is undone
// and the failure is reported so the screen can show a snackbar.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Allowed values and the step of the +/- buttons for each timer setting.
class FocusSettingsLimits {
  const FocusSettingsLimits._();

  static const int focusMin = 5;
  static const int focusMax = 90;
  static const int focusStep = 5;

  static const int shortBreakMin = 1;
  static const int shortBreakMax = 30;
  static const int shortBreakStep = 1;

  static const int longBreakMin = 5;
  static const int longBreakMax = 60;
  static const int longBreakStep = 5;

  static const int sessionsMin = 2;
  static const int sessionsMax = 8;
  static const int sessionsStep = 1;
}

class FocusSettingsCubit extends Cubit<FocusSettingsState> {
  FocusSettingsCubit({required FocusRepository repository})
    : _repository = repository,
      super(const FocusSettingsInitial());

  final FocusRepository _repository;

  Future<void> load() async {
    emit(const FocusSettingsLoading());
    final result = await _repository.getSettings();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(FocusSettingsLoaded(settings: data));
      case Failed(:final failure):
        emit(FocusSettingsError(failure));
    }
  }

  Future<void> focusMinutesChanged(int value) => _apply(
    (s) => s.copyWith(
      focusMinutes: _limit(
        value,
        FocusSettingsLimits.focusMin,
        FocusSettingsLimits.focusMax,
      ),
    ),
  );

  Future<void> shortBreakMinutesChanged(int value) => _apply(
    (s) => s.copyWith(
      shortBreakMinutes: _limit(
        value,
        FocusSettingsLimits.shortBreakMin,
        FocusSettingsLimits.shortBreakMax,
      ),
    ),
  );

  Future<void> longBreakMinutesChanged(int value) => _apply(
    (s) => s.copyWith(
      longBreakMinutes: _limit(
        value,
        FocusSettingsLimits.longBreakMin,
        FocusSettingsLimits.longBreakMax,
      ),
    ),
  );

  Future<void> sessionsBeforeLongChanged(int value) => _apply(
    (s) => s.copyWith(
      sessionsBeforeLong: _limit(
        value,
        FocusSettingsLimits.sessionsMin,
        FocusSettingsLimits.sessionsMax,
      ),
    ),
  );

  Future<void> autoStartChanged(bool value) =>
      _apply((s) => s.copyWith(autoStart: value));

  Future<void> soundChanged(bool value) =>
      _apply((s) => s.copyWith(sound: value));

  Future<void> vibrationChanged(bool value) =>
      _apply((s) => s.copyWith(vibration: value));

  Future<void> keepScreenOnChanged(bool value) =>
      _apply((s) => s.copyWith(keepScreenOn: value));

  Future<void> resetToDefaults() => _apply((_) => const FocusSettings());

  /// Shows the change immediately, then saves it. Undoes it if saving fails.
  Future<void> _apply(FocusSettings Function(FocusSettings s) change) async {
    final current = state;
    if (current is! FocusSettingsLoaded) return;

    final updated = change(current.settings);
    if (updated == current.settings) return;
    emit(FocusSettingsLoaded(settings: updated));

    final result = await _repository.saveSettings(updated);
    if (isClosed) return;
    if (result case Failed(:final failure)) {
      emit(
        FocusSettingsLoaded(settings: current.settings, saveFailure: failure),
      );
    }
  }

  static int _limit(int value, int min, int max) =>
      value.clamp(min, max).toInt();
}
