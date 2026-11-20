import 'package:bloc_test/bloc_test.dart';
import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/subtask_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_cubit.dart';
import 'package:brainly_life/features/tasks/logic/task_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  // Due in 2 hours, half of its checklist done.
  final report = Task(
    id: 'report',
    title: 'Write report',
    dueAt: now.add(const Duration(hours: 2)),
    subtasks: const [
      Subtask(id: 'subtask_1', title: 'Intro', done: true),
      Subtask(id: 'subtask_2', title: 'Results'),
    ],
    createdAt: now,
    updatedAt: now,
  );

  final late = Task(
    id: 'late',
    title: 'Pay the bill',
    dueAt: now.subtract(const Duration(hours: 1)),
    createdAt: now,
    updatedAt: now,
  );

  final finished = Task(
    id: 'finished',
    title: 'Buy books',
    status: TaskStatus.done,
    completedAt: now.subtract(const Duration(hours: 3)),
    createdAt: now,
    updatedAt: now,
  );

  late MockTaskRepository repository;
  late TaskDetailCubit cubit;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  TaskDetailLoaded loaded() => cubit.state as TaskDetailLoaded;

  Future<void> open(String id) async {
    await cubit.load(id);
    await settle();
  }

  setUp(() {
    repository = MockTaskRepository(
      tasks: [report, late, finished],
      now: () => now,
    );
    cubit = TaskDetailCubit(repository, now: () => now);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('starts in TaskDetailInitial', () {
    expect(cubit.state, const TaskDetailInitial());
  });

  blocTest<TaskDetailCubit, TaskDetailState>(
    'load emits Loading, then the task',
    build: () => TaskDetailCubit(repository, now: () => now),
    act: (cubit) => cubit.load('report'),
    expect: () => [isA<TaskDetailLoading>(), isA<TaskDetailLoaded>()],
  );

  test('shows progress and the due soon flag', () async {
    await open('report');

    expect(loaded().task.title, 'Write report');
    expect(loaded().progress, 0.5);
    expect(loaded().isDueSoon, isTrue);
    expect(loaded().isOverdue, isFalse);
  });

  test('an overdue task has isOverdue', () async {
    await open('late');

    expect(loaded().isOverdue, isTrue);
  });

  test('a change from another screen shows up by itself', () async {
    await open('report');

    await repository.updateTask(report.copyWith(title: 'Write final report'));
    await settle();

    expect(loaded().task.title, 'Write final report');
  });

  test('toggleSubtask ticks the item and updates the progress', () async {
    await open('report');

    final failure = await cubit.toggleSubtask('subtask_2');
    await settle();

    expect(failure, isNull);
    expect(loaded().task.subtasks.every((s) => s.done), isTrue);
    expect(loaded().progress, 1.0);
  });

  test('markDone saves done with the completion time', () async {
    await open('report');

    await cubit.markDone();
    await settle();

    expect(loaded().task.status, TaskStatus.done);
    expect(loaded().task.completedAt, now);
    expect(loaded().isDueSoon, isFalse); // done tasks are not due soon
  });

  test('reopen makes a done task not done again', () async {
    await open('finished');

    await cubit.reopen();
    await settle();

    expect(loaded().task.status, TaskStatus.todo);
    expect(loaded().task.completedAt, isNull);
  });

  test('markDone on a done task does nothing', () async {
    await open('finished');
    final before = cubit.state;

    final failure = await cubit.markDone();
    await settle();

    expect(failure, isNull);
    expect(cubit.state, before);
  });

  test('delete emits Deleted, without showing "not found" first', () async {
    await open('report');
    final states = <TaskDetailState>[];
    final subscription = cubit.stream.listen(states.add);

    final failure = await cubit.delete();
    await settle();

    expect(failure, isNull);
    expect(states, [const TaskDetailDeleted()]);
    final gone = await repository.watchTask('report').first;
    expect(gone.failureOrNull, isA<NotFoundFailure>());
    await subscription.cancel();
  });

  test('a failed delete returns the failure and keeps the task', () async {
    await open('report');
    repository.failWith = const NetworkFailure();

    final failure = await cubit.delete();

    expect(failure, const NetworkFailure());
    expect(loaded().task.id, 'report');
  });

  test('a failed action returns the failure', () async {
    await open('report');
    repository.failWith = const NetworkFailure();

    expect(await cubit.markDone(), const NetworkFailure());
  });

  test('a missing task emits NotFound', () async {
    await open('missing');

    expect(cubit.state, const TaskDetailNotFound());
  });

  test('a failing repository emits Error', () async {
    repository.failWith = const NetworkFailure();

    await open('report');

    expect(cubit.state, const TaskDetailError(NetworkFailure()));
  });
}
