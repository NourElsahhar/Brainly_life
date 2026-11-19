import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/repository_task_creation_port.dart';
import 'package:brainly_life/features/tasks/data/repositories/task_creation_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  late MockTaskRepository repository;
  late RepositoryTaskCreationPort port;

  setUp(() {
    repository = MockTaskRepository(now: () => now);
    port = RepositoryTaskCreationPort(repository, now: () => now);
  });

  tearDown(() => repository.dispose());

  Future<Task> savedTask(String id) async {
    final result = await repository.watchTask(id).first;
    return result.dataOrNull!;
  }

  Future<List<Task>> allActiveTasks() async {
    final result = await repository.watchActiveTasks().first;
    return result.dataOrNull!;
  }

  test('creates the task and returns its id', () async {
    final due = DateTime.utc(2026, 11, 16, 17);

    final result = await port.createTask(
      TaskDraft(
        title: 'Study physics',
        description: 'Chapters 1 and 2',
        priority: TaskPriority.high,
        dueAt: due,
        subtaskTitles: const ['Chapter 1', 'Chapter 2'],
      ),
    );

    final id = result.dataOrNull!;
    final task = await savedTask(id);
    expect(task.title, 'Study physics');
    expect(task.description, 'Chapters 1 and 2');
    expect(task.priority, TaskPriority.high);
    expect(task.dueAt, due);
    expect(task.subtasks.map((s) => s.title), ['Chapter 1', 'Chapter 2']);
    expect(task.subtasks.map((s) => s.id), ['subtask_1', 'subtask_2']);
  });

  test('a short draft gets the defaults', () async {
    final result = await port.createTask(const TaskDraft(title: 'Call mom'));

    final task = await savedTask(result.dataOrNull!);
    expect(task.status, TaskStatus.todo);
    expect(task.priority, TaskPriority.medium);
    expect(task.categoryId, isNull); // Uncategorized
    expect(task.dueAt, isNull);
    expect(task.subtasks, isEmpty);
  });

  test('trims the text and drops empty checklist items', () async {
    final result = await port.createTask(
      const TaskDraft(
        title: '  Study physics  ',
        description: '   ',
        subtaskTitles: ['  Chapter 1 ', '', '   ', 'Chapter 2'],
      ),
    );

    final task = await savedTask(result.dataOrNull!);
    expect(task.title, 'Study physics');
    expect(task.description, isNull);
    expect(task.subtasks.map((s) => s.title), ['Chapter 1', 'Chapter 2']);
  });

  test('saves dueAt in UTC', () async {
    final localDue = DateTime(2026, 11, 16, 17); // not UTC

    final result = await port.createTask(
      TaskDraft(title: 'Study', dueAt: localDue),
    );

    final task = await savedTask(result.dataOrNull!);
    expect(task.dueAt!.isUtc, isTrue);
    expect(task.dueAt!.isAtSameMomentAs(localDue), isTrue);
  });

  group('returns ValidationFailure and saves nothing when', () {
    final drafts = {
      'the title is empty': const TaskDraft(title: ''),
      'the title is only spaces': const TaskDraft(title: '   '),
      'the title is too long': TaskDraft(title: 'a' * 101),
      'the description is too long': TaskDraft(
        title: 'Study',
        description: 'a' * 1001,
      ),
      'there are too many checklist items': TaskDraft(
        title: 'Study',
        subtaskTitles: [for (var i = 0; i < 21; i++) 'Item $i'],
      ),
    };

    drafts.forEach((reason, draft) {
      test(reason, () async {
        final result = await port.createTask(draft);

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(await allActiveTasks(), isEmpty);
      });
    });
  });

  test('the longest allowed title is accepted', () async {
    final result = await port.createTask(TaskDraft(title: 'a' * 100));

    expect(result.isSuccess, isTrue);
  });

  test('returns the repository failure', () async {
    repository.failWith = const NetworkFailure();

    final result = await port.createTask(const TaskDraft(title: 'Study'));

    expect(result.failureOrNull, const NetworkFailure());
  });
}
