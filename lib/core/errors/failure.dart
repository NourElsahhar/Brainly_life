// Failure = "something went wrong", described in a way the UI can show.
//
// Repositories never throw errors to the Cubits. When something fails they
// return a Failure inside a Result (see result.dart).
//
// Every Failure has:
//   - userMessage: a safe, friendly text the screen can show to the user.
//                  Never show raw exception text to the user.
//   - code: an optional technical code (for logs and debugging only).
//
// Usage:
//   return Result.failure(const NetworkFailure());
//   return Result.failure(const ValidationFailure(userMessage: 'Title is required'));
//
// Need a new kind of failure? Add a small class at the bottom of this file
// (and tell M1 in the PR).

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({required this.userMessage, this.code});

  final String userMessage;
  final String? code;

  @override
  List<Object?> get props => [userMessage, code];
}

/// No internet, timeout, or the server could not be reached.
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.userMessage =
        'No internet connection. Please check your network and try again.',
    super.code,
  });
}

/// Sign-in problems: wrong password, expired session, user not found...
class AuthFailure extends Failure {
  const AuthFailure({
    super.userMessage = 'Authentication failed. Please sign in again.',
    super.code,
  });
}

/// The user is not allowed to read or write this data (Firestore rules).
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.userMessage = 'You do not have permission to do this.',
    super.code,
  });
}

/// The document or item does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.userMessage = 'We could not find what you were looking for.',
    super.code,
  });
}

/// The data entered by the user is not valid.
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.userMessage = 'Some of the information you entered is not valid.',
    super.code,
  });
}

/// Problems with AI features. M5 can extend this class for each gateway
/// error code (rate_limited, provider_unavailable, ...).
class AiFailure extends Failure {
  const AiFailure({
    super.userMessage =
        'The AI service is not available right now. Please try again later.',
    super.code,
  });
}

/// Anything we did not expect. Used as the last fallback.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.userMessage = 'Something went wrong. Please try again.',
    super.code,
  });
}