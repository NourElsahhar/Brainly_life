import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:brainly_life/features/tasks/tasks_injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_creation_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_cubit.dart';

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
    test('registers TaskSummaryProvider (useMocks: $useMocks)', () async {
      registerTasksFeature(getIt, useMocks: useMocks);

      expect(getIt.isRegistered<TaskSummaryProvider>(), isTrue);
      final result = await getIt<TaskSummaryProvider>().todaySummary();
      expect(result.isSuccess, isTrue);
    });
    test('registers TaskCreationPort (useMocks: $useMocks)', () async {
      registerTasksFeature(getIt, useMocks: useMocks);

      final result = await getIt<TaskCreationPort>().createTask(
        const TaskDraft(title: 'From the AI'),
      );
      expect(result.isSuccess, isTrue);
    });
    test('registers TaskCategoryRepository (useMocks: $useMocks)', () async {
      registerTasksFeature(getIt, useMocks: useMocks);

      final result = await getIt<TaskCategoryRepository>()
          .watchCategories()
          .first;
      expect(result.dataOrNull, isNotEmpty);
    });
    test(
      'registers a new CategoryCubit each time (useMocks: $useMocks)',
      () async {
        registerTasksFeature(getIt, useMocks: useMocks);

        final first = getIt<CategoryCubit>();
        final second = getIt<CategoryCubit>();
        expect(identical(first, second), isFalse);
        await first.close();
        await second.close();
      },
    );
    test(
      'registers a new TaskFormCubit each time (useMocks: $useMocks)',
      () async {
        registerTasksFeature(getIt, useMocks: useMocks);

        final first = getIt<TaskFormCubit>();
        final second = getIt<TaskFormCubit>();
        expect(identical(first, second), isFalse);
        await first.close();
        await second.close();
      },
    );
  }
}
