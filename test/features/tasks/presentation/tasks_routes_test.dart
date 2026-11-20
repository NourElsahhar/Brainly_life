import 'package:brainly_life/core/routes/app_routes.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/presentation/tasks_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:brainly_life/features/tasks/tasks_injection.dart';
import 'package:brainly_life/injection.dart';

void main() {
  setUp(() => registerTasksFeature(getIt, useMocks: true));
  tearDown(() => getIt.reset());
  Future<GoRouter> pumpRoutes(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.tasks,
      routes: tasksRoutes,
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder appBarTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  test('paths', () {
    expect(AppRoutes.taskPath('abc'), '/tasks/abc');
    expect(AppRoutes.editTaskPath('abc'), '/tasks/abc/edit');
  });

  final cases = {
    AppRoutes.tasks: 'Tasks',
    AppRoutes.newTask: 'New task', // not a task called "new"
    AppRoutes.taskCategories: 'Categories',
    AppRoutes.taskPath('abc'): 'Task abc',
    AppRoutes.editTaskPath('abc'): 'Edit task abc',
  };

  cases.forEach((path, title) {
    testWidgets('$path opens "$title"', (tester) async {
      final router = await pumpRoutes(tester);

      router.go(path);
      await tester.pumpAndSettle();

      expect(appBarTitle(title), findsOneWidget);
    });
  });
}
