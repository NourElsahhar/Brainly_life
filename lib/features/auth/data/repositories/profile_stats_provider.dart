// ProfileStatsProvider = the PORT that gives the 3 numbers on the Profile
// screen: the day streak, the hours studied and the tasks done.
//
// Why a port: those numbers belong to other features (habits, focus,
// tasks), and a feature must not import another feature. So Profile (M1)
// only knows this small interface. The owners write an adapter that
// implements it (like RepositoryTaskSummaryProvider does for Home), and
// auth_injection.dart registers it.
//
// Until then:
//   - mock mode -> MockProfileStatsProvider (12 days, 18 h, 42 tasks)
//   - real mode -> EmptyProfileStatsProvider (zeros)
//
// Usage:
//   final result = await provider.load();

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
