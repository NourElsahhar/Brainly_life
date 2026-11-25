// Tests for SettingsCubit: the change shows at once, is saved, is given to
// AuthCubit, comes back when the save fails, and delete account.
// Run with: fvm flutter test test/features/auth/logic/settings_cubit_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/logic/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepo repository;
  late UserProfile user;
  late List<UserProfile> published;

  setUpAll(() => registerFallbackValue(UserSettings.defaults()));

  setUp(() {
    repository = MockAuthRepo();
    published = [];
    user = UserProfile(
      uid: 'u1',
      email: 'a@b.com',
      displayName: 'Shahd',
      createdAt: DateTime.utc(2026, 1, 1),
      settings: UserSettings.defaults(),
    );
  });

  SettingsCubit build() => SettingsCubit(
    repository: repository,
    currentUser: () => user,
    onProfileUpdated: (profile) {
      user = profile;
      published.add(profile);
    },
  );

  void stubSave(Result<void> result) =>
      when(() => repository.updateSettings(any()))
          .thenAnswer((_) async => result);

  test('starts with the settings of the signed-in user', () {
    final cubit = build();
    expect(cubit.state.settings, user.settings);
    cubit.close();
  });

  blocTest<SettingsCubit, SettingsState>(
    'a change shows at once, is saved and given to AuthCubit',
    setUp: () => stubSave(const Result<void>.success(null)),
    build: build,
    act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
    expect: () => [
      isA<SettingsState>().having(
        (s) => s.settings.themeMode,
        'themeMode',
        AppThemeMode.dark,
      ),
    ],
    verify: (_) {
      final saved =
          verify(() => repository.updateSettings(captureAny())).captured.single
              as UserSettings;
      expect(saved.themeMode, AppThemeMode.dark);
      expect(published.single.settings.themeMode, AppThemeMode.dark);
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'the same value again does nothing',
    build: build,
    act: (cubit) => cubit.setAiEnabled(true), // already true by default
    expect: () => <SettingsState>[],
    verify: (_) => verifyNever(() => repository.updateSettings(any())),
  );

  blocTest<SettingsCubit, SettingsState>(
    'a failed save brings the old value back and shows the error',
    setUp: () => stubSave(const Result<void>.failure(NetworkFailure())),
    build: build,
    act: (cubit) => cubit.setDailyStudyHours(5),
    expect: () => [
      isA<SettingsState>().having((s) => s.settings.dailyStudyHours, 'new', 5),
      isA<SettingsState>()
          .having(
            (s) => s.settings.dailyStudyHours,
            'old',
            UserSettings.defaultDailyStudyHours,
          )
          .having((s) => s.failure, 'failure', const NetworkFailure())
          .having((s) => s.failureId, 'failureId', 1),
    ],
    verify: (_) => expect(
      user.settings.dailyStudyHours,
      UserSettings.defaultDailyStudyHours,
    ),
  );

  group('deleteAccount', () {
    blocTest<SettingsCubit, SettingsState>(
      'success: deleting, then done',
      setUp: () =>
          when(() => repository.deleteAccount())
              .thenAnswer((_) async => const Result<void>.success(null)),
      build: build,
      act: (cubit) async => expect(await cubit.deleteAccount(), isTrue),
      expect: () => [
        isA<SettingsState>().having((s) => s.isDeleting, 'deleting', true),
        isA<SettingsState>().having((s) => s.isDeleting, 'deleting', false),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'sign in too long ago: the error is shown',
      setUp: () => when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Result<void>.failure(
          AuthFailure(code: 'requires-recent-login'),
        ),
      ),
      build: build,
      act: (cubit) async => expect(await cubit.deleteAccount(), isFalse),
      expect: () => [
        isA<SettingsState>().having((s) => s.isDeleting, 'deleting', true),
        isA<SettingsState>()
            .having((s) => s.isDeleting, 'deleting', false)
            .having(
              (s) => s.failure,
              'failure',
              const AuthFailure(code: 'requires-recent-login'),
            ),
      ],
    );
  });
}
