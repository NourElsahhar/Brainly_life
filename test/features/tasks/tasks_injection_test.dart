import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/tasks_injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late GetIt getIt;

  setUp(() => getIt = GetIt.asNewInstance());

  tearDown(() => getIt.reset());

  for (final useMocks in [true, false]) {
    test('registers TaskRepository (useMocks: $useMocks)', () async {
      registerTasksFeature(getIt, useMocks: useMocks);

      expect(getIt.isRegistered<TaskRepository>(), isTrue);
      final result = await getIt<TaskRepository>().watchActiveTasks().first;
      expect(result.dataOrNull, isNotEmpty);
    });
  }
}
