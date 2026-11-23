// Tests for AuthCubit (the repository is faked with mocktail).
// Run with: fvm flutter test test/features/auth/logic/auth_cubit_test.dart

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/auth_repository.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepo repository;
  late StreamController<Result<UserProfile?>> authChanges;
  late UserProfile profile;

  setUp(() {
    repository = MockAuthRepo();
    authChanges = StreamController<Result<UserProfile?>>();
    profile = UserProfile(
      uid: 'u1',
      email: 'a@b.com',
      createdAt: DateTime.utc(2026, 1, 1),
      settings: UserSettings.defaults(),
    );
    when(() => repository.authStateChanges())
        .thenAnswer((_) => authChanges.stream);
  });

  tearDown(() => authChanges.close());

  void stubSignIn(Result<UserProfile> result) {
    when(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubRegister(Result<UserProfile> result) {
    when(
      () => repository.registerWithEmail(
        displayName: any(named: 'displayName'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('session', () {
    test('starts as AuthInitial', () async {
      final cubit = AuthCubit(repository);

      expect(cubit.state, const AuthInitial());
      await cubit.close();
    });

    blocTest<AuthCubit, AuthState>(
      'a signed in user from the repository gives Authenticated',
      build: () => AuthCubit(repository),
      act: (cubit) async {
        authChanges.add(Result<UserProfile?>.success(profile));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [Authenticated(profile)],
    );

    blocTest<AuthCubit, AuthState>(
      'no user from the repository gives Unauthenticated',
      build: () => AuthCubit(repository),
      act: (cubit) async {
        authChanges.add(const Result<UserProfile?>.success(null));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'a profile that cannot be loaded gives AuthError',
      build: () => AuthCubit(repository),
      act: (cubit) async {
        authChanges.add(const Result<UserProfile?>.failure(NetworkFailure()));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [const AuthError(NetworkFailure())],
    );

    test('close stops listening to the repository', () async {
      final cubit = AuthCubit(repository);
      expect(authChanges.hasListener, isTrue);

      await cubit.close();

      expect(authChanges.hasListener, isFalse);
    });
  });

  group('signIn', () {
    blocTest<AuthCubit, AuthState>(
      'success: Loading then Authenticated',
      build: () {
        stubSignIn(Result.success(profile));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'secret123'),
      expect: () => [const AuthLoading(), Authenticated(profile)],
      verify: (_) => verify(
        () => repository.signInWithEmail(
          email: 'a@b.com',
          password: 'secret123',
        ),
      ).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'failure: Loading then AuthError',
      build: () {
        stubSignIn(const Result.failure(AuthFailure()));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signIn(email: 'a@b.com', password: 'bad'),
      expect: () => [const AuthLoading(), const AuthError(AuthFailure())],
    );

    test('a second signIn while loading is ignored', () async {
      final pending = Completer<Result<UserProfile>>();
      when(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => pending.future);

      final cubit = AuthCubit(repository);
      final first = cubit.signIn(email: 'a@b.com', password: 'secret123');
      await cubit.signIn(email: 'a@b.com', password: 'secret123');

      verify(
        () => repository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);

      pending.complete(Result.success(profile));
      await first;
      await cubit.close();
    });
  });

  group('register', () {
    blocTest<AuthCubit, AuthState>(
      'success: Loading then Authenticated',
      build: () {
        stubRegister(Result.success(profile));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.register(
        displayName: 'Nour',
        email: 'a@b.com',
        password: 'secret123',
      ),
      expect: () => [const AuthLoading(), Authenticated(profile)],
      verify: (_) => verify(
        () => repository.registerWithEmail(
          displayName: 'Nour',
          email: 'a@b.com',
          password: 'secret123',
        ),
      ).called(1),
    );

    blocTest<AuthCubit, AuthState>(
      'failure: Loading then AuthError',
      build: () {
        stubRegister(
          const Result.failure(
            AuthFailure(code: 'email-already-in-use'),
          ),
        );
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.register(
        displayName: 'Nour',
        email: 'a@b.com',
        password: 'secret123',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(AuthFailure(code: 'email-already-in-use')),
      ],
    );
  });

  group('signInWithGoogle', () {
    void stubGoogle(Result<UserProfile?> result) {
      when(() => repository.signInWithGoogle()).thenAnswer((_) async => result);
    }

    blocTest<AuthCubit, AuthState>(
      'success: Loading then Authenticated',
      build: () {
        stubGoogle(Result<UserProfile?>.success(profile));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const AuthLoading(), Authenticated(profile)],
    );

    blocTest<AuthCubit, AuthState>(
      'picker closed: Loading then back to Unauthenticated (no error)',
      build: () {
        stubGoogle(const Result<UserProfile?>.success(null));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'failure: Loading then AuthError',
      build: () {
        stubGoogle(
          const Result<UserProfile?>.failure(
            AuthFailure(code: 'google-unknownError'),
          ),
        );
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [
        const AuthLoading(),
        const AuthError(AuthFailure(code: 'google-unknownError')),
      ],
    );
  });

  group('sendPasswordReset', () {
    blocTest<AuthCubit, AuthState>(
      'success: Loading then AuthPasswordResetSent',
      build: () {
        when(() => repository.sendPasswordReset(email: any(named: 'email')))
            .thenAnswer((_) async => const Result<void>.success(null));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.sendPasswordReset(email: 'a@b.com'),
      expect: () => [const AuthLoading(), const AuthPasswordResetSent()],
    );

    blocTest<AuthCubit, AuthState>(
      'failure: Loading then AuthError',
      build: () {
        when(() => repository.sendPasswordReset(email: any(named: 'email')))
            .thenAnswer(
          (_) async => const Result<void>.failure(ValidationFailure()),
        );
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.sendPasswordReset(email: 'nope'),
      expect: () => [const AuthLoading(), const AuthError(ValidationFailure())],
    );
  });

  group('signOut', () {
    blocTest<AuthCubit, AuthState>(
      'success: Loading then Unauthenticated',
      build: () {
        when(() => repository.signOut())
            .thenAnswer((_) async => const Result<void>.success(null));
        return AuthCubit(repository);
      },
      act: (cubit) => cubit.signOut(),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'failure: the user stays signed in',
      build: () {
        when(() => repository.signOut()).thenAnswer(
          (_) async => const Result<void>.failure(NetworkFailure()),
        );
        return AuthCubit(repository);
      },
      act: (cubit) async {
        authChanges.add(Result<UserProfile?>.success(profile));
        await Future<void>.delayed(Duration.zero);
        await cubit.signOut();
      },
      expect: () => [
        Authenticated(profile),
        const AuthLoading(),
        const AuthError(NetworkFailure()),
        Authenticated(profile),
      ],
    );
  });
}