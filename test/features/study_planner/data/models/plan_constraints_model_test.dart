import 'package:flutter_test/flutter_test.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';

void main() {
  group('PlanConstraints', () {
    final constraints = PlanConstraints(
      minutesPerWeekday: {1: 120, 3: 90, 5: 60},
      daysOff: {7, 6},
      maxSessionMinutes: 60,
      breakMinutes: 10,
    );

    test('toFirestore writes weekdays as string keys and sorts daysOff', () {
      final map = constraints.toFirestore();

      expect(map['minutesPerWeekday'], {'1': 120, '3': 90, '5': 60});
      expect(map['daysOff'], [6, 7]);
      expect(map['maxSessionMinutes'], 60);
      expect(map['breakMinutes'], 10);
    });

    test('fromFirestore(toFirestore()) returns equal constraints', () {
      final restored = PlanConstraints.fromFirestore(constraints.toFirestore());

      expect(restored, constraints);
    });

    test('fromFirestore throws FormatException for a weekday above 7', () {
      final data = constraints.toFirestore()..['minutesPerWeekday'] = {'8': 60};

      expect(() => PlanConstraints.fromFirestore(data), throwsFormatException);
    });

    test('fromFirestore throws FormatException for a non numeric weekday', () {
      final data = constraints.toFirestore()
        ..['minutesPerWeekday'] = {'monday': 60};

      expect(() => PlanConstraints.fromFirestore(data), throwsFormatException);
    });

    test(
      'fromFirestore throws FormatException when minutes are not an int',
      () {
        final data = constraints.toFirestore()
          ..['minutesPerWeekday'] = {'1': 'two hours'};

        expect(
          () => PlanConstraints.fromFirestore(data),
          throwsFormatException,
        );
      },
    );

    test('fromFirestore throws FormatException when a field is missing', () {
      final data = constraints.toFirestore()..remove('maxSessionMinutes');

      expect(() => PlanConstraints.fromFirestore(data), throwsFormatException);
    });

    test('copyWith changes only the given fields', () {
      final updated = constraints.copyWith(maxSessionMinutes: 90);

      expect(updated.maxSessionMinutes, 90);
      expect(updated.minutesPerWeekday, constraints.minutesPerWeekday);
      expect(updated.daysOff, constraints.daysOff);
    });
  });
}
