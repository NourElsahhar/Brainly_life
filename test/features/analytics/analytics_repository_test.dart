import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/analytics/data/datasources/analytics_remote_data_source.dart';
import 'package:brainly_life/features/analytics/data/repositories/firestore_analytics_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _DataSource extends Mock implements AnalyticsRemoteDataSource {}

void main() {
  test(
    'Returns an absent report and maps Firestore errors to safe failures',
    () async {
      final source = _DataSource();
      when(() => source.readReport('2026-W45')).thenAnswer((_) async => null);
      when(() => source.readReport('2026-W46')).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'internal details',
        ),
      );
      final repository = FirestoreAnalyticsRepository(source);
      expect((await repository.readReport('2026-W45')).isSuccess, isTrue);
      final result = await repository.readReport('2026-W46');
      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.userMessage,
        isNot(contains('internal details')),
      );
    },
  );
}
