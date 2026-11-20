import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/logic/category_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);
  const blue = 0xFF2196F3;
  const green = 0xFF4CAF50;
  const pink = 0xFFE91E63;

  const uni = TaskCategory(id: 'uni', name: 'University', colorValue: blue);
  const home = TaskCategory(id: 'home', name: 'Home', colorValue: green);

  Task task(String id, String categoryId) => Task(
    id: id,
    title: 'Task $id',
    categoryId: categoryId,
    createdAt: now,
    updatedAt: now,
  );

  late MockTaskCategoryRepository categories;
  late MockTaskRepository tasks;
  late CategoryCubit cubit;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<String> names() =>
      (cubit.state as CategoryLoaded).categories.map((c) => c.name).toList();

  Future<Task> taskById(String id) async =>
      (await tasks.watchTask(id).first).dataOrNull!;

  setUp(() {
    categories = MockTaskCategoryRepository(categories: [uni, home]);
    tasks = MockTaskRepository(
      tasks: [task('lecture', 'uni'), task('cook', 'home')],
      now: () => now,
    );
    cubit = CategoryCubit(categories, tasks);
  });

  tearDown(() async {
    await cubit.close();
    await categories.dispose();
    await tasks.dispose();
  });

  test('starts in CategoryInitial', () {
    expect(cubit.state, const CategoryInitial());
  });

  blocTest<CategoryCubit, CategoryState>(
    'load emits Loading, then the categories sorted by name',
    build: () => CategoryCubit(categories, tasks),
    act: (cubit) => cubit.load(),
    expect: () => [
      const CategoryLoading(),
      const CategoryLoaded([home, uni]),
    ],
  );

  test('a failing repository emits CategoryError', () async {
    categories.failWith = const NetworkFailure();

    await cubit.load();
    await settle();

    expect(cubit.state, const CategoryError(NetworkFailure()));
  });

  group('after load', () {
    setUp(() async {
      await cubit.load();
      await settle();
    });

    test('create adds the category with a trimmed name', () async {
      final failure = await cubit.create('  Gym  ', pink);
      await settle();

      expect(failure, isNull);
      expect(names(), ['Gym', 'Home', 'University']);
    });

    group('create returns ValidationFailure and adds nothing when', () {
      final badNames = {
        'the name is empty': '',
        'the name is only spaces': '   ',
        'the name is longer than 30': 'a' * 31,
        'the name is taken (any case)': 'uNiVeRsItY',
      };

      badNames.forEach((reason, name) {
        test(reason, () async {
          final failure = await cubit.create(name, pink);
          await settle();

          expect(failure, isA<ValidationFailure>());
          expect(names(), ['Home', 'University']);
        });
      });
    });

    test('a name of exactly 30 characters is accepted', () async {
      expect(await cubit.create('a' * 30, pink), isNull);
    });

    test('rename saves the new name', () async {
      final failure = await cubit.rename(uni, 'Uni');
      await settle();

      expect(failure, isNull);
      expect(names(), ['Home', 'Uni']);
    });

    test('rename can change only the case of its own name', () async {
      expect(await cubit.rename(uni, 'UNIVERSITY'), isNull);
    });

    test('rename to another category name fails', () async {
      final failure = await cubit.rename(uni, 'home');

      expect(failure, isA<ValidationFailure>());
    });

    test('recolor saves the new colour', () async {
      final failure = await cubit.recolor(uni, pink);
      await settle();

      expect(failure, isNull);
      final saved = (cubit.state as CategoryLoaded).categories.last;
      expect(saved.colorValue, pink);
    });

    test(
      'delete removes the category and its tasks become Uncategorized',
      () async {
        final failure = await cubit.delete(uni);
        await settle();

        expect(failure, isNull);
        expect(names(), ['Home']);
        expect((await taskById('lecture')).categoryId, isNull);
        expect((await taskById('cook')).categoryId, 'home'); // not touched
      },
    );

    test('a failed delete keeps the tasks in their category', () async {
      categories.failWith = const NetworkFailure();

      final failure = await cubit.delete(uni);

      expect(failure, const NetworkFailure());
      expect((await taskById('lecture')).categoryId, 'uni');
    });

    test('a failed save returns the repository failure', () async {
      categories.failWith = const NetworkFailure();

      expect(await cubit.create('Gym', pink), const NetworkFailure());
    });
  });
}
