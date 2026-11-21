import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subjects_state.dart';
import 'package:brainly_life/features/study_planner/presentation/study_planner_paths.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/subject_card.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The subjects list. Creates its Cubit, then shows [SubjectsView].
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SubjectsCubit>()..load(),
      child: const SubjectsView(),
    );
  }
}

/// Loading, empty, error and loaded states of the subjects list.
class SubjectsView extends StatelessWidget {
  const SubjectsView({super.key});

  /// Opens the form (new when [subjectId] is null), then reloads the list
  /// if the user saved.
  Future<void> _openForm(BuildContext context, {String? subjectId}) async {
    final cubit = context.read<SubjectsCubit>();
    final path = subjectId == null
        ? StudyPlannerPaths.newSubject
        : StudyPlannerPaths.editSubject(subjectId);
    final saved = await context.push<bool>(path);
    if (saved != true || !context.mounted) return;
    AppSnackBar.success(context, 'Subject saved');
    await cubit.load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SubjectOverview overview,
  ) async {
    final cubit = context.read<SubjectsCubit>();
    final topics = overview.topicCount;
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete "${overview.subject.name}"?',
      message: topics == 0
          ? 'Its planned sessions will be deleted too.'
          : 'Its $topics ${topics == 1 ? 'topic' : 'topics'} and planned '
                'sessions will be deleted too.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok) await cubit.deleteSubject(overview.subject);
  }

  /// One-time messages after a delete: success or failure.
  void _showMessages(BuildContext context, SubjectsState state) {
    final (deletedName, failure) = switch (state) {
      SubjectsLoaded(:final deletedName, :final actionFailure) => (
        deletedName,
        actionFailure,
      ),
      SubjectsEmpty(:final deletedName) => (deletedName, null),
      _ => (null, null),
    };
    if (failure != null) {
      AppSnackBar.error(context, failure.userMessage);
    } else if (deletedName != null) {
      AppSnackBar.success(context, '"$deletedName" deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    // The + button only makes sense next to a list; the empty state has
    // its own big button.
    final hasList = context.select<SubjectsCubit, bool>(
      (cubit) => cubit.state is SubjectsLoaded,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      floatingActionButton: hasList
          ? FloatingActionButton(
              tooltip: 'Add subject',
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: BlocConsumer<SubjectsCubit, SubjectsState>(
        listener: _showMessages,
        builder: (context, state) => switch (state) {
          SubjectsInitial() || SubjectsLoading() => const LoadingView(),
          SubjectsEmpty() => EmptyView(
            icon: Icons.menu_book_rounded,
            title: 'No subjects yet',
            message: 'Add your first subject to start planning your studies.',
            actionLabel: 'Add your first subject',
            onAction: () => _openForm(context),
          ),
          SubjectsError(:final failure) => ErrorView(
            failure: failure,
            onRetry: context.read<SubjectsCubit>().load,
          ),
          SubjectsLoaded(:final subjects) => RefreshIndicator(
            onRefresh: context.read<SubjectsCubit>().load,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              itemCount: subjects.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.cardGap),
              itemBuilder: (context, index) {
                final overview = subjects[index];
                return SubjectCard(
                  key: ValueKey(overview.subject.id),
                  overview: overview,
                  onEdit: () =>
                      _openForm(context, subjectId: overview.subject.id),
                  onDelete: () => _confirmDelete(context, overview),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}
