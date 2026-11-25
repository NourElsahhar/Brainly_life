// ProfileStatsProvider = the PORT that gives the 3 numbers on the Profile
// screen: the day streak, the hours studied and the tasks done.
//
// Why a port: those numbers belong to other features (habits, focus,
// tasks), and a feature must not import another feature. So Profile (M1)
// only knows this small interface. The owners write an adapter that
// implements it (like RepositoryTaskSummaryProvider does for Home), and
// auth_injection.dart registers it.
//
// Each owner registers ONE small source for its number:
//   - habits (M4) -> ProfileStreakSource   (best current streak)
//   - focus  (M4) -> ProfileStudySource    (all focus minutes)
//   - tasks  (M3) -> ProfileTasksSource    (completed tasks)
// CombinedProfileStatsProvider reads the sources that are registered and
// shows 0 for a missing one (or one that fails).
//
//   - mock mode -> MockProfileStatsProvider (12 days, 18 h, 42 tasks)
//   - real mode -> CombinedProfileStatsProvider
//
// Usage:
//   final result = await provider.load();

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/errors/result.dart';
import 'package:equatable/equatable.dart';

class ProfileStats extends Equatable {
  const ProfileStats({
    required this.streakDays,
    required this.studiedMinutes,
    required this.tasksDone,
  });

  static const empty = ProfileStats(
    streakDays: 0,
    studiedMinutes: 0,
    tasksDone: 0,
  );

  /// Days in a row with activity (from habits / focus).
  final int streakDays;

  /// Total focus/study time, in minutes. The screen shows hours.
  final int studiedMinutes;

  /// Completed tasks (all time).
  final int tasksDone;

  @override
  List<Object?> get props => [streakDays, studiedMinutes, tasksDone];
}

abstract interface class ProfileStatsProvider {
  Future<Result<ProfileStats>> load();
}

/// Real mode until the habits/focus/tasks adapters are written: zeros.
class EmptyProfileStatsProvider implements ProfileStatsProvider {
  const EmptyProfileStatsProvider();

  @override
  Future<Result<ProfileStats>> load() async =>
      const Result.success(ProfileStats.empty);
}

/// Mock mode: the numbers of the design.
class MockProfileStatsProvider implements ProfileStatsProvider {
  const MockProfileStatsProvider();

  @override
  Future<Result<ProfileStats>> load() async => const Result.success(
    ProfileStats(streakDays: 12, studiedMinutes: 18 * 60, tasksDone: 42),
  );
}

/// The day streak shown on Profile (owner: habits).
abstract interface class ProfileStreakSource {
  Future<Result<int>> streakDays();
}

/// The total focus/study minutes shown on Profile (owner: focus).
abstract interface class ProfileStudySource {
  Future<Result<int>> studiedMinutes();
}

/// The number of completed tasks shown on Profile (owner: tasks).
abstract interface class ProfileTasksSource {
  Future<Result<int>> tasksDone();
}

/// Real mode: asks every registered source. A missing or failing source
/// shows 0, so one broken number never hides the other two.
///
/// The sources are read through functions because the other features
/// register them AFTER auth.
class CombinedProfileStatsProvider implements ProfileStatsProvider {
  CombinedProfileStatsProvider({
    required ProfileStreakSource? Function() streak,
    required ProfileStudySource? Function() study,
    required ProfileTasksSource? Function() tasks,
  }) : _streak = streak,
       _study = study,
       _tasks = tasks;

  final ProfileStreakSource? Function() _streak;
  final ProfileStudySource? Function() _study;
  final ProfileTasksSource? Function() _tasks;

  @override
  Future<Result<ProfileStats>> load() async {
    final values = await Future.wait([
      _read(() => _streak()?.streakDays()),
      _read(() => _study()?.studiedMinutes()),
      _read(() => _tasks()?.tasksDone()),
    ]);
    return Result.success(
      ProfileStats(
        streakDays: values[0],
        studiedMinutes: values[1],
        tasksDone: values[2],
      ),
    );
  }

  /// Calls the source inside try, so even an error thrown right away
  /// shows 0 instead of breaking the Profile screen.
  static Future<int> _read(Future<Result<int>>? Function() call) async {
    try {
      final future = call();
      if (future == null) return 0;
      return (await future).dataOrNull ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
