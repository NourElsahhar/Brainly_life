// OnboardingStore remembers if the onboarding was already shown on this
// phone. The flag is saved the first time the onboarding appears, so closing
// and reopening the app never shows it again. Uninstalling the app clears it,
// so a fresh install shows the onboarding again.
//
// Call load() once before the router starts (it is async). After that,
// hasSeen is a plain getter, so the router redirect can read it.

// ignore_for_file: prefer_initializing_formals

import 'package:shared_preferences/shared_preferences.dart';

abstract class OnboardingStore {
  /// True once the onboarding was shown on this phone. Valid after [load].
  bool get hasSeen;

  Future<void> load();

  /// Remembers that the onboarding was shown.
  Future<void> markSeen();
}

class SharedPrefsOnboardingStore implements OnboardingStore {
  static const String _key = 'onboarding_seen';

  bool _seen = false;

  @override
  bool get hasSeen => _seen;

  @override
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seen = prefs.getBool(_key) ?? false;
    } catch (_) {
      // If the phone storage fails, do not block the user with onboarding.
      _seen = true;
    }
  }

  @override
  Future<void> markSeen() async {
    _seen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // The flag only lives in memory this time. The app still works.
    }
  }
}

/// In-memory version, for tests and mock mode.
class MockOnboardingStore implements OnboardingStore {
  MockOnboardingStore({bool seen = false}) : _seen = seen;

  bool _seen;

  @override
  bool get hasSeen => _seen;

  @override
  Future<void> load() async {}

  @override
  Future<void> markSeen() async => _seen = true;
}
