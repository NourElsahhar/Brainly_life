// RouterAuthState = tells the router three things:
//   1) is the user signed in?               (status)
//   2) has the splash screen finished?      (splashDone)
//   3) was the onboarding already shown?    (onboardingSeen)
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
// The real app uses RouterAuthState.app(): it waits for the splash and asks
// OnboardingStore if the onboarding was already shown.
// RouterAuthState() and RouterAuthState.withSplash() are for tests.

// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, signedIn, signedOut }

class RouterAuthState extends ChangeNotifier {
  RouterAuthState([AuthStatus status = AuthStatus.unknown])
    : _status = status,
      _splashDone = true,
      _hasSeenOnboarding = _alwaysSeen;

  /// Waits for the splash animation (splash screen calls finishSplash()).
  RouterAuthState.withSplash([AuthStatus status = AuthStatus.unknown])
    : _status = status,
      _splashDone = false,
      _hasSeenOnboarding = _alwaysSeen;

  /// The real app: splash + onboarding.
  /// [hasSeenOnboarding] is read every time the router decides where to go.
  RouterAuthState.app({
    required bool Function() hasSeenOnboarding,
    AuthStatus status = AuthStatus.unknown,
    bool splashDone = false,
  }) : _status = status,
       _splashDone = splashDone,
       _hasSeenOnboarding = hasSeenOnboarding;

  static bool _alwaysSeen() => true;

  AuthStatus _status;
  bool _splashDone;
  final bool Function() _hasSeenOnboarding;

  AuthStatus get status => _status;

  /// True when the splash animation has finished.
  bool get splashDone => _splashDone;

  /// True if the onboarding was already shown on this phone.
  bool get onboardingSeen => _hasSeenOnboarding();

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
