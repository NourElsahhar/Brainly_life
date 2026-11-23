// Tests for the Profile/Settings part of MockAuthRepository:
// updateDisplayName, updateSettings and deleteAccount.
// Run with: fvm flutter test test/features/auth/data/repositories/mock_auth_profile_test.dart

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nobody signed in: the changes fail', () async {
    final repository = MockAuthRepository();

    expect(await repository.updateDisplayName('X'), isA<Failed<void>>());
    expect(
      await repository.updateSettings(UserSettings.defaults()),
      isA<Failed<void>>(),
    );
    expect(await repository.deleteAccount(), isA<Failed<void>>());
  });

  test('a new name is kept after signing out and in again', () async {
    final repository = MockAuthRepository(startSignedIn: true);

    expect(await repository.updateDisplayName('  Nour  '), isA<Success<void>>());
    await repository.signOut();
    final result = await repository.signInWithEmail(
      email: MockAuthRepository.demoEmail,
      password: MockAuthRepository.demoPassword,
    );

    expect(result.dataOrNull?.displayName, 'Nour');
  });

  test('new settings are kept after signing in again', () async {
    final repository = MockAuthRepository(startSignedIn: true);
    final dark = UserSettings.defaults().copyWith(
      themeMode: AppThemeMode.dark,
    );

    await repository.updateSettings(dark);
    await repository.signOut();
    final result = await repository.signInWithEmail(
      email: MockAuthRepository.demoEmail,
      password: MockAuthRepository.demoPassword,
    );

    expect(result.dataOrNull?.settings.themeMode, AppThemeMode.dark);
  });

  test('deleteAccount signs out and the account is gone', () async {
    final repository = MockAuthRepository(startSignedIn: true);
    final sessions = <Object?>[];
    final sub = repository.authStateChanges().listen(
      (r) => sessions.add(r.dataOrNull),
    );
    await Future<void>.delayed(Duration.zero);

    expect(await repository.deleteAccount(), isA<Success<void>>());
    await Future<void>.delayed(Duration.zero);

    expect(sessions.last, isNull);
    final again = await repository.signInWithEmail(
      email: MockAuthRepository.demoEmail,
      password: MockAuthRepository.demoPassword,
    );
    expect(again, isA<Failed<Object?>>());
    await sub.cancel();
  });
}
