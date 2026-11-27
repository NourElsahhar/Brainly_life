// Tests for AiChatContext: the user's study planner data reaches the chat,
// and missing sources never break it.

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/ai_assistant/data/repositories/ai_chat_context.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_plan_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Streak implements ProfileStreakSource {
  _Streak(this.result);
  final Result<int> result;
  @override
  Future<Result<int>> streakDays() async => result;
}

void main() {
  // 10:00 in Cairo (UTC+2) on Friday 2026-11-27.
  final now = DateTime.utc(2026, 11, 27, 8);

  test('subjects, exam dates and the next sessions of the plan', () async {
    final repository = MockStudyRepository(withSampleData: false);
    final subject = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Math',
        colorValue: 0xFF2196F3,
        examDate: DateTime.utc(2026, 12, 9, 22), // 10 Dec in Cairo
        priority: 3,
      ),
    )).dataOrNull!;
    final topic = (await repository.addTopic(
      Topic(
        id: '',
        subjectId: subject.id,
        title: 'Limits',
        difficulty: 3,
        estimatedMinutes: 120,
        status: TopicStatus.inProgress,
        completedMinutes: 30,
      ),
    )).dataOrNull!;
    final plan = StudyPlan(
      id: 'p1',
      title: 'Study plan',
      startDate: DateTime.utc(2026, 11, 27),
      endDate: DateTime.utc(2026, 12, 9),
      generatedBy: PlanGenerator.ai,
      constraints: PlanConstraints(
        minutesPerWeekday: {1: 60},
        daysOff: {},
        maxSessionMinutes: 45,
        breakMinutes: 10,
      ),
    );
    StudySession session(String id, String day, DateTime startAt) =>
        StudySession(
          id: id,
          planId: 'p1',
          subjectId: subject.id,
          topicId: topic.id,
          dateKey: day,
          startAt: startAt,
          plannedMinutes: 45,
        );
    await repository.savePlan(plan, [
      // 18:00 in Cairo today, and tomorrow.
      session('a', '2026-11-27', DateTime.utc(2026, 11, 27, 16)),
      session('b', '2026-11-28', DateTime.utc(2026, 11, 28, 16)),
    ]);

    final context = await AiChatContext(
      timezone: () async => 'Africa/Cairo',
      now: () => now,
      study: () => repository,
      streak: () => _Streak(const Result.success(5)),
    ).build();

    expect(context['today'], '2026-11-27');
    expect(context['bestHabitStreak'], 5);
    final study = context['studyPlanner']! as Map;
    expect(study['subjects'], [
      {
        'name': 'Math',
        'examDate': '2026-12-10',
        'daysUntilExam': 13,
        'priority': 3,
        'topicsLeft': 1,
        'minutesLeft': 90,
      },
    ]);
    final active = study['activePlan']! as Map;
    expect(active['sessionsLeft'], 2);
    expect(active['today'], [
      {
        'date': '2026-11-27',
        'time': '18:00',
        'subject': 'Math',
        'topic': 'Limits',
        'minutes': 45,
        'status': 'planned',
      },
    ]);
  });

  test('no sources or failing sources: only today', () async {
    final context = await AiChatContext(
      timezone: () async => 'Africa/Cairo',
      now: () => now,
      streak: () => _Streak(const Result.failure(NetworkFailure())),
    ).build();

    expect(context, {'today': '2026-11-27'});
  });
}
