import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 15 Nov 2026, 13:00 UTC = 3:00 PM in Cairo.
  final now = DateTime.utc(2026, 11, 15, 13);
  DateTime fixedNow() => now;

  late MockTaskRepository repository;

  Task newTask(String title, {DateTime? dueAt}) {
    return Task(
      id: '',
      title: title,
      dueAt: dueAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<Task> completedTasks(int count) {
    return [
      for (var i = 1; i <= count; i++)
        Task(
          id: 'done_$i',
          title: 'Done $i',
          status: TaskStatus.done,
          completedAt: now.subtract(Duration(hours: i)),
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }

  /// Lets the streams deliver their pending events.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = MockTaskRepository(now: fixedNow);
  });

  tearDown(() => repository.dispose());

  group('sample data', () {
    test('has four active tasks, earliest deadline first, none last', () async {
      final sample = MockTaskRepository.withSampleData(now: fixedNow);

      final result = await sample.watchActiveTasks().first;

      expect(result.dataOrNull!.map((task) => task.id), [
        'sample_email',
        'sample_report',
        'sample_slides',
        'sample_books',
      ]);
      await sample.dispose();
    });

    test('has one completed task', () async {
      final sample = MockTaskRepository.withSampleData(now: fixedNow);

      final result = await sample.getCompletedTasks();

      expect(result.dataOrNull!.single.id, 'sample_groceries');
      await sample.dispose();
    });
  });

  group('createTask', () {
    test('sets the id and the times and returns the saved task', () async {
      final result = await repository.createTask(newTask('Read'));

      final saved = result.dataOrNull!;
      expect(saved.id, 'mock_task_1');
      expect(saved.title, 'Read');
      expect(saved.createdAt, now);
      expect(saved.updatedAt, now);
    });

    test('the active tasks stream emits again after a change', () async {
      final counts = <int>[];
      final subscription = repository.watchActiveTasks().listen(
        (result) => counts.add(result.dataOrNull!.length),
      );
      await settle();

      await repository.createTask(newTask('Read'));
      await settle();

      expect(counts, [0, 1]);
      await subscription.cancel();
    });
  });

  group('updateTask and deleteTask', () {
    test(
      'a done task leaves the active list and appears in completed',
      () async {
        final saved = (await repository.createTask(newTask('Read')))
            .dataOrNull!;

        await repository.updateTask(
          saved.copyWith(status: TaskStatus.done, completedAt: now),
        );

        final active = await repository.watchActiveTasks().first;
        final completed = await repository.getCompletedTasks();
        expect(active.dataOrNull, isEmpty);
        expect(completed.dataOrNull!.single.id, saved.id);
      },
    );

    test(
      'updating a task that does not exist returns NotFoundFailure',
      () async {
        final result = await repository.updateTask(
          newTask('Ghost').copyWith(id: 'missing'),
        );

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('watchTask emits NotFoundFailure after the task is deleted', () async {
      final saved = (await repository.createTask(newTask('Read'))).dataOrNull!;
      final found = <bool>[];
      final subscription = repository
          .watchTask(saved.id)
          .listen((result) => found.add(result.isSuccess));
      await settle();

      await repository.deleteTask(saved.id);
      await settle();

      expect(found, [true, false]);
      await subscription.cancel();
    });
  });

  group('getCompletedTasks', () {
    test('returns newest first, 20 per page, then the next page', () async {
      final paged = MockTaskRepository(
        tasks: completedTasks(25),
        now: fixedNow,
      );

      final page1 = (await paged.getCompletedTasks()).dataOrNull!;
      final page2 = (await paged.getCompletedTasks(afterTaskId: page1.last.id))
          .dataOrNull!;

      expect(page1, hasLength(20));
      expect(page1.first.id, 'done_1');
      expect(page2, hasLength(5));
      expect(page2.first.id, 'done_21');
      await paged.dispose();
    });

    test('skips tasks completed more than 30 days ago', () async {
      final old = completedTasks(1).single
          .copyWith(completedAt: now.subtract(const Duration(days: 31)));
      final withOld = MockTaskRepository(tasks: [old], now: fixedNow);

      final result = await withOld.getCompletedTasks();

      expect(result.dataOrNull, isEmpty);
      await withOld.dispose();
    });
  });

  group('failWith', () {
    test('every method returns the failure', () async {
      repository.failWith = const NetworkFailure();

      final created = await repository.createTask(newTask('Read'));
      final active = await repository.watchActiveTasks().first;
      final completed = await repository.getCompletedTasks();

      expect(created.failureOrNull, const NetworkFailure());
      expect(active.failureOrNull, const NetworkFailure());
      expect(completed.failureOrNull, const NetworkFailure());
    });
  });
}
