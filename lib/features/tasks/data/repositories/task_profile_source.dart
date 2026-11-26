// The tasks side of the Profile "tasks done" number (owner: M3).
// ProfileTasksSource is M1's port (auth feature); auth_injection.dart picks
// it up when tasks_injection.dart registers it.
//
//   real mode -> FirestoreTaskProfileSource: counts the done tasks, all
//                time (not only the last 30 days of the Completed tab)
//   mock mode -> MockTaskProfileSource: a fixed number

import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_results.dart';

class FirestoreTaskProfileSource
    with FirestoreResults
    implements ProfileTasksSource {
  FirestoreTaskProfileSource({required this._dataSource});

  final TaskRemoteDataSource _dataSource;

  @override
  Future<Result<int>> tasksDone() =>
      runSafely('Count done tasks', _dataSource.countDoneTasks);
}

class MockTaskProfileSource implements ProfileTasksSource {
  const MockTaskProfileSource({this.count = 42});

  final int count;

  @override
  Future<Result<int>> tasksDone() async => Result.success(count);
}
