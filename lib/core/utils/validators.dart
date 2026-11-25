// Validators = ready-made checks for form fields.
//
// Every validator returns:
//   - null            -> the value is OK
//   - a text message  -> the problem, ready to show UNDER the field
//
// That is exactly what AppTextField's errorText wants.
//
// Usage in a Cubit:
//   final emailError = Validators.email(email);          // String? (null = OK)
//   if (emailError != null) { emit(state.copyWith(emailError: emailError)); return; }
//
// Several checks on one field: the first problem wins.
//   Validators.firstError([
//     Validators.nonEmpty(name, fieldName: 'Name'),
//     Validators.maxLength(name, 60, fieldName: 'Name'),
//   ]);
//
// Text lengths (title 1-100, name 1-60...) in one call:
//   Validators.lengthBetween(title, min: 1, max: 100, fieldName: 'Title');
//
// Rules:
//   - Text is trimmed before checking (spaces at the ends do not count).
//     Passwords are NOT trimmed.
//   - Validators only check. They never throw and never change the value.
//   - The app validates, and the Firestore rules validate again. Both are needed.

class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// The field must not be empty.
  static String? nonEmpty(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// A valid email address, like name@example.com.
  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// A password of at least [minLength] characters (8 by default).
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// The confirmation must be the same as the [original] password.
  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  /// The text must have at most [max] characters.
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'This field',
  }) {
    if ((value?.trim().length ?? 0) > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  /// The text must have between [min] and [max] characters.
  /// With min: 1 it also means "required".
  static String? lengthBetween(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'This field',
  }) {
    final length = value?.trim().length ?? 0;
    if (length < min) {
      return min <= 1
          ? '$fieldName is required'
          : '$fieldName must be at least $min characters';
    }
    if (length > max) return '$fieldName must be at most $max characters';
    return null;
  }

  /// The first message that is not null, or null if everything is OK.
  static String? firstError(Iterable<String?> results) {
    for (final result in results) {
      if (result != null) return result;
    }
    return null;
  }
}
