// Tests for PriorityChip, DateTimePickerField and ColorPickerRow.
// Run with: fvm flutter test test/core/widgets/input_widgets_test.dart

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/color_picker_row.dart';
import 'package:brainly_life/core/widgets/date_time_picker_field.dart';
import 'package:brainly_life/core/widgets/priority_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  // A tall phone-like screen, so the pickers use their portrait layout.
  Future<void> pumpWidgetUnderTest(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  group('PriorityChip', () {
    testWidgets('shows the text and the icon of each level', (tester) async {
      final expected = {
        PriorityLevel.low: ('Low', Icons.keyboard_arrow_down_rounded),
        PriorityLevel.medium: ('Medium', Icons.drag_handle_rounded),
        PriorityLevel.high: ('High', Icons.priority_high_rounded),
      };

      for (final entry in expected.entries) {
        await pumpWidgetUnderTest(tester, PriorityChip(level: entry.key));

        expect(find.text(entry.value.$1), findsOneWidget);
        expect(find.byIcon(entry.value.$2), findsOneWidget);
      }
    });

    testWidgets('is not tappable without onTap', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        const PriorityChip(level: PriorityLevel.high),
      );

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var taps = 0;
      await pumpWidgetUnderTest(
        tester,
        PriorityChip(level: PriorityLevel.low, onTap: () => taps++),
      );

      await tester.tap(find.byType(PriorityChip));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('an unselected chip still builds', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        PriorityChip(
          level: PriorityLevel.medium,
          selected: false,
          onTap: () {},
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
    });
  });

  group('DateTimePickerField', () {
    testWidgets('shows the hint when there is no value', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(label: 'Due date', value: null, onChanged: (_) {}),
      );

      expect(find.text('Due date'), findsOneWidget);
      expect(find.text('Select date'), findsOneWidget);
    });

    testWidgets('shows the formatted date', (tester) async {
      final date = DateTime(2026, 11, 20);
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(label: 'Due date', value: date, onChanged: (_) {}),
      );

      expect(find.text(DateFormat.yMMMd().format(date)), findsOneWidget);
    });

    testWidgets('shows the error text under the field', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Exam date',
          value: null,
          errorText: 'Exam date cannot be in the past',
          onChanged: (_) {},
        ),
      );

      expect(find.text('Exam date cannot be in the past'), findsOneWidget);
    });

    testWidgets('date mode: confirming the picker calls onChanged',
        (tester) async {
      DateTime? picked;
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Due date',
          value: DateTime(2026, 11, 20),
          onChanged: (value) => picked = value,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 11, 20));
    });

    testWidgets('time mode: opens the time picker', (tester) async {
      DateTime? picked;
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Reminder',
          mode: DateTimePickerMode.time,
          value: DateTime(2026, 11, 20, 14, 30),
          onChanged: (value) => picked = value,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 11, 20, 14, 30));
    });

    testWidgets('dateTime mode: date first, then time', (tester) async {
      DateTime? picked;
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Due',
          mode: DateTimePickerMode.dateTime,
          value: DateTime(2026, 11, 20, 14, 30),
          onChanged: (value) => picked = value,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 11, 20, 14, 30));
    });

    testWidgets('clear button gives null', (tester) async {
      var cleared = false;
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Due date',
          value: DateTime(2026, 11, 20),
          clearable: true,
          onChanged: (value) => cleared = value == null,
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('a disabled field does not open the picker', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        DateTimePickerField(
          label: 'Due date',
          value: null,
          enabled: false,
          onChanged: (_) {},
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });

  group('ColorPickerRow', () {
    final colors = ColorPickerRow.defaultColors;

    testWidgets('shows one swatch for each default color', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        ColorPickerRow(selectedColorValue: null, onChanged: (_) {}),
      );

      for (final color in colors) {
        expect(find.byKey(ValueKey(color.toARGB32())), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('the selected color shows a check mark', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        ColorPickerRow(
          selectedColorValue: colors[2].toARGB32(),
          onChanged: (_) {},
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('tapping a color gives its colorValue', (tester) async {
      int? picked;
      await pumpWidgetUnderTest(
        tester,
        ColorPickerRow(
          selectedColorValue: null,
          onChanged: (value) => picked = value,
        ),
      );

      await tester.tap(find.byKey(ValueKey(colors[1].toARGB32())));
      await tester.pump();

      expect(picked, colors[1].toARGB32());
    });

    testWidgets('shows the label when given', (tester) async {
      await pumpWidgetUnderTest(
        tester,
        ColorPickerRow(
          label: 'Color',
          selectedColorValue: null,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Color'), findsOneWidget);
    });
  });
}