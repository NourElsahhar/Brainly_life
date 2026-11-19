// RouterAuthState = tells the router if the user is signed in.
// The router listens to it and redirects when it changes.
//
// AuthCubit (when it is ready) calls:
//   routerAuthState.update(AuthStatus.signedIn);
//   routerAuthState.update(AuthStatus.signedOut);
//
//   unknown    -> we are still checking (the splash screen is shown)
//   signedIn   -> the user is signed in
//   signedOut  -> the user must sign in

import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, signedIn, signedOut }

class RouterAuthState extends ChangeNotifier {
  RouterAuthState([AuthStatus status = AuthStatus.unknown]) : _status = status;

  AuthStatus _status;

  AuthStatus get status => _status;

  void update(AuthStatus status) {
    if (status == _status) return;
    _status = status;
    notifyListeners();
  }
}