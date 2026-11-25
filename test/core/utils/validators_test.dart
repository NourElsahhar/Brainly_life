// Tests for Validators.
// Run with: fvm flutter test test/core/utils/validators_test.dart

import 'package:brainly_life/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nonEmpty', () {
    test('rejects null, empty and spaces only', () {
      for (final value in [null, '', '   ']) {
        expect(Validators.nonEmpty(value), 'This field is required');
      }
    });

    test('uses the field name in the message', () {
      expect(Validators.nonEmpty('', fieldName: 'Title'), 'Title is required');
    });

    test('accepts any text', () {
      expect(Validators.nonEmpty('Read chapter 3'), isNull);
    });
  });

  group('email', () {
    test('accepts valid emails (spaces around are ignored)', () {
      for (final value in [
        'a@b.co',
        'name.last+tag@example.com',
        '  student@school.edu.eg  ',
      ]) {
        expect(Validators.email(value), isNull, reason: value);
      }
    });

    test('empty gives "required"', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email('  '), 'Email is required');
    });

    test('rejects wrong formats', () {
      for (final value in [
        'abc',
        'a@b',
        'a@b.',
        '@b.com',
        'a b@c.com',
        'a@b@c.com',
        'a@.com',
      ]) {
        expect(
          Validators.email(value),
          'Enter a valid email address',
          reason: value,
        );
      }
    });
  });

  group('password', () {
    test('rejects empty', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('needs at least 8 characters', () {
      expect(
        Validators.password('1234567'),
        'Password must be at least 8 characters',
      );
      expect(Validators.password('12345678'), isNull);
    });

    test('spaces count as characters (not trimmed)', () {
      expect(Validators.password('        '), isNull);
    });

    test('minLength can be changed', () {
      expect(
        Validators.password('12345', minLength: 6),
        'Password must be at least 6 characters',
      );
    });
  });

  group('confirmPassword', () {
    test('rejects empty', () {
      expect(
        Validators.confirmPassword('', 'secret123'),
        'Please confirm your password',
      );
      expect(
        Validators.confirmPassword(null, 'secret123'),
        'Please confirm your password',
      );
    });

    test('rejects a different password', () {
      expect(
        Validators.confirmPassword('secret124', 'secret123'),
        'Passwords do not match',
      );
    });

    test('accepts the same password', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('maxLength', () {
    test('rejects longer text and accepts the limit', () {
      expect(
        Validators.maxLength('abcd', 3, fieldName: 'Name'),
        'Name must be at most 3 characters',
      );
      expect(Validators.maxLength('abc', 3), isNull);
      expect(Validators.maxLength(null, 3), isNull);
    });

    test('ignores spaces at the ends', () {
      expect(Validators.maxLength('  abc  ', 3), isNull);
    });
  });

  group('lengthBetween', () {
    test('min 1 means required', () {
      expect(
        Validators.lengthBetween('  ', min: 1, max: 60, fieldName: 'Name'),
        'Name is required',
      );
    });

    test('min above 1 gives "at least"', () {
      expect(
        Validators.lengthBetween('ab', min: 3, max: 10, fieldName: 'Code'),
        'Code must be at least 3 characters',
      );
    });

    test('too long gives "at most"', () {
      expect(
        Validators.lengthBetween('a' * 61, min: 1, max: 60, fieldName: 'Name'),
        'Name must be at most 60 characters',
      );
    });

    test('accepts both limits', () {
      expect(Validators.lengthBetween('a', min: 1, max: 60), isNull);
      expect(Validators.lengthBetween('a' * 60, min: 1, max: 60), isNull);
    });
  });

  group('firstError', () {
    test('returns the first message', () {
      expect(Validators.firstError([null, 'first', 'second']), 'first');
    });

    test('returns null when everything is OK', () {
      expect(Validators.firstError([null, null]), isNull);
      expect(Validators.firstError(const []), isNull);
    });
  });
}
