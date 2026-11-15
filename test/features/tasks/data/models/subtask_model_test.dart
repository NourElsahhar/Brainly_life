import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const subtask = Subtask(id: 's1', title: 'Read chapter 1');

  group('Subtask', () {
    test('is not done by default', () {
      expect(subtask.done, isFalse);
    });

    test('two subtasks with the same values are equal', () {
      expect(subtask, equals(const Subtask(id: 's1', title: 'Read chapter 1')));
    });

    test('copyWith can mark it as done without changing the rest', () {
      final checked = subtask.copyWith(done: true);

      expect(checked.done, isTrue);
      expect(checked.id, subtask.id);
      expect(checked.title, subtask.title);
      expect(subtask.done, isFalse);
    });

    test('toMap keeps the id inside the map', () {
      expect(subtask.toMap(), {
        'id': 's1',
        'title': 'Read chapter 1',
        'done': false,
      });
    });

    test('fromMap(toMap()) gives back the same subtask', () {
      final checked = subtask.copyWith(done: true);

      expect(Subtask.fromMap(checked.toMap()), equals(checked));
    });

    test('fromMap treats a missing done field as false', () {
      final restored = Subtask.fromMap({'id': 's2', 'title': 'Old data'});

      expect(restored.done, isFalse);
    });
  });
}
