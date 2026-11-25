// Decides what the router should think ("signed in?"), from the AuthCubit
// state. app.dart calls it every time the AuthCubit state changes.
//
//   Authenticated   -> signedIn
//   Unauthenticated -> signedOut
//   AuthError       -> signedOut, but only while we were still "unknown"
//                      (for example the profile could not be loaded at start).
//                      After that an error never changes where the user is.
//   everything else -> no change

import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';

AuthStatus authStatusFor(AuthState state, AuthStatus current) {
  return switch (state) {
    AuthInitial() => current,
    AuthLoading() => current,
    AuthPasswordResetSent() => current,
    Authenticated() => AuthStatus.signedIn,
    Unauthenticated() => AuthStatus.signedOut,
    AuthError() =>
      current == AuthStatus.unknown ? AuthStatus.signedOut : current,
  };
}
