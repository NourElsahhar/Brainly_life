import 'package:brainly_life/core/ai/ai_failures.dart';
import 'package:brainly_life/core/errors/result.dart';
import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/study_planner/data/models/plan_constraints_model.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/subject_model.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/data/repositories/mock_study_repository.dart';
import 'package:brainly_life/features/study_planner/logic/plan_generation_service.dart';
import 'package:brainly_life/features/study_planner/logic/plan_wizard_cubit.dart';
import 'package:brainly_life/features/study_planner/logic/study_plan_payload.dart';
import 'package:brainly_life/features/study_planner/presentation/screens/plan_wizard_screen.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeGenerator extends Mock implements PlanGenerationService {}

// Friday 2026-11-20, 12:00 in Cairo.
final _clock = Clock.fixed(DateTime.utc(2026, 11, 20, 10));
const _cairo = 'Africa/Cairo';

void main() {
  late MockStudyRepository repository;
  late _FakeGenerator generator;
  late PlanWizardCubit cubit;

  setUpAll(() {
    registerFallbackValue(
      const StudyPlanRequest(
        payload: {},
        days: [],
        subjects: [],
        topics: [],
        constraints: PlanConstraints(
          minutesPerWeekday: {},
          daysOff: {},
          maxSessionMinutes: 45,
          breakMinutes: 10,
        ),
      ),
    );
  });

  setUp(() async {
    repository = MockStudyRepository(clock: _clock, withSampleData: false);
    generator = _FakeGenerator();
    final physics = (await repository.addSubject(
      Subject(
        id: '',
        name: 'Physics',
        colorValue: 0xFF3F51B5,
        examDate: DateTime.utc(2026, 11, 26, 7),
        priority: 2,
      ),
    )).dataOrNull!;
    for (final title in ['Waves', 'Optics']) {
      await repository.addTopic(
        Topic(
          id: '',
          subjectId: physics.id,
          title: title,
          difficulty: 3,
          estimatedMinutes: 120,
          status: TopicStatus.notStarted,
          completedMinutes: 0,
        ),
      );
    }
    cubit = PlanWizardCubit(
      repository,
      generator,
      payloadBuilder: StudyPlanPayloadBuilder(clock: _clock, timezone: _cairo),
    );
    await cubit.load();
  });

  tearDown(() => cubit.close());

  Future<void> pumpWizard(WidgetTester tester) async {
    // A phone-sized screen, so step 2 fits.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider.value(value: cubit, child: const PlanWizardView()),
      ),
    );
    await tester.pump();
  }

  testWidgets('step 1 lists the topics; Continue needs one selected', (
    tester,
  ) async {
    await pumpWizard(tester);

    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Optics'), findsOneWidget);
    expect(find.text('Waves'), findsOneWidget);

    await tester.tap(find.text('All topics')); // all selected -> none
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('step 2: a day set to 0 shows Day off', (tester) async {
    await pumpWizard(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Set your time'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);

    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Day off'));
    await tester.pumpAndSettle();

    expect(find.text('Day off'), findsOneWidget);
    expect(cubit.state.daysOff, {DateTime.friday});
  });

  testWidgets('an AI error shows the error card with Try again', (
    tester,
  ) async {
    when(() => generator.generate(any())).thenAnswer(
      (_) async =>
          Result.failure(AiGatewayFailure(AiErrorCode.providerUnavailable)),
    );
    await pumpWizard(tester);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    await tester.tap(find.text('Generate plan'));
    await tester.pumpAndSettle();

    expect(find.text(AiErrorCode.providerUnavailable.message), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
    // Nothing was saved.
    expect((await repository.getActivePlan()).dataOrNull, isNull);
  });
}
