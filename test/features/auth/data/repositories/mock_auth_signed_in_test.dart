// Tests for MockAuthRepository(startSignedIn: true).
// Run with: fvm flutter test test/features/auth/data/repositories/mock_auth_signed_in_test.dart

import 'package:brainly_life/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('by default the first event is signed out', () async {
    final first = await MockAuthRepository().authStateChanges().first;

    expect(first.isSuccess, isTrue);
    expect(first.dataOrNull, isNull);
  });

  test('startSignedIn: the first event is the demo user', () async {
    final first =
        await MockAuthRepository(startSignedIn: true).authStateChanges().first;

    expect(first.dataOrNull?.email, MockAuthRepository.demoEmail);
  });

  test('startSignedIn: signing out works', () async {
    final repository = MockAuthRepository(startSignedIn: true);
    final events = <String?>[];
    final subscription = repository
        .authStateChanges()
        .listen((result) => events.add(result.dataOrNull?.email));
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    await repository.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(events, [MockAuthRepository.demoEmail, null]);
  });
}