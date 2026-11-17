import 'package:freezed_annotation/freezed_annotation.dart';

import 'firestore_mapping.dart';
import 'study_enums.dart';

part 'topic_model.freezed.dart';

@freezed
abstract class Topic with _$Topic {
  const Topic._();

  const factory Topic({
    required String id,
    required String subjectId,
    required String title,
    required int difficulty,
    required int estimatedMinutes,
    required TopicStatus status,
    required int completedMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Topic;

  factory Topic.fromFirestore(String id, Map<String, dynamic> data) {
    return Topic(
      id: id,
      subjectId: requireField<String>(data, 'subjectId'),
      title: requireField<String>(data, 'title'),
      difficulty: requireField<int>(data, 'difficulty'),
      estimatedMinutes: requireField<int>(data, 'estimatedMinutes'),
      status: parseEnum(TopicStatus.values, data['status'], 'status'),
      completedMinutes: requireField<int>(data, 'completedMinutes'),
      createdAt: optionalDate(data, 'createdAt'),
      updatedAt: optionalDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'title': title,
      'difficulty': difficulty,
      'estimatedMinutes': estimatedMinutes,
      'status': status.name,
      'completedMinutes': completedMinutes,
    };
  }
}
