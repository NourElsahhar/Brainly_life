// Tests for FirestoreTaskRepository and FirestoreTaskCategoryRepository
// with a fake data source (mocktail): the dates are set, the 30-day window
// is sent, a missing task is NotFoundFailure, Firebase errors become
// Failures, and a stream error stays INSIDE the stream as a Failure.

import 'dart:async';

import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/firestore_task_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_profile_source.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements TaskRemoteDataSource {}

void main() {
  final now = DateTime.utc(2026, 11, 25, 10);
  final old = DateTime.utc(2026, 11, 1);

  Task task(String id) =>
      Task(id: id, title: 'Task $id', createdAt: old, updatedAt: old);

  late _MockDataSource dataSource;
  late FirestoreTaskRepository tasks;
  late FirestoreTaskCategoryRepository categories;

  setUpAll(() {
    registerFallbackValue(task('fallback'));
    registerFallbackValue(
      const TaskCategory(id: 'fallback', name: 'x', colorValue: 0),
    );
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    dataSource = _MockDataSource();
    tasks = FirestoreTaskRepository(dataSource: dataSource, now: () => now);
    categories = FirestoreTaskCategoryRepository(dataSource: dataSource);
  });

  group('tasks', () {
    test('createTask sets createdAt and updatedAt to now', () async {
      when(() => dataSource.createTask(any())).thenAnswer(
        (call) async =>
            (call.positionalArguments.first as Task).copyWith(id: 'new'),
      );

      final result = await tasks.createTask(task(''));

      final saved = result.dataOrNull!;
      expect(saved.id, 'new');
      expect(saved.createdAt, now);
      expect(saved.updatedAt, now);
    });

    test('updateTask refreshes updatedAt and keeps createdAt', () async {
      when(() => dataSource.updateTask(any())).thenAnswer((_) async {});

      await tasks.updateTask(task('a'));

      final sent =
          verify(() => dataSource.updateTask(captureAny())).captured.single
              as Task;
      expect(sent.updatedAt, now);
      expect(sent.createdAt, old);
    });

    test('getCompletedTasks asks for the last 30 days', () async {
      when(
        () => dataSource.getCompletedTasks(
          since: any(named: 'since'),
          limit: any(named: 'limit'),
          afterTaskId: any(named: 'afterTaskId'),
        ),
      ).thenAnswer((_) async => [task('done')]);

      final result = await tasks.getCompletedTasks(afterTaskId: 'last');

      expect(result.dataOrNull, [task('done')]);
      verify(
        () => dataSource.getCompletedTasks(
          since: now.subtract(const Duration(days: 30)),
          limit: 20,
          afterTaskId: 'last',
        ),
      ).called(1);
    });

    test('a Firebase error becomes a Failure', () async {
      when(() => dataSource.deleteTask(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await tasks.deleteTask('a');

      expect(result.isSuccess, isFalse);
      expect(result.failureOrNull, isA<Failure>());
    });

    test('watchTask: a missing task is NotFoundFailure', () async {
      when(() => dataSource.watchTask('gone'))
          .thenAnswer((_) => Stream.value(null));

      final result = await tasks.watchTask('gone').first;

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('a stream error stays in the stream as a Failure', () async {
      final controller = StreamController<List<Task>>();
      when(() => dataSource.watchActiveTasks())
          .thenAnswer((_) => controller.stream);

      final results = <Result<List<Task>>>[];
      final subscription = tasks.watchActiveTasks().listen(results.add);
      controller
        ..add([task('a')])
        ..addError(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        )
        ..add([task('a'), task('b')]);
      await pumpEventQueue();

      expect(results, hasLength(3));
      expect(results[0].dataOrNull, [task('a')]);
      expect(results[1].failureOrNull, isA<Failure>());
      expect(results[2].dataOrNull, hasLength(2)); // still open
      await subscription.cancel();
      await controller.close();
    });

    test('no signed-in user is a Failure, not a crash', () async {
      when(() => dataSource.watchActiveTasks())
          .thenThrow(FirebaseAuthException(code: 'no-current-user'));

      final result = await tasks.watchActiveTasks().first;

      expect(result.failureOrNull, isA<Failure>());
    });

    test('clearCategory sends the time of the change', () async {
      when(() => dataSource.clearCategory(any(), any()))
          .thenAnswer((_) async {});

      final result = await tasks.clearCategory('uni');

      expect(result.isSuccess, isTrue);
      verify(() => dataSource.clearCategory('uni', now)).called(1);
    });
  });

  group('categories', () {
    test('watchCategories sorts by name, ignoring case', () async {
      when(() => dataSource.watchCategories()).thenAnswer(
        (_) => Stream.value([
          const TaskCategory(id: '1', name: 'gym', colorValue: 1),
          const TaskCategory(id: '2', name: 'Art', colorValue: 2),
          const TaskCategory(id: '3', name: 'University', colorValue: 3),
        ]),
      );

      final result = await categories.watchCategories().first;

      expect(result.dataOrNull!.map((c) => c.name), [
        'Art',
        'gym',
        'University',
      ]);
    });

    test('updateCategory on a missing category is NotFoundFailure', () async {
      when(() => dataSource.updateCategory(any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );

      final result = await categories.updateCategory(
        const TaskCategory(id: 'gone', name: 'x', colorValue: 0),
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('profile tasks done', () {
    test('returns the count of done tasks', () async {
      when(() => dataSource.countDoneTasks()).thenAnswer((_) async => 7);

      final result = await FirestoreTaskProfileSource(dataSource: dataSource)
          .tasksDone();

      expect(result.dataOrNull, 7);
    });

    test('a Firebase error becomes a Failure', () async {
      when(() => dataSource.countDoneTasks()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await FirestoreTaskProfileSource(dataSource: dataSource)
          .tasksDone();

      expect(result.failureOrNull, isA<Failure>());
    });

    test('the mock returns its fixed number', () async {
      final result = await const MockTaskProfileSource(count: 3).tasksDone();

      expect(result.dataOrNull, 3);
    });
  });
}
