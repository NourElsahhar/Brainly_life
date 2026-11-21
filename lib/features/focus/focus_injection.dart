// Dependency injection for the focus feature (owner: M4).
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

import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_cubit.dart';
import 'package:get_it/get_it.dart';

void registerFocusFeature(GetIt getIt, {required bool useMocks}) {
  // The Firestore repository comes in Phase 3. Until then the mock is used
  // in both modes.
  getIt.registerLazySingleton<FocusRepository>(() => MockFocusRepository());

  getIt.registerFactory(
    () => FocusSettingsCubit(repository: getIt<FocusRepository>()),
  );
}
