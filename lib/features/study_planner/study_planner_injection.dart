// Dependency injection for the study_planner feature (owner: M2).
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

import 'package:get_it/get_it.dart';

void registerStudyPlannerFeature(GetIt getIt, {required bool useMocks}) {
  // Nothing to register yet.
}
