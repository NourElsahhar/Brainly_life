import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/focus/data/models/focus_session_model.dart';
import 'package:brainly_life/features/focus/data/models/focus_settings_model.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/core/utils/utils.dart';
import 'package:clock/clock.dart';

/// In-memory [FocusRepository] for development and tests.
class MockFocusRepository implements FocusRepository {
  MockFocusRepository({
    List<FocusSession> sessions = const [],
    FocusSettings settings = const FocusSettings(),
  }) : _sessions = {for (final session in sessions) session.id: session},
       // ignore: prefer_initializing_formals
       _settings = settings;

  /// A repository filled with a few sample sessions.
  /// A repository filled with sample focus sessions of the last 7 days
  /// (relative to today), so the statistics always have something to show.
  factory MockFocusRepository.withSampleData() {
    final now = clock.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    FocusSession sample(String id, int daysAgo, int hour, int minutes) {
      final start = today
          .subtract(Duration(days: daysAgo))
          .add(Duration(hours: hour));
      return FocusSession(
        id: id,
        type: FocusSessionType.focus,
        startedAt: start,
        endedAt: start.add(Duration(minutes: minutes)),
        plannedMinutes: 25,
        actualMinutes: minutes,
        completed: minutes >= 25,
        dateKey: DateKeyUtils.toDateKey(start, timezone: 'UTC'),
        createdAt: start,
        updatedAt: start,
      );
    }

    return MockFocusRepository(
      sessions: [
        sample('sample_today_1', 0, 8, 25),
        sample('sample_today_2', 0, 10, 25),
        sample('sample_1', 1, 20, 50),
        sample('sample_2', 2, 19, 25),
        sample('sample_3', 3, 9, 25),
        sample('sample_4', 3, 15, 12),
        sample('sample_5', 4, 18, 50),
        sample('sample_6', 5, 19, 25),
        sample('sample_7', 6, 20, 25),
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
