import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockTaskCategoryRepository repository;

  TaskCategory category(String name, {int colorValue = 0xFF2196F3}) =>
      TaskCategory(id: '', name: name, colorValue: colorValue);

  Future<List<TaskCategory>> current() async {
    final result = await repository.watchCategories().first;
    return result.dataOrNull!;
  }

  /// Lets the stream deliver its pending events.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() => repository = MockTaskCategoryRepository());

  tearDown(() => repository.dispose());

  test('sample data has University and Personal, sorted by name', () async {
    repository = MockTaskCategoryRepository.withSampleData();

    expect((await current()).map((c) => c.name), ['Personal', 'University']);
  });

  test('createCategory sets an id and keeps name and colour', () async {
    final result = await repository.createCategory(
      category('Gym', colorValue: 0xFFFF9800),
    );

    final saved = result.dataOrNull!;
    expect(saved.id, isNotEmpty);
    expect(await current(), [saved]);
    expect(saved.colorValue, 0xFFFF9800);
  });

  test('sorts by name, ignoring upper and lower case', () async {
    await repository.createCategory(category('University'));
    await repository.createCategory(category('personal'));
    await repository.createCategory(category('Art'));

    expect((await current()).map((c) => c.name), [
      'Art',
      'personal',
      'University',
    ]);
  });

  test('updateCategory renames and recolours', () async {
    final saved = (await repository.createCategory(category('Uni')))
        .dataOrNull!;

    await repository.updateCategory(
      saved.copyWith(name: 'University', colorValue: 0xFFE91E63),
    );

    expect(await current(), [
      TaskCategory(id: saved.id, name: 'University', colorValue: 0xFFE91E63),
    ]);
  });

  test(
    'updateCategory of a missing category returns NotFoundFailure',
    () async {
      final result = await repository.updateCategory(
        const TaskCategory(id: 'missing', name: 'X', colorValue: 0),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    },
  );

  test('deleteCategory removes it, and a missing id is fine', () async {
    final saved = (await repository.createCategory(category('Uni')))
        .dataOrNull!;

    await repository.deleteCategory(saved.id);
    final again = await repository.deleteCategory(saved.id);

    expect(await current(), isEmpty);
    expect(again.isSuccess, isTrue);
  });

  test('watchCategories sends the new list after every change', () async {
    final names = <List<String>>[];
    final subscription = repository.watchCategories().listen(
      (result) => names.add(result.dataOrNull!.map((c) => c.name).toList()),
    );
    await settle();

    await repository.createCategory(category('Uni'));
    await settle();
    await repository.createCategory(category('Art'));
    await settle();

    expect(names, [
      <String>[],
      ['Uni'],
      ['Art', 'Uni'],
    ]);
    await subscription.cancel();
  });

  test('failWith makes every method fail', () async {
    repository.failWith = const NetworkFailure();

    expect(
      (await repository.createCategory(category('Uni'))).failureOrNull,
      const NetworkFailure(),
    );
    expect(
      (await repository.watchCategories().first).failureOrNull,
      const NetworkFailure(),
    );
    expect(
      (await repository.deleteCategory('x')).failureOrNull,
      const NetworkFailure(),
    );
  });
}
