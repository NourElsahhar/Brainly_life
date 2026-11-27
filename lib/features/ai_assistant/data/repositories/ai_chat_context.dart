// AiChatContext = the user's real data that the assistant sees with every
// chat message, so it can answer "what do I study today?", "when is my
// next exam?", "how is my plan going?".
//
//   studyPlanner -> subjects (exam dates, work left) and the active plan
//                   (done / missed / left, today's and the next sessions)
//                   from M2's StudyRepository
//   tasks        -> due today / overdue (M3's TaskSummaryProvider)
//   bestStreak   -> best habit streak (M4's ProfileStreakSource)
//
// Every source is optional: a missing or failing one is simply left out,
// so the chat always works. No uid, name or e-mail is included.

// ignore_for_file: prefer_initializing_formals

import 'package:brainly_life/core/ai/gemini_prompts.dart';
import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/auth/data/repositories/profile_stats_provider.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/study_repository.dart';

class AiChatContext {
  AiChatContext({
    required Future<String> Function() timezone,
    required DateTime Function() now,
    StudyRepository? Function()? study,
    TaskSummaryProvider? Function()? tasks,
    ProfileStreakSource? Function()? streak,
  }) : _timezone = timezone,
       _now = now,
       _study = study,
       _tasks = tasks,
       _streak = streak;

  /// At most this many upcoming sessions are sent.
  static const int maxNextSessions = 8;

  final Future<String> Function() _timezone;
  final DateTime Function() _now;
  final StudyRepository? Function()? _study;
  final TaskSummaryProvider? Function()? _tasks;
  final ProfileStreakSource? Function()? _streak;

  Future<Map<String, Object?>> build() async {
    final timezone = await _timezone();
    final today = DateKeyUtils.toDateKey(_now(), timezone: timezone);
    final context = <String, Object?>{'today': today};

    final study = await _safe(() => _studyPlanner(today, timezone));
    if (study != null) context['studyPlanner'] = study;

    final tasks = await _safe(() async {
      final summary = (await _tasks?.call()?.todaySummary())?.dataOrNull;
      if (summary == null) return null;
      return {
        'dueToday': summary.dueTodayCount,
        'overdue': summary.overdueCount,
        'doneToday': summary.completedTodayCount,
      };
    });
    if (tasks != null) context['tasks'] = tasks;

    final streak = await _safe(
      () async => (await _streak?.call()?.streakDays())?.dataOrNull,
    );
    if (streak != null) context['bestHabitStreak'] = streak;

    return context;
  }

  Future<Map<String, Object?>?> _studyPlanner(
    String today,
    String timezone,
  ) async {
    final repository = _study?.call();
    if (repository == null) return null;

    final subjects = (await repository.getSubjects()).dataOrNull ?? const [];
    final topics = (await repository.getTopics()).dataOrNull ?? const [];
    final plan = (await repository.getActivePlan()).dataOrNull;
    final sessions = plan == null
        ? const <StudySession>[]
        : (await repository.getSessionsForPlan(plan.id)).dataOrNull ??
              const <StudySession>[];

    final subjectNames = {
      for (final subject in subjects)
        subject.id: GeminiPrompts.cleanLabel(subject.name),
    };
    final topicTitles = {
      for (final topic in topics)
        topic.id: GeminiPrompts.cleanLabel(topic.title),
    };

    String key(DateTime moment) =>
        DateKeyUtils.toDateKey(moment, timezone: timezone);

    Map<String, Object?> describe(StudySession session) {
      final dayStart = DateKeyUtils.dayBounds(
        session.dateKey,
        timezone: timezone,
      ).start;
      final minutes = session.startAt.difference(dayStart).inMinutes;
      return {
        'date': session.dateKey,
        'time':
            '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
            '${(minutes % 60).toString().padLeft(2, '0')}',
        'subject': subjectNames[session.subjectId] ?? 'Subject',
        'topic': topicTitles[session.topicId] ?? 'Topic',
        'minutes': session.plannedMinutes,
        'status': session.status.name,
      };
    }

    final upcoming =
        sessions
            .where(
              (s) =>
                  s.status == SessionStatus.planned &&
                  s.dateKey.compareTo(today) >= 0,
            )
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return {
      'subjects': [
        for (final subject in subjects)
          {
            'name': subjectNames[subject.id],
            'examDate': key(subject.examDate),
            'daysUntilExam': DateKeyUtils.daysBetween(
              today,
              key(subject.examDate),
            ),
            'priority': subject.priority,
            'topicsLeft': topics
                .where(
                  (t) =>
                      t.subjectId == subject.id && t.status != TopicStatus.done,
                )
                .length,
            'minutesLeft': topics
                .where((t) => t.subjectId == subject.id)
                .fold<int>(0, (sum, t) {
                  final left = t.estimatedMinutes - t.completedMinutes;
                  return sum + (left > 0 ? left : 0);
                }),
          },
      ],
      'activePlan': plan == null
          ? null
          : {
              'startDate': key(plan.startDate),
              'endDate': key(plan.endDate),
              'sessionsDone': sessions
                  .where((s) => s.status == SessionStatus.done)
                  .length,
              'sessionsMissed': sessions
                  .where(
                    (s) =>
                        s.status == SessionStatus.missed ||
                        s.status == SessionStatus.skipped,
                  )
                  .length,
              'sessionsLeft': upcoming.length,
              'today': [
                for (final s in upcoming.where((s) => s.dateKey == today))
                  describe(s),
              ],
              'next': [
                for (final s in upcoming.take(maxNextSessions)) describe(s),
              ],
            },
    };
  }

  static Future<T?> _safe<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } catch (_) {
      return null;
    }
  }
}
