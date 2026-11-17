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
//   - This file registers the Firebase services and then calls ONE function
//     for each feature (registerTasksFeature, registerHabitsFeature, ...).
//   - Each feature owner writes their own function in
//     features/<name>/<name>_injection.dart, so we never edit the same file.
//
// Ready to use from getIt: FirebaseAuth, FirebaseFirestore, FirebaseFunctions.
//
// Rules:
//   - Repositories, data sources, services -> registerLazySingleton
//     (one copy for the whole app, created on first use).
//   - Cubits -> registerFactory (a new one for every screen).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import 'core/constants/app_config.dart';
import 'features/ai_assistant/ai_assistant_injection.dart';
import 'features/analytics/analytics_injection.dart';
import 'features/auth/auth_injection.dart';
import 'features/focus/focus_injection.dart';
import 'features/habits/habits_injection.dart';
import 'features/home/home_injection.dart';
import 'features/notifications/notifications_injection.dart';
import 'features/study_planner/study_planner_injection.dart';
import 'features/tasks/tasks_injection.dart';

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

  // One line per feature.
  registerAuthFeature(getIt, useMocks: mocks);
  registerHomeFeature(getIt, useMocks: mocks);
  registerStudyPlannerFeature(getIt, useMocks: mocks);
  registerTasksFeature(getIt, useMocks: mocks);
  registerNotificationsFeature(getIt, useMocks: mocks);
  registerHabitsFeature(getIt, useMocks: mocks);
  registerFocusFeature(getIt, useMocks: mocks);
  registerAnalyticsFeature(getIt, useMocks: mocks);
  registerAiAssistantFeature(getIt, useMocks: mocks);
}