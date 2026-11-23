// Tests for OnboardingStore: it starts as "not seen", remembers after
// markSeen (even in a new store, like after closing the app), and an empty
// phone (fresh install) shows it again.

import 'package:brainly_life/features/auth/data/repositories/onboarding_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('starts as not seen', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsOnboardingStore();
    await store.load();
    expect(store.hasSeen, isFalse);
  });

  test('remembers after markSeen, also in a new store', () async {
    SharedPreferences.setMockInitialValues({});
    final first = SharedPrefsOnboardingStore();
    await first.load();
    await first.markSeen();
    expect(first.hasSeen, isTrue);

    // The app was closed and opened again.
    final second = SharedPrefsOnboardingStore();
    await second.load();
    expect(second.hasSeen, isTrue);
  });

  test('a fresh install (empty storage) shows it again', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsOnboardingStore();
    await store.load();
    expect(store.hasSeen, isFalse);
  });
}
