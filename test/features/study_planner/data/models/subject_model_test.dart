import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Subject', () {
    final examDate = DateTime.utc(2026, 12, 20, 9);
    final subject = Subject(
      id: 'subject_1',
      name: 'Operating Systems',
      colorValue: 0xFF3F51B5,
      examDate: examDate,
      priority: 2,
    );

    test('toFirestore writes business fields only, without timestamps', () {
      final map = subject.toFirestore();

      expect(
        map.keys,
        unorderedEquals(['name', 'colorValue', 'examDate', 'priority']),
      );
      expect(map['examDate'], Timestamp.fromDate(examDate));
    });

    test('fromFirestore(toFirestore()) returns an equal subject', () {
      final restored = Subject.fromFirestore(
        'subject_1',
        subject.toFirestore(),
      );

      expect(restored, subject);
    });

    test('fromFirestore reads server timestamps as UTC', () {
      final restored = Subject.fromFirestore('subject_1', {
        ...subject.toFirestore(),
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 1, 8)),
        'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 2, 8)),
      });

      expect(restored.createdAt, DateTime.utc(2026, 11, 1, 8));
      expect(restored.updatedAt, DateTime.utc(2026, 11, 2, 8));
      expect(restored.createdAt!.isUtc, isTrue);
    });

    test('a pending server timestamp (null) is read as null', () {
      final restored = Subject.fromFirestore('subject_1', {
        ...subject.toFirestore(),
        'createdAt': null,
        'updatedAt': null,
      });

      expect(restored.createdAt, isNull);
      expect(restored.updatedAt, isNull);
    });

    test('fromFirestore throws FormatException when a field is missing', () {
      final data = subject.toFirestore()..remove('name');

      expect(
        () => Subject.fromFirestore('subject_1', data),
        throwsFormatException,
      );
    });

    test(
      'fromFirestore throws FormatException when a field has wrong type',
      () {
        final data = subject.toFirestore()..['priority'] = 'high';

        expect(
          () => Subject.fromFirestore('subject_1', data),
          throwsFormatException,
        );
      },
    );

    test('copyWith changes only the given fields', () {
      final renamed = subject.copyWith(name: 'Databases');

      expect(renamed.name, 'Databases');
      expect(renamed.id, subject.id);
      expect(renamed.examDate, subject.examDate);
      expect(renamed.priority, subject.priority);
    });
  });
}
