// Dependency injection for the study_planner feature (owner: M2).
// injection.dart calls this function once when the app starts.
//
//   - Repositories: registerLazySingleton (one copy for the app)
//   - Cubits: registerFactory (a new one for every screen)

import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_form_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_cubit.dart';
import 'package:get_it/get_it.dart';

/// The timezone used until the user's `settings.timezone` is available to
/// features (M1's settings work). Change it in this one place.
const String studyPlannerFallbackTimezone = 'Africa/Cairo';

void registerStudyPlannerFeature(GetIt getIt, {required bool useMocks}) {
  // FirestoreStudyRepository is not ready yet, so both modes use the mock
  // with sample data. When it is ready, this becomes:
  //   () => useMocks ? MockStudyRepository() : FirestoreStudyRepository(...)
  getIt.registerLazySingleton<StudyRepository>(
    () => MockStudyRepository(timezone: studyPlannerFallbackTimezone),
  );

  // Cubits: a new one for every screen.
  getIt.registerFactory(
    () => SubjectsCubit(getIt(), timezone: studyPlannerFallbackTimezone),
  );
  getIt.registerFactory(
    () => SubjectFormCubit(getIt(), timezone: studyPlannerFallbackTimezone),
  );
  getIt.registerFactory(
    () => SubjectDetailCubit(getIt(), timezone: studyPlannerFallbackTimezone),
  );
}
