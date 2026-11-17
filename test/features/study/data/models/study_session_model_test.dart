import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_session_model.dart';

void main() {
  group('StudySession', () {
    final startAt = DateTime.utc(2026, 11, 16, 17);
    final session = StudySession(
      id: 'session_1',
      planId: 'plan_1',
      subjectId: 'subject_1',
      topicId: 'topic_1',
      dateKey: '2026-11-16',
      startAt: startAt,
      plannedMinutes: 45,
    );

    test('a new session is planned and has no actual minutes', () {
      expect(session.status, SessionStatus.planned);
      expect(session.actualMinutes, 0);
      expect(session.reminderId, isNull);
    });

    test('toFirestore stores dateKey under the field "date"', () {
      final map = session.toFirestore();

      expect(map['date'], '2026-11-16');
      expect(map.containsKey('dateKey'), isFalse);
      expect(map['startAt'], Timestamp.fromDate(startAt));
      expect(map['status'], 'planned');
      expect(map['reminderId'], isNull);
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('fromFirestore(toFirestore()) returns an equal session', () {
      final restored = StudySession.fromFirestore(
        'session_1',
        session.toFirestore(),
      );

      expect(restored, session);
    });

    test('every SessionStatus survives a round trip', () {
      for (final status in SessionStatus.values) {
        final original = session.copyWith(status: status);
        final restored = StudySession.fromFirestore(
          'session_1',
          original.toFirestore(),
        );

        expect(restored.status, status);
      }
    });

    test('reminderId and actualMinutes survive a round trip', () {
      final completed = session.copyWith(
        reminderId: 'study_session_1',
        actualMinutes: 50,
        status: SessionStatus.done,
      );

      final restored = StudySession.fromFirestore(
        'session_1',
        completed.toFirestore(),
      );

      expect(restored.reminderId, 'study_session_1');
      expect(restored.actualMinutes, 50);
    });

    test('a pending server timestamp (null) is read as null', () {
      final restored = StudySession.fromFirestore('session_1', {
        ...session.toFirestore(),
        'createdAt': null,
        'updatedAt': null,
      });

      expect(restored.createdAt, isNull);
      expect(restored.updatedAt, isNull);
    });

    test('fromFirestore throws FormatException for an unknown status', () {
      final data = session.toFirestore()..['status'] = 'finished';

      expect(
        () => StudySession.fromFirestore('session_1', data),
        throwsFormatException,
      );
    });

    test('fromFirestore throws FormatException when "date" is missing', () {
      final data = session.toFirestore()..remove('date');

      expect(
        () => StudySession.fromFirestore('session_1', data),
        throwsFormatException,
      );
    });
  });
}