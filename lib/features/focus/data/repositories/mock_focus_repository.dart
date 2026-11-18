import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';

/// In-memory [FocusRepository] for development and tests.
class MockFocusRepository implements FocusRepository {
  MockFocusRepository({
    List<FocusSession> sessions = const [],
    FocusSettings settings = const FocusSettings(),
  }) : _sessions = {for (final session in sessions) session.id: session},
       // ignore: prefer_initializing_formals
       _settings = settings;

  /// A repository filled with a few sample sessions.
  factory MockFocusRepository.withSampleData() {
    FocusSession sample(String id, String day, int hour, int minutes) {
      final start = DateTime.utc(2026, 11, int.parse(day.substring(8)), hour);
      return FocusSession(
        id: id,
        type: FocusSessionType.focus,
        startedAt: start,
        endedAt: start.add(Duration(minutes: minutes)),
        plannedMinutes: 25,
        actualMinutes: minutes,
        completed: minutes >= 25,
        dateKey: day,
        createdAt: start,
        updatedAt: start,
      );
    }

    return MockFocusRepository(
      sessions: [
        sample('sample_1', '2026-11-13', 9, 25),
        sample('sample_2', '2026-11-14', 10, 25),
        sample('sample_3', '2026-11-14', 15, 12),
      ],
    );
  }

  final Map<String, FocusSession> _sessions;
  FocusSettings _settings;
  int _counter = 0;

  @override
  Future<Result<FocusSession>> saveSession(FocusSession session) async {
    var saved = session;
    if (session.id.isEmpty) {
      _counter++;
      saved = session.copyWith(id: 'mock_focus_$_counter');
    }
    _sessions[saved.id] = saved;
    return Result.success(saved);
  }

  @override
  Future<Result<List<FocusSession>>> getSessions({
    required String fromDate,
    required String toDate,
  }) async {
    final sessions =
        _sessions.values
            .where(
              (session) =>
                  session.dateKey.compareTo(fromDate) >= 0 &&
                  session.dateKey.compareTo(toDate) <= 0,
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return Result.success(sessions);
  }

  @override
  Future<Result<FocusSettings>> getSettings() async {
    return Result.success(_settings);
  }

  @override
  Future<Result<void>> saveSettings(FocusSettings settings) async {
    _settings = settings;
    return const Result.success(null);
  }
}
