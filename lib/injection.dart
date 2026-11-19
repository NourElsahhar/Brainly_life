// injection.dart = the "phone book" of the app (dependency injection).
//
// Instead of writing `FirestoreTaskRepository()` inside a Cubit, we register
// it once here, and any code asks for it with getIt():
//
//   final repository = getIt<TaskRepository>();
//
// Why: in tests and with USE_MOCKS the SAME code gets a Mock repository.
//
// How it is organized:
//   - This file registers the Firebase services and the router, and then
//     calls ONE function for each feature (registerTasksFeature, ...).
//   - Each feature owner writes their own function in
//     features/<name>/<name>_injection.dart, so we never edit the same file.
//
// Ready to use from getIt: FirebaseAuth, FirebaseFirestore, FirebaseFunctions.
//
// Rules:
//   - Repositories, data sources, services -> registerLazySingleton
//     (one copy for the whole app, created on first use).
//   - Cubits -> registerFactory (a new one for every screen).

import 'package:brainly_life/core/constants/app_config.dart';
import 'package:brainly_life/core/routes/app_router.dart';
import 'package:brainly_life/core/routes/router_auth_state.dart';
import 'package:brainly_life/features/ai_assistant/ai_assistant_injection.dart';
import 'package:brainly_life/features/analytics/analytics_injection.dart';
import 'package:brainly_life/features/auth/auth_injection.dart';
import 'package:brainly_life/features/focus/focus_injection.dart';
import 'package:brainly_life/features/habits/habits_injection.dart';
import 'package:brainly_life/features/home/home_injection.dart';
import 'package:brainly_life/features/study_planner/study_planner_injection.dart';
import 'package:brainly_life/features/tasks/tasks_injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

final GetIt getIt = GetIt.instance;

/// Call once at app start (see main.dart).
/// [useMocks] is only for tests. Normally it comes from --dart-define=USE_MOCKS.
Future<void> configureDependencies({bool? useMocks}) async {
  // Start clean (safe in tests and after a hot restart).
  await getIt.reset();

  final mocks = useMocks ?? AppConfig.useMocks;

  // Firebase services. They are created only when someone asks for them,
  // so mock mode never touches Firebase.
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instance,
  );

  // Router. TEMPORARY: it starts as signed in, so the team can see the tabs.
  // When AuthCubit is ready it will update RouterAuthState with the real status.
  getIt.registerLazySingleton<RouterAuthState>(
    () => RouterAuthState(AuthStatus.signedIn),
  );
  getIt.registerLazySingleton<GoRouter>(
    () => createAppRouter(getIt<RouterAuthState>()),
  );

  // One line per feature.
  registerAuthFeature(getIt, useMocks: mocks);
  registerHomeFeature(getIt, useMocks: mocks);
  registerStudyPlannerFeature(getIt, useMocks: mocks);
  registerTasksFeature(getIt, useMocks: mocks);
  registerHabitsFeature(getIt, useMocks: mocks);
  registerFocusFeature(getIt, useMocks: mocks);
  registerAnalyticsFeature(getIt, useMocks: mocks);
  registerAiAssistantFeature(getIt, useMocks: mocks);
}