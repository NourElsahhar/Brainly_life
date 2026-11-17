import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainly_life/features/study/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study/data/models/study_enums.dart';
import 'package:brainly_life/features/study/data/models/study_plan_model.dart';

void main() {
  group('StudyPlan', () {
    final constraints = PlanConstraints(
      minutesPerWeekday: {1: 120, 3: 90},
      daysOff: {6, 7},
      maxSessionMinutes: 60,
      breakMinutes: 10,
    );
    final startDate = DateTime.utc(2026, 11, 16);
    final endDate = DateTime.utc(2026, 12, 20);
    final plan = StudyPlan(
      id: 'plan_1',
      title: 'Finals preparation',
      startDate: startDate,
      endDate: endDate,
      generatedBy: PlanGenerator.ai,
      promptVersion: 1,
      constraints: constraints,
    );

    test('a new plan is active by default', () {
      expect(plan.status, PlanStatus.active);
    });

    test('toFirestore writes enums as names and nests the constraints', () {
      final map = plan.toFirestore();

      expect(map['generatedBy'], 'ai');
      expect(map['status'], 'active');
      expect(map['promptVersion'], 1);
      expect(map['startDate'], Timestamp.fromDate(startDate));
      expect(map['endDate'], Timestamp.fromDate(endDate));
      expect(map['constraints'], constraints.toFirestore());
      expect(map.containsKey('createdAt'), isFalse);
    });

    test('fromFirestore(toFirestore()) returns an equal plan', () {
      final restored = StudyPlan.fromFirestore('plan_1', plan.toFirestore());

      expect(restored, plan);
    });

    test('a rule-based plan has no promptVersion', () {
      final rulesPlan = plan.copyWith(
        generatedBy: PlanGenerator.rules,
        promptVersion: null,
      );

      final restored = StudyPlan.fromFirestore(
        'plan_1',
        rulesPlan.toFirestore(),
      );

      expect(restored.generatedBy, PlanGenerator.rules);
      expect(restored.promptVersion, isNull);
    });

    test('fromFirestore throws FormatException for an unknown generator', () {
      final data = plan.toFirestore()..['generatedBy'] = 'robot';

      expect(() => StudyPlan.fromFirestore('plan_1', data), throwsFormatException);
    });

    test('fromFirestore throws FormatException when constraints are missing', () {
      final data = plan.toFirestore()..remove('constraints');

      expect(() => StudyPlan.fromFirestore('plan_1', data), throwsFormatException);
    });

    test('fromFirestore throws FormatException when promptVersion is not an int', () {
      final data = plan.toFirestore()..['promptVersion'] = 'v1';

      expect(() => StudyPlan.fromFirestore('plan_1', data), throwsFormatException);
    });
  });
}