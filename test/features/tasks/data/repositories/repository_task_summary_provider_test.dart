import 'package:brainly_life/core/errors/failure.dart';
import 'package:brainly_life/features/home/data/repositories/home_summary_port.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/repository_task_summary_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  Task todo(String id, String title, {Duration? dueIn}) => Task(
    id: id,
    title: title,
    dueAt: dueIn == null ? null : now.add(dueIn),
    createdAt: now,
    updatedAt: now,
  );

  Task done(String id, Duration ago) {
    final completedAt = now.subtract(ago);
    return Task(
      id: id,
      title: 'Done $id',
      status: TaskStatus.done,
      completedAt: completedAt,
      createdAt: completedAt,
      updatedAt: completedAt,
    );
  }

  late MockTaskRepository repository;

  Future<TaskSummary> summaryOf(List<Task> tasks) async {
    repository = MockTaskRepository(tasks: tasks, now: () => now);
    final provider = RepositoryTaskSummaryProvider(repository, now: () => now);
    final result = await provider.todaySummary();
    return result.dataOrNull!;
  }

  tearDown(() => repository.dispose());

  test('counts today, overdue and completed today', () async {
    final summary = await summaryOf([
      todo('email', 'Old email', dueIn: const Duration(hours: -5)),
      todo('call', 'Call the bank', dueIn: const Duration(hours: -1)),
      todo('report', 'Write report', dueIn: const Duration(hours: 2)),
      todo('exam', 'Study for exam', dueIn: const Duration(days: 2)),
      todo('books', 'Read books'),
      done('d1', const Duration(hours: 1)),
      done('d2', const Duration(hours: 3)),
      done('yesterday', const Duration(hours: 20)),
    ]);

    expect(
      summary,
      const TaskSummary(
        dueTodayCount: 1,
        overdueCount: 2,
        completedTodayCount: 2,
        nextTaskTitle: 'Old email', // the oldest overdue task
      ),
    );
  });

  test('next task is the nearest today task when nothing is overdue', () async {
    final summary = await summaryOf([
      todo('late', 'Later today', dueIn: const Duration(hours: 5)),
      todo('soon', 'Soon', dueIn: const Duration(hours: 1)),
    ]);

    expect(summary.nextTaskTitle, 'Soon');
    expect(summary.dueTodayCount, 2);
  });

  test('upcoming tasks are not counted and give no next task', () async {
    final summary = await summaryOf([
      todo('exam', 'Study for exam', dueIn: const Duration(days: 2)),
      todo('books', 'Read books'),
    ]);

    expect(summary.isEmpty, isTrue);
    expect(summary.nextTaskTitle, isNull);
  });

  test('counts completed today across more than one page', () async {
    final summary = await summaryOf([
      for (var i = 1; i <= 25; i++) done('d$i', Duration(minutes: i)),
    ]);

    expect(summary.completedTodayCount, 25);
  });

  test(
    'a task done just after midnight counts, just before does not',
    () async {
      final summary = await summaryOf([
        done('after', const Duration(hours: 12, minutes: 59)), // 00:01 today
        done(
          'before',
          const Duration(hours: 13, minutes: 1),
        ), // 23:59 yesterday
      ]);

      expect(summary.completedTodayCount, 1);
    },
  );

  test('returns the failure when the repository fails', () async {
    repository = MockTaskRepository(now: () => now)
      ..failWith = const NetworkFailure();
    final provider = RepositoryTaskSummaryProvider(repository, now: () => now);

    final result = await provider.todaySummary();

    expect(result.failureOrNull, const NetworkFailure());
  });
}
