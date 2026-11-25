// Tests for authStatusFor.
// Run with: fvm flutter test test/features/auth/logic/auth_status_mapper_test.dart

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/features/auth/data/models/user_profile_model.dart';
import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/auth/logic/auth_status_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = UserProfile(
    uid: 'u1',
    email: 'a@b.com',
    createdAt: DateTime.utc(2026, 1, 1),
    settings: UserSettings.defaults(),
  );

  test('Authenticated means signed in, from any status', () {
    for (final current in AuthStatus.values) {
      expect(
        authStatusFor(Authenticated(profile), current),
        AuthStatus.signedIn,
      );
    }
  });

  test('Unauthenticated means signed out, from any status', () {
    for (final current in AuthStatus.values) {
      expect(
        authStatusFor(const Unauthenticated(), current),
        AuthStatus.signedOut,
      );
    }
  });

  test('Initial, Loading and PasswordResetSent change nothing', () {
    const states = <AuthState>[
      AuthInitial(),
      AuthLoading(),
      AuthPasswordResetSent(),
    ];

    for (final state in states) {
      for (final current in AuthStatus.values) {
        expect(authStatusFor(state, current), current);
      }
    }
  });

  group('AuthError', () {
    const error = AuthError(NetworkFailure());

    test('while unknown it sends the user to sign in', () {
      expect(authStatusFor(error, AuthStatus.unknown), AuthStatus.signedOut);
    });

    test('later it never moves the user', () {
      expect(authStatusFor(error, AuthStatus.signedIn), AuthStatus.signedIn);
      expect(authStatusFor(error, AuthStatus.signedOut), AuthStatus.signedOut);
    });
  });
}
