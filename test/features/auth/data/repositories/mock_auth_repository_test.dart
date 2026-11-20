// Tests for MockAuthRepository.
// Run with: fvm flutter test test/features/auth/data/repositories/mock_auth_repository_test.dart

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('signInWithEmail', () {
    test('the demo account works (email is not case sensitive)', () async {
      final result = await repository.signInWithEmail(
        email: ' DEMO@example.com ',
        password: MockAuthRepository.demoPassword,
      );

      expect(result.dataOrNull?.email, MockAuthRepository.demoEmail);
    });

    test('a wrong password or an unknown email gives the same failure',
        () async {
      final wrongPassword = await repository.signInWithEmail(
        email: MockAuthRepository.demoEmail,
        password: 'wrong',
      );
      final unknownEmail = await repository.signInWithEmail(
        email: 'nobody@example.com',
        password: 'password123',
      );

      for (final result in [wrongPassword, unknownEmail]) {
        expect(result.failureOrNull, isA<AuthFailure>());
        expect(
          result.failureOrNull?.userMessage,
          'Incorrect email or password.',
        );
      }
    });
  });

  group('registerWithEmail', () {
    test('creates an account and the user can sign in with it', () async {
      final registered = await repository.registerWithEmail(
        displayName: ' Nour ',
        email: 'nour@example.com',
        password: 'secret123',
      );

      expect(registered.dataOrNull?.displayName, 'Nour');

      final signedIn = await repository.signInWithEmail(
        email: 'nour@example.com',
        password: 'secret123',
      );
      expect(signedIn.dataOrNull?.uid, registered.dataOrNull?.uid);
    });

    test('every new account has its own uid', () async {
      final first = await repository.registerWithEmail(
        displayName: 'A',
        email: 'a@example.com',
        password: 'secret123',
      );
      final second = await repository.registerWithEmail(
        displayName: 'B',
        email: 'b@example.com',
        password: 'secret123',
      );

      expect(first.dataOrNull?.uid, isNot(second.dataOrNull?.uid));
    });

    test('an email that already exists gives email-already-in-use', () async {
      final result = await repository.registerWithEmail(
        displayName: 'Demo',
        email: MockAuthRepository.demoEmail,
        password: 'secret123',
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, 'email-already-in-use');
    });
  });

  test('sendPasswordReset always works', () async {
    final result = await repository.sendPasswordReset(email: 'anyone@x.com');

    expect(result.isSuccess, isTrue);
  });

  test('authStateChanges starts signed out and follows every change',
      () async {
    final emitted = <UserProfile?>[];
    final subscription = repository
        .authStateChanges()
        .listen((result) => emitted.add(result.dataOrNull));
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.signInWithEmail(
      email: MockAuthRepository.demoEmail,
      password: MockAuthRepository.demoPassword,
    );
    await Future<void>.delayed(Duration.zero);

    await repository.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 3);
    expect(emitted[0], isNull);
    expect(emitted[1]?.email, MockAuthRepository.demoEmail);
    expect(emitted[2], isNull);
  });
}