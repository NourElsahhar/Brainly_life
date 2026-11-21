// Routes of the study_planner feature (owner: M2).
// app_router.dart combines the route lists of all features.

import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/subject_detail_screen.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/subject_form_screen.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/subjects_screen.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/topic_form_screen.dart';
import 'package:go_router/go_router.dart';

final List<RouteBase> studyPlannerRoutes = [
  // The Plan tab shows the subjects for now. When the weekly plan screen is
  // ready it takes this tab, and the subjects move to their own route.
  GoRoute(
    path: AppRoutes.plan,
    builder: (context, state) => const SubjectsScreen(),
    routes: [
      // These must match StudyPlannerPaths. 'subjects/new' comes first, so
      // "new" is never read as a subject id.
      GoRoute(
        path: 'subjects/new',
        builder: (context, state) => const SubjectFormScreen(),
      ),
      GoRoute(
        path: 'subjects/:id',
        builder: (context, state) =>
            SubjectDetailScreen(subjectId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) =>
                SubjectFormScreen(subjectId: state.pathParameters['id']),
          ),
          // 'topics/new' comes before 'topics/:topicId/edit' for the same
          // reason as 'subjects/new'.
          GoRoute(
            path: 'topics/new',
            builder: (context, state) =>
                TopicFormScreen(subjectId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'topics/:topicId/edit',
            builder: (context, state) => TopicFormScreen(
              subjectId: state.pathParameters['id']!,
              topicId: state.pathParameters['topicId'],
            ),
          ),
        ],
      ),
    ],
  ),
];
