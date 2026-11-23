// MockAuthRepository = a fake AuthRepository that lives in memory.
// Used when the app runs with --dart-define=USE_MOCKS=true, and in tests.
//
// It starts signed out (or signed in as the demo user with startSignedIn).
// A demo account already exists:
//   email:    MockAuthRepository.demoEmail      (demo@example.com)
//   password: MockAuthRepository.demoPassword   (password123)
// Register works too (new accounts live until the app restarts).
// "Continue with Google" signs in as MockAuthRepository.googleEmail
// (set googleCancels: true to act as if the user closed the picker).
//
// delay: makes every call slower, to see your loading states:
//   MockAuthRepository(delay: const Duration(seconds: 1))

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:clock/clock.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.delay = Duration.zero,
    bool startSignedIn = false,
    this.googleCancels = false,
  }) {
    final demo = _MockAccount(
      password: demoPassword,
      profile: _newProfile(
        uid: 'mock-user-1',
        displayName: 'Demo Student',
        email: demoEmail,
      ),
    );
    _accounts[demoEmail] = demo;
    if (startSignedIn) _current = demo.profile;
  }

  static const String demoEmail = 'demo@example.com';
  static const String demoPassword = 'password123';
  static const String googleEmail = 'google.student@gmail.com';

  final Duration delay;
  final bool googleCancels;

  final Map<String, _MockAccount> _accounts = {};
  final StreamController<Result<UserProfile?>> _changes =
      StreamController<Result<UserProfile?>>.broadcast();
  UserProfile? _current;
  int _nextUid = 2;

  @override
  Stream<Result<UserProfile?>> authStateChanges() async* {
    yield Result<UserProfile?>.success(_current);
    yield* _changes.stream;
  }

  @override
  Future<Result<UserProfile>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    final account = _accounts[_key(email)];
    // A Google account has no password, so email sign in never works for it.
    if (account == null ||
        account.password == null ||
        account.password != password) {
      return const Result.failure(
        AuthFailure(
          userMessage: 'Incorrect email or password.',
          code: 'invalid-credential',
        ),
      );
    }

    _setCurrent(account.profile);
    return Result.success(account.profile);
  }

  @override
  Future<Result<UserProfile>> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(delay);

    final key = _key(email);
    if (_accounts.containsKey(key)) {
      return const Result.failure(
        AuthFailure(
          userMessage: 'This email is already registered. Try signing in.',
          code: 'email-already-in-use',
        ),
      );
    }

    final profile = _newProfile(
      uid: 'mock-user-${_nextUid++}',
      displayName: displayName.trim(),
      email: email.trim(),
    );
    _accounts[key] = _MockAccount(password: password, profile: profile);

    _setCurrent(profile);
    return Result.success(profile);
  }

  @override
  Future<Result<UserProfile?>> signInWithGoogle() async {
    await Future<void>.delayed(delay);
    if (googleCancels) return const Result<UserProfile?>.success(null);

    // The same Google account every time (created on the first use).
    final account = _accounts.putIfAbsent(
      googleEmail,
      () => _MockAccount(
        password: null,
        profile: _newProfile(
          uid: 'mock-google-user',
          displayName: 'Google Student',
          email: googleEmail,
        ),
      ),
    );
    _setCurrent(account.profile);
    return Result<UserProfile?>.success(account.profile);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    await Future<void>.delayed(delay);
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(delay);
    _setCurrent(null);
    return const Result<void>.success(null);
  }

  void _setCurrent(UserProfile? profile) {
    _current = profile;
    _changes.add(Result<UserProfile?>.success(profile));
  }

  static String _key(String email) => email.trim().toLowerCase();

  static UserProfile _newProfile({
    required String uid,
    required String displayName,
    required String email,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      createdAt: clock.now().toUtc(),
      settings: UserSettings.defaults(),
    );
  }
}

class _MockAccount {
  const _MockAccount({required this.password, required this.profile});

  /// null for a Google account (no password).
  final String? password;
  final UserProfile profile;
}
