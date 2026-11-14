import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const category = TaskCategory(
    id: 'c1',
    name: 'University',
    colorValue: 0xFF4CAF50,
  );

  group('TaskCategory', () {
    test('two categories with the same values are equal', () {
      expect(
        category,
        equals(
          const TaskCategory(
            id: 'c1',
            name: 'University',
            colorValue: 0xFF4CAF50,
          ),
        ),
      );
    });

    test('copyWith can rename without changing the rest', () {
      final renamed = category.copyWith(name: 'College');

      expect(renamed.name, 'College');
      expect(renamed.id, category.id);
      expect(renamed.colorValue, category.colorValue);
      expect(category.name, 'University');
    });

    test('toFirestore does not store the id', () {
      expect(category.toFirestore(), {
        'name': 'University',
        'colorValue': 0xFF4CAF50,
      });
    });

    test('fromMap(toFirestore()) gives back the same category', () {
      final restored = TaskCategory.fromMap(
        category.id,
        category.toFirestore(),
      );

      expect(restored, equals(category));
    });
  });
}
