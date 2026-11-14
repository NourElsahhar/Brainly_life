// Tests for Failure and Result.
// Run with: fvm flutter test test/core/errors/result_test.dart

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success holds the data', () {
      const result = Result<int>.success(5);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 5);
      expect(result.failureOrNull, isNull);
    });

    test('failure holds a Failure', () {
      const result = Result<int>.failure(NetworkFailure());

      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, const NetworkFailure());
    });

    test('fold calls the matching callback', () {
      const ok = Result<int>.success(2);
      const bad = Result<int>.failure(AuthFailure());

      expect(ok.fold(onSuccess: (d) => d * 10, onFailure: (_) => -1), 20);
      expect(bad.fold(onSuccess: (d) => d * 10, onFailure: (_) => -1), -1);
    });

    test('results with the same content are equal', () {
      expect(const Result<int>.success(1), const Result<int>.success(1));
    });
  });

  group('Failure', () {
    test('same type and message are equal', () {
      expect(const NetworkFailure(), const NetworkFailure());
    });

    test('different types are not equal', () {
      expect(const NetworkFailure(), isNot(const AuthFailure()));
    });

    test('every failure has a user message', () {
      const failures = <Failure>[
        NetworkFailure(),
        AuthFailure(),
        PermissionFailure(),
        NotFoundFailure(),
        ValidationFailure(),
        AiFailure(),
        UnknownFailure(),
      ];

      for (final failure in failures) {
        expect(failure.userMessage, isNotEmpty);
      }
    });
  });
}
