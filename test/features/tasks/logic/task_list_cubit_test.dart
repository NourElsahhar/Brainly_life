import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_list_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_list_state.dart';
import 'package:brainly_life/features/tasks/logic/task_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  Task task(
    String id,
    String title, {
    Duration? dueIn,
    TaskPriority priority = TaskPriority.medium,
  }) {
    return Task(
      id: id,
      title: title,
      priority: priority,
      dueAt: dueIn == null ? null : now.add(dueIn),
      createdAt: now,
      updatedAt: now,
    );
  }

  final email = task(
    'email',
    'Reply to email',
    dueIn: const Duration(hours: -2),
  );
  final slides = task(
    'slides',
    'Prepare slides',
    dueIn: const Duration(hours: 2),
    priority: TaskPriority.low,
  );
  final report = task(
    'report',
    'Write Report',
    dueIn: const Duration(hours: 4),
    priority: TaskPriority.high,
  );
  final exam = task('exam', 'Study for exam', dueIn: const Duration(days: 2));
  final books = task('books', 'Read books');

  late MockTaskRepository repository;
  late TaskListCubit cubit;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  TaskListCubit createCubit() =>
      TaskListCubit(repository, now: () => now, searchDelay: Duration.zero);

  TaskListLoaded loaded() => cubit.state as TaskListLoaded;

  List<String> visibleIds() => loaded().tasks.map((t) => t.id).toList();

  setUp(() {
    repository = MockTaskRepository(
      tasks: [email, slides, report, exam, books],
      now: () => now,
    );
    cubit = createCubit();
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('starts in TaskListInitial', () {
    expect(cubit.state, const TaskListInitial());
  });

  blocTest<TaskListCubit, TaskListState>(
    'load emits Loading, then the list',
    build: createCubit,
    act: (cubit) => cubit.load(),
    expect: () => [isA<TaskListLoading>(), isA<TaskListLoaded>()],
  );

  group('after load', () {
    setUp(() async {
      await cubit.load();
      await settle();
    });

    test('shows the today tab sorted by due date', () {
      expect(loaded().tab, TaskBucket.today);
      expect(visibleIds(), ['slides', 'report']);
    });

    test('counts the tasks of every tab', () {
      expect(loaded().countOf(TaskBucket.today), 2);
      expect(loaded().countOf(TaskBucket.overdue), 1);
      expect(loaded().countOf(TaskBucket.upcoming), 2);
      expect(loaded().countOf(TaskBucket.completed), 0);
    });

    test('selectTab shows another tab', () {
      cubit.selectTab(TaskBucket.overdue);
      expect(visibleIds(), ['email']);

      cubit.selectTab(TaskBucket.upcoming);
      expect(visibleIds(), ['exam', 'books']); // no due date goes last
    });

    test('search filters by title, ignoring case and spaces', () async {
      cubit.search('  REPORT ');
      await settle();

      expect(visibleIds(), ['report']);
      expect(loaded().query, 'report');
    });

    test('sortBy priority puts high priority first', () {
      cubit.sortBy(TaskSort.priority);

      expect(visibleIds(), ['report', 'slides']);
      expect(loaded().sort, TaskSort.priority);
    });

    test('completeTask hides the task, and undo brings it back', () async {
      await cubit.completeTask(slides);
      await settle();

      expect(visibleIds(), ['report']);
      expect(
        loaded().lastChange,
        TaskChange(type: TaskChangeType.completed, task: slides),
      );

      await cubit.undo();
      await settle();

      expect(visibleIds(), ['slides', 'report']);
      expect(loaded().lastChange, isNull);
    });

    test(
      'deleteTask removes the task, and undo restores the same id',
      () async {
        await cubit.deleteTask(report);
        await settle();

        expect(visibleIds(), ['slides']);
        expect(loaded().lastChange?.type, TaskChangeType.deleted);

        await cubit.undo();
        await settle();

        expect(visibleIds(), ['slides', 'report']);
      },
    );

    test('a failed action keeps the list and shows actionFailure', () async {
      repository.failWith = const NetworkFailure();

      await cubit.completeTask(slides);

      expect(visibleIds(), ['slides', 'report']);
      expect(loaded().actionFailure, const NetworkFailure());
      expect(loaded().lastChange, isNull);
    });
  });

  test('selectTab before load does not show a list', () {
    cubit.selectTab(TaskBucket.overdue);
    expect(cubit.state, const TaskListInitial());
  });

  test('completing the last task emits Empty with undo', () async {
    await repository.dispose();
    repository = MockTaskRepository(tasks: [slides], now: () => now);
    await cubit.close();
    cubit = createCubit();

    await cubit.load();
    await settle();
    await cubit.completeTask(slides);
    await settle();

    final state = cubit.state as TaskListEmpty;
    expect(state.lastChange?.type, TaskChangeType.completed);

    await cubit.undo();
    await settle();

    expect(visibleIds(), ['slides']);
  });

  test('a failing repository emits TaskListError', () async {
    repository.failWith = const NetworkFailure();

    await cubit.load();
    await settle();

    expect(cubit.state, const TaskListError(NetworkFailure()));
  });

  test('close cancels a waiting search without errors', () async {
    final other = createCubit();
    await other.load();
    await settle();

    other.search('report');
    await other.close();
    await settle();

    expect(other.isClosed, isTrue);
  });
}
