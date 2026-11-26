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
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_form_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_cubit.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_cubit.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_task_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_profile_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void registerTasksFeature(GetIt getIt, {required bool useMocks}) {
  // Mock mode: sample tasks in memory. Real mode: users/{uid}/tasks and
  // users/{uid}/taskCategories in Firestore (one data source for both).
  getIt.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSource(
      auth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<TaskRepository>(
    () => useMocks
        ? MockTaskRepository.withSampleData()
        : FirestoreTaskRepository(dataSource: getIt()),
  );
  getIt.registerLazySingleton<TaskCategoryRepository>(
    () => useMocks
        ? MockTaskCategoryRepository.withSampleData()
        : FirestoreTaskCategoryRepository(dataSource: getIt()),
  );
  // The "Today's tasks" card on Home. It reads TaskRepository, so it works
  // the same with the mock and with Firestore.
  getIt.registerLazySingleton<TaskSummaryProvider>(
    () => RepositoryTaskSummaryProvider(getIt()),
  );
  // The "tasks done" number on the Profile (M1's port).
  getIt.registerLazySingleton<ProfileTasksSource>(
    () => useMocks
        ? const MockTaskProfileSource()
        : FirestoreTaskProfileSource(dataSource: getIt()),
  );
  // Lets other features (M5's AI assistant) create tasks.
  getIt.registerLazySingleton<TaskCreationPort>(
    () => RepositoryTaskCreationPort(getIt()),
  );
  // Cubits: a new one for every screen.
  getIt.registerFactory(() => TaskListCubit(getIt()));
  getIt.registerFactory(() => CompletedTasksCubit(getIt()));
  getIt.registerFactory(() => CategoryCubit(getIt(), getIt()));
  getIt.registerFactory(() => TaskFormCubit(getIt()));
  getIt.registerFactory(() => TaskDetailCubit(getIt()));
}
