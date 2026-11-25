// Tests for injection.dart.
// Run with: fvm flutter test test/injection_test.dart

import 'package:brainly_life/core/constants/app_config.dart';
import 'package:brainly_life/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => getIt.reset());

  group('configureDependencies', () {
    test('registers the Firebase services without creating them', () async {
      await configureDependencies(useMocks: true);

      expect(getIt.isRegistered<FirebaseAuth>(), isTrue);
      expect(getIt.isRegistered<FirebaseFirestore>(), isTrue);
      expect(getIt.isRegistered<FirebaseFunctions>(), isTrue);
    });

    test('can run more than once', () async {
      await configureDependencies(useMocks: true);
      await configureDependencies(useMocks: false);

      expect(getIt.isRegistered<FirebaseAuth>(), isTrue);
    });
  });

  group('AppConfig', () {
    test('mocks are off unless USE_MOCKS is set', () {
      expect(AppConfig.useMocks, isFalse);
    });
  });
}
