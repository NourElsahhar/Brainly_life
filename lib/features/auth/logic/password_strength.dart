// PasswordStrength = how strong a new password is: weak, medium or strong.
// Used by the strength bar on Register, and to refuse weak passwords.
//
// How the score is counted (1 point each):
//   - 8 characters or more
//   - 12 characters or more
//   - small AND capital letters
//   - a number
//   - a symbol (anything that is not a letter or a number, like ! @ #)
//
//   score 0-2 -> weak    (1 bar,  red)
//   score 3   -> medium  (2 bars, orange)
//   score 4   -> strong  (3 bars, green)
//   score 5   -> strong  (4 bars, green)
// A password shorter than 8 characters is always weak.
//
// Usage:
//   final strength = PasswordStrength.of('Shahd2026!');
//   strength.level   // PasswordLevel.strong
//   strength.bars    // 4
//
// Real life: like a padlock. A 3-digit lock is weak, a long code with
// letters and numbers takes a thief much longer to guess.

enum PasswordLevel { none, weak, medium, strong }

class PasswordStrength {
  const PasswordStrength._(this.level, this.bars);

  /// The level, or PasswordLevel.none for an empty password.
  final PasswordLevel level;

  /// How many of the 4 bars are filled (0 to 4).
  final int bars;

  static const int minLength = 8;
  static const int maxBars = 4;

  static final RegExp _lower = RegExp('[a-z]');
  static final RegExp _upper = RegExp('[A-Z]');
  static final RegExp _digit = RegExp('[0-9]');
  static final RegExp _symbol = RegExp(r'[^A-Za-z0-9]');

  static PasswordStrength of(String password) {
    if (password.isEmpty) return const PasswordStrength._(PasswordLevel.none, 0);

    var score = 0;
    if (password.length >= minLength) score++;
    if (password.length >= 12) score++;
    if (_lower.hasMatch(password) && _upper.hasMatch(password)) score++;
    if (_digit.hasMatch(password)) score++;
    if (_symbol.hasMatch(password)) score++;

    if (password.length < minLength || score <= 2) {
      return const PasswordStrength._(PasswordLevel.weak, 1);
    }
    if (score == 3) return const PasswordStrength._(PasswordLevel.medium, 2);
    if (score == 4) return const PasswordStrength._(PasswordLevel.strong, 3);
    return const PasswordStrength._(PasswordLevel.strong, maxBars);
  }

  /// The error for a NEW password (Register), or null when it is OK.
  /// It must have 8+ characters and must not be weak.
  static String? validateNew(String password, {required String tooWeak}) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (of(password).level == PasswordLevel.weak) return tooWeak;
    return null;
  }
}
