// Tests for FirestoreFocusRepository with a fake data source (mocktail):
// sessions come back oldest first, missing settings are the defaults, and
// Firebase errors become Failures.

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_remote_data_source.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/firestore_focus_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements FocusRemoteDataSource {}

void main() {
  late _MockDataSource dataSource;
  late FirestoreFocusRepository repository;

  FocusSession session(String id, int hour) {
    final start = DateTime.utc(2026, 11, 25, hour);
    return FocusSession(
      id: id,
      type: FocusSessionType.focus,
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 25)),
      plannedMinutes: 25,
      actualMinutes: 25,
      completed: true,
      dateKey: '2026-11-25',
      createdAt: start,
      updatedAt: start,
    );
  }

  setUp(() {
    dataSource = _MockDataSource();
    repository = FirestoreFocusRepository(dataSource: dataSource);
  });

  test('sessions come back oldest first', () async {
    when(
      () =>
          dataSource.getSessions(fromDate: '2026-11-25', toDate: '2026-11-25'),
    ).thenAnswer((_) async => [session('late', 18), session('early', 8)]);

    final result = await repository.getSessions(
      fromDate: '2026-11-25',
      toDate: '2026-11-25',
    );

    expect(result.dataOrNull!.map((s) => s.id), ['early', 'late']);
  });

  test('no saved settings means the defaults', () async {
    when(() => dataSource.getSettings()).thenAnswer((_) async => null);

    final result = await repository.getSettings();

    expect(result.dataOrNull, const FocusSettings());
  });

  test('a Firebase error becomes a Failure', () async {
    when(() => dataSource.getSettings()).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );

    final result = await repository.getSettings();

    expect(result, isA<Failed<FocusSettings>>());
  });
}
