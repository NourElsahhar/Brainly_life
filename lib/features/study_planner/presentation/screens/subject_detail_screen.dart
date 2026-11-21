import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_state.dart';
import 'package:brainly_life/features/study_planner/presentation/study_planner_paths.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/subject_header_card.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/topic_tile.dart';
import 'package:brainly_life/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The page of one subject. Closes with the subject name when the subject
/// was deleted, so the list can say so.
class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SubjectDetailCubit>()..load(subjectId),
      child: const SubjectDetailView(),
    );
  }
}

class SubjectDetailView extends StatelessWidget {
  const SubjectDetailView({super.key});

  Future<void> _editSubject(BuildContext context, String subjectId) async {
    final cubit = context.read<SubjectDetailCubit>();
    final saved = await context.push<bool>(
      StudyPlannerPaths.editSubject(subjectId),
    );
    if (saved != true || !context.mounted) return;
    AppSnackBar.success(context, 'Subject saved');
    await cubit.reload();
  }

  Future<void> _confirmDeleteSubject(
    BuildContext context,
    SubjectDetailLoaded state,
  ) async {
    final cubit = context.read<SubjectDetailCubit>();
    final topics = state.overview.topicCount;
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete "${state.overview.subject.name}"?',
      message: topics == 0
          ? 'Its planned sessions will be deleted too.'
          : 'Its $topics ${topics == 1 ? 'topic' : 'topics'} and planned '
                'sessions will be deleted too.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok) await cubit.deleteSubject();
  }

  Future<void> _deleteTopic(BuildContext context, Topic topic) async {
    final cubit = context.read<SubjectDetailCubit>();
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete "${topic.title}"?',
      message: 'Its planned sessions will be deleted too.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (ok) await cubit.deleteTopic(topic);
  }

  // Step 6.3 replaces these two with the topic form.
  void _addTopic(BuildContext context) {
    AppSnackBar.info(context, 'Adding topics comes in the next update');
  }

  void _editTopic(BuildContext context, Topic topic) {
    AppSnackBar.info(context, 'Editing topics comes in the next update');
  }

  // The plan wizard is the next milestone.
  void _generatePlan(BuildContext context) {
    AppSnackBar.info(context, 'The plan wizard is coming soon');
  }

  void _onStateChanged(BuildContext context, SubjectDetailState state) {
    switch (state) {
      case SubjectDetailDeleted(:final subjectName):
        context.pop(subjectName);
      case SubjectDetailLoaded(:final actionFailure?):
        AppSnackBar.error(context, actionFailure.userMessage);
      case SubjectDetailLoaded(:final deletedTopicTitle?):
        AppSnackBar.success(context, '"$deletedTopicTitle" deleted');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final loaded = context.select<SubjectDetailCubit, SubjectDetailLoaded?>(
      (cubit) => switch (cubit.state) {
        final SubjectDetailLoaded s => s,
        _ => null,
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject'),
        actions: [
          if (loaded != null) ...[
            IconButton(
              tooltip: 'Edit subject',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  _editSubject(context, loaded.overview.subject.id),
            ),
            IconButton(
              tooltip: 'Delete subject',
              icon: Icon(Icons.delete_outline_rounded, color: p.error),
              onPressed: () => _confirmDeleteSubject(context, loaded),
            ),
          ],
        ],
      ),
      bottomNavigationBar: loaded == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.s2,
                  AppSpacing.screenMargin,
                  AppSpacing.s4,
                ),
                child: AppButton(
                  label: 'Generate study plan',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: loaded.topics.isEmpty
                      ? null
                      : () => _generatePlan(context),
                ),
              ),
            ),
      body: BlocConsumer<SubjectDetailCubit, SubjectDetailState>(
        listener: _onStateChanged,
        builder: (context, state) => switch (state) {
          // Deleted: the page is closing, keep a spinner for that moment.
          SubjectDetailLoading() ||
          SubjectDetailDeleted() => const LoadingView(),
          SubjectDetailNotFound() => EmptyView(
            icon: Icons.search_off_rounded,
            title: 'Subject not found',
            message: 'It may have been deleted.',
            actionLabel: 'Back to subjects',
            onAction: () => context.pop(),
          ),
          SubjectDetailError(:final failure) => ErrorView(
            failure: failure,
            onRetry: context.read<SubjectDetailCubit>().reload,
          ),
          SubjectDetailLoaded() => _LoadedBody(
            state: state,
            onAddTopic: () => _addTopic(context),
            onEditTopic: (topic) => _editTopic(context, topic),
            onDeleteTopic: (topic) => _deleteTopic(context, topic),
          ),
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.onAddTopic,
    required this.onEditTopic,
    required this.onDeleteTopic,
  });

  final SubjectDetailLoaded state;
  final VoidCallback onAddTopic;
  final ValueChanged<Topic> onEditTopic;
  final ValueChanged<Topic> onDeleteTopic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final topics = state.topics;

    return RefreshIndicator(
      onRefresh: context.read<SubjectDetailCubit>().reload,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          SubjectHeaderCard(overview: state.overview),
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: [
              Expanded(
                child: Text('Topics', style: context.text.headlineSmall),
              ),
              TextButton.icon(
                onPressed: onAddTopic,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add topic'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          if (topics.isEmpty)
            AppCard(
              child: Text(
                'No topics yet. Add the chapters or lessons you need to '
                'study, then generate a plan.',
                style: context.text.bodyMedium?.copyWith(
                  color: p.textSecondary,
                ),
              ),
            )
          else
            for (final topic in topics)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: TopicTile(
                  key: ValueKey(topic.id),
                  topic: topic,
                  onEdit: () => onEditTopic(topic),
                  onDelete: () => onDeleteTopic(topic),
                ),
              ),
        ],
      ),
    );
  }
}
