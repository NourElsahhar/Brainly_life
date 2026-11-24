import 'package:brainly_life/core/utils/date_key_utils.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/study_session_model.dart';
import 'package:brainly_life/features/study_planner/logic/local_time.dart';

/// Turns `AiResponse.data` of the `studyPlan` feature into sessions.
///
/// The expected shape is `responseSchema` in
/// `functions/src/ai/features/studyPlan.ts`:
/// `{"sessions": [{"subjectId", "topicId", "date", "startTime",
/// "plannedMinutes"}]}`.
///
/// This only checks the shape. The rules (no past sessions, no overlaps,
/// daily limits, known ids) are checked afterwards by `PlanValidator`.
/// Pure Dart.
class StudyPlanResponseParser {
  const StudyPlanResponseParser({required this.timezone});

  final String timezone;

  /// Throws a [FormatException] when [data] does not have the expected
  /// shape. The caller treats that like any invalid AI answer: nothing is
  /// saved and the user can try again.
  List<StudySession> parse(
    Map<String, Object?> data, {
    required String planId,
    required String Function() newSessionId,
  }) {
    final rawSessions = data['sessions'];
    if (rawSessions is! List || rawSessions.isEmpty) {
      throw const FormatException('The answer has no sessions.');
    }

    return [
      for (final (index, raw) in rawSessions.indexed)
        _session(raw, index, planId: planId, id: newSessionId()),
    ];
  }

  StudySession _session(
    Object? raw,
    int index, {
    required String planId,
    required String id,
  }) {
    if (raw is! Map) {
      throw FormatException('Session $index is not an object.');
    }
    String text(String key) {
      final value = raw[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Session $index: "$key" is missing.');
      }
      return value;
    }

    final dateKey = text('date');
    if (!DateKeyUtils.isValid(dateKey)) {
      throw FormatException('Session $index: "$dateKey" is not a day.');
    }
    final minuteOfDay = LocalTime.parseTime(text('startTime'));
    if (minuteOfDay == null) {
      throw FormatException('Session $index: bad "startTime".');
    }
    final minutes = raw['plannedMinutes'];
    if (minutes is! int) {
      throw FormatException('Session $index: "plannedMinutes" is not a number.');
    }

    return StudySession(
      id: id,
      planId: planId,
      subjectId: text('subjectId'),
      topicId: text('topicId'),
      dateKey: dateKey,
      startAt: LocalTime.toUtc(dateKey, minuteOfDay, timezone: timezone),
      plannedMinutes: minutes,
      status: SessionStatus.planned,
    );
  }
}