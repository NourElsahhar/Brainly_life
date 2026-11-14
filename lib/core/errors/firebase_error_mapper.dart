// FirebaseErrorMapper turns ANY error into a Failure (see failure.dart).
//
// Firebase throws exceptions with a text `code` (like 'permission-denied').
// Instead of every repository writing its own switch, everyone uses this one.
//
// Usage inside a repository:
//   try {
//     final tasks = await dataSource.getTasks();
//     return Result.success(tasks);
//   } catch (e) {
//     return Result.failure(FirebaseErrorMapper.map(e));
//   }
//
// What it does:
//   - FirebaseAuthException  -> sign-in related failures
//   - FirebaseException      -> Firestore / Storage / Functions failures
//   - no internet / timeout  -> NetworkFailure
//   - anything else          -> UnknownFailure
//
// The original Firebase code is kept in failure.code, so a Cubit can react to
// a special case, e.g. failure.code == 'requires-recent-login' means
// "ask the user to sign in again before deleting the account".
//
// The message shown to the user is always friendly. The raw Firebase message
// is never exposed.

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:firebase_core/firebase_core.dart';

import 'failure.dart';

class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static Failure map(Object error) {
    if (error is Failure) return error;
    // FirebaseAuthException is a kind of FirebaseException,
    // so it must be checked FIRST.
    if (error is FirebaseAuthException) return _fromAuth(error);
    if (error is FirebaseException) return _fromFirebase(error);
    if (error is SocketException || error is TimeoutException) {
      return const NetworkFailure();
    }
    return const UnknownFailure();
  }

  static Failure _fromAuth(FirebaseAuthException e) {
    final code = e.code;
    return switch (code) {
      'invalid-email' => ValidationFailure(
          userMessage: 'The email address is not valid.',
          code: code,
        ),
      'weak-password' => ValidationFailure(
          userMessage: 'The password is too weak. Please choose a stronger one.',
          code: code,
        ),
      // Newer Firebase versions return 'invalid-credential' for both
      // "wrong password" and "no such user" on purpose, so we show one message.
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' ||
      'invalid-login-credentials' =>
        AuthFailure(
          userMessage: 'Incorrect email or password.',
          code: code,
        ),
      'email-already-in-use' => AuthFailure(
          userMessage: 'This email is already registered. Try signing in.',
          code: code,
        ),
      'account-exists-with-different-credential' => AuthFailure(
          userMessage:
              'An account already exists with this email using another sign-in method.',
          code: code,
        ),
      'user-disabled' => AuthFailure(
          userMessage: 'This account has been disabled.',
          code: code,
        ),
      'requires-recent-login' => AuthFailure(
          userMessage: 'For your security, please sign in again to continue.',
          code: code,
        ),
      'too-many-requests' => AuthFailure(
          userMessage: 'Too many attempts. Please wait a bit and try again.',
          code: code,
        ),
      'operation-not-allowed' => AuthFailure(
          userMessage: 'This sign-in method is not available right now.',
          code: code,
        ),
      'network-request-failed' => NetworkFailure(code: code),
      _ => AuthFailure(code: code),
    };
  }

  static Failure _fromFirebase(FirebaseException e) {
    final code = e.code;
    return switch (code) {
      'permission-denied' || 'unauthorized' => PermissionFailure(code: code),
      'unauthenticated' => AuthFailure(code: code),
      'not-found' || 'object-not-found' => NotFoundFailure(code: code),
      'unavailable' ||
      'deadline-exceeded' ||
      'retry-limit-exceeded' =>
        NetworkFailure(code: code),
      'invalid-argument' || 'out-of-range' => ValidationFailure(code: code),
      _ => UnknownFailure(code: code),
    };
  }
}