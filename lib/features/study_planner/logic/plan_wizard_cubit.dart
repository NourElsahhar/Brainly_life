import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/plan_generation_service.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_state.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the two-step "New study plan" wizard (Master Document B.2):
///
/// 1. choose subjects and topics;
/// 2. set the time (minutes per weekday, days off, session length), then
///    the user taps "Generate plan".
///
/// The plan is made by AI only, through [PlanGenerationService]. When it
/// fails, nothing is saved and the user can try again. Saving happens later,
/// in the preview, after the user accepts the plan.
class PlanWizardCubit extends Cubit<PlanWizardState> {
  PlanWizardCubit(
    this._repository,
    this._generator, {
    required this._payloadBuilder,
  }) : super(const PlanWizardState(status: PlanWizardStatus.loading));

  /// The session lengths the user can pick (design: 25, 45, 60 min).
  static const List<int> sessionLengths = [25, 45, 60];

  /// Starting study time for every day, before the user changes it.
  static const int defaultDayMinutes = 120;

  /// The most study time the wizard offers for one day.
  static const int maxDayMinutes = 12 * 60;

  /// Pause between two sessions. Not in the design, so it is fixed.
  static const int breakMinutes = 10;

  final StudyRepository _repository;
  final PlanGenerationService _generator;
  final StudyPlanPayloadBuilder _payloadBuilder;

  /// Loads the subjects that can be planned. When [subjectId] is given
  /// (the wizard was opened from a subject page), only that subject's topics
  /// start selected; otherwise all topics do.
  Future<void> load({String? subjectId}) async {
    emit(const PlanWizardState(status: PlanWizardStatus.loading));

    final subjectsResult = await _repository.getSubjects();
    final topicsResult = await _repository.getTopics();
    if (isClosed) return;

    final failure = subjectsResult.failureOrNull ?? topicsResult.failureOrNull;
    if (failure != null) {
      emit(
        PlanWizardState(status: PlanWizardStatus.loadFailed, failure: failure),
      );
      return;
    }

    final wizardSubjects = _plannable(
      subjectsResult.dataOrNull ?? const <Subject>[],
      topicsResult.dataOrNull ?? const <Topic>[],
    );
    if (wizardSubjects.isEmpty) {
      emit(const PlanWizardState(status: PlanWizardStatus.nothingToPlan));
      return;
    }

    final startWith = wizardSubjects.any((s) => s.subject.id == subjectId)
        ? wizardSubjects.where((s) => s.subject.id == subjectId)
        : wizardSubjects;

    emit(
      PlanWizardState(
        status: PlanWizardStatus.editing,
        subjects: wizardSubjects,
        selectedTopicIds: {
          for (final s in startWith)
            for (final t in s.topics) t.id,
        },
        minutesPerWeekday: {
          for (var day = 1; day <= 7; day++) day: defaultDayMinutes,
        },
      ),
    );
  }

  void toggleTopic(String topicId) {
    if (!_canEdit) return;
    final selected = {...state.selectedTopicIds};
    if (!selected.remove(topicId)) selected.add(topicId);
    _emit(selectedTopicIds: selected);
  }

  /// Selects all topics of the subject, or none if all were selected.
  void toggleSubject(String subjectId) {
    if (!_canEdit) return;
    final subject = state.subjects.where((s) => s.subject.id == subjectId);
    if (subject.isEmpty) return;
    final ids = {for (final t in subject.first.topics) t.id};
    final selected = {...state.selectedTopicIds};
    if (selected.containsAll(ids)) {
      selected.removeAll(ids);
    } else {
      selected.addAll(ids);
    }
    _emit(selectedTopicIds: selected);
  }

  /// Goes to step 2. Does nothing while no topic is selected.
  void next() {
    if (!_canEdit || state.step != 1 || !state.canContinue) return;
    _emit(step: 2);
  }

  /// Goes back to step 1. Returns false on step 1, so the screen can close.
  bool back() {
    if (state.isBusy) return true;
    if (state.step == 1) return false;
    _emit(step: 1, status: PlanWizardStatus.editing);
    return true;
  }

  /// Sets the study time of [weekday] (1 = Monday). 0 makes it a day off.
  void setDayMinutes(int weekday, int minutes) {
    if (!_canEdit || weekday < 1 || weekday > 7) return;
    _emit(
      minutesPerWeekday: {
        ...state.minutesPerWeekday,
        weekday: minutes.clamp(0, maxDayMinutes),
      },
    );
  }

  void sessionLengthChanged(int minutes) {
    if (!_canEdit || !sessionLengths.contains(minutes)) return;
    _emit(maxSessionMinutes: minutes);
  }

  /// Asks the AI for a plan. Also used by "Try again".
  Future<void> generate() async {
    final ready =
        state.step == 2 &&
        state.canContinue &&
        state.hasStudyTime &&
        (state.status == PlanWizardStatus.editing ||
            state.status == PlanWizardStatus.generateFailed);
    if (!ready) return;

    _emit(status: PlanWizardStatus.generating);

    final selected = state.selectedSubjects;
    final request = _payloadBuilder.buildNew(
      subjects: [for (final s in selected) s.subject],
      topics: [
        for (final s in selected)
          for (final t in s.topics)
            if (state.isSelected(t)) t,
      ],
      constraints: PlanConstraints(
        minutesPerWeekday: state.minutesPerWeekday,
        daysOff: state.daysOff,
        maxSessionMinutes: state.maxSessionMinutes,
        breakMinutes: breakMinutes,
      ),
    );

    final result = await _generator.generate(request);
    if (isClosed) return;

    switch (result) {
      case Success(:final data):
        _emit(status: PlanWizardStatus.generated, result: data);
      case Failed(:final failure):
        _emit(status: PlanWizardStatus.generateFailed, failure: failure);
    }
  }

  /// After the preview opened (or was closed without saving), the wizard
  /// goes back to step 2 so the user can change the time and try again.
  void previewClosed() {
    if (state.status != PlanWizardStatus.generated) return;
    _emit(status: PlanWizardStatus.editing);
  }

  bool get _canEdit =>
      state.status == PlanWizardStatus.editing ||
      state.status == PlanWizardStatus.generateFailed;

  List<WizardSubject> _plannable(List<Subject> subjects, List<Topic> topics) {
    final result = <WizardSubject>[];
    for (final subject in subjects) {
      if (!_payloadBuilder.canPlan(subject)) continue;
      final open = topics
          .where((t) => t.subjectId == subject.id)
          .where((t) => StudyPlanPayloadBuilder.remainingMinutes(t) > 0)
          .toList();
      if (open.isEmpty) continue;
      result.add(
        WizardSubject(
          subject: subject,
          examDateKey: _payloadBuilder.examDateKey(subject),
          topics: open,
        ),
      );
    }
    // The soonest exam first.
    result.sort((a, b) => a.examDateKey.compareTo(b.examDateKey));
    return result;
  }

  /// Emits the current state with some fields changed. The failure and the
  /// result are cleared unless given, so an old error never shows again.
  void _emit({
    PlanWizardStatus? status,
    int? step,
    Set<String>? selectedTopicIds,
    Map<int, int>? minutesPerWeekday,
    int? maxSessionMinutes,
    GeneratedPlan? result,
    Failure? failure,
  }) {
    final s = state;
    final nextStatus =
        status ??
        (s.status == PlanWizardStatus.generateFailed
            ? PlanWizardStatus.editing
            : s.status);
    emit(
      PlanWizardState(
        status: nextStatus,
        step: step ?? s.step,
        subjects: s.subjects,
        selectedTopicIds: selectedTopicIds ?? s.selectedTopicIds,
        minutesPerWeekday: minutesPerWeekday ?? s.minutesPerWeekday,
        maxSessionMinutes: maxSessionMinutes ?? s.maxSessionMinutes,
        result: result,
        failure: failure,
      ),
    );
  }
}
