// Dependency injection for the habits feature (owner: M4).
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
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/core/ai/ai_client.dart';
import 'package:brainly_life/features/habits/data/datasources/habit_remote_data_source.dart';
import 'package:brainly_life/features/habits/data/repositories/ai_habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/data/models/habit_model.dart';
import 'package:brainly_life/features/habits/data/repositories/firestore_habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_creation_port.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_profile_streak_source.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/data/repositories/habit_summary_provider.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_repository.dart';
import 'package:brainly_life/features/habits/data/repositories/mock_habit_suggestion_port.dart';
import 'package:brainly_life/features/habits/data/repositories/repository_habit_creation_port.dart';
import 'package:brainly_life/features/habits/logic/habit_detail_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_form_cubit.dart';
import 'package:brainly_life/features/habits/logic/habit_suggestion_cubit.dart';
import 'package:brainly_life/features/habits/logic/habits_cubit.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:brainly_life/features/habits/logic/habit_templates.dart';

/// The settings of the signed-in user (timezone, week start day), or the
/// defaults when nobody is signed in.
UserSettings _settings(GetIt getIt) {
  final state = getIt<AuthCubit>().state;
  return state is Authenticated ? state.user.settings : UserSettings.defaults();
}

/// First name of the signed-in user, for the greeting. Null if unknown.
String? _firstName(GetIt getIt) {
  final state = getIt<AuthCubit>().state;
  if (state is! Authenticated) return null;
  final name = state.user.displayName.trim();
  return name.isEmpty ? null : name.split(' ').first;
}

void registerHabitsFeature(GetIt getIt, {required bool useMocks}) {
  // Mock mode: sample habits in memory. Real mode: users/{uid}/habits and
  // users/{uid}/habitLogs in Firestore.
  getIt.registerLazySingleton<HabitRepository>(
    () => useMocks
        ? MockHabitRepository.withSampleData()
        : FirestoreHabitRepository(
            dataSource: HabitRemoteDataSource(
              auth: getIt<FirebaseAuth>(),
              firestore: getIt<FirebaseFirestore>(),
            ),
            timezone: () => _settings(getIt).timezone,
            weekStartDay: () => _settings(getIt).weekStartDay,
          ),
  );

  // For M5's assistant: "create a habit" after the user confirms.
  getIt.registerLazySingleton<HabitCreationPort>(
    () => RepositoryHabitCreationPort(
      getIt<HabitRepository>(),
      timezone: () => _settings(getIt).timezone,
    ),
  );

  // The day streak on Profile.
  getIt.registerLazySingleton<ProfileStreakSource>(
    () => HabitProfileStreakSource(getIt<HabitRepository>()),
  );

  // AI suggestions on the Habits screen: statistics of the last 30 days,
  // sent through the shared AiClient (registered by ai_assistant).
  getIt.registerLazySingleton<HabitSuggestionPort>(
    () => useMocks
        ? MockHabitSuggestionPort(delay: const Duration(milliseconds: 600))
        : AiHabitSuggestionPort(
            client: getIt<AiClient>(),
            repository: getIt<HabitRepository>(),
            timezone: () => _settings(getIt).timezone,
          ),
  );
  getIt.registerFactory(
    () => HabitSuggestionCubit(port: getIt<HabitSuggestionPort>()),
  );

  // The "Habits" card on Home.
  getIt.registerLazySingleton<HabitSummaryProvider>(
    () => DefaultHabitSummaryProvider(
      repository: getIt<HabitRepository>(),
      timezone: () => _settings(getIt).timezone,
    ),
  );

  getIt.registerFactory(
    () => HabitsCubit(
      repository: getIt<HabitRepository>(),
      timezone: _settings(getIt).timezone,
      userName: () => _firstName(getIt),
    ),
  );

  // The form gets the habit to edit (or null) and an optional template.
  getIt.registerFactoryParam<HabitFormCubit, Habit?, HabitTemplate?>((
    habit,
    template,
  ) {
    final settings = _settings(getIt);
    return HabitFormCubit(
      repository: getIt<HabitRepository>(),
      timezone: settings.timezone,
      weekStartDay: settings.weekStartDay,
      habit: habit,
      template: template,
    );
  });

  getIt.registerFactoryParam<HabitDetailCubit, String, void>((habitId, _) {
    final settings = _settings(getIt);
    return HabitDetailCubit(
      repository: getIt<HabitRepository>(),
      habitId: habitId,
      timezone: settings.timezone,
      weekStartDay: settings.weekStartDay,
    );
  });
}
