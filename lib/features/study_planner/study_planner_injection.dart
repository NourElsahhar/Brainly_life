// Dependency injection for the study_planner feature (owner: M2).
// injection.dart calls this function once when the app starts.
//
//   - Repositories and providers: registerLazySingleton (one for the app)
//   - Cubits: registerFactory (a new one for every screen)

import 'package:brainly_life/features/auth/data/models/user_settings_model.dart';
import 'package:brainly_life/features/auth/logic/auth_cubit.dart';
import 'package:brainly_life/features/auth/logic/auth_state.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_session_completion_port.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_summary_provider.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_cubit.dart';
import 'package:get_it/get_it.dart';

/// The signed-in user's `settings.timezone`, or the default when nobody is
/// signed in (or in tests without auth). Same approach as the focus
/// feature; replace it with M1's shared settings contract when it exists.
String studyPlannerTimezone(GetIt getIt) {
  if (getIt.isRegistered<AuthCubit>()) {
    final state = getIt<AuthCubit>().state;
    if (state is Authenticated) return state.user.settings.timezone;
  }
  return UserSettings.defaults().timezone;
}

void registerStudyPlannerFeature(GetIt getIt, {required bool useMocks}) {
  // FirestoreStudyRepository is not ready yet, so both modes use the
  // in-memory repository. When it is ready, this becomes:
  //   useMocks ? MockStudyRepository(...) : FirestoreStudyRepository(...)
  getIt.registerLazySingleton<MockStudyRepository>(
    () => MockStudyRepository(timezone: studyPlannerTimezone(getIt)),
  );
  getIt.registerLazySingleton<StudyRepository>(
    () => getIt<MockStudyRepository>(),
  );

  // Contracts other features use (Master Document Part C).
  // M4: a finished focus session adds its minutes to the study session.
  getIt.registerLazySingleton<StudySessionCompletionPort>(
    () => getIt<MockStudyRepository>(),
  );
  // M3: the "Next study session" card on Home.
  getIt.registerLazySingleton<StudySummaryProvider>(
    () => DefaultStudySummaryProvider(repository: getIt<StudyRepository>()),
  );

  // Cubits: a new one for every screen, with the timezone of that moment.
  getIt.registerFactory(
    () => SubjectsCubit(getIt(), timezone: studyPlannerTimezone(getIt)),
  );
  getIt.registerFactory(
    () => SubjectFormCubit(getIt(), timezone: studyPlannerTimezone(getIt)),
  );
  getIt.registerFactory(
    () => SubjectDetailCubit(getIt(), timezone: studyPlannerTimezone(getIt)),
  );
  getIt.registerFactory(() => TopicFormCubit(getIt()));
}
