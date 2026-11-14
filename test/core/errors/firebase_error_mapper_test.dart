// Tests for FirebaseErrorMapper.
// Run with: fvm flutter test test/core/errors/firebase_error_mapper_test.dart

import 'dart:async';
import 'dart:io';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseAuthException', () {
    FirebaseAuthException auth(String code) =>
        FirebaseAuthException(code: code);

    test('wrong credentials all give the same friendly message', () {
      for (final code in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      ]) {
        final failure = FirebaseErrorMapper.map(auth(code));

        expect(failure, isA<AuthFailure>());
        expect(failure.userMessage, 'Incorrect email or password.');
        expect(failure.code, code);
      }
    });

    test('invalid email and weak password are validation failures', () {
      expect(FirebaseErrorMapper.map(auth('invalid-email')),
          isA<ValidationFailure>());
      expect(FirebaseErrorMapper.map(auth('weak-password')),
          isA<ValidationFailure>());
    });

    test('email already in use is an AuthFailure', () {
      expect(FirebaseErrorMapper.map(auth('email-already-in-use')),
          isA<AuthFailure>());
    });

    test('requires-recent-login keeps its code for the Cubit', () {
      final failure = FirebaseErrorMapper.map(auth('requires-recent-login'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, 'requires-recent-login');
    });

    test('network-request-failed is a NetworkFailure', () {
      expect(FirebaseErrorMapper.map(auth('network-request-failed')),
          isA<NetworkFailure>());
    });

    test('unknown auth code falls back to AuthFailure', () {
      final failure = FirebaseErrorMapper.map(auth('something-new'));

      expect(failure, isA<AuthFailure>());
      expect(failure.code, 'something-new');
    });
  });

  group('FirebaseException', () {
    FirebaseException firebase(String code) =>
        FirebaseException(plugin: 'cloud_firestore', code: code);

    test('permission-denied -> PermissionFailure', () {
      expect(FirebaseErrorMapper.map(firebase('permission-denied')),
          isA<PermissionFailure>());
    });

    test('not-found -> NotFoundFailure', () {
      expect(FirebaseErrorMapper.map(firebase('not-found')),
          isA<NotFoundFailure>());
    });

    test('unavailable and deadline-exceeded -> NetworkFailure', () {
      expect(FirebaseErrorMapper.map(firebase('unavailable')),
          isA<NetworkFailure>());
      expect(FirebaseErrorMapper.map(firebase('deadline-exceeded')),
          isA<NetworkFailure>());
    });

    test('unauthenticated -> AuthFailure', () {
      expect(FirebaseErrorMapper.map(firebase('unauthenticated')),
          isA<AuthFailure>());
    });

    test('unknown code -> UnknownFailure and keeps the code', () {
      final failure = FirebaseErrorMapper.map(firebase('failed-precondition'));

      expect(failure, isA<UnknownFailure>());
      expect(failure.code, 'failed-precondition');
    });
  });

  group('other errors', () {
    test('SocketException and TimeoutException -> NetworkFailure', () {
      expect(FirebaseErrorMapper.map(const SocketException('no internet')),
          isA<NetworkFailure>());
      expect(FirebaseErrorMapper.map(TimeoutException('too slow')),
          isA<NetworkFailure>());
    });

    test('a Failure is returned as it is', () {
      const original = NotFoundFailure();

      expect(FirebaseErrorMapper.map(original), same(original));
    });

    test('anything else -> UnknownFailure', () {
      expect(FirebaseErrorMapper.map(Exception('boom')),
          isA<UnknownFailure>());
    });
  });
}