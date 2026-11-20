import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_cubit.dart';
import 'package:brainly_life/features/tasks/logic/completed_tasks_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  /// A task completed [hoursAgo] hours before [now].
  Task doneTask(String id, int hoursAgo) {
    final completedAt = now.subtract(Duration(hours: hoursAgo));
    return Task(
      id: id,
      title: 'Task $id',
      status: TaskStatus.done,
      completedAt: completedAt,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }

  // 25 done tasks: done_0 is the newest, done_24 the oldest.
  final done = [for (var i = 0; i < 25; i++) doneTask('done_$i', i + 1)];
  final active = Task(
    id: 'active',
    title: 'Not done yet',
    createdAt: now,
    updatedAt: now,
  );
  final tooOld = doneTask('too_old', 24 * 40); // 40 days ago

  late MockTaskRepository repository;
  late CompletedTasksCubit cubit;

  CompletedTasksLoaded loaded() => cubit.state as CompletedTasksLoaded;

  List<String> ids() => loaded().tasks.map((t) => t.id).toList();

  setUp(() {
    repository = MockTaskRepository(
      tasks: [...done, active, tooOld],
      now: () => now,
    );
    cubit = CompletedTasksCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('starts in CompletedTasksInitial', () {
    expect(cubit.state, const CompletedTasksInitial());
  });

  blocTest<CompletedTasksCubit, CompletedTasksState>(
    'load emits Loading, then the first page',
    build: () => CompletedTasksCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [isA<CompletedTasksLoading>(), isA<CompletedTasksLoaded>()],
  );

  group('after load', () {
    setUp(() => cubit.load());

    test('shows the 20 newest done tasks and hasMore', () {
      expect(ids(), [for (var i = 0; i < 20; i++) 'done_$i']);
      expect(loaded().hasMore, isTrue);
      expect(loaded().isLoadingMore, isFalse);
    });

    test('loadMore adds the next page, then hasMore is false', () async {
      await cubit.loadMore();

      expect(ids(), [for (var i = 0; i < 25; i++) 'done_$i']);
      expect(loaded().hasMore, isFalse); // too_old is not included
    });

    test('loadMore does nothing when there is no more', () async {
      await cubit.loadMore();
      final before = cubit.state;

      await cubit.loadMore();

      expect(cubit.state, before);
    });

    test('two loadMore calls at the same time load the page once', () async {
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);

      expect(ids().length, 25); // not 30
    });

    test('a failed loadMore keeps the list, and retry works', () async {
      repository.failWith = const NetworkFailure();
      await cubit.loadMore();

      expect(ids().length, 20);
      expect(loaded().loadMoreFailure, const NetworkFailure());

      repository.failWith = null;
      await cubit.loadMore();

      expect(ids().length, 25);
      expect(loaded().loadMoreFailure, isNull);
    });

    test('reopenTask removes the task and makes it active again', () async {
      await cubit.reopenTask(done[0]);

      expect(ids(), isNot(contains('done_0')));
      expect(loaded().lastDeleted, isNull);

      final activeTasks = await repository.watchActiveTasks().first;
      final activeIds = activeTasks.dataOrNull!.map((t) => t.id);
      expect(activeIds, contains('done_0'));
    });

    test(
      'deleteTask removes the task, and undo puts it back in place',
      () async {
        await cubit.deleteTask(done[1]);

        expect(ids(), isNot(contains('done_1')));
        expect(loaded().lastDeleted, done[1]);

        await cubit.undo();

        expect(ids()[1], 'done_1');
        expect(loaded().lastDeleted, isNull);
      },
    );

    test('a failed action keeps the list and shows actionFailure', () async {
      repository.failWith = const NetworkFailure();

      await cubit.deleteTask(done[0]);

      expect(ids().length, 20);
      expect(loaded().actionFailure, const NetworkFailure());
      expect(loaded().lastDeleted, isNull);
    });

    test('an old loadMore answer is ignored after a new load', () async {
      final oldLoadMore = cubit.loadMore(); // not awaited yet
      final newLoad = cubit.load();
      await Future.wait([oldLoadMore, newLoad]);

      expect(ids().length, 20);
      expect(loaded().hasMore, isTrue);
    });

    test('deleteTask hides the task right away', () async {
      final future = cubit.deleteTask(done[0]);

      expect(ids(), isNot(contains('done_0')));
      await future;
    });
  });

  test('no done tasks emits Empty', () async {
    await repository.dispose();
    repository = MockTaskRepository(tasks: [active], now: () => now);
    await cubit.close();
    cubit = CompletedTasksCubit(repository);

    await cubit.load();

    expect(cubit.state, const CompletedTasksEmpty());
  });

  test('deleting the only done task emits Empty with undo', () async {
    await repository.dispose();
    repository = MockTaskRepository(tasks: [done[0]], now: () => now);
    await cubit.close();
    cubit = CompletedTasksCubit(repository);

    await cubit.load();
    await cubit.deleteTask(done[0]);

    expect(cubit.state, CompletedTasksEmpty(lastDeleted: done[0]));

    await cubit.undo();

    expect(ids(), ['done_0']);
  });

  test('a failing first page emits CompletedTasksError', () async {
    repository.failWith = const NetworkFailure();

    await cubit.load();

    expect(cubit.state, const CompletedTasksError(NetworkFailure()));
  });
}
