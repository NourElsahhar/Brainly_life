// FirestoreFocusRepository = the real FocusRepository (owner: M4).
// The Firestore calls are in FocusRemoteDataSource; every exception becomes
// a Result.failure with a friendly message (FirebaseErrorMapper).

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/firebase_error_mapper.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_remote_data_source.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';

class FirestoreFocusRepository implements FocusRepository {
  FirestoreFocusRepository({required FocusRemoteDataSource dataSource})
    : _dataSource = dataSource;

  final FocusRemoteDataSource _dataSource;

  @override
  Future<Result<FocusSession>> saveSession(FocusSession session) =>
      _run('Save focus session', () => _dataSource.saveSession(session));

  @override
  Future<Result<List<FocusSession>>> getSessions({
    required String fromDate,
    required String toDate,
  }) => _run('Load focus sessions', () async {
    final sessions = await _dataSource.getSessions(
      fromDate: fromDate,
      toDate: toDate,
    );
    // Oldest first (the contract).
    return sessions..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  });

  @override
  Future<Result<FocusSettings>> getSettings() => _run(
    'Load focus settings',
    () async => await _dataSource.getSettings() ?? const FocusSettings(),
  );

  @override
  Future<Result<void>> saveSettings(FocusSettings settings) =>
      _run('Save focus settings', () => _dataSource.saveSettings(settings));

  Future<Result<T>> _run<T>(String name, Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } catch (error) {
      final failure = FirebaseErrorMapper.map(error);
      AppLogger.warning(
        '$name failed (${failure.code ?? failure.runtimeType})',
        tag: 'Focus',
      );
      return Result.failure(failure);
    }
  }
}
