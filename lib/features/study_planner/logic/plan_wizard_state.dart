import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/logic/plan_generation_service.dart';
import 'package:equatable/equatable.dart';

enum PlanWizardStatus {
  /// Loading the subjects and topics.
  loading,

  /// Loading failed. Show ErrorView with Retry.
  loadFailed,

  /// No subject with an exam from tomorrow on and topics left to study.
  /// Show an empty state that sends the user to the subjects.
  nothingToPlan,

  /// The user is choosing (step 1) or setting the time (step 2).
  editing,

  /// Waiting for the AI. Show a loading state, block the buttons.
  generating,

  /// The AI made a valid plan: open the preview with [PlanWizardState.result].
  generated,

  /// The AI failed. Show the AI error card with "Try again". Nothing was
  /// saved, and an existing plan is unchanged.
  generateFailed,
}

/// A subject the wizard can plan, with its topics that still need study.
class WizardSubject extends Equatable {
  const WizardSubject({
    required this.subject,
    required this.examDateKey,
    required this.topics,
  });

  final Subject subject;

  /// The exam day as `yyyy-MM-dd` in the user's timezone.
  final String examDateKey;

  /// Topics that are not done, sorted by title.
  final List<Topic> topics;

  @override
  List<Object?> get props => [subject, examDateKey, topics];
}

class PlanWizardState extends Equatable {
  const PlanWizardState({
    required this.status,
    this.step = 1,
    this.subjects = const [],
    this.selectedTopicIds = const {},
    this.minutesPerWeekday = const {},
    this.maxSessionMinutes = 45,
    this.result,
    this.failure,
  });

  final PlanWizardStatus status;

  /// 1 = choose subjects and topics, 2 = set your time.
  final int step;

  final List<WizardSubject> subjects;
  final Set<String> selectedTopicIds;

  /// Study minutes for each weekday, 1 = Monday ... 7 = Sunday.
  /// 0 means a day off.
  final Map<int, int> minutesPerWeekday;

  /// One of `PlanWizardCubit.sessionLengths`.
  final int maxSessionMinutes;

  /// The plan to preview, when [status] is `generated`.
  final GeneratedPlan? result;

  final Failure? failure;

  bool isSelected(Topic topic) => selectedTopicIds.contains(topic.id);

  /// The subjects that have at least one selected topic.
  List<WizardSubject> get selectedSubjects => [
    for (final s in subjects)
      if (s.topics.any(isSelected)) s,
  ];

  /// Step 1 needs at least one topic.
  bool get canContinue => selectedTopicIds.isNotEmpty;

  /// Weekdays with no study time.
  Set<int> get daysOff => {
    for (var day = 1; day <= 7; day++)
      if ((minutesPerWeekday[day] ?? 0) == 0) day,
  };

  /// Step 2 needs study time on at least one day.
  bool get hasStudyTime => daysOff.length < 7;

  bool get isBusy => status == PlanWizardStatus.generating;

  @override
  List<Object?> get props => [
    status,
    step,
    subjects,
    selectedTopicIds,
    minutesPerWeekday,
    maxSessionMinutes,
    result,
    failure,
  ];
}
