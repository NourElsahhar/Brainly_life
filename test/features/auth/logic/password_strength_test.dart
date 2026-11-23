// Tests for PasswordStrength (weak / medium / strong) and validateNew.
// Run with: fvm flutter test test/features/auth/logic/password_strength_test.dart

import 'package:brainly_life/features/auth/logic/password_strength.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PasswordLevel level(String password) => PasswordStrength.of(password).level;

  test('empty password has no level and no bars', () {
    expect(level(''), PasswordLevel.none);
    expect(PasswordStrength.of('').bars, 0);
  });

  test('short passwords are always weak', () {
    expect(level('Ab1!'), PasswordLevel.weak);
    expect(level('Ab1!xyz'), PasswordLevel.weak);
  });

  test('only letters, or letters and numbers in one case, are weak', () {
    expect(level('password'), PasswordLevel.weak);
    expect(level('password123'), PasswordLevel.weak);
  });

  test('mixed case with a number is medium', () {
    expect(level('Password1'), PasswordLevel.medium);
    expect(PasswordStrength.of('Password1').bars, 2);
  });

  test('mixed case, number and symbol is strong', () {
    expect(level('Shahd2026!'), PasswordLevel.strong);
    expect(PasswordStrength.of('Shahd2026!').bars, 3);
  });

  test('long with everything fills the 4 bars', () {
    expect(PasswordStrength.of('MyStudyPlan2026!').bars, 4);
  });

  group('validateNew', () {
    String? validate(String value) =>
        PasswordStrength.validateNew(value, tooWeak: 'weak');

    test('empty is required', () {
      expect(validate(''), 'Password is required');
    });

    test('under 8 characters is refused', () {
      expect(validate('Ab1!'), 'Password must be at least 8 characters');
    });

    test('a weak password is refused', () {
      expect(validate('password123'), 'weak');
    });

    test('medium and strong are accepted', () {
      expect(validate('Password1'), isNull);
      expect(validate('Shahd2026!'), isNull);
    });
  });
}
