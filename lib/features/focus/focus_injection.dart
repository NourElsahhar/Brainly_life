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

import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/focus/data/datasources/focus_timer_local_data_source.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_repository.dart';
import 'package:brainly_life/features/focus/data/repositories/focus_summary_provider.dart';
import 'package:brainly_life/features/focus/data/repositories/mock_focus_repository.dart';
import 'package:brainly_life/features/focus/logic/focus_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_settings_cubit.dart';
import 'package:brainly_life/features/focus/logic/focus_stats_cubit.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_session_completion_port.dart';
import 'package:get_it/get_it.dart';

/// The settings of the signed-in user (timezone, week start day), or the
/// defaults when nobody is signed in yet.
/// replace with a shared settings contract when it exists.
UserSettings _userSettings(GetIt getIt) {
  final state = getIt<AuthCubit>().state;
  return state is Authenticated ? state.user.settings : UserSettings.defaults();
}

void registerFocusFeature(GetIt getIt, {required bool useMocks}) {
  // The Firestore repository comes in Phase 3. Until then the mock (with
  // sample sessions of the last days) is used in both modes.
  getIt.registerLazySingleton<FocusRepository>(
    () => MockFocusRepository.withSampleData(),
  );
  getIt.registerLazySingleton<FocusTimerLocalDataSource>(
    () => SharedPrefsFocusTimerLocalDataSource(),
  );

  // The "Focus" card on Home.
  getIt.registerLazySingleton<FocusSummaryProvider>(
    () => DefaultFocusSummaryProvider(
      repository: getIt<FocusRepository>(),
      timezone: () => _userSettings(getIt).timezone,
    ),
  );

  getIt.registerFactory(
    () => FocusSettingsCubit(repository: getIt<FocusRepository>()),
  );
  getIt.registerFactory(() {
    final settings = _userSettings(getIt);
    return FocusStatsCubit(
      repository: getIt<FocusRepository>(),
      timezone: settings.timezone,
      weekStartDay: settings.weekStartDay,
    );
  });

  // The Pomodoro screen passes the optional task and study session ids.
  getIt.registerFactoryParam<FocusCubit, String?, String?>(
    (taskId, studySessionId) => FocusCubit(
      repository: getIt<FocusRepository>(),
      localDataSource: getIt<FocusTimerLocalDataSource>(),
      timezone: _userSettings(getIt).timezone,
      completionPort: getIt.isRegistered<StudySessionCompletionPort>()
          ? getIt<StudySessionCompletionPort>()
          : null,
      taskId: taskId,
      studySessionId: studySessionId,
    ),
  );
}
