// Dependency injection for the tasks feature (owner: M3).
// injection.dart calls this function once when the app starts.
//
// Register here: repositories, data sources, services and Cubits.
//   - Repositories and data sources: registerLazySingleton (one copy for the app)
//   - Cubits: registerFactory (a new one for every screen)
//   - useMocks is true when the app runs with --dart-define=USE_MOCKS=true.
//     Then register the Mock repository instead of the Firestore one.
//
// Example:
//   getIt.registerLazySingleton<TaskRepository>(
//     () => useMocks ? MockTaskRepository() : FirestoreTaskRepository(getIt()),
//   );
//   getIt.registerFactory(() => TaskListCubit(getIt()));
//
// Ready to use from getIt: FirebaseAuth, FirebaseFirestore, FirebaseFunctions.
// Other features' contracts (like TaskSummaryProvider) are registered by their
// own owner. Ask for them with getIt<TaskSummaryProvider>().

import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/repository_task_summary_provider.dart';
import 'package:brainly_life/features/tasks/data/repositories/repository_task_creation_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_creation_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_category_repository.dart';

void registerTasksFeature(GetIt getIt, {required bool useMocks}) {
  // FirestoreTaskRepository is not ready yet, so both modes use the mock
  // with sample data for now. When it is ready, this becomes:
  //   () => useMocks
  //       ? MockTaskRepository.withSampleData()
  //       : FirestoreTaskRepository(getIt()),
  getIt.registerLazySingleton<TaskRepository>(
    () => MockTaskRepository.withSampleData(),
  );
  // Same as TaskRepository: the mock in both modes until the Firestore one
  // is ready.
  getIt.registerLazySingleton<TaskCategoryRepository>(
    () => MockTaskCategoryRepository.withSampleData(),
  );
  // The "Today's tasks" card on Home. It reads TaskRepository, so it works
  // the same with the mock and with Firestore.
  getIt.registerLazySingleton<TaskSummaryProvider>(
    () => RepositoryTaskSummaryProvider(getIt()),
  );
  // Lets other features (M5's AI assistant) create tasks.
  getIt.registerLazySingleton<TaskCreationPort>(
    () => RepositoryTaskCreationPort(getIt()),
  );
}
