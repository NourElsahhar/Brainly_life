import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/features/study_planner/data/models/study_enums.dart';
import 'package:brainly_life/features/study_planner/data/models/topic_model.dart';
import 'package:brainly_life/features/study_planner/presentation/widgets/topic_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const topic = Topic(
    id: 'forces',
    subjectId: 'physics',
    title: 'Forces',
    difficulty: 4,
    estimatedMinutes: 90,
    status: TopicStatus.inProgress,
    completedMinutes: 30,
  );

  Future<void> pumpTile(WidgetTester tester, Widget tile) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: tile),
      ),
    );
  }

  group('formatStudyMinutes', () {
    test('formats minutes and hours', () {
      expect(formatStudyMinutes(45), '45 min');
      expect(formatStudyMinutes(60), '1 h');
      expect(formatStudyMinutes(90), '1.5 h');
      expect(formatStudyMinutes(140), '2 h 20 min');
    });
  });

  testWidgets('shows title, estimate, status and difficulty', (tester) async {
    await pumpTile(
      tester,
      TopicTile(topic: topic, onEdit: () {}, onDelete: () {}),
    );

    expect(find.text('Forces'), findsOneWidget);
    expect(find.text('Est. 1.5 h'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    // The tappable card merges its texts into one label for screen
    // readers, so look for the difficulty inside it.
    expect(find.bySemanticsLabel(RegExp('Difficulty 4 of 5')), findsOneWidget);
  });

  testWidgets('tap edits, the menu edits or deletes', (tester) async {
    var edits = 0;
    var deletes = 0;
    await pumpTile(
      tester,
      TopicTile(topic: topic, onEdit: () => edits++, onDelete: () => deletes++),
    );

    await tester.tap(find.text('Forces'));
    await tester.tap(find.byTooltip('Topic options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(edits, 1);
    expect(deletes, 1);
  });
}
