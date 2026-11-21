// RouterAuthState = tells the router two things:
//   1) is the user signed in?   (status)
//   2) has the splash screen finished its animation?  (splashDone)
// The router listens to it and redirects when it changes.
//
// AuthCubit (through app.dart) calls:
//   routerAuthState.update(AuthStatus.signedIn);
//   routerAuthState.update(AuthStatus.signedOut);
//
//   unknown    -> we are still checking (the splash screen is shown)
//   signedIn   -> the user is signed in
//   signedOut  -> the user must sign in
//
// The app starts with RouterAuthState.withSplash(): the splash screen stays
// until it calls finishSplash(), even if we already know the user.
// RouterAuthState() (no splash wait) is used in tests.

import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, signedIn, signedOut }

class RouterAuthState extends ChangeNotifier {
  RouterAuthState([AuthStatus status = AuthStatus.unknown])
      : _status = status,
        _splashDone = true;

  /// For the real app: wait for the splash animation to finish.
  RouterAuthState.withSplash([AuthStatus status = AuthStatus.unknown])
      : _status = status,
        _splashDone = false;

  AuthStatus _status;
  bool _splashDone;

  AuthStatus get status => _status;

  /// True when the splash animation has finished.
  bool get splashDone => _splashDone;

  void update(AuthStatus status) {
    if (status == _status) return;
    _status = status;
    notifyListeners();
  }

  /// Called by the splash screen when its animation ends.
  void finishSplash() {
    if (_splashDone) return;
    _splashDone = true;
    notifyListeners();
  }
}