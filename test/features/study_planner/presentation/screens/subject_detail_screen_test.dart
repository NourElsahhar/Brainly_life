import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/subject_detail_cubit.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/subject_detail_screen.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// "Now" is Friday 2026-11-20 10:00 UTC.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));

void main() {
  late MockStudyRepository repository;
  late SubjectDetailCubit cubit;
  late Subject physics;

  setUp(() async {
    repository = MockStudyRepository(clock: _clock, withSampleData: false);
    physics = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Physics',
        colorValue: 0xFF3F51B5,
        examDate: DateTime.utc(2026, 11, 26, 9),
        priority: 2,
      ),
    )).dataOrNull!;
    for (final (title, status) in [
      ('Motion', TopicStatus.done),
      ('Waves', TopicStatus.notStarted),
    ]) {
      await repository.addTopic(
        Topic(
          id: '',
          subjectId: physics.id,
          title: title,
          difficulty: 3,
          estimatedMinutes: 120,
          status: status,
          completedMinutes: 0,
        ),
      );
    }
    cubit = SubjectDetailCubit(repository, timezone: 'UTC', clock: _clock);
  });

  tearDown(() => cubit.close());

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(
          value: cubit,
          child: const SubjectDetailView(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the header, the topics and the generate button', (
    tester,
  ) async {
    await cubit.load(physics.id);
    await pumpView(tester);

    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Exam on Thu, 26 Nov · in 6 days'), findsOneWidget);
    expect(find.text('1 of 2 topics done'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Motion'), findsOneWidget);
    expect(find.text('Waves'), findsOneWidget);
    expect(find.text('Est. 2 h'), findsNWidgets(2));
    expect(find.text('Generate study plan'), findsOneWidget);
    expect(find.byTooltip('Delete subject'), findsOneWidget);
  });

  testWidgets('a missing subject shows Subject not found', (tester) async {
    await cubit.load('missing');
    await pumpView(tester);

    expect(find.text('Subject not found'), findsOneWidget);
    expect(find.byTooltip('Edit subject'), findsNothing);
  });

  testWidgets('menu, confirm, and the topic is deleted', (tester) async {
    await cubit.load(physics.id);
    await pumpView(tester);

    // The second tile is "Waves" (topics are sorted by title).
    await tester.tap(find.byTooltip('Topic options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    // The confirmation dialog has its own "Delete" button.
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Waves'), findsNothing);
    expect(find.text('"Waves" deleted'), findsOneWidget);
    final topics = (await repository.getTopics()).dataOrNull!;
    expect(topics.map((t) => t.title), ['Motion']);
  });
}
