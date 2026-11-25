// Tests for FirebaseAuthRepository (the data source is faked with mocktail).
// Run with: fvm flutter test test/features/auth/data/repositories/firebase_auth_repository_test.dart

// ignore_for_file: unnecessary_import

import 'dart:async';
import 'dart:io';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUser extends Mock implements User {}

class FakeUser extends Fake implements User {}

void main() {
  late MockAuthRemoteDataSource dataSource;
  late FirebaseAuthRepository repository;
  late UserProfile profile;

  setUpAll(() => registerFallbackValue(FakeUser()));

  setUp(() {
    dataSource = MockAuthRemoteDataSource();
    profile = UserProfile(
      uid: 'u1',
      email: 'a@b.com',
      createdAt: DateTime.utc(2026, 1, 1),
      settings: UserSettings.defaults(),
    );
    repository = FirebaseAuthRepository(
      dataSource: dataSource,
      getTimezone: () async => 'Africa/Cairo',
    );
  });

  void stubLoadProfile() {
    when(
      () => dataSource.loadOrCreateProfile(
        any(),
        timezone: any(named: 'timezone'),
      ),
    ).thenAnswer((_) async => profile);
  }

  group('signInWithEmail', () {
    test('returns the profile and trims the email', () async {
      final user = MockUser();
      when(
        () => dataSource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);
      stubLoadProfile();

      final result = await repository.signInWithEmail(
        email: '  a@b.com ',
        password: 'secret123',
      );

      expect(result.dataOrNull, profile);
      verify(
        () =>
            dataSource.signInWithEmail(email: 'a@b.com', password: 'secret123'),
      ).called(1);
      verify(
        () => dataSource.loadOrCreateProfile(user, timezone: 'Africa/Cairo'),
      ).called(1);
    });

    test('wrong password gives a friendly AuthFailure', () async {
      when(
        () => dataSource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await repository.signInWithEmail(
        email: 'a@b.com',
        password: 'bad',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.userMessage, 'Incorrect email or password.');
    });

    test('no internet gives a NetworkFailure', () async {
      when(
        () => dataSource.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const SocketException('offline'));

      final result = await repository.signInWithEmail(
        email: 'a@b.com',
        password: 'secret123',
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('registerWithEmail', () {
    test(
      'creates the account with the trimmed values and the timezone',
      () async {
        when(
          () => dataSource.registerWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
            timezone: any(named: 'timezone'),
          ),
        ).thenAnswer((_) async => profile);

        final result = await repository.registerWithEmail(
          displayName: '  Nour ',
          email: ' a@b.com ',
          password: 'secret123',
        );

        expect(result.dataOrNull, profile);
        verify(
          () => dataSource.registerWithEmail(
            email: 'a@b.com',
            password: 'secret123',
            displayName: 'Nour',
            timezone: 'Africa/Cairo',
          ),
        ).called(1);
      },
    );

    test(
      'an email already in use gives an AuthFailure with its code',
      () async {
        when(
          () => dataSource.registerWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
            timezone: any(named: 'timezone'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        final result = await repository.registerWithEmail(
          displayName: 'Nour',
          email: 'a@b.com',
          password: 'secret123',
        );

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull?.code, 'email-already-in-use');
      },
    );

    test('a timezone problem falls back to UTC', () async {
      final repo = FirebaseAuthRepository(
        dataSource: dataSource,
        getTimezone: () async => throw Exception('no timezone'),
      );
      when(
        () => dataSource.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
          timezone: any(named: 'timezone'),
        ),
      ).thenAnswer((_) async => profile);

      await repo.registerWithEmail(
        displayName: 'Nour',
        email: 'a@b.com',
        password: 'secret123',
      );

      verify(
        () => dataSource.registerWithEmail(
          email: 'a@b.com',
          password: 'secret123',
          displayName: 'Nour',
          timezone: 'UTC',
        ),
      ).called(1);
    });
  });

  group('sendPasswordReset and signOut', () {
    test('send password reset works and trims the email', () async {
      when(() => dataSource.sendPasswordReset(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final result = await repository.sendPasswordReset(email: ' a@b.com ');

      expect(result.isSuccess, isTrue);
      verify(() => dataSource.sendPasswordReset(email: 'a@b.com')).called(1);
    });

    test('send password reset failure gives a Failure', () async {
      when(() => dataSource.sendPasswordReset(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final result = await repository.sendPasswordReset(email: 'nope');

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('sign out works', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      expect((await repository.signOut()).isSuccess, isTrue);
    });

    test('sign out failure gives a Failure', () async {
      when(() => dataSource.signOut())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect((await repository.signOut()).failureOrNull, isA<NetworkFailure>());
    });
  });

  group('authStateChanges', () {
    test('signed out gives success(null)', () async {
      when(() => dataSource.authStateChanges())
          .thenAnswer((_) => Stream<User?>.value(null));

      final results = await repository.authStateChanges().toList();

      expect(results.single.isSuccess, isTrue);
      expect(results.single.dataOrNull, isNull);
    });

    test('signed in gives the profile', () async {
      when(() => dataSource.authStateChanges())
          .thenAnswer((_) => Stream<User?>.value(MockUser()));
      stubLoadProfile();

      final results = await repository.authStateChanges().toList();

      expect(results.single.dataOrNull, profile);
    });

    test('a profile that cannot be loaded gives a failure', () async {
      when(() => dataSource.authStateChanges())
          .thenAnswer((_) => Stream<User?>.value(MockUser()));
      when(
        () => dataSource.loadOrCreateProfile(
          any(),
          timezone: any(named: 'timezone'),
        ),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final results = await repository.authStateChanges().toList();

      expect(results.single.failureOrNull, isA<NetworkFailure>());
    });

    test('waits for a registration before loading the profile', () async {
      final authEvents = StreamController<User?>();
      addTearDown(authEvents.close);
      final registration = Completer<UserProfile>();

      when(() => dataSource.authStateChanges())
          .thenAnswer((_) => authEvents.stream);
      when(
        () => dataSource.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
          timezone: any(named: 'timezone'),
        ),
      ).thenAnswer((_) => registration.future);
      stubLoadProfile();

      final emitted = <UserProfile?>[];
      final subscription = repository.authStateChanges().listen(
        (result) => emitted.add(result.dataOrNull),
      );
      addTearDown(subscription.cancel);

      final registering = repository.registerWithEmail(
        displayName: 'Nour',
        email: 'a@b.com',
        password: 'secret123',
      );
      await Future<void>.delayed(Duration.zero);

      // Firebase says "signed in" while the profile is still being written.
      authEvents.add(MockUser());
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      verifyNever(
        () => dataSource.loadOrCreateProfile(
          any(),
          timezone: any(named: 'timezone'),
        ),
      );

      registration.complete(profile);
      await registering;
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [profile]);
    });
  });
}
