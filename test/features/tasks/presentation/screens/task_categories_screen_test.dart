import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/tasks/data/models/task_category_model.dart';
import 'package:brainly_life/features/tasks/data/models/task_model.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_category_repository.dart';
import 'package:brainly_life/features/tasks/data/repositories/mock_task_repository.dart';
import 'package:brainly_life/features/tasks/logic/category_cubit.dart';
import 'package:brainly_life/features/tasks/presentation/screens/task_categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 15, 13);

  final report = Task(
    id: 'report',
    title: 'Write report',
    categoryId: 'uni',
    createdAt: now,
    updatedAt: now,
  );

  late MockTaskRepository tasks;
  late MockTaskCategoryRepository categories;

  setUp(() {
    tasks = MockTaskRepository(tasks: [report], now: () => now);
    categories = MockTaskCategoryRepository(
      categories: const [
        TaskCategory(id: 'uni', name: 'University', colorValue: 0xFF74B9FF),
        TaskCategory(id: 'home', name: 'Home', colorValue: 0xFF55EFC4),
      ],
    );
  });

  tearDown(() async {
    await tasks.dispose();
    await categories.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => CategoryCubit(categories, tasks)..load(),
          child: const TaskCategoriesView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The name box inside the bottom sheet.
  Finder nameField() => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(TextField),
  );

  testWidgets('shows the categories', (tester) async {
    await pumpScreen(tester);

    expect(find.text('University'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('no categories shows the empty view', (tester) async {
    categories = MockTaskCategoryRepository();
    await pumpScreen(tester);

    expect(find.text('No categories yet'), findsOneWidget);
  });

  testWidgets('adds a category', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), 'Gym');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing); // the sheet closed
    expect(find.text('Gym'), findsOneWidget);
  });

  testWidgets('a name that is taken shows an error', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('New category'));
    await tester.pumpAndSettle();
    await tester.enterText(nameField(), 'university');
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();

    expect(
      find.text('You already have a category with this name.'),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsOneWidget); // still open
  });

  testWidgets('tapping a category renames it', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('University'));
    await tester.pumpAndSettle();
    expect(find.text('Edit category'), findsOneWidget);

    await tester.enterText(nameField(), 'College');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('College'), findsOneWidget);
    expect(find.text('University'), findsNothing);
  });

  testWidgets('delete asks first, then its tasks become Uncategorized', (
    tester,
  ) async {
    await pumpScreen(tester);

    // "University" is the second row (sorted by name: Home, University).
    await tester.tap(find.byTooltip('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "University"?'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Delete')),
    );
    await tester.pumpAndSettle();

    expect(find.text('University'), findsNothing);
    final task = (await tasks.watchTask('report').first).dataOrNull!;
    expect(task.categoryId, isNull);
  });
}
