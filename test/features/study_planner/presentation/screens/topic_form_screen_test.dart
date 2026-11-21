import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/topic_form_cubit.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/topic_form_screen.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockStudyRepository repository;
  late TopicFormCubit cubit;

  setUp(() async {
    repository = MockStudyRepository(
      clock: Clock.fixed(DateTime.utc(2026, 11, 20, 10)),
      withSampleData: false,
    );
    final physics = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Physics',
        colorValue: 0xFF3F51B5,
        examDate: DateTime.utc(2026, 11, 26),
        priority: 2,
      ),
    )).dataOrNull!;
    cubit = TopicFormCubit(repository)..startCreate(physics.id);
  });

  tearDown(() => cubit.close());

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const TopicFormView()),
      ),
    );
  }

  testWidgets('Save with empty fields shows the field errors', (tester) async {
    await pumpForm(tester);

    // The test screen is small: scroll to the button first.
    await tester.ensureVisible(find.text('Save topic'));
    await tester.tap(find.text('Save topic'));
    await tester.pump();

    expect(find.text('Enter a topic title'), findsOneWidget);
    expect(find.text('Pick a difficulty'), findsOneWidget);
    expect(find.text('Enter the estimated hours'), findsOneWidget);
    expect(find.text('Delete topic'), findsNothing);
  });

  testWidgets('hours out of range shows the range error', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextField).first, 'Optics');
    await tester.tap(find.text('3'));
    await tester.enterText(find.byType(TextField).last, '300');
    // The test screen is small: scroll to the button first.
    await tester.ensureVisible(find.text('Save topic'));
    await tester.tap(find.text('Save topic'));
    await tester.pump();

    expect(find.text('Use between 0.5 and 200 hours'), findsOneWidget);
    expect(find.text('Enter a topic title'), findsNothing);
    expect(find.text('Pick a difficulty'), findsNothing);
  });
}
