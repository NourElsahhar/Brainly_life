// Dependency injection for the home feature (owner: M3).
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

import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/home/data/repositories/mock_home_summary_providers.dart';
import 'package:brainly_life/features/home/logic/home_cubit.dart';
import 'package:get_it/get_it.dart';

void registerHomeFeature(GetIt getIt, {required bool useMocks}) {
  // Every card uses its owner's real provider once they register it.
  // Until then the card shows the mock's sample data.
  // This runs when the Home screen opens, after every feature registered.
  getIt.registerFactory(
    () => HomeCubit(
      tasks: _realOrMock<TaskSummaryProvider>(
        getIt,
        MockTaskSummaryProvider.new,
      ),
      study: _realOrMock<StudySummaryProvider>(
        getIt,
        MockStudySummaryProvider.withSampleData,
      ),
      habits: _realOrMock<HabitSummaryProvider>(
        getIt,
        MockHabitSummaryProvider.new,
      ),
      focus: _realOrMock<FocusSummaryProvider>(
        getIt,
        MockFocusSummaryProvider.new,
      ),
      tip: _realOrMock<AiTipProvider>(getIt, MockAiTipProvider.new),
    ),
  );
}

/// The registered provider, or the mock when its owner hasn't added it yet.
T _realOrMock<T extends Object>(GetIt getIt, T Function() mock) {
  return getIt.isRegistered<T>() ? getIt<T>() : mock();
}
