import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/topic_model.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('Topic', () {
    const topic = Topic(
      id: 'topic_1',
      subjectId: 'subject_1',
      title: 'Deadlocks',
      difficulty: 4,
      estimatedMinutes: 180,
      status: TopicStatus.inProgress,
      completedMinutes: 60,
    );

    test('toFirestore stores the status as its lowercase camelCase name', () {
      final map = topic.toFirestore();

      expect(map['status'], 'inProgress');
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('updatedAt'), isFalse);
    });

    test('fromFirestore(toFirestore()) returns an equal topic', () {
      final restored = Topic.fromFirestore('topic_1', topic.toFirestore());

      expect(restored, topic);
    });

    test('every TopicStatus survives a round trip', () {
      for (final status in TopicStatus.values) {
        final original = topic.copyWith(status: status);
        final restored = Topic.fromFirestore('topic_1', original.toFirestore());

        expect(restored.status, status);
      }
    });

    test('fromFirestore throws FormatException for an unknown status', () {
      final data = topic.toFirestore()..['status'] = 'finished';

      expect(
        () => Topic.fromFirestore('topic_1', data),
        throwsFormatException,
      );
    });

    test('fromFirestore throws FormatException when a field is missing', () {
      final data = topic.toFirestore()..remove('subjectId');

      expect(
        () => Topic.fromFirestore('topic_1', data),
        throwsFormatException,
      );
    });

    test('copyWith changes only the given fields', () {
      final updated = topic.copyWith(completedMinutes: 120);

      expect(updated.completedMinutes, 120);
      expect(updated.title, topic.title);
      expect(updated.status, topic.status);
    });
  });
}