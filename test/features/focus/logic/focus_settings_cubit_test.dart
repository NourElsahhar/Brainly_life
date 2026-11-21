// Tests for FocusSettingsCubit: loading, saving each change, limits,
// undo when saving fails, and reset to defaults.

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingLoadRepository extends MockFocusRepository {
  @override
  Future<Result<FocusSettings>> getSettings() async =>
      const Result.failure(NetworkFailure());
}

class _FailingSaveRepository extends MockFocusRepository {
  @override
  Future<Result<void>> saveSettings(FocusSettings settings) async =>
      const Result.failure(NetworkFailure());
}

void main() {
  late MockFocusRepository repository;

  setUp(() {
    repository = MockFocusRepository();
  });

  Matcher loadedWith(FocusSettings settings) => isA<FocusSettingsLoaded>()
      .having((s) => s.settings, 'settings', settings);

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'load emits loading then the default settings',
    build: () => FocusSettingsCubit(repository: repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      const FocusSettingsLoading(),
      loadedWith(const FocusSettings()),
    ],
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'load emits an error when loading fails',
    build: () => FocusSettingsCubit(repository: _FailingLoadRepository()),
    act: (cubit) => cubit.load(),
    expect: () => [
      const FocusSettingsLoading(),
      const FocusSettingsError(NetworkFailure()),
    ],
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'a change is shown and saved right away',
    build: () => FocusSettingsCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.soundChanged(false);
    },
    skip: 2,
    expect: () => [loadedWith(const FocusSettings(sound: false))],
    verify: (_) async {
      final saved = (await repository.getSettings()).dataOrNull!;
      expect(saved.sound, isFalse);
    },
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'values stay inside the limits',
    build: () => FocusSettingsCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.focusMinutesChanged(500);
      await cubit.focusMinutesChanged(1);
    },
    skip: 2,
    expect: () => [
      loadedWith(const FocusSettings(focusMinutes: 90)),
      loadedWith(const FocusSettings(focusMinutes: 5)),
    ],
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'setting the same value changes nothing',
    build: () => FocusSettingsCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.soundChanged(true);
    },
    skip: 2,
    expect: () => <Matcher>[],
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'a failed save undoes the change and reports the failure',
    build: () => FocusSettingsCubit(repository: _FailingSaveRepository()),
    act: (cubit) async {
      await cubit.load();
      await cubit.autoStartChanged(true);
    },
    skip: 2,
    expect: () => [
      loadedWith(const FocusSettings(autoStart: true)),
      isA<FocusSettingsLoaded>()
          .having((s) => s.settings, 'settings', const FocusSettings())
          .having((s) => s.saveFailure, 'saveFailure', const NetworkFailure()),
    ],
  );

  blocTest<FocusSettingsCubit, FocusSettingsState>(
    'resetToDefaults brings back the default settings',
    build: () => FocusSettingsCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      await cubit.focusMinutesChanged(50);
      await cubit.resetToDefaults();
    },
    skip: 2,
    expect: () => [
      loadedWith(const FocusSettings(focusMinutes: 50)),
      loadedWith(const FocusSettings()),
    ],
  );
}
