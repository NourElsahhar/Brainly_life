import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_mapping.dart';
import 'study_enums.dart';

part 'study_session_model.freezed.dart';

@freezed
abstract class StudySession with _$StudySession {
  const StudySession._();

  const factory StudySession({
    required String id,
    required String planId,
    required String subjectId,
    required String topicId,
    required String dateKey,
    required DateTime startAt,
    required int plannedMinutes,
    @Default(0) int actualMinutes,
    @Default(SessionStatus.planned) SessionStatus status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _StudySession;

  factory StudySession.fromFirestore(String id, Map<String, dynamic> data) {
    return StudySession(
      id: id,
      planId: requireField<String>(data, 'planId'),
      subjectId: requireField<String>(data, 'subjectId'),
      topicId: requireField<String>(data, 'topicId'),
      dateKey: requireField<String>(data, 'date'),
      startAt: requireDate(data, 'startAt'),
      plannedMinutes: requireField<int>(data, 'plannedMinutes'),
      actualMinutes: requireField<int>(data, 'actualMinutes'),
      status: parseEnum(SessionStatus.values, data['status'], 'status'),
      createdAt: optionalDate(data, 'createdAt'),
      updatedAt: optionalDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'planId': planId,
      'subjectId': subjectId,
      'topicId': topicId,
      'date': dateKey,
      'startAt': Timestamp.fromDate(startAt),
      'plannedMinutes': plannedMinutes,
      'actualMinutes': actualMinutes,
      'status': status.name,
    };
  }
}
